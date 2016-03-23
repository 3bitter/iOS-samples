//
//  TbBTPresentationInfo.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// [表示形式]
typedef NS_ENUM(NSInteger, TbBTViewPresentationType) {
    TbBTViewPresentationTypeShowWebPage = 1,
    TbBTViewPresentationTypeShowAVContent = 2,
    TbBTViewPresentationTypeShowBanner = 3,
    TbBTViewPresentationTypeUnknown = -1
};

// [通知内容加工可否区分]
typedef NS_ENUM(NSUInteger, TbBTAnnotationType) {
    TbBTAnnotationTypeFixed = 1,
    TbBTAnnotationTypeCustomizable = 2,
    TbBTAnnotationTypeOverridable = 3,
    TbBTAnnotationTypeUnKnown = -1
};

@interface TbBTPresentationInfo : NSObject

@property (copy, nonatomic, readonly) NSString *presentationID;
@property (copy, nonatomic, readonly) NSString *campaignID;
@property (strong, nonatomic, readonly) NSDate *lastModified;
@property (assign, nonatomic, readonly) TbBTViewPresentationType presentationType;
@property (copy, nonatomic, readonly) NSString *contentURLString;
@property (assign, nonatomic, readonly) TbBTAnnotationType annotationType;
@property (copy, nonatomic, readonly) NSString *defaultBody;
@property (assign, nonatomic, readonly) NSUInteger alertWaitingTime;
@property (strong, nonatomic, readonly) NSDate *endTime;
@property (copy, nonatomic) NSString *optionalBody;
@property (assign, nonatomic) NSUInteger iconBudgeNumber;
@property (copy, nonatomic) NSString *notificationSoundName;

+ (BOOL)isValidProperties:(NSDictionary *)properties;
- (void)setUpProperties:(NSDictionary *)properties;

@end
