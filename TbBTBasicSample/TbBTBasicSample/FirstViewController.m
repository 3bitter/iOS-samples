//
//  FirstViewController.m
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "FirstViewController.h"
#import "TbBTManager.h"
#import "AppDelegate.h"
#import "ItemViewController.h"

@interface FirstViewController ()

@end

extern NSString *kAnnounceLogFile;
extern NSString *kNumberOfMonitoredRegions;

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSelectedItem:) name:@"localNotificationTapped" object:[UIApplication sharedApplication].delegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 現時点でモニタリングされている領域の数と、　記録されているイベントログの表示
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSUInteger numberOfMonitoredRegions = appDelegate.appLocManager.monitoredRegions.count;
    _numberOfRegionsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfMonitoredRegions];

    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    NSError *error = nil;
    _announceView.text = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
}

- (void)showSelectedItem:(NSNotification *)notification {
    ItemViewController *itemVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ItemViewController"];
    assert(itemVC);
    NSString *imageName = (NSString *)[[notification userInfo] objectForKey:@"selection"];
    itemVC.selectedItemImage = [UIImage imageNamed:imageName];
    [self presentViewController:itemVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
