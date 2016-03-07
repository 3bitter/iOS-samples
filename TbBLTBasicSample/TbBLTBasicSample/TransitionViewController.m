//
//  TransitionViewController.m
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "TransitionViewController.h"
#import "AppDelegate.h"
#import "BaseNotificationViewController.h"

#import "TbBTManager.h"
#import <CoreBluetooth/CoreBluetooth.h> // Just for dialog

extern NSString *kBaseLocServiceEnabled;
extern NSString *kAlwaysLocServicePermitted;
extern NSString *kAlwaysLocServiceDenied;

NSString *kBeaconUseKey = @"UseBRContents";

@interface TransitionViewController()<TbBTManagerDelegate>

@property (assign, nonatomic) BOOL brPermitted; // Beacon reagion contents wanted by user
@property (assign, nonatomic) BOOL locServiceStateDetermined;
@property (assign, nonatomic) BOOL locServiceForAppDetermined;
@property (assign, nonatomic) BOOL bluetoothStateDetermined;
@property (strong, nonatomic) TbBTManager *btManager;

@end

@implementation TransitionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    _locServiceStateDetermined = NO;
    _locServiceForAppDetermined = NO;
    _bluetoothStateDetermined = NO;
    _brPermitted = NO;
   // [self loadBRUserPermission];
   // if (!_brPermitted) {
        _requireNotification = YES;
   // }
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    [super viewDidAppear:animated];
    
    // Observer for user permission
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kBaseLocServiceEnabled object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kAlwaysLocServicePermitted object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kAlwaysLocServiceDenied object:appDelegate];
    
    if (_requireNotification) {
        [self showNotificationViewAsPop];
    } else {
        if (appDelegate.skipBLT) { // Skip explicitly
            [self gotoMenuPage];
        }
        if (![TbBTManager isBeaconEventConditionMet]) { // Simple check
            if  (!_locServiceStateDetermined || !_locServiceForAppDetermined) { // Location service status not checked
                _stateLabel.text = @"現在の設定では限定コンテンツが使用できません";
                [self checkLocServiceStateAndContinue];
            }
        } else if (!_bluetoothStateDetermined){ // Bluetooth status not checked yet
            [self prepareBeaconManager];
            [self checkBluetoothState];
        } else { // Every setting is O.K.
            [self gotoMenuPage];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_locServiceForAppDetermined && _locServiceForAppDetermined) {
        // Quit observe for permission changing
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)showNotificationViewAsPop {
    // Show popover notification page
    BaseNotificationViewController *notificationVC = (BaseNotificationViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"BaseNotificationViewController"];
    notificationVC.modalPresentationStyle = UIModalPresentationFormSheet;
    notificationVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:notificationVC animated:YES completion:nil];
}

- (void)didConfirmNotification {
    [self saveBRUserPermission];
    _requireNotification = NO;
}

- (void)didDetermineLocationState {
    NSLog(@" -- %s --", __func__);
    
    if (!_locServiceStateDetermined || !_locServiceForAppDetermined)  {
        while (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState) {
            [NSThread sleepForTimeInterval:0.5];
            NSLog(@"Sleeping........");
        }
        [self checkLocServiceStateAndContinue];
    }else if (_locServiceForAppDetermined
              && _locServiceForAppDetermined
              &&!_bluetoothStateDetermined) {// At last check current bluetooth condition
        [self prepareBeaconManager];
        [self checkBluetoothState];
    }
}

- (void)gotoMenuPage {
    UITabBarController *baseMenuController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MenuTabBarController"];
    //[self presentViewController:baseMenuController animated:YES completion:nil];
   // [self.view addSubview:baseMenuController.view];
    [self.navigationController pushViewController:baseMenuController animated:YES];
}

# pragma  mark Beacon Related methods

- (void)loadBRUserPermission {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _brPermitted = [[userDefaults valueForKey:kBeaconUseKey] boolValue];
}

- (void)saveBRUserPermission {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:kBeaconUseKey];
        [userDefaults synchronize];
}

- (BOOL)checkBasicSupportAndUserSettingCondition {
    return [TbBTManager isBeaconEventConditionMet];
}

- (void)checkLocServiceStateAndContinue {
    NSLog(@"-- %s --", __func__);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.locManager && ![self prepareLocManager]) {
        // Can not use. Skip beacon service ..
        NSLog(@"何らかの制約によりサービス機能を初期化できません。スキップします");
        [self gotoMenuPage];
    } else if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"位置情報サービス自体がオフ");
        assert(appDelegate.locManager);
        [appDelegate.locManager requestAlwaysAuthorization];// Show loc service dialog by framework
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
         NSLog(@"アプリに対しての位置情報サービス許可がされていない");
        _locServiceStateDetermined = YES;
        [appDelegate.locManager requestAlwaysAuthorization];// Show app permission dialog by framework
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways
               || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied
               || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
         NSLog(@"アプリに対しての位置情報サービス許可が決定した");
        // Location Service is O.K. Prepare beacon manager
        _locServiceForAppDetermined = YES;
    } else {
        _locServiceStateDetermined = YES;
        _locServiceForAppDetermined = YES;
        // Location Service is O.K. Prepare beacon manager
    }
}

- (void)checkBluetoothState {
       NSLog(@"--%s--", __func__);
    // [self prepareBeaconManager] is required before this call
    TbBTManager *btManager = [TbBTManager sharedManager];
    assert(btManager != nil);
    assert([btManager.delegate isEqual:self]);
    [[TbBTManager sharedManager] checkCurrentBluetoothAvailability];
}

// Can be skipped if location manager already exists
- (BOOL)prepareLocManager {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.locManager = [[CLLocationManager alloc] init];
    appDelegate.locManager.delegate = appDelegate;
    
    if (appDelegate.locManager) {
        return YES;
    }
    return NO;
}

- (BOOL)prepareBeaconManager {
   
    _btManager = [TbBTManager sharedManager];
    if (!_btManager) {
        _btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
    }
    if (_btManager) {
        _btManager.delegate = self;
        return YES;
    }
    return NO;
}

#pragma mark TbBTManagerDelegate method (Bluetooth checkonly)

- (void)didDetermineBlutoothAvailability:(BOOL)available {
    NSLog(@"--%s--", __func__);
    if (!available) {
        //[self showCustomAlert];
        [self showDefaultAlertWithCBFramework];
    } else { // Now Bluetooth is ON
        _bluetoothStateDetermined = YES;
       [self performSelectorOnMainThread:@selector(gotoMenuPage) withObject:nil waitUntilDone:NO];
    }
}

- (void)showCustomAlert {
    // Show custom alert dialog by yourself
}

- (void)showDefaultAlertWithCBFramework {
    // CoreBluetooth.framework is required
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    assert(centralManager);
    // Framework dialog may appear
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
