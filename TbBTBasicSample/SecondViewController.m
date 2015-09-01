//
//  SecondViewController.m
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "SecondViewController.h"
#import "TbBTBuiltInUIActionDispatcher.h"
#import "BeaconDesignateViewController.h"
#import "DesignatedBeaconsViewController.h"
#import "AppDelegate.h"

@interface SecondViewController ()<UIAlertViewDelegate>

- (BOOL)canFireNotification;
- (void)requestUserAuthorization;

@end

NSString *kLocAuthAuthorizedAlways = @"LocationAuthorizationAuthorizedAlways";
NSString *kLocAuthRestricted = @"LocationAuthorizationRestricted";
NSString *kLocAuthDenied = @"LocationAuthorizationDenied";

extern NSString *kAnnounceLogFile;

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // サービス利用（位置モニタリング）同意フラグ
    _monitoringAndSDKServiceAgreed = [[defaults valueForKey:@"locationMonitoringAgreed"] boolValue];
    if (_monitoringAndSDKServiceAgreed) {
        // 位置情報のモニタリングを可能にします
        _myLocManager = [[CLLocationManager alloc] init];
        _myLocManager.delegate = self;
        
        // 3bitter システムとの連携を可能にします
        _btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
        _btManager.delegate = self;
        
        /* オプション：モニタリングスイッチング機能の使用例。
         スイッチタイプでないビーコンが存在し、モニタリング中状態であれば、モニタリング不要になるタイミングでストップします */
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL slaveBeaconsOn = [[userDefaults valueForKey:@"slaveBeaconsON"] boolValue];
        if (slaveBeaconsOn && [_btManager currentUsableServiceBeaconDatas].count > 1) {
            if ([_btManager stopMonitoringTbBTNonSwitcherBeaconRegions:_myLocManager] > 0) {
                slaveBeaconsOn = NO;
                [userDefaults setValue:[NSNumber numberWithBool:slaveBeaconsOn] forKey:@"slaveBeaconsON"];
                [userDefaults synchronize];
            }
        }
    }
    [self setUpView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self layoutView];
    
    // ビルトインのビューを使用して規約を表示しています
    if (_monitoringAndSDKServiceAgreed == NO && _monitoringAndSDKServiceDisagreed == NO) {
        TbBTBuiltInUIActionDispatcher *dispatcher = [TbBTBuiltInUIActionDispatcher sharedDispatcher];
        [dispatcher presentTbBTAgreementViewControllerFromVC:self];
        
    } else if (_monitoringAndSDKServiceAgreed) {
        _stateDescriptionLabel.text = @"位置情報の使用と3bitterサービスの規約に同意済みです";
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

- (void)setUpView {
    
    _updateRegionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_updateRegionButton setTitle:@"位置情報の取得確認（規約）" forState:UIControlStateNormal];
    [_updateRegionButton addTarget:self action:@selector(updateRegionButtonDidPushed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_updateRegionButton];
    
    _stateDescriptionLabel = [[UILabel alloc] init];
    _stateDescriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _stateDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    _stateDescriptionLabel.numberOfLines = 2;
    _stateDescriptionLabel.font = [UIFont systemFontOfSize:13.0];
    _stateDescriptionLabel.numberOfLines = 2;
    _stateDescriptionLabel.textColor = [UIColor redColor];
    [self.view addSubview:_stateDescriptionLabel];
}

- (void)layoutView {
    CGFloat centerX = 0.0;
    CGFloat controlOriginX = 0.0;
    CGFloat controlWidth = 0.0;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat longEdgeLength = screenBounds.size.height;
    CGFloat shortEdgeLength = screenBounds.size.width;
    if (screenBounds.size.width > screenBounds.size.height) {
        longEdgeLength = screenBounds.size.width;
        shortEdgeLength = screenBounds.size.height;
    }
    UIInterfaceOrientation appOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(appOrientation)) {
        centerX = shortEdgeLength / 2;
        controlOriginX = centerX - (shortEdgeLength - 60) / 2;
        controlWidth = shortEdgeLength - 60.0;
    } else if (UIInterfaceOrientationIsLandscape(appOrientation)) {
        centerX = longEdgeLength / 2;
        controlOriginX = centerX - (longEdgeLength - 120) / 2;
        controlWidth = longEdgeLength - 120.0;
    }
    
    CGRect updateButtonFrame = CGRectMake(centerX - 90.0, 200.0, 180.0, 60.0);
    _updateRegionButton.frame =updateButtonFrame;

    CGRect stateLabelFrame = CGRectMake(controlOriginX, 280.0, controlWidth, 120.0);
    _stateDescriptionLabel.frame = stateLabelFrame;
    
}

