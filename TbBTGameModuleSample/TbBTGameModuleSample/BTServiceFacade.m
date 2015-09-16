//
//  BTServiceFacade.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "BTServiceFacade.h"
#import "RangedBeaconInfoViewController.h"
#import "BTFuncServerClient.h"
#import "AppDelegate.h"
#import "ItemManager.h"

#import "TbSandboxCredential.h"

@interface BTServiceFacade ()<BTFuncServerClientDelegate>

@property (strong, nonatomic) CLLocationManager *locManager;
@property (strong, nonatomic) TbBTManager *btManager;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgRangingTask;

@property (strong, nonatomic) MyBeacon *userSelectedBeacon;

@property (assign, nonatomic) BOOL checking; // Server interaction block flag
@property (assign, nonatomic) BTItemCheckType requestType;
@property (assign, nonatomic) NSUInteger totalRequests;
@property (assign, nonatomic) NSUInteger hasItemCount; // Counter for item check
@property (assign, nonatomic) NSUInteger noItemCount; // Counter for item check
@property (assign, nonatomic) NSUInteger memberCount; // Counter for member check
@property (assign, nonatomic) NSUInteger unknownCount; // Counter for member check

@property (strong, nonatomic) NSMutableArray *discoveredSharedItems;

@property (strong, nonatomic) NSMutableArray *rangedBeaconOwnerInfos; //Array of game user

@end

NSString *kLocAuthAuthorizedAlways = @"LocationAuthorizationAuthorizedAlways";
NSString *kLocAuthRestricted = @"LocationAuthorizationRestricted";
NSString *kLocAuthDenied = @"LocationAuthorizationDenied";

// 状態通知
NSString *kBRMonitoringDidFail = @"BeaconRegionMonitoringFailed"; // モニタリング開始に失敗しました
NSString *kRangingDidFail = @"BeaconRangingFailed"; // レンジングに失敗しました
NSString *kFoundNewBeacon = @"FoundNewBeaconUnderRegistration"; // 新規登録処理で未登録のビーコンが見つかりました
NSString *kOutsideOfRegion = @"OutsideOfRegion";
NSString *kRangingTimeOverNotification = @"RangingTimedOut"; // レンジングがタイムアウトしました
NSString *kRangingStoppedOnBackgroundState = @"RangingStoppedOnBackgroundState"; // アプリがバックグラウンドに入ったのでレンジングを中止しました
NSString *kBeaconKeyRegistered = @"BeaconKeyRegisteredOnServer";
NSString *kBeaconKeyRegistFailed = @"BeaconKeyNotRegisteredOnServer";
NSString *kBeaconKeyDeactivated = @"BeaconKeyDeactivatedOnServer";
NSString *kBeaconKeyDeactivateFailed = @"BeaconKeyNotDeactivatedOnServer";

NSString *kNoNeighberBeaconsFound = @"NoNeighberBeaconsFound";
NSString *kNeighberBeaconsFound = @"NeighberBeaconsFound";
NSString *kFailedToCheckNeighbers = @"FailedToCheckNeighberBeacons";

// ディクショナリーキー
NSString *kBeaconInfoLabel = @"BeaconInfos";
NSString *kRegionLabel = @"Region";

NSString *kMyBeaconStore = @"MyBeacon.plist";
NSString *kMyBeaconsLabel = @"MyBeacons";

// 上限値
static const NSUInteger MAX_NEIGHBERS = 10;
static const NSUInteger UNKNOWN_STATE_THRESHOLD = 5;

@implementation BTServiceFacade

+ (instancetype)sharedFacade {
    static id instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[BTServiceFacade alloc] init];
    });
    return instance;
}

+ (BOOL)isLocationEventConditionMet {
    return [TbBTManager isBeaconEventConditionMet];
}

- (id)init {
    self = [super init];
    if (self) {
        [self prepareManagers];
        [self loadRegisteredBeacons];
    }
    return self;
}

- (void)prepareManagers {
    // 位置情報マネージャのインスタンスを生成して保持します。delegateを自身に指定します
    _locManager = [[CLLocationManager alloc] init];
    _locManager.delegate = self;
    
    // ここでは既に位置情報の使用は規約内で同意されているものとし、TbBTManagerのインスタンスを生成して保持します。delegateを自身に指定します
    _btManager = [TbBTManager initSharedManagerUnderAgreement:YES];
    _btManager.delegate = self;
}

- (void) requestUserAuthorization {
    [_locManager requestAlwaysAuthorization];
}

/* ユーザ自身のビーコン（マイビーコン）を登録するために検索 */
- (void)startSearchForRegister {
    // 領域に入った場合または端末画面がアクティブになったタイミングで領域内にいるときに通知されるように指定して、3bitterビーコン（未登録分）のモニタリングを指示します
    TbBTRegionNotificationSettingOptions *options = [TbBTRegionNotificationSettingOptions settingWithTypes:TbBTRegionNotificationTypeOnEntry|TbBTRegionNotificationTypeEntryStateOnDisplay];
    [_btManager startMonitoringTbBTInitialRegions:_locManager withSupportTypeOptions:options];
}

