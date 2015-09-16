//
//  ItemManager.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/06/24.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemManager.h"
#import "DefaultServerClient.h"

#import "TbSandboxCredential.h"

@interface ItemManager ()<DefaultServerClientDelegate>

@property (strong, nonatomic) NSMutableArray *currentShareList;

@property (assign, nonatomic) NSUInteger downloadIconIndex;
@property (assign, nonatomic) BOOL iconsPrepared;

@end

NSString *kMasterItemPrepared = @"MasterItemPrepared";
NSString *kInitialItemPrepared = @"InitialItemPrepared";
NSString *kItemPreparationFailed = @"ItemPreparationFailed";
NSString *kMyItemAdded = @"MyItemAdded";
NSString *kItemAdditionFailed = @"ItemAdditionFailed";
NSString *kMainItemChanged = @"MainItemChanged";
NSString *kMainChangeFailed = @"MainItemChangeFailed";

NSString *kOneThirdIconsDownloaded = @"abount1/3";
NSString *kTwoThirdIconsDownloaded = @"abount2/3";

@implementation ItemManager

NSString *kSharedItem = @"sharedItem";
NSString *kItemCheckType = @"checkType";

static const NSUInteger USE_LIMIT = 3;

NSString *kItemStore = @"ItemStore";

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[ItemManager alloc] init];
        if (instance) {
            [instance loadItems];
            [instance prepareUseItem];
        }
    });
    return instance;
}


- (NSArray *)myItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"own = YES"];
    return [NSMutableArray arrayWithArray:[_allItems filteredArrayUsingPredicate:predicate]];
}

- (Item *)itemOfTheID:(NSString *)itemID {
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"itemID = %@", itemID];
    // Should be only 1
    NSArray *candidates = [_allItems filteredArrayUsingPredicate:predicate];
    if (candidates.count == 0) {
        return nil;
    } else {
        return [candidates firstObject];
    }
}

- (NSArray *)usingItems {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"usingInGame = YES"];
    return [NSMutableArray arrayWithArray:[_allItems filteredArrayUsingPredicate:predicate]];
}

- (BOOL)isInMyItems:(Item *)item {
    if ([[self myItems] containsObject:item]) {
        return YES;
    }
    return NO;
}

- (void)addMyItem:(Item *)newItem {
    for (Item *masterItem in _allItems) {
        if ([masterItem.itemID isEqualToString:newItem.itemID]) {
            masterItem.own = YES;
            break;
        }
    }
    [self saveItems];
}

- (void)addAndPersistMyItem:(Item *)newItem {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *memberToken = [userDefaults objectForKey:@"token"];
    if (!memberToken) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kItemAdditionFailed object:self];
    }
    for (Item *masterItem in _allItems) {
        if ([masterItem.itemID isEqualToString:newItem.itemID]) {
            masterItem.own = YES;
            break;
        }
    }
    
    [self saveItems];
    
    DefaultServerClient *serverClient = [[DefaultServerClient alloc] init];
    serverClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    serverClient.myAppToken = appToken;
    [serverClient requestAddItemAsUserItem:newItem.itemID forMember:memberToken];
}

- (void)removeMyItem:(NSString *)targetItemID {
    for (Item *masterItem in _allItems) {
        if ([masterItem.itemID isEqualToString:targetItemID]) {
            masterItem.own = NO;
            break;
        }
    }
    [self saveItems];
}

- (BOOL)isUsingItem:(Item *)item {
    if (item.usingInGame) {
        return YES;
    }
    return NO;
}

- (void)addToUseList:(Item *)item {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"usingInGame = YES"];
    NSArray *usingItems = [_allItems filteredArrayUsingPredicate:predicate];
    if ([usingItems containsObject:item]) {
         NSLog(@"Already using");
        return;
    } else if (usingItems.count == USE_LIMIT) { // change the last using item
        ((Item *)[usingItems lastObject]).usingInGame = NO;
    }
    item.usingInGame = YES;
    [self saveItems];
}

