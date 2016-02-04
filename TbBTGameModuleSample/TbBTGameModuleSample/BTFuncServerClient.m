//
//  BTFuncServerClient.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/16.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "BTFuncServerClient.h"
#import "Item.h"
#import "BeaconOwner.h"

typedef NS_ENUM(NSInteger, BTBeaconManagementTaskType) {
    BTBeaconManagementTaskTypeRegistGameUseBeacon,
    BTBeaconManagementTaskTypeDeactivateGameUseBeacon,
    BTBeaconManagementTaskTypeSearchOwner,
};

@interface BTFuncServerClient()

@property (assign, nonatomic) NSUInteger expectedDataBytes;
@property (strong, nonatomic) NSMutableData *receivedData;

@property (strong, nonatomic) NSURLSession *beaconKeySession;
@property (strong, nonatomic) NSURLSession *itemCheckSession;

@property (assign, nonatomic)BTBeaconManagementTaskType workingTaskType;
@property (copy, nonatomic) NSString *workingKeyCode;

@end

static NSString *kNewBeaconKeyURL = @"https://bitterbeacon.tokyo/BTGameUseServer/NewBeaconKey";
static NSString *kOffBeaconKeyURL = @"https://bitterbeacon.tokyo/BTGameUseServer/DeactivateBeaconKey";
static NSString *kCheckItemURL = @"https://bitterbeacon.tokyo/BTGameUseServer/SharedItem";
static NSString *kBeaconOwnerURL = @"https://bitterbeacon.tokyo/BTGameUseServer/BeaconOwner";

@implementation BTFuncServerClient