/* 登録しておく（ユーザ自身の）ビーコンの検索を中止 */
- (void)stopSearchForRegister {
    [_btManager stopMonitoringTbBTInitialRegions:_locManager];
}

/* （他ユーザーの）ビーコンのモニタリングを開始 */
- (void)startMonitoringForCandidatesRegion {
    NSLog(@"%s", __func__);
    // Entry（ビーコン領域接触）時、ディスプレイオンの時に反応通知を受け取るようにします
    TbBTRegionNotificationSettingOptions *settingOptions = [TbBTRegionNotificationSettingOptions settingWithTypes:TbBTRegionNotificationTypeOnEntry | TbBTRegionNotificationTypeEntryStateOnDisplay];
    // 登録済みビーコンは無視されます
    [_btManager startMonitoringTbBTInitialRegions:_locManager withSupportTypeOptions:settingOptions];
}

/* 全ての3bitterビーコン領域のモニタリングを停止 */
- (void)stopMonitoringForServiceRegion {
    [_btManager stopMonitoringTbBTAllRegions:_locManager];
}

- (BOOL)isTargetMonitoring {
    if (!_locManager) {
        return NO;
    }
    NSSet *monitored = _locManager.monitoredRegions;
    assert([TbBTDefaults sharedDefaults]);
    NSUUID *serviceUUID = [[TbBTDefaults sharedDefaults].reservedServiceUUIDs objectAtIndex:0];
    for (CLRegion *aRegion in monitored) {
        // モニタリングされているうちの、3bitterのビーコン領域
       if ([aRegion isKindOfClass:[CLBeaconRegion class]]
            && [[((CLBeaconRegion *)aRegion).proximityUUID UUIDString] isEqualToString:[serviceUUID UUIDString]]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)monitoredBTRegions {
    NSSet *osBasedMonitored = _locManager.monitoredRegions;
    if (osBasedMonitored.count == 0) {
        return nil;
    }
    NSMutableArray *btRegions = [NSMutableArray array];
    for (CLRegion *monitored in osBasedMonitored) {
        if ([_btManager isReservedRegion:(CLBeaconRegion *)monitored]) {
            [btRegions addObject:monitored];
        } else if ([_btManager isManagedRegion:(CLBeaconRegion *)monitored]) {
            [btRegions addObject:monitored];
        }
    }
    return btRegions;
}

- (void)registFirstKey:(NSArray *)beaconInfos ofRegion:(CLBeaconRegion *)region {
    
}

- (BOOL)saveOwnBeacons:(NSArray *)beaconInfos ofRegion:(CLBeaconRegion *)region {
    if (beaconInfos.count == 0) {
        NSLog(@"-- %s -- beaconInfos cannot be nil", __func__);
        return NO;
    }
    TbBTRegionNotificationSettingOptions *settingOptions = [TbBTRegionNotificationSettingOptions settingWithTypes:TbBTRegionNotificationTypeOnEntry | TbBTRegionNotificationTypeEntryStateOnDisplay];
    // 取得されたビーコン情報を使ってSDKに指定ビーコンとして登録させます
    BOOL isSaved = [_btManager specifyNewUsableServiceBeaconWithCodes:beaconInfos forRegion:region locationManager:_locManager withOptions:settingOptions];
    if (isSaved) {
        NSLog(@"Saved beacon by SDK");
        NSMutableArray *usingBeacons = nil;
        if (_designatedBeacons.count > 0) {
            usingBeacons = [NSMutableArray arrayWithArray:_designatedBeacons];
        }
        // SDK側で登録済みのビーコン情報
        NSMutableArray *savedBySDK = [NSMutableArray arrayWithArray:[_btManager currentUsableServiceBeaconDatas]];
        NSMutableArray *myBeacons = [NSMutableArray array];
        for (TbBTServiceBeaconData *beaconData in [savedBySDK reverseObjectEnumerator]) {
            if (usingBeacons != nil) {
                // 使用中のものと一致しているかチェックします
                BOOL match = NO;
                for (MyBeacon *using in usingBeacons) {
                    NSString *theKeyCode = using.keycode;
                    NSString *theRegionID = using.regionID;
                    if ([theKeyCode isEqualToString:beaconData.keycode] && [theRegionID isEqualToString:beaconData.regionID]) {
                        [myBeacons addObject:using];
                        match = YES;
                        break;
                    }
                }
                if (!match) {
                    // 今回新規に登録されたビーコンなので、アプリ側でも管理用の名前などを付与して登録しておきます
                    MyBeacon *myBeacon = [[MyBeacon alloc] init];
                    myBeacon.regionID = beaconData.regionID;
                    myBeacon.segment = beaconData.segment;
                    myBeacon.keycode = beaconData.keycode;
                    myBeacon.useForGame = NO;
                    myBeacon.beaconName = @"反応OFF用の自分のビーコン";
                    [myBeacons addObject:myBeacon];
                }
            } else {
                // 使用中ビーコンがない場合（初回登録）SDKによって登録された分全てを登録しておきます
                MyBeacon *myBeacon = [[MyBeacon alloc] init];
                myBeacon.regionID = beaconData.regionID;
                myBeacon.segment = beaconData.segment;
                myBeacon.keycode = beaconData.keycode;
                myBeacon.useForGame = NO;
                myBeacon.beaconName = @"反応OFF用の自分のビーコン";
                [myBeacons addObject:myBeacon];
            }
        }
        // アプリ側でビーコン情報を登録しておきます（optional）
        if ([self registerMyBeacons:myBeacons]) {
            // 一旦現在保持している登録ビーコン情報を置き換えます
            _designatedBeacons = myBeacons;
            return YES;
        } else {
            NSLog(@"-- %s -- Failed to save beacon", __func__);
            return NO;
        }
    } else { // SDKによる登録処理が成功していません
        NSLog(@"-- %s -- Failed to save beacon", __func__);
        return NO;
    }
}

/* このサンプルではシンプルにplistファイルに保存 */
- (BOOL)registerMyBeacons:(NSArray *)myBeacons {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *beaconStorePath = [rootPath stringByAppendingPathComponent:kMyBeaconStore];
    
    NSMutableDictionary *registeredBeaconDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *beaconsArray = nil;
    @synchronized(myBeacons) {
        for (MyBeacon *selectedBeacon in myBeacons) {
            NSMutableDictionary *beaconDict = [NSMutableDictionary dictionary];
            [beaconDict setObject:selectedBeacon.regionID forKey:@"regionID"];
            [beaconDict setValue:[NSNumber numberWithInteger:selectedBeacon.segment] forKey:@"segment"];
            [beaconDict setObject:selectedBeacon.keycode forKey:@"keycode"];
            [beaconDict setValue:[NSNumber numberWithBool:selectedBeacon.useForGame] forKey:@"useForGame"];
            [beaconDict setObject:selectedBeacon.beaconName forKey:@"beaconName"];
            if (!beaconsArray) {
                    beaconsArray = [NSMutableArray array];
                }
                [beaconsArray addObject:beaconDict];
            }
        }
        if (beaconsArray) {
            [registeredBeaconDictionary setObject:beaconsArray forKey:kMyBeaconsLabel];
        } else {
            NSLog(@"Nothing to save");
            return NO;
        }
        
        if ([registeredBeaconDictionary writeToFile:beaconStorePath atomically:YES]) {
            NSLog(@"Saved to MyBeacon store");
        } else {
            NSLog(@"Save failed....");
            return NO;
        }
    return YES;
}

- (BOOL)deleteRegisteredBeaconAtIndex:(NSUInteger)index {
    BOOL deleted = NO;
    MyBeacon *targetBeacon = [_designatedBeacons objectAtIndex:index];
    // TbBTServiceBeaconData に変換します
    TbBTServiceBeaconData *targetBeaconData = [[TbBTServiceBeaconData alloc] initWithRegionID:targetBeacon.regionID segment:targetBeacon.segment keycode:targetBeacon.keycode];
    // SDK側に登録抹消処理をさせます
    BOOL released = [_btManager releaseUsableServiceBeacon:targetBeaconData locationManager:_locManager];
    if (released) {
        // 現在保持されているリストから削除分を抜きます
        [_designatedBeacons removeObject:targetBeacon];
        if (_designatedBeacons.count > 0) {
            // 残りの指定ビーコンがあれば再登録します
            [self registerMyBeacons:_designatedBeacons];
        } else {
            // 残りがなければアプリ側でも登録しているビーコン情報を抹消します
            [self cleanUpRegisteredBeacons];
        }
        deleted = YES;
    }
    return deleted;
}

/* 保存済みマイビーコン情報のロード */
- (void)loadRegisteredBeacons {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *beaconStorePath = [rootPath stringByAppendingPathComponent:kMyBeaconStore];
    if (![[NSFileManager defaultManager] fileExistsAtPath:beaconStorePath]) {
        return;
    }
    
    NSDictionary *registeredBeaconDictionary = [NSDictionary dictionaryWithContentsOfFile:beaconStorePath];
    
    NSArray *beaconDicts = [registeredBeaconDictionary objectForKey:kMyBeaconsLabel];
    if (beaconDicts.count > 0) {
        _designatedBeacons = [NSMutableArray arrayWithCapacity:beaconDicts.count];
        for (NSDictionary *beaconDict in beaconDicts) {
            MyBeacon *theBeacon = [[MyBeacon alloc] init];
            theBeacon.regionID = [beaconDict objectForKey:@"regionID"];
            theBeacon.segment = [[beaconDict valueForKey:@"segment"] integerValue];
            theBeacon.keycode = [beaconDict objectForKey:@"keycode"];
            theBeacon.useForGame = [[beaconDict valueForKey:@"useForGame"] boolValue];
            theBeacon.beaconName = [beaconDict objectForKey:@"beaconName"];
           
            [_designatedBeacons addObject:theBeacon];
        }
    }
}

- (void)cleanUpRegisteredBeacons {
    NSError *error = nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *beaconStorePath = [rootPath stringByAppendingPathComponent:kMyBeaconStore];
    [[NSFileManager defaultManager] removeItemAtPath:beaconStorePath error:&error];
    if (error) {
        NSLog(@"Registered beacon info clean up failed: %@", [error localizedDescription]);
    }
}

#pragma mark Beacon Triggered Server Interaction

- (void)registerUserMainBeacon:(MyBeacon *)selectedBeacon {
    //サーバにメインビーコン（所有ユーザのアイテムチェックに使える唯一のビーコン）のキーとして登録依頼をします
    _userSelectedBeacon = selectedBeacon;
    BTFuncServerClient *btClient = [[BTFuncServerClient alloc] init];
    btClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    btClient.myAppToken = appToken;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *memberToken = [userDefaults objectForKey:@"token"];
    [btClient requestAddBeaconkey:selectedBeacon.keycode forMember:memberToken]; // コールバックを待ちます
}

- (void)inactivateUserBeacon:(MyBeacon *)selectedBeacon {
    //サーバにメインビーコン（他ユーザが反応するビーコン）のキーを無効化しておくことを依頼します
    _userSelectedBeacon = selectedBeacon;
    BTFuncServerClient *btClient = [[BTFuncServerClient alloc] init];
    btClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    btClient.myAppToken = appToken;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *memberToken = [userDefaults objectForKey:@"token"];
    [btClient requestDeactivateBeaconkey:selectedBeacon.keycode forMember:memberToken]; // コールバックを待ちます
}

- (void)checkSharedItemsByBeacon:(NSString *)beaconKey {
    if (_checking) {
        NSLog(@"Still under checking. Abort start new check");
        return;
    }
    if (!beaconKey) {
        [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:@"Given beaconKey is nil"];
        return;
    }
    _checking = YES;
    // 検知されたビーコンのキーコードを使ってサーバにアイテムを問い合わせています（非同期）
    _requestType = BTItemCheckTypeSingleBeacon;
    BTFuncServerClient *bTFuncServerClient = [[BTFuncServerClient alloc] init];
    bTFuncServerClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    bTFuncServerClient.myAppToken = appToken;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *memberToken = [userDefaults objectForKey:@"token"];
    [bTFuncServerClient requestCheckItemsWithKeycode:beaconKey fromMember:memberToken]; // コールバックを待ちます
}

- (void)checkSharedItemsByBeacons:(NSArray *)beaconKeys {
    NSLog(@"%s",__func__);
    if (_checking) { // 重複リクエストブロック
        NSLog(@"Still under checking. Abort start new check");
        return;
    }
    if (beaconKeys.count == 0) {
        [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:@"Given beaconKeys is nil"];
        return;
    }
    
    _checking = YES;
    _totalRequests = beaconKeys.count;
    _hasItemCount = 0;
    _noItemCount = 0;
    _requestType = BTItemCheckTypeMultipleBeacon;
    _discoveredSharedItems = [NSMutableArray array];
    
    for (NSString *beaconKey in beaconKeys) {
        BTFuncServerClient *btClient = [[BTFuncServerClient alloc] init];
        btClient.delegate = self;
        NSString *appToken = [[TbSandboxCredential myCredential] appToken];
        btClient.myAppToken = appToken;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *memberToken = [userDefaults objectForKey:@"token"];
        [btClient requestCheckItemsWithKeycode:beaconKey fromMember:memberToken]; // Wait each client call back
    }
}

- (BOOL)isChecking {
    return _checking;
}

- (NSArray *)neighberUsers {
    return [NSArray arrayWithArray:_rangedBeaconOwnerInfos];
}

#pragma mark Private methods

- (BOOL)containsNonDesignatedBeacon:(NSArray *)foundBeacons {
    // 計測されたビーコンの中から未登録のビーコンを探します
    if ([_btManager hasDesignatedBeacon]) {
        for (CLBeacon *foundBeacon in foundBeacons) {
            if (![_btManager isDesignatedBeacon:foundBeacon]) {
                return YES;
            }
        }
        return NO; // 未登録なし
    }
    return YES; // 未登録分あり
}

- (NSArray *)filterUnidentifiedOwnerBeaconKeys:(NSArray *)beaconDatas {
    // Check ownerInfo contains keys in beaconDatas
    NSMutableArray *unidetifiedKeys = [NSMutableArray array];
    for (TbBTServiceBeaconData *beaconData in beaconDatas) {
        NSString *theKey = beaconData.keycode;
        if (_rangedBeaconOwnerInfos) {
            NSPredicate *keyPredicate = [NSPredicate predicateWithFormat:@"beaconKey = %@", theKey];
            NSArray *filteredArray = [_rangedBeaconOwnerInfos filteredArrayUsingPredicate:keyPredicate];
            if (filteredArray.count == 0) {
                [unidetifiedKeys addObject:theKey];
            }
        } else {
            [unidetifiedKeys addObject:theKey];
        }
    }
    if (unidetifiedKeys.count == 0) {
        return nil;
    }
    return [NSArray arrayWithArray:unidetifiedKeys];
}


#pragma mark Neighber ranging (Service region case)

- (void)startSearchNeighbers {
    assert(_locManager);
    if (_locManager.monitoredRegions.count == 0) {
        NSLog(@"No regions monitored");
        _neighbersSearching = NO;
        return;
    }
    
    for (CLRegion *aRegion in _locManager.monitoredRegions) {
        if ([aRegion isKindOfClass:[CLBeaconRegion class]]
            &&[[TbBTManager sharedManager] isInitialRegion:(CLBeaconRegion *)aRegion]) {
            _neighbersSearching = YES;
            [_locManager requestStateForRegion:aRegion];
            return;
        }
    }
    NSError *error = [NSError errorWithDomain:@"Invalid Region" code:-100 userInfo:nil];
    [_delegate btFacade:self didFailToProfileNeighbersWithError:error];
}

- (void)stopSearchNeighbers {
    assert(_locManager);
    if (!_neighbersSearching) {
        return;
    }
    _neighbersSearching = NO;
    
    if (!_locManager.monitoredRegions.count == 0) {
        NSLog(@"No regions monitored");
        return;
    }
    
    for (CLRegion *aRegion in _locManager.monitoredRegions) {
        if ([aRegion isKindOfClass:[CLBeaconRegion class]]
            &&[[TbBTManager sharedManager] isInitialRegion:(CLBeaconRegion *)aRegion]) {
            [_locManager stopRangingBeaconsInRegion:(CLBeaconRegion *)aRegion];
            return;
        }
    }
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (kCLAuthorizationStatusAuthorizedAlways == status) {
        // ユーザが位置情報の使用を許可しました/しています
        assert(_locManager);
        // Notification to settings view controller
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocAuthAuthorizedAlways object:self];
    } else if (kCLAuthorizationStatusRestricted == status) {
        // ユーザが位置情報の使用を制限しました
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocAuthRestricted object:self];
    } else if (kCLAuthorizationStatusDenied == status) {
        // ユーザが位置情報の使用を拒否しました
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocAuthDenied object:self];
    } else if (kCLAuthorizationStatusNotDetermined == status) {
        // 位置情報の使用許可は未設定です
        NSLog(@"-- Authorization not determined yet --");
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    // ビーコン以外の領域なら無視します
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        return;
    }
    if (CLRegionStateInside == state) {
        if (_addProcessing) {
            NSLog(@"-- Inside of beacon in new beacon registration process --");
        } else if (_neighbersSearching) {
            [_locManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            return;
        } else {
            NSLog(@"-- Inside of beacon but not in registration process --");
            assert(_btManager);
            /* 自身のビーコン以外の3bitterビーコン用の処理 */
            if ([_btManager isInitialRegion:(CLBeaconRegion *)region]) {
                // // バックグラウンドでレンジングを開始します
                _bgRangingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    if (_bgRangingTask != UIBackgroundTaskInvalid) {
                    // レンジングストップを指示してタスクを終了
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            [[UIApplication sharedApplication] endBackgroundTask:_bgRangingTask];
                            _bgRangingTask = UIBackgroundTaskInvalid;
                            [_locManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                        });
                    }
                }];
                NSLog(@"Target Found. Start ranging in background");
                dispatch_queue_t queue;
                queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(queue, ^{
                    // レンジング開始を指示します
                    [_locManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
                });
            } else if ([_btManager isManagedRegion:(CLBeaconRegion *)region]) {
                // TO Be prepared: サーバ管理されている、反応対象として使用できる領域。同様に対象を特定します
            } else {
                NSLog(@"Target Not Found. This region may be the registered beacon's");
            }
        }
    } else if (CLRegionStateOutside == state) {
        if (_neighbersSearching) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kOutsideOfRegion object:self];
        }
         NSLog(@"-- Outside of region --");
    } else if (CLRegionStateUnknown == state) {
        NSLog(@"-- Unknown state --");
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    if (![manager isEqual:_locManager]) {
        NSLog(@"Location manager is not mine");
        return;
    }
    if ([region isKindOfClass:[CLCircularRegion class]]) { // Geofenceなどで何かしているなら、別の処理をします
        NSLog(@"We may do something");
        return;
    } else if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if (_addProcessing && [_btManager isInitialRegion:(CLBeaconRegion *)region]) { // ビーコン登録処理のケース
                [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
                NSLog(@"Ranging started for region %@", region.identifier);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    // 全ての領域で失敗した場合、タイムアウト処理に任せています
    NSLog(@" -- %s -- ", __func__);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"%@ -- didEnterRegion of %@--", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle], region.identifier);
    /* 今回のケースではInside状態の検知に処理を任せます */
}

