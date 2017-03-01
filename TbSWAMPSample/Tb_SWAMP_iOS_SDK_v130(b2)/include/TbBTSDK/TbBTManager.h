//
//  TbBTManager.h (for SWAMP Edition)
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2016/03/02.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//


#import <CoreLocation/CoreLocation.h>
#import "TbBTDefaults.h"
#import "TbBTDeveloperPreference.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTRegionNotificationSettingOptions.h"

@protocol TbBTManagerDelegate;

@interface TbBTManager : NSObject

@property (weak, nonatomic) id<TbBTManagerDelegate> delegate;
@property (copy, nonatomic) NSString *auid;

//[管理マネージャ初期化と取得]
/* Initialize singleton beacon trigger manager under agreement 
 　サービス許可フラグを受け取ってインスタンスを返します。NOを与えて、インスタンス化をブロックします */
+ (TbBTManager *)initSharedManagerUnderAgreement:(BOOL)allowed;

/* Returns nil if user not agreed to service
   シングルトンの共有インスタンスを返します（使用条件の同意YESが過去に与えられていない場合はnil） */
+ (TbBTManager *)sharedManager;

//[[ハードウェア、OSのサポート状態と、位置情報サービス許可のチェック]]
/* Return YES if conditions for beacon related event are met
 ビーコン領域検知等に必要な条件（ハードウェアサポート及び位置情報サービス設定系）が満たされているかをチェックするユーティリティメソッドです。
 （バックグラウンド含む）*/
+ (BOOL)isBeaconEventConditionMet;
/* Return YES if conditions for beacon related event are met
 アプリがアクティブな状態のときにビーコン領域検知等に必要な条件が満たされているかをチェックするユーティリティメソッドです*/
+ (BOOL)isBeaconEventConditionMetForForegroundOnly;
/* Return YES if device support beacon region monitoring and beacon ranging 
ハードウェアサポート状態のみをチェックするユーティリティメソッドです */
+ (BOOL)isSupportedBeaconEventByDevice;

//[[現在のBluetoothの設定のチェック]]
/* Try to check current bluetooth settings on the device
 端末のBluetooth使用可否状況をチェックします 決定状態の応答に若干のタイムラグがあるので、デリゲートメソッドを応答します */
- (void)checkCurrentBluetoothAvailability;

//[使用初期設定の確認]
- (TbBTDeveloperPreference *)preference;

//[モニタリング用領域更新管理系]
/* サービス専用の有効なCLBeaconRegion型ビーコン領域のリストを返します */
- (NSArray *)initialRegions;
/* サービス領域のうち、ダイナミックビーコン用のビーコン領域リストを返します */
- (NSArray *)tbDynamicBeaconRegions;

/* Utility method for check the region is reserved by the Service
 渡された領域がサービス専用の領域かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isReservedRegion:(CLBeaconRegion *)region;
/* Utility method for check the region is initially defined (prepared) by the Service
 渡された領域がサービスにより事前に定義された初期領域かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isInitialRegion:(CLBeaconRegion *)region;
/* Utility method for check the region is for dynamic beacon defined (prepared) by the Service
 渡された領域がサービスにより事前に定義されたダイナミックビーコン領域かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isTbDynamicBeaconRegion:(CLBeaconRegion *)region;

//[3bitterビーコン領域モニタリング指示系]
/* Start monitoring of 3bitter's beacon(static properties) common regions
 3bitter専用ビーコン（固定値ビーコン）領域の初期モニタリングを開始します。specifyNewメソッドで特定ビーコン指定すると、停止します
 3bitter専用ビーコン以外のサービス管理下の領域のモニタリングは制御しません
 */
- (BOOL)startMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager;

- (BOOL)startMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager  withSupportTypeOptions:(TbBTRegionNotificationSettingOptions *)options;

/* Start monitoring of 3bitter's beacon(dynamic properties) regions
 3bitter専用ビーコン（可変値ビーコン）領域の初期モニタリングを開始します
 */
- (BOOL)startMonitoringTbBTDynamicRegions:(CLLocationManager *)locationManager;

- (BOOL)startMonitoringTbBTDynamicRegions:(CLLocationManager *)locationManager  withSupportTypeOptions:(TbBTRegionNotificationSettingOptions *)options;

/* Stop monitoring of 3bitter's static beacon common regions and return No. of stopped regions
 3bitter専用ビーコン領域の初期モニタリングを強制的に停止します
 */
- (NSUInteger)stopMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager;
/* Stop monitoring of 3bitter's beacon regions and return No. of stopped regions
 3bitter専用動的ビーコン領域の初期モニタリングを強制的に停止します
 */
- (NSUInteger)stopMonitoringTbBTDynamicRegions:(CLLocationManager *)locationManager;
/* Stop monitoring of 3bitter's beacon regions and return No. of stopped regions
 3bitter専用ビーコン領域全てのモニタリングを強制的に停止します
 */
- (NSUInteger)stopMonitoringTbBTAllRegions:(CLLocationManager *)locationManager;

/*
 Start monitoring designated 3bitter's beacons , (not switcher type only)
 3bitter専用ビーコンのうち、スイッチビーコン指定されていない方の指定ビーコンのモニタリングを開始します
 */
- (NSUInteger)startMonitoringTbBTNonSwitcherBeaconRegions:(CLLocationManager *)locationManager;
- (NSUInteger)startMonitoringTbBTNonSwitcherBeaconRegions:(CLLocationManager *)locationManager withSupportTypeOptions:(TbBTRegionNotificationSettingOptions *)options;
/*
 Stop monitoring designated 3bitter's beacons , (not switcher type only)
 3bitter専用ビーコンのうち、スイッチビーコン指定されていない方の指定ビーコンのモニタリングを停止します
 */
