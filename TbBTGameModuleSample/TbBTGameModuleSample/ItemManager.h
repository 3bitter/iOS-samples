//
//  ItemManager.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/06/24.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Item.h"
#import "BTServiceFacade.h"

@interface ItemManager : NSObject<BTServiceFacadeDelegate, NSStreamDelegate>

@property (copy, nonatomic) NSArray *allItems;

+ (instancetype)sharedManager;

// Initial preparation
- (void)prepareMasterItem;
- (void)decideUserInitialItems;

- (void)addMyItem:(Item *)sharedItem;
- (void)addToUseList:(Item *)item;

// Server side save
- (void)addAndPersistMyItem:(Item *)newItem;
- (void)setNewMainItem:(Item *)item;

- (void)saveItems;
- (void)loadItems;
- (NSArray *)myItems;
- (NSArray *)usingItems;

- (BOOL)isInMyItems:(Item *)item;
- (BOOL)isUsingItem:(Item *)item;

- (Item *)itemOfTheID:(NSString *)itemID;

// ユーザ通知用データフォーマット変換メソッド
- (void)setDict:(NSMutableDictionary *)itemDict forItem:(Item *)item;
- (void)setItem:(Item *)item forItemDict:(NSDictionary *)itemDict;

@end