// ビーコン領域Exit時に何か処理をしたい場合は実装します
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"%@ [debug] didExitRegion of %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle], region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (beacons.count == 0) {
        // exit and wait for next call
        return;
    }
    if (![_btManager isReservedRegion:region] && ![_btManager isManagedRegion:region]) {
         NSLog(@"-- Beacons in unknown region %@ is found. Do nothing. --", region.identifier);
        return;
    }
    /* ビーコンの新規登録処理 */
    if (_addProcessing) {
        // 所定のタイムアウト時間が経過したのでレンジングを止めてUI処理側に通知しています
        if (NSOrderedDescending == [[NSDate date] compare:_addProcessTimeoutTime]) {
            NSLog(@"-- ranging time out --");
            [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            [[NSNotificationCenter defaultCenter] postNotificationName:kRangingTimeOverNotification object:self];
            return;
        }
        // アプリが非アクティブにされたらレンジングを中止しています
        if (UIApplicationStateInactive == [UIApplication sharedApplication].applicationState
            || UIApplicationStateBackground == [UIApplication sharedApplication].applicationState) {
            [_locManager stopRangingBeaconsInRegion:region];
            [[NSNotificationCenter defaultCenter] postNotificationName:kRangingStoppedOnBackgroundState object:self];
            _addProcessing = NO;
            return;
        }
        if ([self containsNonDesignatedBeacon:beacons]) {
            NSLog(@"-- マイビーコン登録処理。新規ビーコンが見つかりました");
            // 未登録のビーコンが見つかったので、レンジングを止めてデリゲートメソッドをコールしています
            NSArray *rangedBeaconInfos = [_btManager keyCodesForBeaconsExcludeDesignated:beacons ofRegion:region];
            NSMutableDictionary *beaconInfoDict = [NSMutableDictionary dictionary];
            [beaconInfoDict setObject:rangedBeaconInfos forKey:kBeaconInfoLabel];
            [beaconInfoDict setObject:region forKey:kRegionLabel];
            
            [manager stopRangingBeaconsInRegion:region];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFoundNewBeacon object:self userInfo:[NSDictionary dictionaryWithDictionary:beaconInfoDict]];
            return;
        }
    } else if (_neighbersSearching) { /* 近隣メンバーチェック処理 */
        if (_checking) { // サーバからのレスポンス待ちの状態であれば、スキップします
            return;
        }
        if (_rangedBeaconOwnerInfos.count >= MAX_NEIGHBERS) {
            return;
        }
        _memberCount = 0;
        _unknownCount = 0;
        if ([self containsNonDesignatedBeacon:beacons]) {
            // 登録されてないビーコンが見つかったので、該当ビーコンの管理データをSDKから取得します
            NSLog(@"　オーナーチェック処理。対象のビーコンが見つかりました");
            NSArray *beaconDatas = [_btManager keyCodesForBeaconsExcludeDesignated:beacons ofRegion:region];
            assert(beaconDatas);
            if (beaconDatas.count > 0) {
            // 新規キーコードが見つかった場合はサーバにキーコードのオーナー情報を問い合わせます
                NSArray *newBeaconKeys = [self filterUnidentifiedOwnerBeaconKeys:beaconDatas];
                if (newBeaconKeys.count > 0) {
                    _checking = YES;
                    _totalRequests = newBeaconKeys.count;
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    NSString *memberToken = [userDefaults objectForKey:@"token"];
                    for (NSString *newKey in newBeaconKeys) { // サーバスペックを信じて並列リクエストとしてみます（同時検知数が大多数となる可能性がある場合はシーケンシャルなリクエスト推奨）
                        BTFuncServerClient *btClient = [[BTFuncServerClient alloc] init];
                        btClient.delegate = self;
                        NSString *appToken = [[TbSandboxCredential myCredential] appToken];
                        btClient.myAppToken = appToken;
                        [btClient requestCheckOwnerForBeaconKey:newKey fromMember:memberToken]; // 全てのコールバックを待ちます
                    }
                } else { //　取得済みのBeaconOwnerの情報を更新します
                    NSUInteger beaconIndex = 0;
                    NSArray *allBeaconKeyDatas = [_btManager keyCodesForBeacons:beacons ofRegion:region];
                    for (CLBeacon *beacon in beacons) {
                        if (![_btManager isDesignatedBeacon:beacon]) { // 登録ビーコンは除く
                            TbBTServiceBeaconData *beaconData = [allBeaconKeyDatas objectAtIndex:beaconIndex];
                            NSPredicate *keycodePredicate = [NSPredicate predicateWithFormat:@"beaconKey = %@", beaconData.keycode];
                            NSArray *matchedOwner = [_rangedBeaconOwnerInfos filteredArrayUsingPredicate:keycodePredicate];
                                if (matchedOwner.count == 1) {
                                    BeaconOwner *theOwner = [matchedOwner firstObject];
                                    theOwner.dummyIndicator = beacon.rssi + 100;
                                    switch (beacon.proximity) {
                                        case CLProximityImmediate:
                                            theOwner.proximityDescription = @"くっついてませんか？";
                                            theOwner.unknownStateCount = 0;
                                            break;
                                        case CLProximityNear:
                                            theOwner.proximityDescription = @"すぐ横くらいにいませんか？";
                                            theOwner.unknownStateCount = 0;
                                            break;
                                        case CLProximityFar:
                                            theOwner.proximityDescription = @"ある程度遠いところにいます";
                                            theOwner.unknownStateCount = 0;
                                            break;
                                        case CLProximityUnknown:
                                            // Count up for missing
                                            theOwner.unknownStateCount++;
                                            if (theOwner.unknownStateCount == UNKNOWN_STATE_THRESHOLD) {
                                                theOwner.dummyIndicator = 0;
                                                theOwner.proximityDescription = @"検知範囲から離脱したようです";
                                            }
                                            break;
                                        default:
                                            break;
                                    }
                                } else {
                                    NSLog(@"%s: May be an error..", __func__);
                                    return;
                                }
                        }
                        beaconIndex++;
                    }
                    [_delegate btFacade:self didUpdateNeighberInfos:_rangedBeaconOwnerInfos];
                }
            }
            return;
        }
    } else { /* すれ違い用通常処理 */
        if ([self containsNonDesignatedBeacon:beacons]) {
            // 登録されてないビーコンが見つかったので、該当ビーコンの管理データをSDKから取得します
            NSLog(@"すれ違い用処理。対象ビーコンが見つかりました");
            NSArray *beaconDatas = [_btManager keyCodesForBeaconsExcludeDesignated:beacons ofRegion:region];
            assert(beaconDatas);
            if (beaconDatas.count > 0) {
             /* [代替（１アイテムのみ選択のケース）]
                TbBTServiceBeaconData *targetBeacon = [beaconDatas firstObject];
                NSString *keyCode = targetBeacon.keycode; */
                 //ビーコンキーを取得できたので計測を止めます
                [_locManager stopRangingBeaconsInRegion:region];
                NSMutableArray *keycodeArray = [NSMutableArray array];
                ItemManager *itemManager = [ItemManager sharedManager];
                self.delegate = itemManager;
                for (TbBTServiceBeaconData  *beaconData in beaconDatas) {
                    NSString* keycodeOfBeacon = beaconData.keycode;
                    [keycodeArray addObject:keycodeOfBeacon];
                }
                // デリゲートメソッドをコールしてビーコンのキーコードを渡しています
             /* [代替]  [itemManager btFacade:self didContactWithTargetBeacon:keyCode]; */
                [itemManager btFacade:self didContactWithTargetBeacons:[NSArray arrayWithArray:keycodeArray]];
            }
            return;
        }
        // 上のブロックに入らない場合は登録されていないビーコンが見つからずストップしていないので、計測は継続します
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] postNotificationName:kRangingDidFail object:self];
}

