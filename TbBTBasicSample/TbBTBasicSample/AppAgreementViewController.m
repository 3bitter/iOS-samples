//
//  AppAgreementViewController.m
//  TbBTBasicSample
//
//  Created by Ueda on 2017/04/11.
//  Copyright © 2017年 3bitter.com. All rights reserved.
//

#import "AppAgreementViewController.h"

@interface AppAgreementViewController ()

@end

@implementation AppAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)agreeButtonDisPush:(id)sender {
    assert(_delegate);
    [_delegate didAgreeByUser];
}

- (IBAction)disagreeButtonDidPush:(id)sender {
    assert(_delegate);
    [_delegate didDisagreeByUser];
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
