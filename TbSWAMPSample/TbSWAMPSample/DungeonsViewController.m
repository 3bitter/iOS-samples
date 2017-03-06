//
//  DungeonsViewController.m
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import "DungeonsViewController.h"
#import "ContentManager.h"
#import "OurContent.h"
#import "ContentManager.h"
#import "DungeonsViewController.h"
#import "TbBTManager.h"

extern NSString *kBeaconUseKey;

extern NSString *kRangingStarted;
extern NSString *kBeaconRangingFailed;
extern NSString *kBeaconDidNotDetectedInRegion;
extern NSString *kBeaconMappedContentsPrepared;

extern NSString *kBaseLocServiceEnabled;
extern NSString *kAlwaysLocServicePermitted;
extern NSString *kInUseLocServicePermitted;
extern NSString *kAlwaysLocServiceDenied;

@interface DungeonsViewController ()<TbBTManagerDelegate>

@property (strong, nonatomic) TbBTManager *btManager;

@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) NSTimer *timeoutTimer;

@property (strong, nonatomic) NSMutableArray *fullContents;

@property (assign, nonatomic) BOOL locServiceStateDetermined; // Flag for location service state
@property (assign, nonatomic) BOOL locServiceForAppDetermined; // Flag for location service for app  permission
@property (assign, nonatomic) BOOL bluetoothStateDetermined; // Flag for bluetooth state
@property (assign, nonatomic) BOOL swampUsed; // Flag for swamp is used
@property (assign, nonatomic) BOOL noMapped; // Flag for beacon-based conent is mapped or not

@property (assign, nonatomic) BOOL searching;

// required iOS state check methods
- (void)checkLocServiceStateAndContinue;
- (void)checkBluetoothState;

- (void)didDetermineLocationState;

// Setup methods for Beacon detection class instances
- (BOOL)prepareLocManager;
- (BOOL)prepareBeaconManager;

- (void)startSearch;
- (void)terminateSearch;

@end

@implementation DungeonsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _fullContents = [NSMutableArray arrayWithArray:[[ContentManager sharedManager] defaultContents]];
    _noMapped = YES;
    
    /* Change this value if you want */
    _ignoreUserSettings = NO;
    
    _locServiceStateDetermined = NO;
    _locServiceForAppDetermined = NO;
    _bluetoothStateDetermined = NO;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_ignoreUserSettings) {
        // [サンプル専用実装] 実行端末の位置情報サービス使用及び、Bluetoothはオンであることを前提に、設定確認処理を無視します
        _locServiceStateDetermined = YES;
        _locServiceForAppDetermined = YES;
        _bluetoothStateDetermined = YES;
        _swampUsed = YES; // ユーザがSWAMPベースの限定機能を使用することに同意している前提
        [self prepareLocManager];
        [self prepareBeaconManager];
        [self startSearch];
    } else { // 必要なユーザー設定を全て確認する処理
        [self fullCheckUserPermissionSettings];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (_indicator) {
        [_indicator stopAnimating];
    }
    if (_searching) {
        [self terminateSearch];
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (_locServiceForAppDetermined && _locServiceForAppDetermined
        && !_searching) {
        // Quit observe for permission changing
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [super viewDidDisappear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _fullContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContentTitleCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContentTitleCell"];
    }
    OurContent *content = [_fullContents objectAtIndex:indexPath.row];
    cell.textLabel.text = content.title;
    cell.detailTextLabel.text = content.contentDescription;
    cell.imageView.image = content.icon;
    return cell;
}


# pragma mark user permission based part

- (void)fullCheckUserPermissionSettings {
    NSLog(@"%s", __func__);
    // Observer for user permission
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kBaseLocServiceEnabled object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kAlwaysLocServicePermitted object:appDelegate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetermineLocationState) name:kAlwaysLocServiceDenied object:appDelegate];
    
    /* @see TbBLTBasicSample for user pre-permission
     
     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
     _swampUsed = [[userDefaults valueForKey:kBeaconUseKey] boolValue];
     */
    // This is a simple alternative.
    _swampUsed = YES;
    
    if (_swampUsed // User confirmed to use SWAMP option
        && [TbBTManager isBeaconEventConditionMet] // Can be use beacon (if bluetooth is off, no)
        && [self prepareLocManager] // Prepare Location manager if not exists
        && [TbBTManager sharedManager]) {  // Prepared TbBTManager before
        [self startSearch];
    } else if (NSFoundationVersionNumber_iOS_8_0 > NSFoundationVersionNumber) {
        [self prepareLocManager];
        [self prepareBeaconManager];
        [self startSearch]; // iOS 7 may show permission dialog
    } else {
        if (![TbBTManager isBeaconEventConditionMet]) {
            if  (!_locServiceStateDetermined || !_locServiceForAppDetermined) { // Location service status not checked
                NSLog(@"現在の設定では限定コンテンツが使用できません");
                [self checkLocServiceStateAndContinue];
            }
        } else if (!_bluetoothStateDetermined){ // Bluetooth status not checked yet
            if (!appDelegate.locManager) {
                [self prepareLocManager];
            }
            [self prepareBeaconManager];
            [self checkBluetoothState];
        }
    }
}
    
