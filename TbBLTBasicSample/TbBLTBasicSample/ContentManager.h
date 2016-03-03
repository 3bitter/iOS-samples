//
//  ContentManager.h
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContentManager : NSObject

+ (instancetype)sharedManager;
- (NSArray *)defaultContents;
- (NSInteger)prepareContentsForTbBeacons:(NSArray *)beaconKeys;
- (NSArray *)mappedContentsForTbBeacons;
- (NSArray *)mappedContentsForTbBeacons:(NSArray *)beaconKeys;

@end
