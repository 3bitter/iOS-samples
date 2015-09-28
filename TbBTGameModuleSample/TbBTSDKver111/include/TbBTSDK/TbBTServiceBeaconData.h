//
//  TbBTServiceBeaconData.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2015/05/15.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TbBTServiceBeaconData : NSObject

@property (copy, nonatomic, readonly) NSString *regionID;
@property (assign, nonatomic, readonly) NSInteger segment;
@property (copy, nonatomic, readonly) NSString *keycode;
// Optional flag for combination control. default 'NO'
@property (assign, nonatomic) BOOL switcher;

- (instancetype)initWithRegionID:(NSString *)regionID segment:(NSInteger)segmentValue keycode:(NSString *)keycode;

- (void)setSwitcher:(BOOL)switcher;
- (BOOL)isSwitcher;

@end
