//
//  ViewController.h
//  VChat
//
//  Created by Malick Youla on 2014-10-07.
//  Copyright (c) 2014 Malick Youla. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
- (void)setupPreviewView:(BOOL)noConnectedPeers;
- (void)sendDataToConnectedPeers:(NSData*)data;
@end

