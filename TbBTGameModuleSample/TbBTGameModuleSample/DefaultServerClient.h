//
//  DefaultServerClient.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DefaultServerClientDelegate;

@interface DefaultServerClient : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate,  NSURLSessionDownloadDelegate>

@property (weak, nonatomic) id<DefaultServerClientDelegate> delegate;
@property (copy, nonatomic) NSString *myAppToken;

@property (strong, nonatomic) NSURLSession *registerSession; // メンバー登録関連
@property (strong, nonatomic) NSURLSession *masterDataSession; // マスタデータ関連
@property (strong, nonatomic) NSURLSession *iconDownloadSession; // アイコンダウンロード用
@property (strong, nonatomic) NSURLSession *memberItemSession; // メンバーアイテム関連
@property (assign, nonatomic) NSUInteger maxNumberOfIcons;

- (void)requestBecomeAMember:(NSString *)nickName;
- (void)retrieveMasterItemData;
- (void)downloadIconFileForName:(NSString *)iconFileName;
- (void)requestInitialItemsForMember:(NSString *)memberToken;
- (void)requestAddItemAsUserItem:(NSString *)itemID forMember:(NSString *)memberToken;
- (void)requestChangeMainItem:(NSString *)mainItemID forMember:(NSString *)memberToken;

@end

@protocol DefaultServerClientDelegate <NSObject>

@optional
// メンバー登録に成功しました
- (void)serverClient:(DefaultServerClient *)client didRegistAsMember:(NSString*)memberToken;
// メンバー登録に error な理由で失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToBecomeMemberWithError:(NSError *)error;
// マスターアイテムリストを取得しました
- (void)serverClient:(DefaultServerClient *)client didRetrieveMasterItems:(NSArray *)masterItemInfos;
// マスターアイテムリストの取得に失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToRetrieveMasterItemsWithError:(NSError *)error;
// アイコン用画像ファイルの取得に成功しました
- (void)serverClient:(DefaultServerClient *)client didDownloadIconFileForName:(NSString *)fileName;
// アイコン用画像ファイルの取得に失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToDownloadIconFileWithError:(NSError *)error forName:(NSString *)fileName;
// ユーザの初期アイテム決定リクエストが成功しました
- (void)serverClient:(DefaultServerClient *)client didDecideUserInitialItems:(NSArray *)itemsInfos;
// サーバにリクエストした初期アイテムの選択が失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToDecideUserItemsWithError:(NSError *)error;
// 取得した itemID のアイテムをユーザのアイテムに追加しました
- (void)serverClient:(DefaultServerClient *)client didAddNewMemberItem:(NSString *)itemID;
// itemID のアイテムのこのメンバーのものとしての追加に失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToAddNewMemberItem:(NSString *)itemID withError:(NSError *)error;
// ユーザのメインアイテムを変更しました
- (void)serverClient:(DefaultServerClient *)client didChangeMainItem:(NSString *)itemID;
// ユーザのメインアイテムの変更に　失敗しました
- (void)serverClient:(DefaultServerClient *)client didFailToChangeMainItemWithError:(NSError *)error;


@end