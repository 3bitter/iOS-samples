//
//  BeaconOwner.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BeaconOwner : NSObject

@property (copy, nonatomic) NSString *userName;
// ビーコンキーはセキュリティ的観点からは他のユーザーには見せない方が良いでしょう
@property (copy, nonatomic) NSString *beaconKey;
@property (assign, nonatomic) NSInteger dummyIndicator;
@property (assign, nonatomic) BOOL usingBeaconForGame;
@property (copy, nonatomic) NSString *proximityDescription;
@property (assign, nonatomic) NSUInteger unknownStateCount;

@end