- (void)setNewMainItem:(Item *)item {
    if (!item || item.main) {
        return;
    } else {
        BOOL valid = YES;
        NSPredicate *mainPredicate = [NSPredicate predicateWithFormat:@"main = YES"];
        NSArray *currentMainCandidates = [[self myItems] filteredArrayUsingPredicate:mainPredicate];
        assert(currentMainCandidates.count == 1);
        Item *currentMainItem = [currentMainCandidates firstObject];
        assert(currentMainItem.main);
        currentMainItem.main = NO;
        item.main = YES;
        [self saveItems];
        
        DefaultServerClient *serverClient = [[DefaultServerClient alloc] init];
        serverClient.delegate = self;
        NSString *appToken = [[TbSandboxCredential myCredential] appToken];
        serverClient.myAppToken = appToken;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *memberToken = [userDefaults objectForKey:@"token"];
        if (!memberToken) {
            valid = NO;
        }
        if (!valid) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMainChangeFailed object:self];
        } else {
            [serverClient requestChangeMainItem:item.itemID forMember:memberToken];
        }
    }
}

- (void)prepareMasterItem {
    [self cleanUpSavedItems];
    
    DefaultServerClient *serverClient = [[DefaultServerClient alloc] init];
    serverClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    serverClient.myAppToken = appToken;
    [serverClient retrieveMasterItemData];
}

- (void)decideUserInitialItems {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *memberToken = [userDefaults objectForKey:@"token"];
    if (!memberToken) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
        return;
    }
    DefaultServerClient *serverClient = [[DefaultServerClient alloc] init];
    serverClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    serverClient.myAppToken = appToken;
    [serverClient requestInitialItemsForMember:memberToken];
}

- (void)loadItems {
    NSArray *itemDictArray = nil;
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *itemStorePath = [rootPath stringByAppendingPathComponent:kItemStore];
    if ([[NSFileManager defaultManager] fileExistsAtPath:itemStorePath]) {
        NSDictionary *storedItemDictionary = [NSDictionary dictionaryWithContentsOfFile:itemStorePath];
        itemDictArray = [storedItemDictionary objectForKey:@"AllItems"];
    } else {
        NSLog(@"No items on local side...");
        return;
    }
    if (itemDictArray.count > 0) {
        NSMutableArray *itemArray = [NSMutableArray arrayWithCapacity:itemDictArray.count];
        for (NSDictionary *itemDict in itemDictArray) {
            Item *anItem = [[Item alloc] init];
            [self setItem:anItem forItemDict:itemDict];
            [itemArray addObject:anItem];
        }
        _allItems = [NSArray arrayWithArray:itemArray];
    }
}

- (void)reloadItems {
    _allItems = nil;
    [self loadItems];
    [self prepareUseItem];
}

- (void)prepareUseItem {
    NSPredicate *usingPredicate = [NSPredicate predicateWithFormat:@"usingInGame = YES"];
    NSArray *usingItems = [_allItems filteredArrayUsingPredicate:usingPredicate];
    if (usingItems.count == 0 && [self myItems].count > 0) {
        [self addToUseList:[[self myItems] objectAtIndex:0]];
    }
}

// For simple management, not using Core Data Framework
- (void)saveItems {
    NSError *error = nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *itemStorePath = [rootPath stringByAppendingPathComponent:kItemStore];
    NSMutableDictionary *itemDictionary = [NSMutableDictionary dictionary];
    
    NSMutableArray *allArray = [NSMutableArray array];
    for (Item *item in _allItems) {
        NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
        [self setDict:itemDict forItem:item];
        [allArray addObject:itemDict];
    }
    [itemDictionary setObject:allArray forKey:@"AllItems"];
    
    if ([itemDictionary writeToFile:itemStorePath atomically:YES]) {
        NSLog(@"Saved to Item store");
    } else {
        NSLog(@"Save failed....");
        if (error) {
            NSLog(@"error: %@", [error userInfo]);
        }
    }
}

- (BOOL)cleanUpSavedItems {
    BOOL success = NO;
    NSError *error = nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *iconStorePath = [rootPath stringByAppendingPathComponent:@"Icons"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:iconStorePath]
        && [[NSFileManager defaultManager] removeItemAtPath:iconStorePath error:&error]) {
        NSLog(@"Icons removed");
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:iconStorePath]){
        NSLog(@"Failed to remove icons");
        return success;
    }
    NSString *itemStorePath = [rootPath stringByAppendingPathComponent:kItemStore];
    if ([[NSFileManager defaultManager] fileExistsAtPath:itemStorePath]
        && [[NSFileManager defaultManager] removeItemAtPath:itemStorePath error:&error]) {
        NSLog(@"Items removed");
        success = YES;
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:kItemStore]) {
        NSLog(@"Failed to remove items");
    }
    return success;
}

