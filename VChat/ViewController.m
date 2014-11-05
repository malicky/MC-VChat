//
//  ViewController.m
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AudioToolbox/AudioToolbox.h>
#import <GameKit/GameKit.h>

#import "VCCaptureVideoDataOutput.h"
#import "ViewController.h"
#import "AVCamPreviewView.h"
#import "VCSessionController.h"
#import "VCVideoPeer.h"

const uint __FRAMERATE = 3;

@interface ViewController ()<VCVideoPeerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate, VCSessionControllerDelegate>
{
    VCSessionController *_sessionController;
    NSMutableDictionary * _videoPeers;
    AVCaptureSession *_captureSession;
}

@property (weak, nonatomic) IBOutlet AVCamPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _videoPeers = [NSMutableDictionary new];
    _sessionController = [[VCSessionController alloc] init];
    _sessionController.delegate = self;
    
    [self captureVideo];
    [_captureSession startRunning];
    
    [self setupPreviewView:YES];
}


- (void)captureVideo
{
    // Create the AVCaptureSession
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Setup the preview view
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureVideoPreviewLayer.frame = CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self.previewView.layer addSublayer:captureVideoPreviewLayer];
    [[self previewView] setSession:_captureSession];
    
    // Create video device input
    AVCaptureDevice *videoDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
    
    if (videoDevice) {
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        if ([_captureSession canAddInput:videoDeviceInput])
        {
            [_captureSession addInput:videoDeviceInput];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Why are we dispatching this to the main queue?
            // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
            // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
            
            [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
        });
        
        // Create output
        VCCaptureVideoDataOutput *multipeerVideoOutput = [[VCCaptureVideoDataOutput alloc] initWithViewController:self ];
        [_captureSession addOutput:multipeerVideoOutput];
        [self setFrameRate:__FRAMERATE onDevice:videoDevice];
        
        
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No video device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void) setFrameRate:(NSInteger) framerate onDevice:(AVCaptureDevice*) videoDevice {

    if ([videoDevice lockForConfiguration:nil]) {
        videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1,(int32_t)framerate);
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1,(int32_t)framerate);
        [videoDevice unlockForConfiguration];
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendDataToConnectedPeers:(NSData*)data
{
    if ([[_sessionController getSession].connectedPeers count]!= 0)
    {
        [_sessionController sendDataToConnectedPeers:data];
    }
}

- (void)setupPreviewView:(BOOL)noPeers{
    // Setup the preview view
    CGRect frame = CGRectMake(190, 300, 120, 150);
    self.previewView.draggable = YES;
    if (noPeers == YES)
    {
        frame = self.view.frame;
        self.previewView.draggable = NO;
    }
    
    {
        self.previewView.frame = frame;
    }
    if (self.previewView.draggable)
    {
        [self.view bringSubviewToFront:self.previewView];
    }
    
}

- (void) showImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"image height: %f",image.size.height);
        NSLog(@"image width: %f",image.size.width);
        self.imageView.image = image;
        self.imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    });
}


-(void)viewDidLayoutSubviews {
    NSLog(@"%@", (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) ? @"Portrait" : @"Landscape");
    
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIDeviceOrientationPortrait:
            NSLog(@"%@", @"UIDeviceOrientationPortrait");
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"%@", @"UIDeviceOrientationPortraitUpsideDown");

            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"%@", @"UIDeviceOrientationLandscapeRight");

            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"%@", @"UIDeviceOrientationLandscapeLeft");

            break;
            
        default: //UIDeviceOrientationUnknown
            break;
    }
}


// Note that UIInterfaceOrientationLandscapeLeft is equal to UIDeviceOrientationLandscapeRight (and vice versa).
// This is because rotating the device to the left requires rotating the content to the right.
//typedef NS_ENUM(NSInteger, UIInterfaceOrientation) {
//    UIInterfaceOrientationUnknown            = UIDeviceOrientationUnknown,
//    UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
//    UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
//    UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
//    UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
//};
#pragma mark - VCSessionControllerDelegate
- (void)sessionDidChangeState:(MCSessionState)newState peer:(MCPeerID*)peerID
{
    switch (newState) {
        case MCSessionStateConnected:
        {
            NSLog(@"PEER CONNECTED: %@", peerID.displayName);
            dispatch_async(dispatch_get_main_queue(), ^{
                VCVideoPeer* newVideoPeer = [[VCVideoPeer alloc] initWithPeer:peerID andSession:[_sessionController getSession]];
                newVideoPeer.delegate = self;
                _videoPeers[peerID.displayName] = newVideoPeer;
                [UIApplication sharedApplication].idleTimerDisabled = YES;
                [self setupPreviewView:NO];
                
                
            });
        }
            break;
            
        case MCSessionStateConnecting:
            break;
            
        case MCSessionStateNotConnected: {
            NSLog(@"PEER NOT CONNECTED: %@", peerID.displayName);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_captureSession stopRunning];
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                [self setupPreviewView:YES];
                
                //                if ([self.delegate conformsToProtocol:@protocol(SGSViewControllerDelegate)]) {
                //                    [self.delegate setupPreviewView:YES];
                //                }
                // SGSVideoPeer* newVideoPeer = (SGSVideoPeer *)peerID;
                //[newVideoPeer stopPlaying];
            });
            break;
        }
            
    }
}


#pragma mark - VCSessionControllerDelegate
- (void) didReceiveData:(NSData *)data fromPeer:(MCPeerID*)peerID
{
    //  NSLog(@"(%@) Read %lu bytes", peerID.displayName, (unsigned long)data.length);
    if (data.length > 14)
    {
        @try {
            NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if (dict[@"image"])
            {
                UIImage* image = [UIImage imageWithData:dict[@"image"] scale:[UIScreen mainScreen].scale];
                NSNumber* framesPerSecond = dict[@"framesPerSecond"];
                
                VCVideoPeer* thisVideoPeer = _videoPeers[peerID.displayName];
                [thisVideoPeer addImageFrame:image withFPS:framesPerSecond];
            }
        }
        @catch (NSException *exception)
        {
            [[GKVoiceChatService defaultVoiceChatService] receivedData:data fromParticipantID:peerID.displayName];
        }
        @finally {
            ;
        }
        
    }
}


@end
