//
//  BaseNotificationViewController.m
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "BaseNotificationViewController.h"
#import "TransitionViewController.h"

@interface BaseNotificationViewController ()

@end

@implementation BaseNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _notificationView.backgroundColor = [UIColor whiteColor];
    
    CGRect infoLabelRect = CGRectMake(0.0, 0.0, _notificationView.frame.size.width - 20.0, 200.0);
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:infoLabelRect];
    infoLabel.numberOfLines = 3;
    infoLabel.font = [UIFont systemFontOfSize:13.0];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.text = @"位置情報サービスとBluetoothをオンにしておくと、XXXXXXに行ったときに限定コンテンツが使用できるよ。";
    [_notificationView addSubview:infoLabel];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirmedButtonDidPush:(id)sender {
    TransitionViewController *transitionVC = [((UINavigationController *)self.presentingViewController).childViewControllers objectAtIndex:0];
    [transitionVC didConfirmNotification];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
