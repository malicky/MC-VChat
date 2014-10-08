//
//  VCSessionController.m
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import "VCSessionController.h"
#import <GameKit/GameKit.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>

@interface VCSessionController () <GKVoiceChatClient>
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;
@end

static NSString * const kMCSessionServiceType = @"p2pVideoChat";

@implementation VCSessionController
{
    MCSessionState _currentState;
    NSString *_displayName;

}

#pragma mark - Memory management

- (void)dealloc
{
    // Unregister for notifications on deallocation.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Nil out delegates
    _session.delegate = nil;
    _serviceAdvertiser.delegate = nil;
    _serviceBrowser.delegate = nil;
}

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        // Register for notifications
        [defaultCenter addObserver:self
                          selector:@selector(startServices)
                              name:UIApplicationWillEnterForegroundNotification
                            object:nil];
        [defaultCenter addObserver:self
                          selector:@selector(stopServices)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        
        [self startServices];
        _displayName = self.session.myPeerID.displayName;
        [self startAudioServices];
        
    }
    return self;
}

- (void)startAudioServices
{
    // Start the audio session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if (![audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error])
    {
        NSLog(@"Error setting the AV play/record category: %@", [error
                                                                 localizedDescription]);
        return;
    }
    
    if (![audioSession setActive: YES error: &error])
    {
        NSLog(@"Error activating the audio session: %@", [error
                                                          localizedDescription]);
        return;
    }
    
    //BOOL  b = [[GKVoiceChatService defaultVoiceChatService] isVoIPAllowed];
    
}

#pragma mark - Override property accessors

- (MCPeerID *)connectedPeer:(MCPeerID *)pid
{
    NSUInteger idx = [self.session.connectedPeers indexOfObjectIdenticalTo:pid];
    if (idx == NSNotFound) {
        return nil;
    }
    return self.session.connectedPeers[idx];
    
}
- (MCSession *)getSession
{
    return self.session;
}
- (MCSessionState)getCurrentSessionState
{
    return _currentState;
}

- (NSArray *)connectedPeers
{
    return self.session.connectedPeers;
}
#pragma mark - Private methods

- (void)setupSession
{
    _currentState = MCSessionStateNotConnected;
    // Create the session that peers will be invited/join into.
    _session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
    
    // Create the service advertiser
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                           discoveryInfo:nil
                                                             serviceType:kMCSessionServiceType];
    self.serviceAdvertiser.delegate = self;
    
    // Create the service browser
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID
                                                       serviceType:kMCSessionServiceType];
    self.serviceBrowser.delegate = self;
}

- (void)teardownSession
{
    [self.session disconnect];
}

- (void)startServices
{
    [self setupSession];
    [self.serviceAdvertiser startAdvertisingPeer];
    [self.serviceBrowser startBrowsingForPeers];
    
    [GKVoiceChatService defaultVoiceChatService].client = self;
    
}

- (void)stopServices
{
    [self.serviceBrowser stopBrowsingForPeers];
    [self.serviceAdvertiser stopAdvertisingPeer];
    [self teardownSession];
}

