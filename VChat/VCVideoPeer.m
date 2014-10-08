//
//  VCVideoPeer.m
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import "VCVideoPeer.h"

@interface VCVideoPeer ()
{
    NSTimer* _playerClock;
    NSNumber* _fps;
    NSMutableArray* _frames;
    NSInteger _numberOfFramesAtLastTick;
    BOOL _isPlaying;
    NSInteger _numberOfTicksWithFullBuffer;
    MCPeerID* _peerID;
    MCSession *_session;
}
@end

@implementation VCVideoPeer
- (instancetype) initWithPeer:(MCPeerID*) peerID andSession:(MCSession *)session
{
    self = [super init];
    if (self) {
        _frames = @[].mutableCopy;
        _isPlaying = NO;
        _peerID = peerID;
        _numberOfTicksWithFullBuffer = 0;
        _session = session;
        //_useAutoFramerate = YES;
    }
    return self;
}

- (void) addImageFrame:(UIImage*) image withFPS:(NSNumber*) fps
{
    if (!image) {
        return;
    }
    _fps = fps;
    if (!_playerClock || (_playerClock.timeInterval != (1.0/fps.floatValue))) {
        //  NSLog(@"(%@) changing framerate: %f", _peerID.displayName, fps.floatValue);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_playerClock) {
                [_playerClock invalidate];
            }
            
            NSTimeInterval timeInterval = 1.0 / [fps floatValue];
            _playerClock = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(playerClockTick)
                                                          userInfo:nil
                                                           repeats:YES];
        });
    }
    [_frames addObject:image];
}

- (void) playerClockTick
{
    
    NSInteger delta = _frames.count - _numberOfFramesAtLastTick;
    //    NSLog(@"(%@) fps: %f frames total: %lu  frames@last: %lu delta: %lu", _peerID.displayName,
    //          _fps.floatValue, (unsigned long)_frames.count, (long)_numberOfFramesAtLastTick, (long)delta);
    _numberOfFramesAtLastTick = _frames.count;
    if (_isPlaying) {
        if(_frames.count >= 1)
        {
            if (self.useAutoFramerate) {
                if (_frames.count >= 10) {
                    if (_numberOfTicksWithFullBuffer >= 30) {
                        // higher framerate
                        //if (self.delegate)
                        {
                            [self raiseFramerateForPeer:_peerID];
                        }
                        _numberOfTicksWithFullBuffer = 0;
                    }
                    
                    _numberOfTicksWithFullBuffer++;
                } else {
                    _numberOfTicksWithFullBuffer = 0;
                    if (delta <= -1) {
                        // lower framerate
                        //if (self.delegate)
                        if (_fps.floatValue > 5)
                        {
                            [self lowerFramerateForPeer:_peerID];
                        }
                    }
                }
            }
            
            if (self.delegate) {
                [self.delegate showImage:_frames[0]];
            }
            [_frames removeObjectAtIndex:0];
            
            
        } else {
            _isPlaying = NO;
        }
    } else {
        if (_frames.count >= 1)
        {
            _isPlaying = YES;
        }
    }
}

- (void) raiseFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) raise framerate", peerID.displayName);
    NSData* data = [@"raiseFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_session sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}

- (void) lowerFramerateForPeer:(MCPeerID *)peerID {
    NSLog(@"(%@) lower framerate", peerID.displayName);
    NSData* data = [@"lowerFramerate" dataUsingEncoding:NSUTF8StringEncoding];
    [_session sendData:data toPeers:@[peerID] withMode:MCSessionSendDataReliable error:nil];
}
@end
