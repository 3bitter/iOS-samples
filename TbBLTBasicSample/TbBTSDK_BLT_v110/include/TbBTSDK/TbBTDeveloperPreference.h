//
//  TbBTDeveloperPreference.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

@interface TbBTDeveloperPreference : NSObject

@property (copy, nonatomic, readonly) NSString *appCode;
@property (copy, nonatomic, readonly) NSString *sdkEdition;
@property (copy, nonatomic, readonly) NSString *sdkVersion;
/* 登録可能なビーコン領域数。1〜 19 */
@property (assign, nonatomic, readonly) NSUInteger maxDesignatableBeaconRegions;
@property (assign, nonatomic, readonly) NSUInteger regionRefreshIntervalHours;
@property (assign, nonatomic, readonly) BOOL testMode;

+ (instancetype)sharedPreference;

@end
