//
//  ContentManager.m
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "ContentManager.h"
#import "OurContent.h"

@interface ContentManager()

@property (copy, nonatomic) NSArray *currentMappedContnents;

@end

@implementation ContentManager

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{
        instance = [[ContentManager alloc] init];
    });
    return instance;
}

- (NSArray *)defaultContents {

    OurContent *justAnotherContent1 = [[OurContent alloc] init];
    justAnotherContent1.title = @" 標準ダンジョン 1";
    justAnotherContent1.contentDescription = @"description 1";
    justAnotherContent1.icon = [UIImage imageNamed:@"normal_dungeon1"];
    
    OurContent *justAnotherContent2 = [[OurContent alloc] init];
    justAnotherContent2.title = @"標準ダンジョン 2";
    justAnotherContent2.contentDescription = @"description 2";
    justAnotherContent2.icon = [UIImage imageNamed:@"normal_dungeon2"];
    
    NSMutableArray *contentArray = [NSMutableArray array];
    [contentArray addObject:justAnotherContent1];
    [contentArray addObject:justAnotherContent2];
    return [NSArray arrayWithArray:contentArray];
}

- (NSInteger)prepareContentsForTbBeacons:(NSArray *)beaconKeys {
    NSMutableArray *dummyCheckedArray = [NSMutableArray array];
    for (NSString  *beaconKey in beaconKeys) {
        OurContent *mappedContent = [self dummySearchWithDummyMap:beaconKey];
        if (mappedContent) {
            [dummyCheckedArray addObject:mappedContent];
        }
    }
    _currentMappedContnents = [NSArray arrayWithArray:dummyCheckedArray];
    if (dummyCheckedArray.count == 0) {
        return 0;
    }
    return _currentMappedContnents.count;
}

- (NSArray *)mappedContentsForTbBeacons {
   return _currentMappedContnents;
}

// One time synchronous type method
- (NSArray *)mappedContentsForTbBeacons:(NSArray *)beaconKeys {
    NSMutableArray *dummyCheckedArray = [NSMutableArray array];
    for (NSString  *beaconKey in beaconKeys) {
        OurContent *mappedContent = [self dummySearchWithDummyMap:beaconKey];
        if (mappedContent) {
            [dummyCheckedArray addObject:mappedContent];
        }
    }
    if (dummyCheckedArray.count == 0) {
        return nil;
    }
    return [NSArray arrayWithArray:dummyCheckedArray];
}

// Get content by beacon key (dummy implementation)
- (OurContent *)dummySearchWithDummyMap:(NSString *)beaconKey {
    if (!beaconKey) {
        return nil;
    }
    
    OurContent *mappedContent1 = [[OurContent alloc] init];
    mappedContent1.title = @"Beacon region 1 limited";
    mappedContent1.contentDescription = @"Server side mapping may be better";
    mappedContent1.icon = [UIImage imageNamed:@"special_dungeon1"];
    
    OurContent *mappedContent2 = [[OurContent alloc] init];
    mappedContent2.title = @"Beacon region 2 limited";
    mappedContent2.contentDescription = @"Server side mapping may be better";
     mappedContent2.icon = [UIImage imageNamed:@"special_dungeon2"];
    
    OurContent *mappedContent3 = [[OurContent alloc] init];
    mappedContent3.title = @"Beacon region 3 limited";
    mappedContent3.contentDescription = @"Server side mapping may be better";

    
    // This matching is not for 1 on 1
    NSString *dummyPart = [beaconKey substringFromIndex:5];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSUInteger keyNumber = [[formatter numberFromString:dummyPart] integerValue];
    switch (keyNumber % 2) {
        case 0:
            return mappedContent1;
        case 1:
            return mappedContent2;
        default:
            return mappedContent3;
    }
    return nil;
}

@end
