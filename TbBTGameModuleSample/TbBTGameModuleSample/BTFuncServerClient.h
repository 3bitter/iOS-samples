//
//  BTFuncServerClient.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/05/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//
// ゲームサーバのビーコンをトリガとする機能とインタラクション（非同期）するクライアントクラス

#import <Foundation/Foundation.h>
#import "BTServiceFacade.h"
#import "BeaconOwner.h"

@protocol BTFuncServerClientDelegate;

@interface BTFuncServerClient : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSStreamDelegate>

@property (assign, nonatomic) id<BTFuncServerClientDelegate> delegate;
@property (copy, nonatomic) NSString *myAppToken;

- (void)requestAddBeaconkey:(NSString *)beaconKey forMember:(NSString *)memberToken;
- (void)requestDeactivateBeaconkey:(NSString *)beaconKey forMember:(NSString *)memberToken;

- (void)requestCheckItemsWithKeycode:(NSString *)keycode fromMember:(NSString *)memberToken;

- (void)requestCheckOwnerForBeaconKey:(NSString *)keycode fromMember:(NSString *)memberToken;

@end

@protocol BTFuncServerClientDelegate <NSObject>
// キーコードの登録に成功しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didAddBeaconkey:(NSString *)beaconKey;
// キーコードの登録が error のエラー発生により失敗しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToAddBeaconkeyWithError:(NSError *)error;
// キーコードの無効化に成功しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didDeactivateBeaconkey:(NSString *)beaconKey;
// キーコードの無効化が error のエラー発生により失敗しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToDeactivateBeaconkeyWithError:(NSError *)error;
// キーコードのビーコンのオーナーの共有可能なアイテム items を取得しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didGetSharedItemsForKeycode:(NSArray *)items;
// error の発生により、アイテムのチェックに失敗しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToCheckItemsWithError:(NSError *)error;
// アイテムのチェックをしましたが、resultType の結果でした（アイテム取得以外の結果を返します）
- (void)BTFuncServerClient:(BTFuncServerClient *)client didCheckItemsWithResult:(CheckResultType)resultType;
// ビーコンオーナーがゲームメンバーかつすれ違い機能用ビーコンを登録してたのでメンバー情報を取得しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didGetBeaconOwner:(BeaconOwner *)member;
// ビーコンオーナーのチェックに失敗しました
- (void)BTFuncServerClient:(BTFuncServerClient *)client didFailToCheckOwnerWithError:(NSError *)error forKeycode:(NSString *)beaconKey;
// beaconKeyのビーコンのオーナーのチェック結果は resultType でした
- (void)BTFuncServerClient:(BTFuncServerClient *)client didCheckOwnerWithResult:(CheckResultType)resultType forKeyCode:(NSString *)beaconKey;

@end