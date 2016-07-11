//
//  XTUITideTabBarController.h
//  XTide
//
//  Created by Lee Ann Rucker on 7/9/16.
//  Copyright © 2016 Lee Ann Rucker. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XTStation;

@protocol XTUITideView

- (void)updateStation: (XTStation *)station;

@optional

- (IBAction)reloadContent;

@end


@interface XTUITideTabBarController : UITabBarController <XTUITideView, UITabBarControllerDelegate>

@end