- (void)saveAgreement {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"locationMonitoringAgreed"];
    [defaults synchronize];
}

- (void)saveTheRestPresentations4AfterUse:(NSArray *)presentations {
    NSLog(@"-- saveTheRestPresentations4AfterUse --");
    // Save given presentations
}

# pragma mark region data control method

- (void)updateRegionButtonDidPushed:(id)sender {
    if (_btManager == nil) {
        _stateDescriptionLabel.text = @"TbBTManagerのインスタンスが居ません..";
        return;
    } else {
         NSString *message = @"サービス管理の領域情報を更新します";
        [self saveAnnounceLogToFile:message];
        
        // 管理システムで使用指定された最新のビーコン領域を取得します（オプションサービス用）
        [_btManager updateManagedRegions];
    }
}

- (void)stopMonitoringAbandonedRegions {
    if (_btManager.abandonedManagedRegions.count == 0) {
        NSString *message = @" 停止対象のサービス管理領域情報はありません";
        [self saveAnnounceLogToFile:message];
    } else {
        for (CLBeaconRegion *retiredRegion in _btManager.abandonedManagedRegions) {
            [_myLocManager stopMonitoringForRegion:retiredRegion];
            NSLog(@"Monitoring for %@ stopped.", retiredRegion.identifier);
        }
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:_myLocManager.monitoredRegions.count] forKey:@"numberOfMonitoredRegions"];
    [defaults synchronize];
}

#pragma mark TkAgreementViewControllerDelegate method

- (void)didAgreeByUser {
    // 再起動後のために同意フラグを保存します
    [self saveAgreement];
    _monitoringAndSDKServiceAgreed = YES;
    _stateDescriptionLabel.text = @"規約が同意されたので位置情報の使用を準備します";
    // 位置情報のモニタリングを可能にします
    _myLocManager = [[CLLocationManager alloc] init];
    _myLocManager.delegate = self;
    
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
    _stateDescriptionLabel.text = @"規約に同意がないので位置情報の使用はしません";
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark TbBTManagerDelegate

- (void)didPrepareToRefreshRegionsWithResult:(TbBTPrepareResultType)resultType {
    NSLog(@"--- didPrepareRefreshRegionsWithResult ---");
    NSString *message = @"サービス管理の領域情報が更新されました";
    [self saveAnnounceLogToFile:message];
    
    NSArray *btMangedRegions = nil;
    switch (resultType) {
        case TbBTPrepareResultTypeHasNew:
            // 新規領域が管理に加わったので、端末で新規領域のモニタリングを開始します
            btMangedRegions = [_btManager newManagedRegions];
            assert(btMangedRegions != nil);
            for (CLBeaconRegion *managedRegion in btMangedRegions) {
                [_myLocManager startMonitoringForRegion:managedRegion];
                NSLog(@"monitoring for region %@ started", managedRegion.identifier);
            }
            break;
        case TbBTPrepareResultTypeHasAbandoned:
            // 管理から外れた領域があるので、端末で該当領域のモニタリングを停止します
            btMangedRegions = [_btManager abandonedManagedRegions];
            assert(btMangedRegions != nil);
            for (CLBeaconRegion *managedRegion in btMangedRegions) {
                [_myLocManager stopMonitoringForRegion:managedRegion];
                NSLog(@"monitoring for region %@ stopped", managedRegion.identifier);
            }
            break;
        case TbBTPrepareResultTypeHasNewAndAbandoned:
            // 管理に加えられた領域も外れた領域もあるので、端末で新管理領域のモニタリングの開始と、管理外となった領域のモニタリングを停止します
            NSLog(@"Found new and retired regions");
            btMangedRegions = [_btManager newManagedRegions];
            assert(btMangedRegions != nil);
            for (CLBeaconRegion *managedRegion in btMangedRegions) {
                [_myLocManager startMonitoringForRegion:managedRegion];
                NSLog(@"monitoring for region %@ started", managedRegion.identifier);
            }
            btMangedRegions = [_btManager abandonedManagedRegions];
            assert(btMangedRegions != nil);
            for (CLBeaconRegion *managedRegion in btMangedRegions) {
                [_myLocManager stopMonitoringForRegion:managedRegion];
                NSLog(@"monitoring for region %@ stopped", managedRegion.identifier);
            }
            break;
        case TbBTPrepareResultTypeNoDifference:
            // SDKで以前から管理されている領域と、管理システムから取得した領域に差分はありません。実際にモニタリングされている領域については関与しませんが、止まっているかもしれないのでこの例では念のため開始しています。
            NSLog(@"No new and retired regions found");
            if (_myLocManager.monitoredRegions.count == 0
                && _btManager.currentManagedRegions.count > 0) {
                btMangedRegions = [_btManager currentManagedRegions];
                assert(btMangedRegions != nil);
                for (CLBeaconRegion *managedRegion in btMangedRegions) {
                    [_myLocManager startMonitoringForRegion:managedRegion];
                    NSLog(@"monitoring for region %@ started", managedRegion.identifier);
                }
            }
            break;
        default:
            NSLog(@"Fatal Error: unknown result type !!!");
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:_myLocManager.monitoredRegions.count] forKey:@"numberOfMonitoredRegions"];
    [defaults synchronize];
}

