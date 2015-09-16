//
//  MyBeacon.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/06/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyBeacon : NSObject

// Copied property
@property (copy, nonatomic) NSString *regionID;
@property (assign, nonatomic) NSInteger segment;
@property (copy, nonatomic) NSString *keycode;
@property (assign, nonatomic) BOOL useForGame;

// Original property
@property (copy, nonatomic) NSString * beaconName;

@end