#pragma mark - MCSessionDelegate protocol conformance

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]);
    
    switch (state)
    {
        case MCSessionStateConnecting:
        {
            _currentState = MCSessionStateConnecting;
            NSLog(@"connecting peer:%@ to session with:%@: " ,peerID.displayName, self.peerID.displayName);
        }
            break;
            
        case MCSessionStateConnected:
        {
            _currentState = MCSessionStateConnected;
            NSError *error;
            if (![[GKVoiceChatService defaultVoiceChatService] startVoiceChatWithParticipantID: peerID.displayName error: &error])
            {
                NSLog(@"Error starting voice chat: %@", [error userInfo]);
            }
        }
            break;
            
        case MCSessionStateNotConnected:
        {
            _currentState = MCSessionStateNotConnected;
            NSLog(@"not connected peer:%@ to session with:%@: " ,peerID.displayName, self.peerID.displayName);
            [[GKVoiceChatService defaultVoiceChatService] stopVoiceChatWithParticipantID:peerID.displayName];
            
        }
            break;
            
    }
    
    if ([_session.connectedPeers count]== 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"multiPEER_VideOoutput_NOT_CONNECTED" object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"multiPEER_VideOoutput_CONNECTED" object:self];
    }
    
    [self.delegate sessionDidChangeState:_currentState peer:peerID];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Current session peer with:%@ didReceiveData from peer:%@ " ,self.peerID.displayName, peerID.displayName);
    [self.delegate didReceiveData:(NSData *)data fromPeer:peerID];
    
    
    
    //    // Decode the incoming data to a UTF8 encoded string
    //    NSString *receivedMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"didReceiveData %@ from %@", receivedMessage, peerID.displayName);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"didStartReceivingResourceWithName [%@] from %@ with progress [%@]", resourceName, peerID.displayName, progress);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"didFinishReceivingResourceWithName [%@] from %@", resourceName, peerID.displayName);
    
    // If error is not nil something went wrong
    if (error)
    {
        NSLog(@"Error [%@] receiving resource from %@ ", [error localizedDescription], peerID.displayName);
    }
    else
    {
        // No error so this is a completed transfer.  The resources is located in a temporary location and should be copied to a permenant location immediately.
        // Write to documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths firstObject], resourceName];
        if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
        {
            NSLog(@"Error copying resource to documents directory");
        }
        else
        {
            // Get a URL for the path we just copied the resource to
            NSURL *url = [NSURL fileURLWithPath:copyPath];
            NSLog(@"url = %@", url);
        }
    }
}

- (void)sendDataToConnectedPeers:(NSData*)data
{
    if ([_session.connectedPeers count]!= 0) {
        NSLog(@"current session with peer:%@ sendDataToAll peers:%@" ,self.peerID.displayName, _session.connectedPeers);
        [_session sendData:data toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    }
}
// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"didReceiveStream %@ from %@", streamName, peerID.displayName);
}

- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";
            
        case MCSessionStateConnecting:
            return @"Connecting";
            
        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}
#pragma mark - MCNearbyServiceBrowserDelegate protocol conformance

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSString *remotePeerName = peerID.displayName;
    
    NSLog(@"Browser found %@", remotePeerName);
    
    MCPeerID *myPeerID = self.session.myPeerID;
    
    BOOL shouldInvite = ([myPeerID.displayName compare:remotePeerName] == NSOrderedDescending);
    
    if (shouldInvite)
    {
        NSLog(@"Inviting %@", remotePeerName);
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:30.0];
    }
    else
    {
        NSLog(@"Not inviting %@", remotePeerName);
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"lostPeer %@", peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"didNotStartBrowsingForPeers: %@", error);
}

#pragma mark - MCNearbyServiceAdvertiserDelegate protocol conformance

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"didReceiveInvitationFromPeer %@", peerID.displayName);
    
    invitationHandler(YES, self.session);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"didNotStartAdvertisingForPeers: %@", error);
}

#pragma mark -
#pragma mark GKVoiceChatClient delegate methods
- (void)voiceChatService:(GKVoiceChatService *)voiceChatService
                sendData:(NSData *)data
         toParticipantID:(NSString *)participantID {
    // [self sendPacket:data ofType:PacketTypeVoice toParticipantID:participantID];
    
    MCPeerID *peer = [self connectedPeerNamed:participantID];
    if (peer) {
        NSArray * peers = @[peer];
        NSError *error = nil;
        [_session sendData:data toPeers:peers withMode:MCSessionSendDataReliable error:&error];
        if (error) {
            assert(error);
        }
    }
}

- (NSString *)participantID {
    return self.peerID.displayName;
}

- (MCPeerID *)connectedPeerNamed:(NSString *)peerDisplaName
{
    for (MCPeerID *peerID in self.session.connectedPeers)
    {
        if ([peerDisplaName isEqualToString:peerID.displayName])
        {
            return peerID;
        }
    }
    return nil;
}
@end
