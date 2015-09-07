//
//  TbBTBeaconizer.h
//  TbBTChecker
//
//  Created by Ueda on 2015/08/01.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//
// ※ TbBTMangerを介した規約への同意後にのみ有効

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol TbBTBeaconizerDelegate;

@interface TbBTBeaconizer : NSObject

@property (weak, nonatomic) id<TbBTBeaconizerDelegate> delegate;

+ (instancetype)instantiateWithMajor:(NSUInteger)majorValue Minor:(NSUInteger)minorValue;
+ (instancetype)sharedBeaconizer;

/* 事前に規約への同意が必要です */
- (void)tryToActivateAsBeacon;
- (void)resignActiveBeacon;
- (CLBeaconRegion *)myBeaconRegion;
- (BOOL)isActivatable;
- (BOOL)isActive;

@end

@protocol TbBTBeaconizerDelegate <NSObject>

- (void)didBecomeActiveBeacon;
- (void)didBlockToBecomeActiveBeaconWithReson:(NSString *)reson;
- (void)didFailToBecomeActiveBeaconWithError:(NSString *)error;
- (void)didResignActiveBeacon;
- (void)didFailToResignActiveBeaconWithReson:(NSString *)reson;

@end