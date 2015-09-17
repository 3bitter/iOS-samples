//
//  SecondViewController.m
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "SecondViewController.h"
#import "RangedBeaconInfoViewController.h"
#import "DesignatedBeaconsViewController.h"
#import "AppDelegate.h"
#import "TbBTBuiltInUIActionDispatcher.h"

@interface SecondViewController ()<UIAlertViewDelegate>

@property (assign, nonatomic) NSUInteger monitoringStartCount;
@property (assign, nonatomic) NSUInteger monitoringFailCount;
// 新規登録用に観測されたビーコン（累積）
@property (strong, nonatomic) NSMutableArray *cumulativeRangedBeacons;
@property (assign, nonatomic) NSUInteger numberOfFoundLoop;
// タイムアウトタイマー停止指示フラグ
@property (assign, nonatomic) BOOL timerCanceled;

@property (assign, nonatomic) UIBackgroundTaskIdentifier bgRangingTask;

- (BOOL)canFireNotification;
- (void)requestUserAuthorization;

@end

extern NSString *kAnnounceLogFile;
extern NSString *kMonitoringAllowed;
extern NSString *kUsingBeaconFlag;
extern NSString *kNumberOfMonitoredRegions;

// 新規登録用ビーコン計測回数上限
static const NSUInteger RANGING_LOOP_LIMIT = 5;

NSString *kMonitoringStateFlag = @"monitoringState";

// 状態通知系
NSString *kMonitoringDidFail = @"RegionMonitoringFailed";
NSString *kRangingDidFail = @"BeaconRangingFailed";
NSString *kRangingStarted = @"RangingStarted";
NSString *kRangingTimeOverNotification = @"RangingTimedOut";
NSString *kFoundNewBeacon = @"FoundNewBeaconUnderRegistration";

// ビーコン情報ラベル
NSString *kBeaconInfoLabel = @"BeaconInfos";
NSString *kRegionLabel = @"Region";

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // サービス利用（位置モニタリング）同意フラグ
    _monitoringAndSDKServiceAgreed = [[defaults valueForKey:kMonitoringAllowed] boolValue];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_monitoringAndSDKServiceAgreed) {
        _stateDescriptionLabel.hidden = NO;
        NSMutableString *stateString = [NSMutableString stringWithString:@"位置情報の使用と"];
        [stateString appendString:@"\n"];
        [stateString appendString:@"3bitterサービスの規約に同意済みです"];
        _stateDescriptionLabel.text = stateString;
        /* LocationManagerはAppDelegateに保持されているものを参照します */
        if (!_appLocManager) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            _appLocManager = appDelegate.appLocManager;
        }
        /* TbBTManagerの共有インスタンスを取得します */
        _btManager = [TbBTManager sharedManager];
        if (!_btManager) {
            _btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
        }
    }
    // ビーコン機能を有効にしない場合はモニタリング制御スイッチを不要にしています
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL usingBeaconFunc = [[defaults valueForKey:kUsingBeaconFlag] boolValue];
    if (!usingBeaconFunc) {
        _beaconFunctionSwitch.on = NO;
        _targetMonitoringSwitch.on = NO;
        _targetMonitoringSwitch.enabled = NO;
    } else {
        _beaconFunctionSwitch.on = YES;
        _targetMonitoringSwitch.enabled = YES;
    }
    BOOL monitoringIsOn = [[defaults valueForKey:kMonitoringStateFlag] boolValue];
    if (monitoringIsOn && _appLocManager.monitoredRegions.count > 0) {
        _targetMonitoringSwitch.on = YES;
    } else {
        _targetMonitoringSwitch.on = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    self.stateDescriptionLabel.text = nil;
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveAgreement {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:kMonitoringAllowed];
    [defaults synchronize];
}

// Show description & my beacon registration view
- (IBAction)beaconFunctionSwitched:(id)sender {
    if ([(UISwitch *)sender isOn]) {
        /* ビーコン（領域）ベースのイベントに反応するかチェックします */
        BOOL canUse = [TbBTManager isBeaconEventConditionMet];
        if (!canUse) {
            [self checkAgreementAndContinue];
        } else {
            _targetMonitoringSwitch.enabled = YES;
            _targetMonitoringSwitch.on = NO;
        }
    } else {
        /* 3bitterビーコン領域のイベント関連に反応しないようにモニタリング処理を止めます */
        _targetMonitoringSwitch.on = NO;
        _targetMonitoringSwitch.enabled = NO;
        assert(_btManager);
        assert(_appLocManager);
        [_btManager stopMonitoringTbBTAllRegions:_appLocManager];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:[NSNumber numberWithBool:NO] forKey:kUsingBeaconFlag];
        [defaults synchronize];
    }
}

