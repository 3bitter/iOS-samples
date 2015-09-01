//
//  FirstViewController.m
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "FirstViewController.h"
#import "TbBTManager.h"
#import "TbBTBuiltInUIActionDispatcher.h"

@interface FirstViewController ()

@end

extern NSString *kAnnounceLogFile;

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUInteger numberOfMonitoredRegions = [[defaults valueForKey:@"numberOfMonitoredRegions"] integerValue];
    _numberOfRegionsLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)numberOfMonitoredRegions];
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    NSError *error = nil;
    _announceView.text = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark TbBTForeNotificationViewControllerDelegate method

- (void)notificationViewController:(TbBTForeNotificationViewController *)controller  didDismissByCheckContent:(NSString*)presentationID checked:(BOOL)checked {
    if (checked) {
        NSLog(@"Content checked");
        TbBTManager *btManager = [TbBTManager sharedManager];
        [btManager fireRequestForPresenTap:presentationID];
    } else {
        NSLog(@"Content not checked");
    }
    
}
@end