- (void)requestAddBeaconkey:(NSString *)beaconKey forMember:(NSString *)memberToken {
    if (!memberToken) {
        NSLog(@"memberToken must not be nil");
        return;
    }
    if (!_beaconKeySession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        NSDictionary *additionalHeaders = [NSDictionary dictionaryWithObject:@"TbBTGameModuleSample" forKey:@"User-Agent"];
        sessionConfig.HTTPAdditionalHeaders = additionalHeaders;
        _beaconKeySession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="]; // Member access token
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_btk="];
    [requestBodyString appendString:beaconKey];
    
    NSURL *keyMapURL = [NSURL URLWithString:[kNewBeaconKeyURL stringByAppendingString:requestBodyString]];
    NSURLRequest *newBeaconKeyRequest = [NSURLRequest requestWithURL:keyMapURL];
    NSURLSessionDataTask *newBeaconKeyTask = [_beaconKeySession dataTaskWithRequest:newBeaconKeyRequest];
    _workingTaskType = BTBeaconManagementTaskTypeRegistGameUseBeacon;
    _workingKeyCode = beaconKey;
    [newBeaconKeyTask resume];
        
}


- (void)requestDeactivateBeaconkey:(NSString *)beaconKey forMember:(NSString *)memberToken {
    if (!_beaconKeySession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        NSDictionary *additionalHeaders = [NSDictionary dictionaryWithObject:@"TbBTGameModuleSample" forKey:@"User-Agent"];
        sessionConfig.HTTPAdditionalHeaders = additionalHeaders;
        _beaconKeySession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="]; // Member access token
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_btk="]; // The keycode to be inactive
    [requestBodyString appendString:beaconKey];
    
    NSURL *keyMapURL = [NSURL URLWithString:[kOffBeaconKeyURL stringByAppendingString:requestBodyString]];
    NSURLRequest *keyDeactivateRequest = [NSURLRequest requestWithURL:keyMapURL];
    NSURLSessionDataTask *deactivateKeyTask = [_beaconKeySession dataTaskWithRequest:keyDeactivateRequest];
    
    _workingTaskType = BTBeaconManagementTaskTypeDeactivateGameUseBeacon;
    _workingKeyCode = beaconKey;
    [deactivateKeyTask resume];

}

- (void)requestCheckItemsWithKeycode:(NSString *)keycode fromMember:(NSString *)memberToken {
    NSLog(@"%s",__func__);
    if (!keycode) {
        NSLog(@"keycode must not be nil");
        return;
    }
    
    if (!_itemCheckSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
    
    
        NSDictionary *additionalHeaders = [NSDictionary dictionaryWithObject:@"TbBTGameModuleSample" forKey:@"User-Agent"];
        sessionConfig.HTTPAdditionalHeaders = additionalHeaders;
        _itemCheckSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="];
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_bk="];
    [requestBodyString appendString:keycode];
    
    NSURL *itemCheckURL = [NSURL URLWithString:[kCheckItemURL stringByAppendingString:requestBodyString]];
    NSURLRequest *itemCheckRequest = [NSURLRequest requestWithURL:itemCheckURL];
    
    NSURLSessionDataTask *itemCheckTask = [_itemCheckSession dataTaskWithRequest:itemCheckRequest];
    [itemCheckTask resume];
}

- (void)requestCheckOwnerForBeaconKey:(NSString *)keycode fromMember:(NSString *)memberToken {
    if (!_beaconKeySession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        NSDictionary *additionalHeaders = [NSDictionary dictionaryWithObject:@"TbBTGameModuleSample" forKey:@"User-Agent"];
        sessionConfig.HTTPAdditionalHeaders = additionalHeaders;
        _beaconKeySession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="];
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_bk="];
    [requestBodyString appendString:keycode];
    
    NSURL *keyOwnerURL = [NSURL URLWithString:[kBeaconOwnerURL stringByAppendingString:requestBodyString]];
    NSURLRequest *keyOwnerRequest = [NSURLRequest requestWithURL:keyOwnerURL];
    NSURLSessionDataTask *ownerSearchTask = [_beaconKeySession dataTaskWithRequest:keyOwnerRequest];
    _workingTaskType = BTBeaconManagementTaskTypeSearchOwner;
    _workingKeyCode = keycode;
    [ownerSearchTask resume];

}

#pragma mark Session Delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        
        BOOL isError = YES;
        NSDictionary *userInfo = nil;
        NSError *checkError = nil;
        
        switch (statusCode) {
            case 200:
                {
                    NSString *mimeType = httpResponse.MIMEType;
                    if (![@"text/json" isEqualToString:mimeType]) {
                        userInfo = [NSDictionary dictionaryWithObject:@"Unexpected MIME Type" forKey:@"errorType"];
                        checkError = [[NSError alloc] initWithDomain:@"Response" code:-1001 userInfo:userInfo];
                    } else {
                        isError = NO;
                        _expectedDataBytes = [[NSNumber numberWithLongLong:response.expectedContentLength] integerValue];
                        completionHandler(NSURLSessionResponseAllow);
                    }
                }
                break;
            default:
                userInfo = [NSDictionary dictionaryWithObject:@"HTTP Error" forKey:@"errorType"];
                checkError = [[NSError alloc] initWithDomain:@"Http" code:statusCode userInfo:userInfo];
                break;
        }
        if (isError) {
            if ([session isEqual:_beaconKeySession]) {
                if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:checkError];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didFailToDeactivateBeaconkeyWithError:checkError];
                } else if (_workingTaskType ==  BTBeaconManagementTaskTypeSearchOwner) {
                    [_delegate BTFuncServerClient:self didFailToCheckOwnerWithError:checkError forKeycode:_workingKeyCode];
                }
            } else if ([session isEqual:_itemCheckSession]) {
                [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:checkError];
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (_receivedData == nil) {
        _receivedData = [[NSMutableData alloc] init];
    }
    if (_receivedData.length < _expectedDataBytes) {
        [_receivedData appendBytes:data.bytes length:data.length];
        return; // Wait next data receive
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s",__func__);
    if (error == NULL) {
        if (_receivedData != nil) {
            [self parseReceivedDataAsJSON:_receivedData ofSession:session];
            // Clean up data
            _receivedData = nil;
        } else {
            NSString *errorMessage = @"Session task complete unexpectedly with no response data";
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:@"errorType"];
            NSError *error = [NSError errorWithDomain:@"SessionTask" code:-1002 userInfo:userInfo];
            if ([session isEqual:_beaconKeySession]) {
                if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:error];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon) {
                        [_delegate BTFuncServerClient:self didFailToDeactivateBeaconkeyWithError:error];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeSearchOwner) {
                    [_delegate BTFuncServerClient:self didFailToCheckOwnerWithError:error forKeycode:_workingKeyCode];
                }
            } else if ([session isEqual:_itemCheckSession]) {
                [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:error];
            }
            [session invalidateAndCancel];
            session = nil;
            return;
        }
        
    } else { // Failure case
        if ([session isEqual:_beaconKeySession]) {
            if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:error];
            } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon) {
                [_delegate BTFuncServerClient:self didFailToDeactivateBeaconkeyWithError:error];
            } else if (_workingTaskType == BTBeaconManagementTaskTypeSearchOwner) {
                [_delegate BTFuncServerClient:self didFailToCheckOwnerWithError:error forKeycode:_workingKeyCode];
            }
        } else if ([session isEqual:_itemCheckSession]) {
            [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:error];
        }
        [session invalidateAndCancel];
        session = nil;
    }
}

#pragma mark Response data parse

