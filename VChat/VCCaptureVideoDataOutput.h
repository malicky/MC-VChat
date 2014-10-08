//
//  VCCaptureVideoDataOutput.h
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
@class ViewController;
@interface VCCaptureVideoDataOutput : AVCaptureVideoDataOutput
- (instancetype)initWithViewController:(ViewController*)v;
@end