// モニタリング制御例：ユーザ指定のビーコンがある場合のみモニタリングを開始
- (IBAction)targetMonitoringChanged:(id)sender {
    assert(_btManager);
    assert(_appLocManager);
    BOOL monitoring = NO;
    if (_targetMonitoringSwitch.isOn) {
        if ([_btManager hasDesignatedBeacon]) {
            // 指定ビーコンの領域情報をSDKを介して取得し、モニタリングを開始します
            NSArray *regionsOfDesignatedBeacons = [_btManager regionsOfDesignatedBeacons];
            for (CLBeaconRegion *beaconRegion in regionsOfDesignatedBeacons) {
                [_appLocManager startMonitoringForRegion:beaconRegion];
            }
        }
        monitoring = YES;
    } else {
        // 指定ビーコンまたは3bitter専用ビーコンの初期のモニタリングを停止します
        [_btManager stopMonitoringTbBTAllRegions:_appLocManager];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithBool:monitoring] forKey:kMonitoringStateFlag];
    [defaults synchronize];
}

- (void)checkAgreementAndContinue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL serviceAgreed = [[defaults valueForKey:kMonitoringAllowed] boolValue];
    if (!serviceAgreed) {
        /* 3bitter側で用意のビーコン機能使用規約の表示 */
        TbBTBuiltInUIActionDispatcher *dispatcher =[TbBTBuiltInUIActionDispatcher sharedDispatcher];
        [dispatcher presentTbBTAgreementViewControllerFromVC:self];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:[NSNumber numberWithBool:YES] forKey:kUsingBeaconFlag];
        [defaults synchronize];
        /* 規約同意済みなので機能使用の準備 */
        [self prepareManager];
    }
}

/* CLLocationManagerのインスタンス、TbBTManagerの共有インスタンスを生成 */
- (void)prepareManager {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.appLocManager) {
        CLLocationManager *newLocManager = [[CLLocationManager alloc] init];
        newLocManager.delegate = self;
        appDelegate.appLocManager = newLocManager;
    }
    _appLocManager = appDelegate.appLocManager;
    if (!_btManager) {
        // 以前に規約に同意済みならば生成される
        _btManager = [TbBTManager sharedManager];
    }
}

#pragma mark TkAgreementViewControllerDelegate method

- (void)didAgreeByUser {
    // 再起動後のために同意フラグを保存します
    [self saveAgreement];
    _monitoringAndSDKServiceAgreed = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kUsingBeaconFlag];
    [defaults synchronize];
    
    _stateDescriptionLabel.text = @"規約が同意されたので位置情報の使用を準備します";
    // 位置情報のモニタリングを可能にします
    _appLocManager = [[CLLocationManager alloc] init];
    _appLocManager.delegate = self;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.appLocManager = _appLocManager;
    
    // 3bitter システムとの連携を可能にします
    _btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
    _btManager.delegate = self;

    // 規約同意後に、OSによるアプリの位置情報許可ダイアログ（や、プッシュ通知許可ダイアログ）を提示します
    // ここで離脱した場合は、別途許可をもらう必要があります
     if ([TbBTManager isBeaconEventConditionMet] == NO || [self canFireNotification] == NO) {
         [self requestUserAuthorization];
     }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didDisagreeByUser {
    _monitoringAndSDKServiceDisagreed = YES;
    [_beaconFunctionSwitch setOn:NO];
    _stateDescriptionLabel.text = @"規約に同意がないので位置情報の使用はしません";
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Authorization

// 位置情報サービスの許可（及びプッシュ通知の許可）を確認します
- (void)requestUserAuthorization {
    
    // Local Notification Permission
    UIApplication *application = [UIApplication sharedApplication];
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound|UIUserNotificationTypeAlert|UIUserNotificationTypeBadge categories:nil]];
    }
    
    // Location Service Permission
    if ([TbBTManager isBeaconEventConditionMet] == NO) {
        if (NSFoundationVersionNumber <=  NSFoundationVersionNumber_iOS_7_1) {
            NSLog(@"Could not request authorization because the OS version < 8.0");
        } else {
            [_appLocManager requestAlwaysAuthorization];
        }
    }
}

- (BOOL)canFireNotification {
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        return YES;
    }
    // Check push notification
    UIUserNotificationType allowedNotificationType = [UIApplication sharedApplication].currentUserNotificationSettings.types;
    if (UIUserNotificationTypeNone == allowedNotificationType) {
        return NO;
    }
    return YES;
}

