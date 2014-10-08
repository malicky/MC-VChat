
#import <AVFoundation/AVFoundation.h>

#import "AVCamPreviewView.h"
#import "ViewController.h"


@implementation AVCamPreviewView
- (void) awakeFromNib
{
    [super awakeFromNib];
    
   [self.superview removeConstraints:self.superview.constraints];
    self.translatesAutoresizingMaskIntoConstraints = YES;
    //[self setNeedsUpdateConstraints];
}

//- (CGSize)intrinsicContentSize
//{
//    CGRect frame = [AVCamViewController frameForDeviceTpe:IPHONE3x5];
//    return CGSizeMake(frame.size.width, frame.size.height);
//}

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    offset = [aTouch locationInView: self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.draggable) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.superview];
        [UIView beginAnimations:@"Dragging" context:nil];
        self.frame = CGRectMake(location.x-offset.x, location.y-offset.y, self.frame.size.width, self.frame.size.height);
        [UIView commitAnimations];
    }
}

@end
