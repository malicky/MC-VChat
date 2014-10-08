#import <UIKit/UIKit.h>

@class AVCaptureSession;
@interface AVCamPreviewView : UIView {
    CGPoint offset;
}
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, assign) BOOL draggable;
@end