#pragma mark Format convert

- (void)setDict:(NSMutableDictionary *)itemDict forItem:(Item *)item {
    [itemDict setObject:item.itemID forKey:@"itemID"];
    [itemDict setObject:item.itemName forKey:@"name"];
    [itemDict setValue:[NSNumber numberWithInteger:item.itemRank] forKey:@"rank"];
    [itemDict setObject:item.iconName forKey:@"icon"];
    [itemDict setObject:item.explanation forKey:@"explanation"];
    [itemDict setValue:[NSNumber numberWithBool:item.own] forKey:@"own"];
    [itemDict setValue:[NSNumber numberWithBool:item.main] forKey:@"main"];
    [itemDict setValue:[NSNumber numberWithBool:item.usingInGame] forKey:@"using"];
}

- (void)setItem:(Item *)item forItemDict:(NSDictionary *)itemDict {
    item.itemID = [itemDict objectForKey:@"itemID"];
    item.itemName = [itemDict objectForKey:@"name"];
    item.itemRank = [[itemDict valueForKey:@"rank"] integerValue];
    NSString *iconName = [itemDict objectForKey:@"icon"];
    if (iconName) {
        item.iconName = iconName;
        UIImage *itemIcon = [UIImage imageNamed:iconName];
        if (!itemIcon) {
            NSString *iconPath = nil;
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *iconStorePath = [rootPath stringByAppendingPathComponent:@"Icons"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:iconStorePath]) {
                iconPath = [iconStorePath stringByAppendingPathComponent:iconName];
            }
            itemIcon = [UIImage imageWithContentsOfFile:iconPath];
        }
        item.itemIcon = itemIcon;
    }
    NSString *explanation = [itemDict objectForKey:@"explanation"];
    if (explanation) {
        item.explanation = explanation;
    }
    item.own = [[itemDict valueForKey:@"own"] boolValue];
    item.main = [[itemDict valueForKey:@"main"] boolValue];
    item.usingInGame = [[itemDict valueForKey:@"using"] boolValue];
}

#pragma mark DefaultServerClientDelegate

- (void)serverClient:(DefaultServerClient *)client didRetrieveMasterItems:(NSArray *)masterItems {
    _allItems = masterItems;
    [self saveItems];
    // Icon files. Using the same client for sequential downloading
    client.maxNumberOfIcons = _allItems.count;
    _downloadIconIndex = 0;
    Item *targetItem = [_allItems objectAtIndex:0];
    NSString *iconFileName = targetItem.iconName;
    if (!iconFileName) { // Abort setup because of missing icon name
        NSLog(@"Missing iconName...");
        [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
        return;
    }
    [client downloadIconFileForName:iconFileName];
}

- (void)serverClient:(DefaultServerClient *)client didFailToRetrieveMasterItemsWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
}

- (void)serverClient:(DefaultServerClient *)client didDownloadIconFileForName:(NSString *)fileName {
    if (_downloadIconIndex == _allItems.count - 1) {
        _iconsPrepared = YES;
    } else if (_downloadIconIndex > _allItems.count / 3) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOneThirdIconsDownloaded object:self];
    } else if (_downloadIconIndex > 2 *_allItems.count / 3) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTwoThirdIconsDownloaded object:self];
    }
    if (_iconsPrepared) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMasterItemPrepared object:self];
    } else {
        _downloadIconIndex++;
        Item *newTargetItem = [_allItems objectAtIndex:_downloadIconIndex];
        [client downloadIconFileForName:newTargetItem.iconName];
    }
}