- (void)checkLocServiceStateAndContinue {
    NSLog(@"-- %s --", __func__);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.locManager && ![self prepareLocManager]) {
    // Can not use. Skip beacon service ..
    NSLog(@"何らかの制約によりサービス機能を初期化できません。スキップします");
        [self startSearch];
    } else if (![CLLocationManager locationServicesEnabled]) {
    NSLog(@"位置情報サービス自体がオフ");
        if (NSFoundationVersionNumber_iOS_8_0 <= NSFoundationVersionNumber) {
        assert(appDelegate.locManager);
        [appDelegate.locManager requestAlwaysAuthorization];// Show loc service dialog by framework
        } else {
            _locServiceStateDetermined = YES;
        }
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
    NSLog(@"アプリに対しての位置情報サービス許可がされていない");
        _locServiceStateDetermined = YES;
        if (NSFoundationVersionNumber_iOS_8_0 <= NSFoundationVersionNumber) {
            [appDelegate.locManager requestAlwaysAuthorization];// Show app permission dialog by framework
        }
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied
               || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        NSLog(@"アプリに対しての位置情報サービス使用許可が決定した（許可はされていない）");
        _locServiceForAppDetermined = YES;
        _swampUsed = NO;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"アプリに対しての位置情報サービス使用許可が決定した（許可されている）");
        _locServiceForAppDetermined = YES;
        _swampUsed = YES;
        if (!_bluetoothStateDetermined) {
            if (!_btManager) {
                [self prepareBeaconManager];
            }
            [self checkBluetoothState];
        } else { // Start search on UI thread
            [self performSelectorOnMainThread:@selector(startSearch) withObject:nil waitUntilDone:NO];
        }
    } else { // When is use
        _locServiceStateDetermined = YES;
        _locServiceForAppDetermined = YES;
        // Location Service is O.K. Prepare beacon manager
    }
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

- (void)checkBluetoothState {
    NSLog(@"--%s--", __func__);
    // [self prepareBeaconManager] is required before this call
    TbBTManager *btManager = [TbBTManager sharedManager];
    assert(btManager != nil);
    assert([btManager.delegate isEqual:self]);
    [[TbBTManager sharedManager] checkCurrentBluetoothAvailability];
}

- (void)showDefaultAlertWithCBFramework {
    // CoreBluetooth.framework is required
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    assert(centralManager);
    // Framework dialog may appear
}

// Can be skipped if location manager already exists
- (BOOL)prepareLocManager {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.locManager) {
        appDelegate.locManager = [[CLLocationManager alloc] init];
        appDelegate.locManager.delegate = appDelegate;
    }
    if (appDelegate.locManager) {
        return YES;
    }
    return NO;
}

# pragma mark Require managers instantiation
    
- (BOOL)prepareBeaconManager {
    _btManager = [TbBTManager sharedManager];
    if (!_btManager & _swampUsed) {
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
        NSLog(@"Bluetooth not available");
        //[self showCustomAlert];
        [self showDefaultAlertWithCBFramework];
    } else { // Now Bluetooth is ON
        NSLog(@"Bluetooth is available");
        _bluetoothStateDetermined = YES;
        [self performSelectorOnMainThread:@selector(startSearch) withObject:nil waitUntilDone:NO];

    }
}

    
#pragma mark beacon based part
    
- (void)startSearch {
    NSLog(@"%s", __func__);
    _searching = YES;
    // Add timer cancel notification (for not ranged case)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelTimeoutTimer)name:kRangingStarted object:nil];
    
    // Observers for failure cases
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearch) name:kBeaconRangingFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearch) name:kBeaconDidNotDetectedInRegion object:nil];
    
    // Observers for success case
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWithMappedContents) name:kBeaconMappedContentsPrepared object:nil];
    
    
    // Add timeout timer (ranging did not send callback)
    if (_timeoutTimer) {
        [_timeoutTimer invalidate];
    }
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(terminateSearch) userInfo:nil repeats:NO];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.cancelTimerStopped = NO;
    
    // Indicator
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.frame = CGRectMake(0.0, 0.0, 50.0, 50.0);
    _indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _indicator.opaque = NO;
        _indicator.backgroundColor = [UIColor blackColor];
        _indicator.color = [UIColor whiteColor];
        _indicator.center = self.view.center;
    }
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
    
    // Simple ranging method
    if (!_btManager) {
        _btManager = [TbBTManager sharedManager];
    }
    [_btManager startRangingTbBTStaticBeacons:appDelegate.locManager]; // Wait for callback
}

- (void)terminateSearch {
     NSLog(@"-- %s --", __func__);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    // Simple ranging method
    [_btManager stopRangingTbBTStaticBeacons:appDelegate.locManager];
    if (_timeoutTimer) {
        [self cancelTimeoutTimer];
    }
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
    _noMapped = YES;
    // Reset full contents
    _fullContents = [NSMutableArray arrayWithArray:[[ContentManager sharedManager] defaultContents]];
    [self.tableView reloadData];
    _searching = NO;
}

- (void)cancelTimeoutTimer {
    if (_timeoutTimer) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.cancelTimerStopped = YES;
    NSLog(@"ranging timeout timer canceled");
}


# pragma mark Mapped content handling

- (void)refreshWithMappedContents {
    NSLog(@"-- %s --", __func__);
    // Reset full contents
    _fullContents = [NSMutableArray arrayWithArray:[[ContentManager sharedManager] defaultContents]];
    ContentManager *contentManager = [ContentManager sharedManager];
    _limitedContents = [contentManager mappedContentsForTbBeacons];
    if (_limitedContents > 0) {
        _noMapped = NO;
        [_fullContents addObjectsFromArray:_limitedContents];
    }
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
    [self.tableView reloadData];
}

@end
