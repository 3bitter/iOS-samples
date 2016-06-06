//
//  TbBTDeveloperPreference.h
//  TbBTSDK Limited
//
//  Created by Takefumi Ueda on 2015/12/20.
//  Copyright (c) 2015年 3bitter, Inc. All rights reserved.
//

@interface TbBTDeveloperPreference : NSObject

@property (copy, nonatomic, readonly) NSString *appCode;
@property (copy, nonatomic, readonly) NSString *sdkEdition;
@property (copy, nonatomic, readonly) NSString *sdkVersion;
/* 登録可能なビーコン領域数。1〜 19 */
@property (assign, nonatomic, readonly) NSUInteger maxDesignatableBeaconRegions;
@property (assign, nonatomic, readonly) NSUInteger regionRefreshIntervalHours;
@property (assign, nonatomic, readonly) BOOL testMode;
@property (assign, nonatomic, readonly) BOOL sendBeaconRegionControlLog;

+ (instancetype)sharedPreference;

@end
