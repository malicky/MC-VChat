//
//  VCSessionController.h
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

// Delegate methods for VCSessionController
@protocol VCSessionControllerDelegate <NSObject>
// Session changed state - connecting, connected and disconnected peers changed
- (void)sessionDidChangeState:(MCSessionState)newState peer:(MCPeerID*)peerID;
- (void) didReceiveData:(NSData *)data fromPeer:(MCPeerID*)peerID;
@end

@interface VCSessionController : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
@property (nonatomic, readonly) MCSession *getSession;
@property (nonatomic, weak) id<VCSessionControllerDelegate> delegate;

- (void)sendDataToConnectedPeers:(NSData*)data;
// Helper method for human readable printing of MCSessionState. This state is per peer.
- (NSString *)stringForPeerConnectionState:(MCSessionState)state;

@end
