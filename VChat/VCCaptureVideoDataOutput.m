//
//  VCCaptureVideoDataOutput.m
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import "VCCaptureVideoDataOutput.h"
#import "ViewController.h"

@interface VCCaptureVideoDataOutput () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _sampleQueue;
    ViewController *_viewController;
}

@end

@implementation VCCaptureVideoDataOutput

- (instancetype)initWithViewController:(ViewController*)vc
{
    self = [super init];
    if (self)
    {
        _viewController = vc;
        _sampleQueue = dispatch_queue_create("VideoSampleQueue", DISPATCH_QUEUE_SERIAL);
        [self setSampleBufferDelegate:self queue:_sampleQueue];
        self.alwaysDiscardsLateVideoFrames = YES;
        
        // Set the video output to store frame in BGRA (It is supposed to be faster)
        NSDictionary* videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
        [self setVideoSettings:videoSettings];
    }
    return self;
}

- (UIImage*) cgImageBackedImageWithCIImage:(CIImage*) ciImage {
    @autoreleasepool //prevent a severe memory leak and crash
    {
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef ref = [context createCGImage:ciImage fromRect:ciImage.extent];
        UIImage* image = [UIImage imageWithCGImage:ref scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];
        CGImageRelease(ref);
        
        return image;
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    @autoreleasepool
    {
        //  NSLog(@"This is a video connection");
        
        NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
#if 1
        CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer];
        UIImage* cgBackedImage = [self cgImageBackedImageWithCIImage:ciImage];
        NSData *imageData = UIImageJPEGRepresentation(cgBackedImage, 0.2);//max compression = 0, min compression:1.0
        // maybe not always the correct input?  just using this to send current FPS...
        AVCaptureInputPort* inputPort = connection.inputPorts[0];
        AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
        CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
        NSDictionary* dict = @{
                               @"image": imageData,
                               @"timestamp" : timestamp,
                               @"framesPerSecond": @(frameDuration.timescale)
                               };
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
        [_viewController sendDataToConnectedPeers:data];
        
#else
        
      
            /*Get information about the image*/
            // Lock the base address of the pixel buffer
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
            size_t width = CVPixelBufferGetWidth(imageBuffer);
            size_t height = CVPixelBufferGetHeight(imageBuffer);
            /*Create a CGImageRef from the CVImageBufferRef*/
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
            CGImageRef newImage = CGBitmapContextCreateImage(newContext);
            // Lock the base address of the pixel buffer
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            
            /*We release some components*/
            CGContextRelease(newContext);
            CGColorSpaceRelease(colorSpace);
        
//        dispatch_queue_t consumer = dispatch_queue_create("consumer", NULL);
//        dispatch_async(consumer,
//                       ^{
            UIImage *image= [UIImage imageWithCGImage:newImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.2);//max compression = 0, min compression:1.0
            // maybe not always the correct input?  just using this to send current FPS...
            AVCaptureInputPort* inputPort = connection.inputPorts[0];
            AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
            CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
            NSDictionary* dict = @{
                                   @"image": imageData,
                                   @"timestamp" : timestamp,
                                   @"framesPerSecond": @(frameDuration.timescale)
                                   };
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
            [_viewController sendDataToConnectedPeers:data];
            
            /*We relase the CGImageRef*/
            CGImageRelease(newImage);
//        });
        
#endif
        
    }
}


@end
