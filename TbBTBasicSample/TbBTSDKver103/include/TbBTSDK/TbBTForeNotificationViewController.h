//
//  TbBTForeNotificationViewController.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/18.
//  Copyright (c) 2014年 T3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TbBTPresentationInfo.h"

@protocol TbBTForeNotificationViewControllerDelegate;

@interface TbBTForeNotificationViewController : UIViewController

@property (weak, nonatomic) id<TbBTForeNotificationViewControllerDelegate> delegateVC;
@property (strong, nonatomic) UILocalNotification *presenNotification;

// UI parts
@property (strong, nonatomic) UIView *baseView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *contentLabel;
@property (strong, nonatomic) UIButton *openButton;
@property (strong, nonatomic) UIButton *nonOpenButton;

@end

@protocol TbBTForeNotificationViewControllerDelegate <NSObject>

//[Biz note] Call TbBTManager#fireRequestForPresenTap method in this method if payment model required
- (void)notificationViewController:(TbBTForeNotificationViewController *)controller didDismissByCheckContent:(NSString *)presentationID checked:(BOOL)checked;

@end