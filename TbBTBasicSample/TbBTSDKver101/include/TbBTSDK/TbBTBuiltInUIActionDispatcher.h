//
//  TbBTBuiltInUIActionDispatcher.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/16.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TbBTDefaults.h"
#import "TbBTServiceHelper.h"
#import "TbBTPresentationInfo.h"

@interface TbBTBuiltInUIActionDispatcher : NSObject<TbBTServiceHelperDelegate>

// Return singleton instance of this class
+ (TbBTBuiltInUIActionDispatcher *)sharedDispatcher;

// Present built-in agreement view from delegate view controller
- (void)presentTbBTAgreementViewControllerFromVC:(id)delegateVC;

// Present built-in view or given URL from delegate view controlller, according to presentation type
- (void)dispatchActionWithURL:(NSString *)contentURL presenType:(TbBTViewPresentationType)presenType presentFromViewController:(UIViewController *)presentVC;
// Present built-in view for given notification from delegate view controller
- (void)dispatchActionWithNotification:(UILocalNotification *)notification presentFromViewController:(UIViewController *)presentVC;

// Present built-in campaign notification view from view controller
- (void)showForeNotificationView:(UILocalNotification *)presenNotification fromViewController:(id)delegateVC;

@end