# pragma mark UIAlertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

# pragma mark CLLocationManagerDelegate

// モニタリング開始後に呼ばれます
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"-- %s --", __func__);
    // Geofence的な領域の場合は他のことをします
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSLog(@"We may do something");
        return;
    } else if ([region isKindOfClass:[CLBeaconRegion class]]) {
            // 登録済みビーコンの領域でない場合、レンジング処理を開始します（キーコード取得のため）
            if ([_btManager isInitialRegion:(CLBeaconRegion *)region]) {
                _numberOfFoundLoop = 0;
                _timerCanceled = NO;
                [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
                NSLog(@"Ranging started for region %@", region.identifier);
            }
    }
    NSLog(@"Monitoring started for region %@ with manager:%@", region.identifier, manager);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"-- didEnterRegion: %@ --", region.identifier);
    // ビーコンではない領域の場合は処理スキップしています
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"Region is not beacon type :%@", region.identifier);
        NSMutableString *message = [NSMutableString stringWithString:@"ビーコンではないモニタリング領域["];
        [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
        [message appendString:@"]に入りました"];
        [self saveAnnounceLogToFile:message];
        return;
    }
    NSMutableString *message = [NSMutableString stringWithString:@"モニタリングビーコン領域["];
    [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
    [message appendString:@"]に入りました"];
    [self saveAnnounceLogToFile:message];
    /* 別ビーコン領域がモニタリングされていて、そこに入った場合はスキップするか、何か別のことをします（例なのでこのアプリではモニタリングしていません） */
    if ([@"3rdParty'sRegionOrSomething" isEqualToString:region.identifier]) {
        NSLog(@"3rdパーティのビーコン領域に入りました");
        return;
    }
    /* ここでは、新規登録処理中でなく、3bitter専用ビーコン領域または3bitterで管理されているビーコン領域である場合にレンジングを開始しています
       （新規登録の場合は didStartMonitoringForRegionメソッド内で処理を開始しています）
     */
    //TbBTManagerの用意。規約に同意済みであれば、sharedManagerメソッドで生成できます
    _btManager = [TbBTManager sharedManager];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    assert(_btManager);
    if (!appDelegate.addProcessing && ([_btManager isReservedRegion:(CLBeaconRegion *)region]
        || [_btManager isManagedRegion:(CLBeaconRegion *)region])) {
        // ビーコンの観測（距離測定）開始
        // // バックグラウンドでレンジングを開始します
        _bgRangingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (_bgRangingTask != UIBackgroundTaskInvalid) {
                // レンジングストップを指示してタスクを終了
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [[UIApplication sharedApplication] endBackgroundTask:_bgRangingTask];
                    _bgRangingTask = UIBackgroundTaskInvalid;
                    [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                });
            }
        }];
        NSLog(@"Target Found. Start ranging in background");
        dispatch_queue_t queue;
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            // レンジング開始を指示します
            [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        });

    }
}

