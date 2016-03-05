//
//  BaseNotificationViewController.h
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseNotificationViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *notificationView;
@property (weak, nonatomic) IBOutlet UIButton *confirmedButton;

- (IBAction)confirmedButtonDidPush:(id)sender;

@end
