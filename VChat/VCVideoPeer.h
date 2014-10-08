//
//  VCVideoPeer.h
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>


@protocol VCVideoPeerDelegate <NSObject>
- (void) showImage:(UIImage*) image;
@end

@interface VCVideoPeer : MCPeerID
@property (strong, nonatomic) id delegate;
@property BOOL useAutoFramerate;

- (void) addImageFrame:(UIImage*) image withFPS:(NSNumber*) fps;
- (instancetype) initWithPeer:(MCPeerID*) peerID andSession:(MCSession *)session;

@end
