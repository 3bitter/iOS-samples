//
//  Item.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/15.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ItemPresenType) {
    ItemPresenTypeMaster = 1,
    ItemPresenTypeOwn = 2,
    ItemPresenTypeShared = 3,
};

@interface Item : NSObject

@property (copy, nonatomic) NSString *itemID;
@property (copy, nonatomic) NSString *itemName;
@property (assign, nonatomic) BOOL main;
@property (assign, nonatomic) NSUInteger itemRank;
@property (copy, nonatomic) NSString *iconName;
@property (strong, nonatomic) UIImage *itemIcon;
@property (copy, nonatomic) NSString *explanation;

@property (assign, nonatomic) BOOL own;
@property (assign, nonatomic) BOOL usingInGame;

@end