#pragma mark BTFuncServerClientDelegate

- (void)BTFuncServerClient:(BTFuncServerClient *)client didAddBeaconkey:(NSString *)beaconKey {
    NSLog(@"%s", __func__);
    // サーバサイド処理に成功したのでローカルでも更新します。更新に失敗したらエラーを通知します
    if (!_userSelectedBeacon || ![_userSelectedBeacon.keycode isEqualToString:beaconKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyRegistFailed object:self];
        return;
    }
    for (MyBeacon *beacon in _designatedBeacons) {
        if ([beacon.keycode isEqualToString:beaconKey]) {
            beacon.useForGame = YES;
        } else {
            beacon.useForGame = NO;
        }
    }
    if ([self registerMyBeacons:_designatedBeacons]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyRegistered object:self];
        return;
    } else {
        NSLog(@"Local save failed");
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyRegistFailed object:self];
    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToAddBeaconkeyWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    // 処理に失敗したので何もせずにUIサイドに通知します
     [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyRegistFailed object:self];
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didDeactivateBeaconkey:(NSString *)beaconKey {
    NSLog(@"%s", __func__);
    // サーバサイド処理に成功したのでローカルでも更新します。更新に失敗したらエラーを通知します
    if (!_userSelectedBeacon || ![_userSelectedBeacon.keycode isEqualToString:beaconKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyDeactivateFailed object:self];
        return;
    }
    for (MyBeacon *beacon in _designatedBeacons) {
        if ([beacon.keycode isEqualToString:beaconKey]) {
            beacon.useForGame = NO;
            break;
        }
    }
    if ([self registerMyBeacons:_designatedBeacons]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyDeactivated object:self];
        return;
    } else {
        NSLog(@"Local save failed");
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyDeactivateFailed object:self];
    }

}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToDeactivateBeaconkeyWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    // 処理に失敗したので何もせずにUIサイドに通知します
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconKeyDeactivateFailed object:self];
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didGetSharedItemsForKeycode:(NSArray *)items {
    NSLog(@"%s", __func__);
    if (_requestType == BTItemCheckTypeSingleBeacon) {
        _checking = NO;
        [_delegate btFacade:self didGetSharedItemsForKeycode:items];
        return;
    } else if (_requestType == BTItemCheckTypeMultipleBeacon) {
        _hasItemCount++;
        if (!_discoveredSharedItems) {
            _discoveredSharedItems = [NSMutableArray array];
        }
        for (NSDictionary *anItemDict in items) {
             [_discoveredSharedItems addObject:anItemDict];
        }
        if (_totalRequests == _hasItemCount + _noItemCount) { // 全クライアント - サーバ通信完了
            _checking = NO;
            [_delegate btFacade:self didGetSharedItemsForDetectedBeacons:_discoveredSharedItems];
            return;
        }
    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didCheckItemsWithResult:(CheckResultType)resultType {
    NSLog(@"%s", __func__);
    if (BTItemCheckTypeSingleBeacon) {
        _checking = NO;
        switch (resultType) {
            case CheckResultTypeOwnerNotCandidate:
                [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:@"Beacon is not used for this service"];
                break;
            case CheckResultTypeSharingInactive:
                [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:@"Beacon owner not sharing item"];
                break;
            case CheckResultTypeHasSame:
                [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:@"The shared item already my item"];
                break;
            default:
                break;
        }
    } else if (BTItemCheckTypeMultipleBeacon) {
        _noItemCount++;
        if (_totalRequests == _hasItemCount + _noItemCount) {
            _checking = NO;
            if (_hasItemCount > 0) {
                [_delegate btFacade:self didGetSharedItemsForDetectedBeacons:_discoveredSharedItems];
                return;
            } else {
                [_delegate btFacade:self didFailToGetItemsForDetectedBeaconsWithReason:@"No new items found"];
                return;
            }
        }
    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToCheckItemsWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    NSLog(@"error:%@", [error userInfo]);
    if (_requestType == BTItemCheckTypeSingleBeacon) {
        _checking = NO;
        [_delegate btFacade:self didFailToGetItemsForKeycodeWithReason:[error localizedDescription]];
    } else {
        _noItemCount++;
        if (_totalRequests == _hasItemCount + _noItemCount) {
            _checking = NO;
            if (_hasItemCount > 0) {
                [_delegate btFacade:self didGetSharedItemsForDetectedBeacons:_discoveredSharedItems];
                return;
            } else {
                [_delegate btFacade:self didFailToGetItemsForDetectedBeaconsWithReason:@"No items found"];
                return;
            }
        }

    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didGetBeaconOwner:(BeaconOwner *)member {
    assert(member);
    // メンバーリストに追加
    if (!_rangedBeaconOwnerInfos) {
        _rangedBeaconOwnerInfos = [NSMutableArray array];
    }
    [_rangedBeaconOwnerInfos addObject:member];
    _memberCount++;
    if (_totalRequests == _memberCount + _unknownCount) {
        [_delegate btFacade:self didProfileNewNeighbers:_rangedBeaconOwnerInfos];
        _checking = NO;
        return;
    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didCheckOwnerWithResult:(CheckResultType)resultType forKeyCode:(NSString *)beaconKey {
    _unknownCount++;
    if (resultType == CheckResultTypeOwnerNotCandidate) {
        BeaconOwner *theOwner = [[BeaconOwner alloc] init];
        theOwner.userName = @"不明さん"; // 非メンバーか、メインビーコンを指定していないユーザ
        theOwner.beaconKey = beaconKey;
        theOwner.usingBeaconForGame = NO;
        if (!_rangedBeaconOwnerInfos) {
            _rangedBeaconOwnerInfos = [NSMutableArray array];
        }
        [_rangedBeaconOwnerInfos addObject:theOwner];
    }
    if (_totalRequests == _memberCount + _unknownCount) {
        [_delegate btFacade:self didProfileNewNeighbers:_rangedBeaconOwnerInfos];
        _checking = NO;
        return;
    }
}

- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToCheckOwnerWithError:(NSError *)error forKeycode:(NSString *)beaconKey {
    NSLog(@"Error with beacon:%@", beaconKey);
    [_delegate btFacade:self didFailToProfileNeighbersWithError:error];
    _checking  = NO;
}

@end
