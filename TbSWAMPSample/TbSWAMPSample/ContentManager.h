//
//  ContentManager.h
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
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
