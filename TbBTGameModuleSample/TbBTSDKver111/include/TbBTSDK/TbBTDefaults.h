//
//  TbBTDefaults.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, TbBTHTTPStatus) {
    TbBTHTTPStatusOK = 200,
    TbBTHTTPStatusMovedPermanently = 301,
    TbBTHTTPStatusMovedTemporarily = 302,
    TbBTHTTPStatusBadRequest = 400,
    TbBTHTTPStatusUnauthorized = 401,
    TbBTHTTPStatusForbidden = 403,
    TbBTHTTPStatusNotFound = 404,
    TbBTHTTPStatusInternalServerError = 500,
    TbBTHTTPStatusBadGateway = 502,
    TbBTHTTPStatusTemporaryUnavailable = 503,
    TbBTHTTPStatusOther = -1
};

typedef NS_ENUM(NSInteger, TbBTEventType) {
    TbBTEventTypeDidEnter = 1,
    TbBTEventTypeDidExit = 2,
    TbBTEventTypeIsInside = 3,
    TbBTEventTypeIsOutside = 4
};

typedef NS_ENUM(NSInteger, TbBTManagedRegionType) {
    TbBTManagedRegionTypeWhole = 0,
    TbBTManagedRegionTypeTest = 1,
    TbBTManagedRegionTypeOwned = 2,
    TbBTManagedRegionType3rd = 3
};

typedef NS_ENUM(NSInteger, TbBTPrepareResultType) {
    TbBTPrepareResultTypeNoDifference,
    TbBTPrepareResultTypeHasNew,
    TbBTPrepareResultTypeHasAbandoned,
    TbBTPrepareResultTypeHasNewAndAbandoned
};

typedef NS_ENUM(NSInteger, TbBTContactCheckResultType) {
    TbBTContactCheckResultTypeDoNothing = 0000,
    TbBTContactCheckResultTypeMarked = 1003,
    TbBTContactCheckResultTypeTotallyBlocked = 2000,
    TbBTContactCheckResultTypePartBlocked = 2001,
    TbBTContactCheckResultTypeUnmarkable = 3000,
    TbBTContactCheckResultTypeTargetNotFound = 4000,
    TbBTContactCheckResultTypeSkipped = 5000
};

@interface TbBTDefaults : NSObject

@property (nonatomic, copy, readonly) NSArray *usingServiceRegionInfos;
@property (nonatomic, copy, readonly) NSArray *reservedServiceUUIDs;

+ (TbBTDefaults *)sharedDefaults;
- (NSString *)SDKIdentifier;
- (NSString *)serviceAgreementURL;

@end