//
//  SampleSettingViewController.m
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2017年 3bitter Inc. All rights reserved.
//

#import "SampleSettingViewController.h"

#import "AppDelegate.h"
#import "TbBTManager.h"

#import <UserNotifications/UNUserNotificationCenter.h>

@interface SampleSettingViewController ()

@end

@implementation SampleSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // プッシュ通知の許可がされていなければ確認
    if (NSFoundationVersionNumber_iOS_7_1 < NSFoundationVersionNumber <NSFoundationVersionNumber10_0) { // Just in case
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound|UIUserNotificationTypeAlert|UIUserNotificationTypeBadge categories:nil]];
        }
    } else if (NSFoundationVersionNumber10_0 <= NSFoundationVersionNumber) {
        if ([UNUserNotificationCenter instanceMethodForSelector:@selector(requestAuthorizationWithOptions:completionHandler:)]){
            UNAuthorizationOptions options =
            (UNAuthorizationOptionSound + UNAuthorizationOptionAlert + UNAuthorizationOptionBadge);
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError *_Nullable error) {
                if (!granted) {
                    NSLog(@"Notification not granted.");
                    _monitoringSwitch.enabled = NO;
                    _monitoringSwitch.userInteractionEnabled = NO;
                }
            }];
        }
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.locManager){
        _monitoringSwitch.enabled = NO;
        _monitoringSwitch.userInteractionEnabled = NO;
    } else {
        _monitoringSwitch.enabled = YES;
        _monitoringSwitch.userInteractionEnabled = YES;
        if (appDelegate.locManager.monitoredRegions.count > 0) {
            [_monitoringSwitch setOn:YES];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)monitoringSwitchDidChange:(id)sender {
    TbBTManager *btManager = [TbBTManager sharedManager];
    if (!btManager) { // Just in case
        btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
    }
    NSArray *tbBeaconRegions = [btManager initialRegions];
    if (tbBeaconRegions.count == 0) {
        NSLog(@"[Preparation error....");
        abort();
    } else {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if ([((UISwitch *)sender) isOn]) {
             [btManager startMonitoringTbBTInitialRegions:appDelegate.locManager];
            // Nearly equals
            //CLRegion *tbOfficialBeaconRegion = (CLRegion *)[tbBeaconRegions objectAtIndex:0];
            // [appDelegate.locManager startMonitoringForRegion:tbOfficialBeaconRegion];
        } else {
            [btManager stopMonitoringTbBTAllRegions:appDelegate.locManager];
           // [appDelegate.locManager stopMonitoringForRegion:tbOfficialBeaconRegion];
        }
    }
}

@end