- (NSUInteger)stopMonitoringTbBTNonSwitcherBeaconRegions:(CLLocationManager *)locationManager;

//
// 3bitterビーコン検出系
- (BOOL)startRangingTbBTStaticBeacons:(CLLocationManager *)locationManager;
- (BOOL)startRangingTbBTDynamicBeacons:(CLLocationManager *)locationManager;
- (void)stopRangingTbBTStaticBeacons:(CLLocationManager *)locationManager;
- (void)stopRangingTbBTDynamicBeacons:(CLLocationManager *)locationManager;

//[ビーコン指定系]
/* Return keycode included infomation list of given service specified beacons (generated from real beacons)
 アプリ側で検知した専用ビーコン端末のキーコードを含む管理情報を返します（実際のビーコン情報から算出） */
- (NSArray *)keyCodesForBeacons:(NSArray *)beacons ofRegion:(CLBeaconRegion *)region;
/* Return keycode included infomation list of given service specified beacons, exclude already designated beacons by user (generated from real beacons)
 アプリ側で検知した専用ビーコン端末の専用ビーコンのキーコードを含む管理情報のうち、渡されたbeaconsの中で既にユーザに指定されているビーコンを除いたビーコンの情報を返します */
- (NSArray *)keyCodesForBeaconsExcludeDesignated:(NSArray *)beacons ofRegion:(CLBeaconRegion *)region;

/* 検知したビーコン分のキーコードリストをサービスサーバ側に非同期送信し、ビーコン情報のリスト(処理中はnil）を返します
  Send detected beacon region track data asynchronously and return back beacon meta data to the caller.
 */
- (NSArray *)beaconsTrack:(NSArray *)beacons ofRegion:(CLBeaconRegion *)region;

/* Add new designated beacons for user interaction (expected user's choice)
 サービス用ビーコンを指定し他のサービス用ビーコンの反応がユーザに影響しないようにします 
 正常登録：1 一部登録：0 登録失敗：マイナス値 */
- (NSInteger)specifyNewUsableServiceBeaconWithCodes:(NSArray *)beaconDatas forRegion:(CLBeaconRegion *)region locationManager:(CLLocationManager *)locationManager;
- (NSInteger)specifyNewUsableServiceBeaconWithCodes:(NSArray *)beaconDatas forRegion:(CLBeaconRegion *)region locationManager:(CLLocationManager *)locationManager withOptions:(TbBTRegionNotificationSettingOptions *)options;
/* Return current designated beacon info list
 指定された専用ビーコン制御用情報のリストを返します
 */
- (NSArray *)currentUsableServiceBeaconDatas;
/* Return regions of designated beacons
 ユーザに指定されたビーコンが反応する領域のリストを返します */
- (NSArray *)regionsOfDesignatedBeacons;
/* Update designated beacon with new info (TbBTServiceBeaconData)
 指定された専用ビーコンの属性を上書きします（現時点では、switcher属性のみ変更） */
- (BOOL)updateDesignatedBeaconData:(TbBTServiceBeaconData *)beaconData;
/* Update designated beacons with new infos (Array of TbBTServiceBeaconData)
 指定されているビーコンリストを全て上書きします（現時点では、switcher属性のみ変更） */
- (BOOL)updateDesignatedBeaconDatas:(NSArray *)beaconDatas;
/* Remove designated beacon
 サービス連動用に指定されている専用ビーコンのモニタリングを停止し、制御から解放します */
- (BOOL)releaseUsableServiceBeacon:(TbBTServiceBeaconData *)beaconData locationManager:(CLLocationManager *)locationManager;
/* Check if exclusive service synchronized beacon exists
 サービスの排他使用目的で指定されたビーコンがあるか否かを返します */
- (BOOL)hasDesignatedBeacon;
/* Check if the beacon is under exclusive control for service
 ビーコンがサービス用に指定されたものか否かを返します */
- (BOOL)isDesignatedBeacon:(CLBeacon *)beacon;

//[独自または付加サービス系]
/*
 付加サービス用にアプリで使用可能な領域情報を最新に更新します
*/
- (void)updateManagedRegionsWithType:(TbBTManagedRegionType)regionType;
/* 発信モード（自社イベントクローズド）用 */
- (void)updateOwnedRegionsOfBeaconType:(TbBTBeaconType)beaconType;
/*
 サービス上でアプリ用に管理されている、3bitterビーコン専用以外の使用可能領域の情報です
 */
- (NSArray *)currentManagedRegions;
- (NSArray *)newManagedRegions;
- (NSArray *)abandonedManagedRegions;

/* Utility method for check the region is managed on the Service for the App
 渡された領域がサービスシステム上でアプリで使用できるように管理されている領域（3bitter専用領域を含まない)かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isManagedRegion:(CLBeaconRegion *)region;


/* [テスト用メソッド]
Can be used under test mode */
/* For event logging. Give our test beacon region  */
- (BOOL)fireTestLoggingRequestForBeaconRegionEvent:(CLBeaconRegion *)region event:(TbBTEventType)eventType;

@end

@protocol TbBTManagerDelegate <NSObject>

@optional
//[Bluetooth使用可否状態のチェック結果]
// bluetooth check result
- (void)didDetermineBlutoothAvailability:(BOOL)available;

//[領域処理結果系]
// for region update
- (void)didPrepareToRefreshRegionsWithResult:(TbBTPrepareResultType)resultType;
- (void)didFailToPrepareLatestRegionsWithError:(NSError *)error;


//[テストログ送信系]
// for test logging
- (void)didSendTestLogRequestSuccessfully;
- (void)didFailToSendTestLogRequestWithError:(NSError *)error;

@end