// 領域から出た場合はこのアプリでは何もしません
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"Region is not beacon type :%@", region.identifier);
        return;
    }
    NSMutableString *message = [NSMutableString stringWithString:@"モニタリングビーコン領域["];
    [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
    [message appendString:@"]からでました"];
    [self saveAnnounceLogToFile:message];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"--- Region is not Beacon Region ---");
        return;
    }
    if (CLRegionStateInside == state) {
        NSLog(@"Determined state: Inside of the region %@", region.identifier);
        NSMutableString *message = [NSMutableString stringWithString:@"モニタリング領域["];
        [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
        [message appendString:@"]の中にいることが検知されました"];
        [self saveAnnounceLogToFile:message];
    } else if (CLRegionStateOutside == state) {
        NSLog(@"Determined state: Outside of the region %@", region.identifier);
        NSMutableString *message = [NSMutableString stringWithString:@"モニタリング領域["];
        [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
        [message appendString:@"]の外にいることが検知されました"];
        [self saveAnnounceLogToFile:message];
    } else {
        NSLog(@"Determined state but Unknown state of the region %@", region.identifier);
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSDate *currentTime = [NSDate date];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"Detect authorization changes. requestAuthorization required if not allowed");
    if (kCLAuthorizationStatusAuthorizedAlways == status) {
        if (manager && _btManager) {
            NSUInteger numberOfMonitored = manager.monitoredRegions.count;
            [defaults setValue:[NSNumber numberWithInteger:numberOfMonitored] forKey:@"numberOfMonitoredRegions"];
            [defaults setObject:currentTime forKey:@"authorizatioznLastConfirmed"];
            [defaults synchronize];
        }
        NSLog(@"Detect [authorized] status for service.");
       
        NSString *message = @"位置情報サービス許可状態を確認しました";
        [self saveAnnounceLogToFile:message];
    } else if (kCLAuthorizationStatusRestricted == status) {
        [defaults setObject:currentTime forKey:@"authorizationLastConfirmed"];
        [defaults synchronize];
        
        NSLog(@"Authorization restricted");
    } else if (kCLAuthorizationStatusDenied == status) {
        [defaults setObject:currentTime forKey:@"authorizationLastConfirmed"];
        [defaults synchronize];
        
        NSLog(@"Authorization denied");
    } else if (kCLAuthorizationStatusNotDetermined == status) {
        // Do nothing
        NSString *message = @"位置情報サービス許可について設定されていません";
        [self saveAnnounceLogToFile:message];
         NSLog(@"Authorization not determined yet");
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed to retreive location value, %@", [error localizedDescription]);
    NSString *message = @"位置情報の取得に失敗しました";
    [self saveAnnounceLogToFile:message];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@" -- monitoringDidFailForRegion:%@ --", region);
    NSLog(@"%@", [error userInfo]);
    NSMutableString *message = [NSMutableString stringWithString:@"領域["];
    [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
    [message appendString:@"]のモニタリングに失敗しました"];
    [self saveAnnounceLogToFile:message];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.addProcessing) {
        _monitoringFailCount++;
        // モニタリング開始指示をした全領域分モニタリングに失敗したことを通知しています
        if (_monitoringFailCount == _monitoringStartCount) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMonitoringDidFail object:self];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"-- didRangeBeacons --");
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.addProcessing && !_timerCanceled) {
        // レンジングがスタートしているので、設計上の方針的にタイムアウト処理をレンジングベースに切り替えています（タイムアウトタイマーのキャンセル）
        [[NSNotificationCenter defaultCenter] postNotificationName:kRangingStarted object:self];
        _timerCanceled = YES;
        NSLog(@"-- Notification posted to cancel timeout timer --");
    }
    
    if (beacons.count == 0) {
        // exit and wait for next call
        return;
    }

    if (beacons.count > 0) {
        CLBeacon *targetBeacon = [beacons firstObject];
        NSMutableString *message = [NSMutableString stringWithString:@"ビーコン領域["];
        [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
        [message appendString:@"]内のビーコンが見つかりました"];
        [self saveAnnounceLogToFile:message];
        
        /* 別ビーコンが観測された場合 */
        // 3bitter管理以外のビーコンでは何もしない場合
        if (![_btManager isReservedRegion:region] && ![_btManager isManagedRegion:region]) {
            NSLog(@"-- Beacons in unknown region %@ is found. Do nothing. --", region.identifier);
            return;
        }
        // 3bitter管理以外のビーコンで何かする場合
       // if ([@"3rdParty'sRegionOrSomething" isEqualToString:region.identifier]) {
       //     NSLog(@"3rdパーティの領域のビーコンが見つかりました");
       //     return;
       // }
        if (!appDelegate.addProcessing) {
            if (_btManager && [_btManager hasDesignatedBeacon]) {
                if ([_btManager isDesignatedBeacon:targetBeacon]) {
                    /*  ユーザ指定登録のビーコンが見つかったので、連動処理をします */
                    NSLog(@"%s Found designated beacon", __func__);
                    NSString *selectedItemImageName = (NSString *)[appDelegate selectItemWithEntryTiming];
                    [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                    
                    NSDictionary *notificationUserInfo =[NSDictionary dictionaryWithObject:selectedItemImageName forKey:@"selection"];
                    UILocalNotification *userNotification = [[UILocalNotification alloc] init];
                    userNotification.fireDate = [NSDate date];
                    userNotification.alertBody = @"ビーコン領域にイン！";
                    userNotification.soundName = UILocalNotificationDefaultSoundName;
                    userNotification.userInfo = notificationUserInfo;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:userNotification];
                }
            }
        } else {
            // 新規登録処理の場合、ビーコンの管理情報を取得します
            if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
                // ここでは追加登録もできるように、登録済みビーコンは除いて取得します
                NSArray *rangedBeaconInfos = [_btManager keyCodesForBeaconsExcludeDesignated:beacons ofRegion:region];
                if (rangedBeaconInfos.count > 0) {
                    // 見つかったビーコンの内、新規発見のビーコンを追加します
                    if (!_cumulativeRangedBeacons) {
                        _cumulativeRangedBeacons = [NSMutableArray array];
                    }
                    // 検索累計のビーコン情報
                    if (_cumulativeRangedBeacons.count == 0) {
                        [_cumulativeRangedBeacons addObjectsFromArray:rangedBeaconInfos];
                    } else if (_cumulativeRangedBeacons.count > 0) {
                        for (TbBTServiceBeaconData  *rangedData in rangedBeaconInfos) {
                            /* 一致しているビーコンの無視
                             keycodeが取得されたビーコンは3bitterのビーコンなので、keycode文字列で比較します */
                            NSPredicate *keycodePredicate = [NSPredicate predicateWithFormat:@"keycode == %@", rangedData.keycode];
                            NSArray *hitDatas = [_cumulativeRangedBeacons filteredArrayUsingPredicate:keycodePredicate];
                            assert(hitDatas.count < 2);
                            if (hitDatas.count == 1) {
                                for (TbBTServiceBeaconData *hit in hitDatas) {
                                    NSLog(@"Match: %@", hit.keycode);
                                }
                            } else if (hitDatas.count == 0) {
                                // 一致しなかったビーコンを追加します
                                [_cumulativeRangedBeacons addObject:rangedData];
                            }
                            break;
                        }
                    }
                    _numberOfFoundLoop++;
                    NSLog(@"ビーコンのキーリストを取得しました:(%lu 回目)", (unsigned long)_numberOfFoundLoop);
                    if (_numberOfFoundLoop >= RANGING_LOOP_LIMIT) {
                        // ビーコンの発見をビーコン情報付きでコントローラに通知します
                        NSMutableDictionary *beaconInfoDict = [NSMutableDictionary dictionary];
                        [beaconInfoDict setObject:_cumulativeRangedBeacons forKey:kBeaconInfoLabel];
                        [beaconInfoDict setObject:region forKey:kRegionLabel];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFoundNewBeacon object:self userInfo:[NSDictionary dictionaryWithDictionary:beaconInfoDict]];
                        // [代替] 直接出す場合
                        // [self showRangedBeaconInfoViewWithCodes:_cumulativeRangedBeacons forRegion:region];
                        // 停止処理
                        [manager stopRangingBeaconsInRegion:region];
                        _cumulativeRangedBeacons = nil;
                          NSLog(@"-- ranging stopped --");
                    }
                } else {
                    // 新規登録用のタイムアウト
                    if (NSOrderedDescending == [[NSDate date] compare:appDelegate.addProcessTimeoutTime]) {
                        NSLog(@"-- ranging time out --");
                        // 必要ならタイムアウト通知をオブザーバに送信します
                        [[NSNotificationCenter defaultCenter] postNotificationName:kRangingTimeOverNotification object:self];
                        [manager stopRangingBeaconsInRegion:region];
                        NSLog(@"-- ranging stopped --");
                        return;
                    }
                }
            }  else {// Do nothing when app is background or inactive
                NSLog(@"アプリがアクティブになっていないため、ビーコン指定用のキーコードの取得をスキップします");
                [manager stopRangingBeaconsInRegion:region];
                NSLog(@"-- ranging stopped --");
            }
            return;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"-- rangingBeaconsDidFailForRegion --");
    NSLog(@"%@", [error userInfo]);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.addProcessing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRangingDidFail object:self];
    }
}

