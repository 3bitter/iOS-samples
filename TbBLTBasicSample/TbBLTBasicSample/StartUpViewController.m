//
//  StartUpViewController.m
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "StartUpViewController.h"
//#import "TransitionViewController.h"
#import "GuideStep1ViewController.h"

@interface StartUpViewController ()

@end

@implementation StartUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)startButtonDidPush:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([[userDefaults valueForKey:@"confirmedBefore"] boolValue] == YES) {
        // Skip guides
        UINavigationController *transitionVC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"TransitionNaviController"];
        [self presentViewController:transitionVC animated:YES completion:nil];
    } else {
        // Show guide 1
        GuideStep1ViewController *step1VC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"GuideStep1ViewController"];
        [self presentViewController:step1VC animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
