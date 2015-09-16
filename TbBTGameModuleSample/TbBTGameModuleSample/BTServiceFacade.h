//
//  BTServiceFacade.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//
//  ビーコンとインタラクションするためのSDKやサーバとの処理は全てこのクラスを介して実行します
//  [設計方針]
// サンプル実装のため把握し易さ優先でビーコン関連メソッドをまとめています。
// サーバとのやりとり結果についてはBTServiceFacadeDelegateのメソッドをコールバックします。
//  デリゲートはItemManager（すれ違い通知処理）と、NeighbersTableViewController（メンバーチェック処理）です。
//  その他UIに対しての状態変更についてはコールバック通知（NSNotification）を送信します
// 実際のアプリ実装では、パフォーマンス、アプリケーションアーキテクチャその他必要要件に応じて適宜分割処理してください。

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "TbBTManager.h"
#import "MyBeacon.h"

@protocol BTServiceFacadeDelegate;

typedef NS_ENUM(NSInteger, BTItemCheckType) {
    BTItemCheckTypeSingleBeacon,
    BTItemCheckTypeMultipleBeacon
};

typedef NS_ENUM(NSInteger, CheckResultType) {
    CheckResultTypeOwnerNotCandidate = 1, // ゲームメンバーのゲーム用ビーコンではありません
    CheckResultTypeSharingInactive = 2, // ビーコンオーナーのゲーム用ビーコンがオフ状態なので共有アイテムが取得できません
    CheckResultTypeHasSame = 3 // 見つかった共有アイテムは既に所有しています
};

@interface BTServiceFacade : NSObject<CLLocationManagerDelegate, TbBTManagerDelegate>

@property (assign, nonatomic) id<BTServiceFacadeDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *designatedBeacons;

@property (assign, nonatomic) BOOL foundNonDesignated;
@property (assign, nonatomic) BOOL addProcessing;
@property (assign, nonatomic) BOOL neighbersSearching;
@property (strong, nonatomic) NSDate *addProcessTimeoutTime;

/* 共有シングルトンインスタンス */
+ (instancetype)sharedFacade;
/* SDKのユーティリティメソッドのラッパーメソッド */
+ (BOOL)isLocationEventConditionMet;
- (void)requestUserAuthorization;
/* Monitoring */
- (void)startSearchForRegister;
- (void)stopSearchForRegister;
- (void)startMonitoringForCandidatesRegion;
- (void)stopMonitoringForServiceRegion;
- (BOOL)isTargetMonitoring;
/* Ranging */
- (void)startSearchNeighbers;
- (void)stopSearchNeighbers;

/* Beacon info management (for meta info) */
- (BOOL)saveOwnBeacons:(NSArray *)beaconInfos ofRegion:(CLBeaconRegion *)region;
- (BOOL)deleteRegisteredBeaconAtIndex:(NSUInteger)index;
- (BOOL)registerMyBeacons:(NSArray *)myBeacons;
- (void)cleanUpRegisteredBeacons;

/* Main beacon handling request */
- (void)registerUserMainBeacon:(MyBeacon *)selectedBeacon;
- (void)inactivateUserBeacon:(MyBeacon *)selectedBeacon;

/* Item request triggered by beacon(s) (to server) */
- (void)checkSharedItemsByBeacon:(NSString *)beaconKey;
- (void)checkSharedItemsByBeacons:(NSArray *)beaconKeys;

- (NSArray *)monitoredBTRegions;

- (BOOL)isChecking;

- (NSArray *)neighberUsers;

@end

@protocol BTServiceFacadeDelegate <NSObject>

@optional

// 1つのビーコンのみ処理対象とする場合：beaconKey のキーコードのビーコン（領域）に接触しました
- (void)btFacade:(BTServiceFacade *)facade didContactWithTargetBeacon:(NSString *)beaconKey;
// 複数のビーコンを同時に処理させる場合：beaconKeys のキーコードのビーコン（領域）に接触しました
- (void)btFacade:(BTServiceFacade *)facade didContactWithTargetBeacons:(NSArray *)beaconKeys;
// ビーコンオーナーが公開している取得可能アイテム sharedItemInfos を取得しました
- (void)btFacade:(BTServiceFacade *)facade didGetSharedItemsForKeycode:(NSArray *)sharedItemInfos;
// reason の理由で接触したビーコンのオーナーの共有可能（メイン）アイテムは取得できませんでした
- (void)btFacade:(BTServiceFacade *)facade didFailToGetItemsForKeycodeWithReason:(NSString *)reason;
// 検知されたユーザー全てのビーコンの共有可能（メイン）アイテム sharedItemInfos を取得しました
- (void)btFacade:(BTServiceFacade *)facade didGetSharedItemsForDetectedBeacons:(NSArray *)sharedItemInfos;
// reason の理由で接触したビーコンに関連した共有アイテムは１つも取得できませんでした
- (void)btFacade:(BTServiceFacade *)facade didFailToGetItemsForDetectedBeaconsWithReason:(NSString *)reason;

// 検知されたビーコンオーナーの情報チェック（ニックネームのみ取得）をしました
- (void)btFacade:(BTServiceFacade *)facade didProfileNewNeighbers:(NSArray *)discoveredNeighbers;
// 検知されたビーコンオーナーの情報チェックに失敗しました
- (void)btFacade:(BTServiceFacade *)facade didFailToProfileNeighbersWithError:(NSError *)error;
// 検知済みのビーコンオーナーの情報を更新しました
- (void)btFacade:(BTServiceFacade *)facade didUpdateNeighberInfos:(NSArray *)currentNeighbers;

@end