#pragma mark event log

- (void)saveAnnounceLogToFile:(NSString *)announceLog {
    if (announceLog == nil) {
        return;
    }
    NSMutableString *message = [NSMutableString stringWithString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle]];
    [message appendString:@" -- "];
    [message appendString:announceLog];
    [message appendString:@"\n\n"];

    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
    }
    NSError *error = nil;
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    if (error != NULL) {
        NSLog(@"save message error: %@", [error userInfo]);
    }
}

#pragma mark direct presentation

- (void)showRangedBeaconInfoViewWithCodes:(NSArray *)beaconDatas forRegion:(CLBeaconRegion *)region {
    RangedBeaconInfoViewController *rangedBeaconInfoVC = [[RangedBeaconInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
    rangedBeaconInfoVC.tbBTBeaconInfos = [NSMutableArray arrayWithArray:beaconDatas];
    rangedBeaconInfoVC.theRegion = region;
    
    DesignatedBeaconsViewController *designatedBeaconsVC = [((UITabBarController *)self.view.window.rootViewController).childViewControllers objectAtIndex:2];
    [designatedBeaconsVC stopSearchIndication];
    if (designatedBeaconsVC.view) {
        [designatedBeaconsVC presentViewController:rangedBeaconInfoVC animated:YES completion:nil];
    }
}

@end
