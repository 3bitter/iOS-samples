//
//  TbBTServiceHelper.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/22.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TbBTServiceHelperDelegate;

@interface TbBTServiceHelper : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (weak, nonatomic) id<TbBTServiceHelperDelegate> delegate;

+ (TbBTServiceHelper *)sharedHelper;
// Method For start retrieve data from server, return NO if start failed
//[サービス規約データ取得]
- (BOOL)retrieveAgreementData;
// If retrieve failed returns nil
- (NSData *)agreementData;

@end

@protocol TbBTServiceHelperDelegate <NSObject>

- (void)didRetrieveAgreementDataExpectedly;
- (void)didFailToRetrieveAgreementDataWithError:(NSError *)error;

@end