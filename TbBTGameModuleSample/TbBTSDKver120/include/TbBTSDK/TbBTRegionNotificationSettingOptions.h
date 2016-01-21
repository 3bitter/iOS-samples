//
//  TbBTRegionNotificationSettingOptions.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2015/05/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TbBTRegionNotificationType) {
    TbBTRegionNotificationTypeOnEntry  = 1 << 0,
    TbBTRegionNotificationTypeOnExit = 1 << 1,
    TbBTRegionNotificationTypeEntryStateOnDisplay = 1 << 2
};

@interface TbBTRegionNotificationSettingOptions : NSObject

// bitmask of region notification types
@property (assign, nonatomic, readonly) NSUInteger supporingTypes;

+ (instancetype)settingWithTypes:(TbBTRegionNotificationType)supportTypes;

@end
