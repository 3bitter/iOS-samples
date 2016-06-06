//
//  TbBTDefaults.h
//  TbBTSDK Limited
//
//  Created by Takefumi Ueda on 2015/12/20.
//  Copyright (c) 2015年 3bitter, Inc. All rights reserved.
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

@interface TbBTDefaults : NSObject

@property (nonatomic, copy, readonly) NSArray *usingServiceRegionInfos;
@property (nonatomic, copy, readonly) NSArray *reservedServiceUUIDs;

+ (TbBTDefaults *)sharedDefaults;
- (NSString *)SDKIdentifier;
- (NSString *)serviceAgreementURL;

@end