- (void) parseReceivedDataAsJSON:(NSData *)receivedData ofSession:(NSURLSession *)session {
    NSLog(@"%s",__func__);
    NSError *parseError = nil;
    NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&parseError];
    
    if (parseError != NULL) {
        if ([session isEqual:_beaconKeySession]) {
            if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:parseError];
            } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon) {
                [_delegate BTFuncServerClient:self didFailToDeactivateBeaconkeyWithError:parseError];
            } else if (_workingTaskType == BTBeaconManagementTaskTypeSearchOwner) {
                [_delegate BTFuncServerClient:self didFailToCheckOwnerWithError:parseError forKeycode:_workingKeyCode];
            }
        } else if ([session isEqual:_itemCheckSession]) {
            [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:parseError];
        }
        return;
    } else { // Parse succeed
        // Data validation
        NSError *validateError = nil;
        NSDictionary *userInfo = nil;
        
        NSString *resultCode = [responseJSON objectForKey:@"resultCode"];
        if (resultCode == nil) {
            userInfo = [NSDictionary dictionaryWithObject:@"Missing result Code" forKey:@"errorType"];
            validateError = [[NSError alloc] initWithDomain:@"Data" code:-1002 userInfo:userInfo];
            [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:validateError];
            return;
        }
        if ([@"BT001OK" isEqualToString:resultCode]) {
            if ([session isEqual:_beaconKeySession]) {
                if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didAddBeaconkey:_workingKeyCode];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon){
                    [_delegate BTFuncServerClient:self didDeactivateBeaconkey:_workingKeyCode];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeSearchOwner) {
                    NSDictionary *appMember = [responseJSON objectForKey:@"appMember"];
                    BeaconOwner *theOwner = [[BeaconOwner alloc] init];
                    theOwner.userName = [appMember objectForKey:@"nickName"];
                    theOwner.beaconKey = _workingKeyCode;
                    theOwner.usingBeaconForGame = YES;
                    
                    [_delegate BTFuncServerClient:self didGetBeaconOwner:theOwner];
                }
                return;
            } else if ([session isEqual:_itemCheckSession]) {
                NSArray *itemDictArray = [responseJSON objectForKey:@"sharedItems"];
                if (itemDictArray == nil) {
                    userInfo = [NSDictionary dictionaryWithObject:@"Missing items" forKey:@"errorType"];
                    validateError = [[NSError alloc] initWithDomain:@"Data" code:-1002 userInfo:userInfo];
                    [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:validateError];
                    return;
                }
                /*  必要に応じてバリデーション
                for (NSDictionary *itemDict in itemDictArray) {
                    NSString *itemID = [itemDict objectForKey:@"itemID"];
                    if (itemID == nil || ![Item validateItemID:itemID]){
                        hasInvalidData = YES;
                    }
                    NSString *ownerID = [itemDict objectForKey:@"ownerID"];
                    if (ownerID == nil || ![Item validateOwnerID:ownerID]) {
                        hasInvalidData = YES;
                    }
                    NSString *explanationText = [itemDict objectForKey:@"explanation"];
                    if (explanationText == nil) {
                        hasInvalidData = YES;
                    }
                    if(hasInvalidData) {
                        userInfo = [NSDictionary dictionaryWithObject:@"Response data has invalid data" forKey:@"errorType"];
                        validateError = [[NSError alloc] initWithDomain:@"Data" code:-1002 userInfo:userInfo];
                        [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:validateError];
                        return; // exit with error
                    }
                }*/
                // Notifify to delegate item check request complete
                [_delegate BTFuncServerClient:self didGetSharedItemsForKeycode:itemDictArray];
                return;
            }
        } else if ([@"BT002NotOwner" isEqualToString:resultCode]) { // ビーコンオーナーはアプリのユーザーではない、もしくはビーコンを使用登録していない
            if ([session isEqual:_itemCheckSession]) {
                [_delegate BTFuncServerClient:self didCheckItemsWithResult:CheckResultTypeOwnerNotCandidate];
            } else if ([session isEqual:_beaconKeySession]) {
                [_delegate BTFuncServerClient:self didCheckOwnerWithResult:CheckResultTypeOwnerNotCandidate forKeyCode:_workingKeyCode];
            }
            return;
        } else if ([@"BT003NoItem" isEqualToString:resultCode]) {
            [_delegate BTFuncServerClient:self didCheckItemsWithResult:CheckResultTypeSharingInactive];
            return;
        } else if ([@"BT004Failed" isEqualToString:resultCode]) {
            NSError *error = [NSError errorWithDomain:@"Server" code:0 userInfo:nil];
            if ([session isEqual:_beaconKeySession]) {
                [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:error];
                return;
            } else if ([session isEqual:_itemCheckSession]) {
                [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:error];
                return;
            }
        } else if ([@"BT005HasSame" isEqualToString:resultCode]) {
            [_delegate BTFuncServerClient:self didCheckItemsWithResult:CheckResultTypeHasSame];
            return;
        } else {
            NSLog(@"parsed resultCode: %@", resultCode);
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Unknown result code" forKey:@"errorType"];
            NSError *parseError = [NSError errorWithDomain:@"Data" code:-1002 userInfo:errorInfo];
            if ([session isEqual:_beaconKeySession]) {
                if (_workingTaskType == BTBeaconManagementTaskTypeRegistGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didFailToAddBeaconkeyWithError:parseError];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeDeactivateGameUseBeacon) {
                    [_delegate BTFuncServerClient:self didFailToDeactivateBeaconkeyWithError:parseError];
                } else if (_workingTaskType == BTBeaconManagementTaskTypeSearchOwner) {
                    [_delegate BTFuncServerClient:self didFailToCheckOwnerWithError:parseError forKeycode:_workingKeyCode];
                }
                return;
            } else if ([session isEqual:_itemCheckSession]) {
                [_delegate BTFuncServerClient:self didFailToCheckItemsWithError:parseError];
                return;
            }
        } // end of item data handling
    } // end of item check case
}

@end