- (void)serverClient:(DefaultServerClient *)client didFailToDownloadIconFileWithError:(NSError *)error forName:(NSString *)fileName {
    NSLog(@"icon download failed :%@ error: %@", fileName, [error userInfo]);
    NSLog(@"error description: %@", [error localizedDescription]);
    // Cleaning item info for retry
    [self cleanUpSavedItems];
    [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
}

- (void)serverClient:(DefaultServerClient *)client didDecideUserInitialItems:(NSArray *)items {
    if (!_allItems) {
        NSLog(@"Missing master items with some reason ....");
        [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
        return;
    }
    for (Item *item in items) {
        NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"itemID = %@", item.itemID];
        NSArray *filtered = [_allItems filteredArrayUsingPredicate:itemPredicate];
        if (filtered.count != 1) {
            NSLog(@"Seems to have wrong data set...");
            [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
            return;
        } else {
            Item *selected = [filtered firstObject];
            if (item.main) {
                selected.main = YES;
            }
            [self addMyItem:selected];
        }
    }
    [self reloadItems];
    [[NSNotificationCenter defaultCenter] postNotificationName:kInitialItemPrepared object:self];
}

- (void)serverClient:(DefaultServerClient *)client didFailToDecideUserItemsWithError:(NSError *)error {
    // Cleaning item info for retry
    [self cleanUpSavedItems];
    [[NSNotificationCenter defaultCenter] postNotificationName:kItemPreparationFailed object:self];
}

- (void)serverClient:(DefaultServerClient *)client didAddNewMemberItem:(NSString *)itemID {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] postNotificationName:kMyItemAdded object:self];
}

- (void)serverClient:(DefaultServerClient *)client didFailToAddNewMemberItem:(NSString *)itemID withError:(NSError *)error {
    // Remove locally added item
    [self removeMyItem:itemID];
    NSLog(@"error: %@", [error localizedDescription]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kItemAdditionFailed object:self];
}

- (void)serverClient:(DefaultServerClient *)client didChangeMainItem:(NSString *)itemID {
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainItemChanged object:self];
}

- (void)serverClient:(DefaultServerClient *)client didFailToChangeMainItemWithError:(NSError *)error {
    NSLog(@"error: %@", [error localizedDescription]);
    [[NSNotificationCenter defaultCenter] postNotificationName:kMainChangeFailed object:self];
}

#pragma mark BTServiceFacadeDelegate

/* ビーコンキーが特定されたので、オーナーのアイテムをリクエストします　*/
- (void)btFacade:(BTServiceFacade *)facade didContactWithTargetBeacon:(NSString *)beaconKey {
    [facade checkSharedItemsByBeacon:beaconKey];
}

- (void)btFacade:(BTServiceFacade *)facade didContactWithTargetBeacons:(NSArray *)beaconKeys {
    [facade checkSharedItemsByBeacons:beaconKeys];
}


- (void)btFacade:(BTServiceFacade *)facade didGetSharedItemsForKeycode:(NSArray *)sharedItemInfos {
    NSLog(@"%s", __func__);
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"アイテムを持ったメンバーと遭遇しました！";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
        
    NSDictionary *sharedItemDict = [sharedItemInfos firstObject];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setValue:[NSNumber numberWithInteger:BTItemCheckTypeSingleBeacon] forKey:kItemCheckType];
    [infoDict setObject:sharedItemDict forKey:kSharedItem];
    localNotification.userInfo = [NSDictionary dictionaryWithDictionary:infoDict];
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

- (void)btFacade:(BTServiceFacade *)facade didFailToGetItemsForKeycodeWithReason:(NSString *)reason {
    NSLog(@"[Warn] Failed to get Items: %@", reason);
    // Nothing affects user
}

- (void)btFacade:(BTServiceFacade *)facade didGetSharedItemsForDetectedBeacons:(NSArray *)sharedItemInfos {
    NSLog(@"%s", __func__);
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"アイテムを持ったメンバーと遭遇しました！";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setValue:[NSNumber numberWithInteger:BTItemCheckTypeMultipleBeacon] forKey:kItemCheckType];
    [infoDict setObject:sharedItemInfos forKey:kSharedItem];
    localNotification.userInfo = [NSDictionary dictionaryWithDictionary:infoDict];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

- (void)btFacade:(BTServiceFacade *)facade didFailToGetItemsForDetectedBeaconsWithReason:(NSString *)reason {
     NSLog(@"[Error] Failed to get Items: %@", reason);
    // Nothing affects user
}

@end
