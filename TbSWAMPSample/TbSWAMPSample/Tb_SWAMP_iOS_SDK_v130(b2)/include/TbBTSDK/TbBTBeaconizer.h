//
//  TbBTBeaconizer.h
//  TbBTSDK
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

// Prepare to be smartphone beacon
+ (instancetype)instantiateStaticWithMajor:(NSUInteger)majorValue Minor:(NSUInteger)minorValue;
+ (instancetype)sharedBeaconizer;

/* 事前にTbBTManagerのインスタンス化
  [TbBTManager initSharedManagerUnderAgreement:YES];
 が実行されている必要があります
 */
- (void)tryToActivateAsBeacon;
- (void)resignActiveBeacon;
- (CLBeaconRegion *)myBeaconRegion;
- (BOOL)isActivatable;
- (BOOL)isActive;

@end

@protocol TbBTBeaconizerDelegate <NSObject>

- (void)didBecomeActiveBeacon;
- (void)didBlockToBecomeActiveBeaconWithReason:(NSString *)reason;
- (void)didFailToBecomeActiveBeaconWithError:(NSString *)error;
- (void)didResignActiveBeacon;
- (void)didFailToResignActiveBeaconWithReason:(NSString *)reason;

@end