#pragma mark SDK optional function (To be prepared in the future) delegate

- (void)didFailToPrepareLatestRegionsWithError:(NSError *)error {
    NSLog(@"--- didFailToPrepareLatestRegionsWithError: %@ ---", [error userInfo]);
    NSString *message = @"サービス管理の領域情報の更新に失敗しました";
    [self saveAnnounceLogToFile:message];
    if (self.isBeingPresented) {
        NSString *errorMessage = [@"didFailToPrepareLatestRegionsWithError:" stringByAppendingString:[error localizedDescription]];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Debug Alert" message:errorMessage delegate:self cancelButtonTitle:@"O.K." otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)didReceivePresentationInfos:(NSArray *)presentations {
    NSLog(@"--- didReceivePresentationInfos ---");
    NSString *message = @"領域向けに用意されたキャンペーン通知内容を取得しました";
    [self saveAnnounceLogToFile:message];
    TbBTPresentationInfo *firstPresentation = [presentations firstObject];
    firstPresentation.optionalBody = @"追加メッセージ";
    [_btManager fireNotificationWithInfo:firstPresentation forEvent:TbBTEventTypeDidEnter];
    [_btManager fireRequestForPresenNotificationCheck:firstPresentation.presentationID forCampaign:firstPresentation.campaignID];
    
    // 複数の通知用情報が返って来たら、残りを任意タイミングで通知 & 通知記録できるように一時保存
    if (presentations.count > 1) {
        NSRange theRestIndexRange = NSMakeRange(1, presentations.count - 1);
        NSIndexSet *theRestIndexSet = [[NSIndexSet alloc] initWithIndexesInRange:theRestIndexRange];
        NSArray *theRestOfPresentations = [presentations objectsAtIndexes:theRestIndexSet];
        [self saveTheRestPresentations4AfterUse:theRestOfPresentations];
    }
}

- (void)didCheckServiceForBeaconWithResult:(TbBTContactCheckResultType)resultType {
    NSLog(@"-- didCheckServiceForBeaconWithResult --");
    NSString *message = @"領域向けに用意されたキャンペーンの条件チェックをしました";
    [self saveAnnounceLogToFile:message];
    NSString *result = nil;
    switch (resultType) {
        case TbBTContactCheckResultTypeDoNothing:
            result = @"条件により処理の必要がありませんでした";
            break;
        case TbBTContactCheckResultTypeTargetNotFound:
            // 有効期限切れも含みます
            result = @"スポットに対しては関連キャンペーンまたはサービスがないようです";
            break;
        case TbBTContactCheckResultTypeMarked:
            result = @"スポットに対して関連キャンペーン用のチェックをしました";
            break;
        case TbBTContactCheckResultTypePartBlocked:
            // 同一端末上の複数のSDK使用アプリがあり、同じキャンペーン通知を取得すると、1つがブロックされます
            result = @"一部のキャンペーンの通知がブロックされました";
            break;
        case TbBTContactCheckResultTypeSkipped:
            // このスポットを使ったキャンペーン用のチェックが既に実行されている可能性があります
            result = @"キャンペーン用の処理はスキップされました";
            break;
        default:
            break;
    }
    if (result != nil) {
        [self saveAnnounceLogToFile:result];
    }
}

- (void)didFailToCheckServiceWithError:(NSError *)error {
    NSLog(@"-- didFailToCheckServiceWithError --");
    NSLog(@"error: %@", [error userInfo]);
    NSString *message = @"スポットのサービスチェックに失敗しました";
    [self saveAnnounceLogToFile:message];
}

- (void)didCheckFireNotificationExpectedly {
    NSString *message = @"SDKを介したローカル通知の送信と記録がされました";
    [self saveAnnounceLogToFile:message];
    NSLog(@"-- DidFireNotificationExpectedly --");
}

- (void)didBlockUserNotificationWithReason:(NSString *)reason {
    NSString *alertMessage = [@"Blocked notification because of " stringByAppendingFormat:@"%@", reason];
    NSLog(@"%@", alertMessage);
    NSString *message = @"ローカル通知がブロックされました";
    [self saveAnnounceLogToFile:message];
}

- (void)didBlockRequestNotificationCheckWithReason:(NSString *)reason {
    NSString *alertMessage = [@"Blocked notification because of " stringByAppendingFormat:@"%@", reason];
    NSLog(@"%@", alertMessage);
    NSString *message = @"ローカル通知の記録リクエストがブロックされました";
    [self saveAnnounceLogToFile:message];
}

- (void)didFailToCheckNotificationWithError:(NSError *)error {
    NSString *alertMessage = [@"Failed check to fire notification because of " stringByAppendingFormat:@"%@", [error userInfo]];
    NSLog(@"%@", alertMessage);
    NSString *message = @"ローカル通知送信の記録に失敗しました";
    [self saveAnnounceLogToFile:message];
}

- (void)didHandleTapRequestExpectedly {
    NSLog(@"-- didFireHandleTapRequestExpectedly --");
    NSString *message = @"キャンペーン通知のタップの記録がされました";
    [self saveAnnounceLogToFile:message];
}

- (void)didFailToHandleTapRequestWithError:(NSError *)error {
    NSLog(@"Handle tap request failed because of %@", [error userInfo]);
    NSString *message = @"キャンペーン通知のタップの記録に失敗しました";
    [self saveAnnounceLogToFile:message];
}


#pragma mark Authorization

// プッシュ通知の許可を確認します
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
            [_myLocManager requestAlwaysAuthorization];
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
    // GPS的な領域の場合は他のことをします
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        NSLog(@"We may do something");
        return;
    } else if ([region isKindOfClass:[CLBeaconRegion class]]) {
        // 新規登録処理の場合、登録済みビーコンをチェックします
        if (_addProcessing) {
            BOOL designated = NO;
            if ([_btManager hasDesignatedBeacon]) {
                NSArray *regionsOfDesignated = [_btManager regionsOfDesignatedBeacons];
                for (CLBeaconRegion * designatedRegion in regionsOfDesignated) {
                    if ([region.identifier isEqualToString:designatedRegion.identifier]) {
                        designated = YES;
                        break;
                    }
                }
            }
            // 登録済みビーコンでない場合、レンジング処理を開始します（キーコード取得のため）
            if (!designated) {
                [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
                NSLog(@"Ranging started for region %@", region.identifier);
            }
        }
        NSLog(@"Monitoring started for region %@ with manager:%@", region.identifier, manager);
    }
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
    /* 関係ない別ビーコン領域に入った場合はスキップするか、何か別のことをします */
    if ([@"3rdParty'sRegionOrSomething" isEqualToString:region.identifier]) {
        NSLog(@"3rdパーティのビーコン領域に入りました");
        return;
    }
    /* ここでは、3bitter専用ビーコン領域の場合と、3bitterで管理されているビーコン領域であり、新規登録でなければ、レンジングを開始しています
       （新規登録の場合は didStartMonitoringForRegionメソッド内で処理を開始しています）
     */
    if (_btManager && !_addProcessing && ([_btManager isReservedRegion:(CLBeaconRegion *)region]
        || [_btManager isManagedRegion:(CLBeaconRegion *)region])) {
        // ビーコンの観測（距離測定）開始
        [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
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
            // Notification to settings view controller
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocAuthAuthorizedAlways object:self];
        }
        NSUInteger numberOfMonitored = _myLocManager.monitoredRegions.count;
        [defaults setValue:[NSNumber numberWithInteger:numberOfMonitored] forKey:@"numberOfMonitoredRegions"];
        [defaults setObject:currentTime forKey:@"authorizatioznLastConfirmed"];
        [defaults synchronize];
        
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
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (beacons.count > 0) {
        CLBeacon *targetBeacon = [beacons firstObject];
        NSMutableString *message = [NSMutableString stringWithString:@"ビーコン領域["];
        [message appendString:[NSString stringWithFormat:@"%@", region.identifier]];
        [message appendString:@"]内のビーコンが見つかりました"];
        [self saveAnnounceLogToFile:message];
        
        /* 別ビーコンが観測された場合 */
        if ([@"3rdParty'sRegionOrSomething" isEqualToString:region.identifier]) {
            NSLog(@"3rdパーティのビーコン領域が見つかりました");
            return;
        }
        /* 1番近い専用ビーコンの処理 */
        if (!_addProcessing) {
            if (_btManager && [_btManager hasDesignatedBeacon]) {
                if ([_btManager isDesignatedBeacon:targetBeacon]) {
                    /* オプション サービス・サーバとの連携処理をします
                   // [_btManager checkServiceForBeacon:targetBeacon inRegion:region event:TbBTEventTypeDidEnter]; */
                    /* オプション：モニタリングスイッチング機能の使用例。
                    // モニタリングされているスイッチタイプのビーコン領域で、非スイッチタイプの領域のモニタリングを一時的に開始します
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    BOOL slaveBeaconsON = [[userDefaults valueForKey:@"slaveBeaconsON"] boolValue];
                    NSArray *designatedBeaconDatas = [_btManager currentUsableServiceBeaconDatas];
                    if (designatedBeaconDatas.count > 1 && slaveBeaconsON == NO) {
                        BOOL nonSwitcherFound = NO;
                        for (TbBTServiceBeaconData *beaconData in designatedBeaconDatas) {
                            if (!beaconData.isSwitcher) {
                                nonSwitcherFound = YES;
                            }
                        }
                        if (nonSwitcherFound) {
                            // スイッチタイプでないビーコン領域のモニタリングを開始します
                            if ([_btManager startMonitoringTbBTNonSwitcherBeaconRegions:manager] > 0) {
                                slaveBeaconsON = YES;
                                [userDefaults setValue:[NSNumber numberWithBool:slaveBeaconsON] forKey:@"slaveBeaconsON"];
                                [userDefaults synchronize];
                            }
                        }
                    } */
                }
            } else {
                // 新規登録処理の場合、ビーコンの管理情報を取得します
                if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
                    // ここでは追加登録もできるように、登録済みビーコンは除いて取得します
                    NSArray *beaconKeyInfos = [_btManager keyCodesForBeaconsExcludeDesignated:beacons ofRegion:region];
                    if (beaconKeyInfos.count > 0) {
                        NSLog(@"ビーコンのキーリストを取得しました");
                        // 取得したビーコンを表示ビュー（コントローラ）に渡します
                        [self showBeaconDesignateViewWithCodes:beaconKeyInfos forRegion:region];
                        
                    }
                }  else {// Do nothing when app is background or inactive
                    NSLog(@"アプリがアクティブになっていないため、ビーコン指定用のキーコードの取得をスキップします");
                }
            }
        }
        [manager stopRangingBeaconsInRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
     NSLog(@"-- rangingBeaconsDidFailForRegion --");
    NSLog(@"%@", [error userInfo]);
}

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
    
- (void)showBeaconDesignateViewWithCodes:(NSArray *)beaconDatas forRegion:(CLBeaconRegion *)region {
    BeaconDesignateViewController *designateViewController = [[BeaconDesignateViewController alloc] initWithStyle:UITableViewStyleGrouped];
    designateViewController.delegate = self;
    designateViewController.tbBTBeaconInfos = [NSMutableArray arrayWithArray:beaconDatas];
    designateViewController.theRegion = region;
    designateViewController.appLocManager = _myLocManager;
    if (self.view) {
        [self presentViewController:designateViewController animated:YES completion:nil];
    }
}

@end
