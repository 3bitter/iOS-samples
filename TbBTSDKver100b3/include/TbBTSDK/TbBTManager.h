//
//  TbBTManager.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//


#import <CoreLocation/CoreLocation.h>
#import "TbBTDefaults.h"
#import "TbBTDeveloperPreference.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTPresentationInfo.h"
#import "TbBTRegionNotificationSettingOptions.h"

@protocol TbBTManagerDelegate;

@interface TbBTManager : NSObject

@property (weak, nonatomic) id<TbBTManagerDelegate> delegate;
@property (copy, nonatomic) NSString *auid;

//[管理マネージャ初期化と取得]
/* Initialize singleton beacon trigger manager under agreement 
 　サービス許可フラグを受け取ってインスタンスを返します */
+ (TbBTManager *)initSharedManagerUnderAgreement:(BOOL)allowed;
/* Returns nil if user not agreed to service 
   既に生成されているインスタンスを返します */
+ (TbBTManager *)sharedManager;

/* Return YES if conditions for beacon related event are met
 ビーコン領域検知等に必要な条件が満たされているかをチェックするユーティリティメソッドです。
 （バックグラウンド含む）*/
+ (BOOL)isBeaconEventConditionMet;
/* Return YES if conditions for beacon related event are met
 アプリがアクティブな状態のときにビーコン領域検知等に必要な条件が満たされているかをチェックするユーティリティメソッドです*/
+ (BOOL)isBeaconEventConditionMetForForegroundOnly;

//[使用初期設定の確認]
- (TbBTDeveloperPreference *)preference;

//[モニタリング用領域更新管理系]
/* Utility method for check the region is reserved by the Service
 渡された領域がサービス専用の領域かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isReservedRegion:(CLBeaconRegion *)region;
/* Utility method for check the region is initially defined (prepared) by the Service
 渡された領域がサービスにより事前に定義された初期領域かどうかを返す、ユーティリティメソッドです
 */
- (BOOL)isInitialRegion:(CLBeaconRegion *)region;

//[3bitterビーコン領域モニタリング指示系]
/* Start monitoring of 3bitter's beacon common regions
 3bitter専用ビーコン領域の初期モニタリングを開始します。specifyNewメソッドで特定ビーコン指定すると、停止します
 3bitter専用ビーコン以外のサービス管理下の領域のモニタリングは制御しません
 */
- (BOOL)startMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager;
- (BOOL)startMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager  withSupportTypeOptions:(TbBTRegionNotificationSettingOptions *)options;
/* Stop monitoring of 3bitter's beacon common regions and return No. of stopped regions
 3bitter専用ビーコン領域の初期モニタリングを強制的に停止します
 */
- (NSUInteger)stopMonitoringTbBTInitialRegions:(CLLocationManager *)locationManager;
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
 Start monitoring designated 3bitter's beacons , (not switcher type only)
 3bitter専用ビーコンのうち、スイッチビーコン指定されていない方の指定ビーコンのモニタリングを停止します
 */
- (NSUInteger)stopMonitoringTbBTNonSwitcherBeaconRegions:(CLLocationManager *)locationManager;

//[ビーコン指定系]
/* Return keycode included infomation list of given service specified beacons (generated from real beacons)
 アプリ側で検知した専用ビーコン端末のキーコードを含む管理情報を返します（実際のビーコン情報から算出） */
- (NSArray *)keyCodesForBeacons:(NSArray *)beacons ofRegion:(CLBeaconRegion *)region;
/* Return keycode included infomation list of given service specified beacons, exclude already designated beacons by user (generated from real beacons)
 アプリ側で検知した専用ビーコン端末の専用ビーコンのキーコードを含む管理情報のうち、渡されたbeaconsの中で既にユーザに指定されているビーコンを除いたビーコンの情報を返します */
- (NSArray *)keyCodesForBeaconsExcludeDesignated:(NSArray *)beacons ofRegion:(CLBeaconRegion *)region;
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

/* Request spot specified data (campaign presentation or service content)
   反応したビーコン領域（スポット）に対してサービス側提供のサービスまたはキャンペーンが
 設定されているかチェックします */
- (void)checkServiceForBeacon:(CLBeacon *)beacon inRegion:(CLBeaconRegion *)region event:(TbBTEventType)eventType;
/* Reset notification block condition for the given beacon region
   指定ビーコンの通知制限用条件（設定されている通知インターバル）を強制リセットします */
- (void)resetBlockingConditionForBeacon:(CLBeacon *)beacon;

// [キャンペーン通知と通知記録系]
/* Fire notification with request for campaign notification
   SDKに指定の通知内容情報を使ってプッシュ通知を送信させます */
- (void)fireNotificationWithInfo:(TbBTPresentationInfo *)presentation forEvent:(TbBTEventType)eventType;
/* Request for campaign info notification log (depends on business requirement)
   プッシュ通知を送信したことの記録をリクエストします （ビジネスモデル上必要な場合）*/
- (void)fireRequestForPresenNotificationCheck:(NSString *)presentationID forCampaign:(NSString *)campaignID;

// [キャンペーン通知タップ記録系]
/* Request for tap logging (depends on business requirement)
  アプリから送信したキャンペーンのプッシュ通知がタップされたことの記録をリクエストします 
 （ビジネスモデル上必要な場合）*/
- (void)fireRequestForPresenTap:(NSString *)presentationID;

/* [テスト用メソッド]
Can be used under test mode */
/* For test stub. Ignore setting and return NO if not under test mode
 checkServiceForBeaconで使う、テスト用のスタブURL（自前を指定します（TestMode=YESの場合のみ有効） */
- (BOOL)setServiceCheckRequestURLForTest:(NSString *)urlString;
/* For event logging. Give our test beacon region  */
- (BOOL)fireTestLoggingRequestForBeaconRegionEvent:(CLBeaconRegion *)region event:(TbBTEventType)eventType;

@end

@protocol TbBTManagerDelegate <NSObject>

@optional
//[領域処理結果系]
// for region update
- (void)didPrepareToRefreshRegionsWithResult:(TbBTPrepareResultType)resultType;
- (void)didFailToPrepareLatestRegionsWithError:(NSError *)error;

//[ビーコン領域接触時用サービス系]
- (void)didCheckServiceForBeaconWithResult:(TbBTContactCheckResultType)resultType;
- (void)didReceivePresentationInfos:(NSArray *)presentations;
- (void)didFailToCheckServiceWithError:(NSError *)error;

//[通知コンテンツ処理結果系]
// for fire notification (and notification log)
- (void)didCheckFireNotificationExpectedly;
// for invalid data error, etc..
// fire notification blocking with some constraint(user setting, app state, interval etc..)
- (void)didBlockUserNotificationWithReason:(NSString *)reason;
- (void)didBlockRequestNotificationCheckWithReason:(NSString *)reason;
// for error of notification check request
- (void)didFailToCheckNotificationWithError:(NSError *)error;

//[タップ処理結果系]
// for tap request
- (void)didHandleTapRequestExpectedly;
- (void)didFailToHandleTapRequestWithError:(NSError *)error;

@end