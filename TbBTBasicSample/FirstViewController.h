//
//  FirstViewController.h
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TbBTForeNotificationViewController.h"

@interface FirstViewController : UIViewController<TbBTForeNotificationViewControllerDelegate>

@property(assign, nonatomic) id<TbBTForeNotificationViewControllerDelegate> delegate;
@property(weak, nonatomic) IBOutlet UITextView *announceView;
@property(weak, nonatomic) IBOutlet UILabel *numberOfRegionsLabel;

@end

