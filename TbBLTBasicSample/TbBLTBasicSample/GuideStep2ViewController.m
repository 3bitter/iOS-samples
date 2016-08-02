//
//  GuideStep2ViewController.m
//  TbOnetimeDemo
//
//  Created by Ueda on 2016/08/01.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "GuideStep2ViewController.h"
#import "TransitionViewController.h"

@interface GuideStep2ViewController ()

@end

@implementation GuideStep2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)nextButtonDidPush:(id)sender {
    TransitionViewController *transitionVC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"TransitionNaviController"];
    [self presentViewController:transitionVC animated:YES completion:^{
        [self saveConfirmation];
    }];
}

- (void)saveConfirmation {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"confirmedBefore"];
    [userDefaults synchronize];
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
