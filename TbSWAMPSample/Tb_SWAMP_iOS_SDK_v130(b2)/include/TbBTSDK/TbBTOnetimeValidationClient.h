//
//  TbBTOnetimeValidationClient.h
//  TbBTSDK
//
//  Created by Ueda on 2016/08/09.
//  Copyright © 2016年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol TbBTOnetimeValidationClientDelegate;

typedef NS_ENUM(NSInteger, TbBTOnetimeValidationError) {
    TbBTOnetimeValidationErrorInvalidApp = 2001,
    TbBTOnetimeValidationErrorInvalidRegion = 2002,
    TbBTOnetimeValidationErrorInvalidBeacon = 2003,
    TbBTOnetimeValidationErrorInternalServerError = 2004,
    TbBTOnetimeValidationErrorInternetUnconnectable = 2005
};


@interface TbBTOnetimeValidationClient : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (weak, nonatomic) id<TbBTOnetimeValidationClientDelegate> delegate;

- (void)requestValidationForOnetimeBeacon:(CLBeacon *)beaconInfo;

@end


@protocol TbBTOnetimeValidationClientDelegate <NSObject>

- (void)confirmedAsValidBeacon;
- (void)decidedAsInvalidBeacon;

// Includes Not found, Invalid beacon, Invalid app token
- (void)didFailToValidateBeaconWithError:(NSError *)error;

@end
