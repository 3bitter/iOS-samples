//
//  BTUseDescriptionViewController.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/05/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "BTUseDescriptionViewController.h"
#import "BTFunctionSettingsViewController.h"

@interface BTUseDescriptionViewController ()

@end

@implementation BTUseDescriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews {
    _guideView.contentSize = CGSizeMake(360.0, 1750.0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)closeButtonDidPush:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
