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
    TbBTOnetimeValidationErrorInvalidApp,
    TbBTOnetimeValidationErrorInvalidRegion,
    TbBTOnetimeValidationErrorInvalidBeacon,
    TbBTOnetimeValidationErrorInternalServerError,
    TbBTOnetimeValidationErrorInternetUnconnectable
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
