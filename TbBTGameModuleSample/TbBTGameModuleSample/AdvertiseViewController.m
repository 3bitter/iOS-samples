//
//  AdvertiseViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "AdvertiseViewController.h"
#import "AppDelegate.h"

@interface AdvertiseViewController ()

@end

extern NSString *kBTFuncUsing;

@implementation AdvertiseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _btBeaconizer = [TbBTBeaconizer instantiateWithMajor:1 Minor:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL usingBTFunc = [[[NSMutableDictionary dictionaryWithDictionary:appDelegate.currentSettings] valueForKey:kBTFuncUsing] boolValue];
    if (!usingBTFunc) {
        _activateSwitch.enabled = NO;
        _statusLabel.text = @"「すれ違い機能」をオンにしてください";
    } else {
        TbBTManager *btManager = [TbBTManager sharedManager];
        if (btManager && [btManager hasDesignatedBeacon]) {
            _activateSwitch.enabled = NO;
            _statusLabel.text = @"「マイビーコン」が登録されているので、ビーコンの使用をお勧めします";
            return;
        }
        _activateSwitch.on = NO;
        // TODO(Should be): Get major & minor for this user from management server
        if (!_btBeaconizer) {
            _btBeaconizer = [TbBTBeaconizer sharedBeaconizer];
            if (!_btBeaconizer) {
                _activateSwitch.enabled = NO;
                [self showAlert];
                return;
            }
        }
        _btBeaconizer.delegate = self;
        _activateSwitch.enabled = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if(_btBeaconizer && [_btBeaconizer isActive]) {
        [_btBeaconizer resignActiveBeacon];
    }
    [super viewWillDisappear:animated];
}

- (IBAction)activateSwitchDidSwitch:(id)sender {
    if (((UISwitch *)sender).isOn) {
        [_btBeaconizer tryToActivateAsBeacon];
         _statusLabel.text = @"ビーコン発信アクティベート中です..";
    } else {
        [_btBeaconizer resignActiveBeacon];
         _statusLabel.text = @"ビーコン発信停止中です...";
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

- (void)showAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"エラー" message:@"ビーコンモードの準備に失敗しました。申し訳ありませんが、再度お試しください" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"仕方ない..." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showResultWithState:(NSNumber *)resultTypeNumber {
    switch ([resultTypeNumber integerValue]) {
        case 1:
        {
            _statusLabel.text = @"ビーコン発信しています";
            _statusLabel.textColor = [UIColor blueColor];
            CLBeaconRegion *myRegion = [_btBeaconizer myBeaconRegion];
            NSString *regionIDDescription = [myRegion.identifier stringByAppendingString:@"\nのビーコンとして発信中"];
            _regionIDLabel.text = regionIDDescription;
            break;
        }
        case 2:
            _statusLabel.text = @"制限によりアクティベートできませんでした";
            _statusLabel.textColor = [UIColor redColor];
            [_activateSwitch setOn:NO];
            _regionIDLabel.text = nil;
            break;
        case 3:
            _statusLabel.text = @"アクティベートに失敗しました";
            _statusLabel.textColor = [UIColor redColor];
            [_activateSwitch setOn:NO];
            _regionIDLabel.text = nil;
            break;
        case 4:
            _statusLabel.text = @"ビーコン発信はオフです";
            _statusLabel.textColor = [UIColor blueColor];
            _regionIDLabel.text = nil;
            break;
        case 5:
            _statusLabel.text = @"ビーコン発信の停止に失敗しました";
            _statusLabel.textColor = [UIColor redColor];
            [_activateSwitch setOn:YES];
            break;
        default:
            break;
    }
}

#pragma mark TbBTBeaconizerDelegate method

- (void)didBecomeActiveBeacon {
    NSLog(@"%s", __func__);
    assert([_btBeaconizer isActive]);
    [self performSelectorOnMainThread:@selector(showResultWithState:) withObject:[NSNumber numberWithInteger:1] waitUntilDone:NO];
}

- (void)didBlockToBecomeActiveBeaconWithReason:(NSString *)reason {
    NSLog(@"block reason: %@", reason);
    [self performSelectorOnMainThread:@selector(showResultWithState:) withObject:[NSNumber numberWithInteger:2] waitUntilDone:NO];
}

- (void)didFailToBecomeActiveBeaconWithError:(NSString *)error {
    NSLog(@"Error:%@", error);
    [self performSelectorOnMainThread:@selector(showResultWithState:) withObject:[NSNumber numberWithInteger:3] waitUntilDone:NO];
}

- (void)didResignActiveBeacon {
    NSLog(@"%s", __func__);
     [self performSelectorOnMainThread:@selector(showResultWithState:) withObject:[NSNumber numberWithInteger:4] waitUntilDone:NO];
}

- (void)didFailToResignActiveBeaconWithReason:(NSString *)reason {
    NSLog(@"block reason: %@", reason);
     [self performSelectorOnMainThread:@selector(showResultWithState:) withObject:[NSNumber numberWithInteger:5] waitUntilDone:NO];

}

@end
