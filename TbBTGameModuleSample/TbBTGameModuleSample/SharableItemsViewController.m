//
//  SharableItemsViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/20.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "SharableItemsViewController.h"
#import "DiscoveredItemsViewController.h"

@interface SharableItemsViewController ()

@end

@implementation SharableItemsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"discoveredItemsVC"]) {
        ((DiscoveredItemsViewController *)[segue destinationViewController]).discoveredItems = [NSArray arrayWithArray:_sharableItems];
        _sharableItems = nil;
    }
}


@end
