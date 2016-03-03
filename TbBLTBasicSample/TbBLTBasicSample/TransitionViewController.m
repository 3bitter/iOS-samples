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

#import <CoreBluetooth/CoreBluetooth.h>

extern NSString *kAlwaysLocServicePermitted;
extern NSString *kAlwaysLocServiceDenied;
NSString *kBeaconUseKey = @"UseBRContents";

@interface TransitionViewController()

@property (assign, nonatomic) BOOL brPermitted; // Beacon reagion contents wanted by user

@end

@implementation TransitionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    _brPermitted = NO;
    [self loadBRUserPermission];
    if (!_brPermitted) {
        _requireNotification = YES;
    }
    // Observer for user permission
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveBRUserPermissionAndContinue) name:kAlwaysLocServicePermitted object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotoMenuPage) name:kAlwaysLocServiceDenied object:appDelegate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_requireNotification) {
        [self showNotificationViewAsPop];
    } else {
        [self decideActionByServiceAvailability];
    }
}

- (void)showNotificationViewAsPop {
    // TODO : Show popover page. This is just a short cut
    [self didNotificationConfirm];
}

- (void)didNotificationConfirm {
    [self decideActionByServiceAvailability];
}

- (void)gotoMenuPage {
    UITabBarController *baseMenuController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MenuTabBarController"];
    assert(baseMenuController);
    [self presentViewController:baseMenuController animated:YES completion:nil];
}

# pragma  mark Beacon Related methods

- (void)loadBRUserPermission {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _brPermitted = [[userDefaults valueForKey:kBeaconUseKey] boolValue];
}

- (void)saveBRUserPermissionAndContinue {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:kBeaconUseKey];
        [userDefaults synchronize];
        
        [self prepareBeaconManager];
        [self gotoMenuPage];
}

- (void)decideActionByServiceAvailability {
    if (![TbBTManager isBeaconEventConditionMet]) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (![CLLocationManager isRangingAvailable]) {
            NSLog(@"Device not supporting bluetooth..");
            [self gotoMenuPage];
        } else if (!appDelegate.locManager && ![self prepareLocManager]) {
            // Can not use location manger. Skip beacon service ..
            [self gotoMenuPage];
        } else if (![CLLocationManager locationServicesEnabled]) {
            [appDelegate.locManager requestAlwaysAuthorization];
        } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
            [appDelegate.locManager requestAlwaysAuthorization];
        } else {
            // Show dialog with framework or by yourself
             // Bluetooth check with Core Bluetooth. ignore callback
            CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
                CBCentralManagerState bluetoothState = centralManager.state;
               if (bluetoothState != CBCentralManagerStatePoweredOn) {
                   NSLog(@"Bluetooth is off");
                }
        }
    } else { // Every condition is O.K.! Can use beacon service !
        [self prepareBeaconManager];
        [self gotoMenuPage];
    }

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
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.btManager = [TbBTManager sharedManager];
    if (!appDelegate.btManager) {
        appDelegate.btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
    }
    appDelegate.btManager.delegate = appDelegate;
    if (appDelegate.btManager) {
        return YES;
    }
    return NO;
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
