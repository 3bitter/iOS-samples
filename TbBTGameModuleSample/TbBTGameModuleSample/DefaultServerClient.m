//
//  DefaultServerClient.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "DefaultServerClient.h"
#import "Item.h"

typedef NS_ENUM(NSInteger, MemberItemDataTaskType){
    MemberDataTaskTypePrepareInitial,
    MemberDataTaskTypeAddNew,
    MemberDataTaskTypeChagneMain,
    
};

@interface DefaultServerClient()

@property (strong, nonatomic) NSMutableData *masterItemData;
@property (strong, nonatomic) NSMutableData *respondData;
@property (assign, nonatomic) NSInteger expectedDataBytes;

@property (assign, nonatomic) NSUInteger downloadedCount;
@property (assign, nonatomic) MemberItemDataTaskType taskType;
@property (strong, nonatomic) NSMutableDictionary *workingItemDict;

@end

@implementation DefaultServerClient

static NSString *kMemberRegisterURL = @"https://bitterbeacon.tokyo/BTGameUseServer/MemberAdd";
static NSString *kMasterItemURL = @"https://bitterbeacon.tokyo/BTGameUseServer/MasterItem";
static NSString *kIconStoreURL = @"https://bitterbeacon.tokyo/bt/TbBTGameSampleIcons/";
static NSString *kInitialItemURL = @"https://bitterbeacon.tokyo/BTGameUseServer/InitialItem";
static NSString *kNewMemberItemURL = @"https://bitterbeacon.tokyo/BTGameUseServer/AddMemberItem";
static NSString *kMainItemURL = @"https://bitterbeacon.tokyo/BTGameUseServer/ChangeMainItem";

- (void)requestBecomeAMember:(NSString *)nickName {
    if (!_registerSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        _registerSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_nn="];
    [requestBodyString appendString:nickName];
    CFStringRef queryStringRef = (__bridge CFStringRef)requestBodyString;
    CFStringRef encodedQueryStringRef = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, queryStringRef, NULL,  CFSTR(":/#[]@!$' ()*+,;"), kCFStringEncodingUTF8);
    NSString *encodedQueryString = [kMemberRegisterURL stringByAppendingString:(__bridge NSString *)encodedQueryStringRef];
    NSURL *newMemberURL = [NSURL URLWithString:encodedQueryString];
    CFRelease(encodedQueryStringRef);

    NSURLRequest *memberURLRequest = [NSURLRequest requestWithURL:newMemberURL];
    
    [[_registerSession dataTaskWithRequest:memberURLRequest] resume];
}

- (void)retrieveMasterItemData {
    if (!_masterDataSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
    
        _masterDataSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }

    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    
    NSURL *itemDataURL = [NSURL URLWithString:[kMasterItemURL stringByAppendingString:requestBodyString]];
    NSURLRequest *masterDataRequest = [NSURLRequest requestWithURL:itemDataURL];
    
    // Start to get data
    [[_masterDataSession dataTaskWithRequest:masterDataRequest] resume];
}

- (void)downloadIconFileForName:(NSString *)iconFileName {
    if (!iconFileName) {
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Missing file name" forKey:@"errorType"];
        NSError *error = [NSError errorWithDomain:@"Input" code:2000 userInfo:errorInfo];
        [_delegate serverClient:self didFailToDownloadIconFileWithError:error forName:iconFileName];
        return;
    }
    if (!_iconDownloadSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 20;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        _iconDownloadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    NSString *fileURLString = [kIconStoreURL stringByAppendingString:iconFileName];
    NSURLRequest *iconDownloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:fileURLString]];
    [[_iconDownloadSession downloadTaskWithRequest:iconDownloadRequest] resume];
}

- (void)requestInitialItemsForMember:(NSString *)memberToken {
    if (!memberToken) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No member token found" forKey:@"errorType"];
        NSError *error = [NSError errorWithDomain:@"Data" code:1005 userInfo:userInfo];
        [_delegate serverClient:self didFailToDecideUserItemsWithError:error];
        return;
    }
    if (!_memberItemSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 10;
        sessionConfig.timeoutIntervalForResource = 30;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        _memberItemSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="];
    
    [requestBodyString appendString:memberToken];
    
    NSURL *itemRequestURL = [NSURL URLWithString:[kInitialItemURL stringByAppendingString:requestBodyString]];
    NSLog(@"URL:%@", [kInitialItemURL stringByAppendingString:requestBodyString]);
    NSURLRequest *initialItemRequest = [NSURLRequest requestWithURL:itemRequestURL];
    
    // Start to get data
    NSURLSessionTask *initalItemTask = [_memberItemSession dataTaskWithRequest:initialItemRequest];
    _taskType = MemberDataTaskTypePrepareInitial;
    [initalItemTask resume];
}

- (void)requestAddItemAsUserItem:(NSString *)itemID forMember:(NSString *)memberToken {
    if (!memberToken) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No member token found" forKey:@"errorType"];
        NSError *error = [NSError errorWithDomain:@"Data" code:1005 userInfo:userInfo];
        [_delegate serverClient:self didFailToDecideUserItemsWithError:error];
        return;
    }
    if (!_memberItemSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        _memberItemSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="];
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_item="];
    [requestBodyString appendString:itemID];
    
    NSURL *addRequestURL = [NSURL URLWithString:[kNewMemberItemURL stringByAppendingString:requestBodyString]];
    NSLog(@"URL:%@", [kNewMemberItemURL stringByAppendingString:requestBodyString]);
    NSURLRequest *initialItemRequest = [NSURLRequest requestWithURL:addRequestURL];
    
    // Start to get data
    NSURLSessionTask *itemAdditionTask = [_memberItemSession dataTaskWithRequest:initialItemRequest];
    _taskType = MemberDataTaskTypeAddNew;
    if (!_workingItemDict) {
        _workingItemDict = [NSMutableDictionary dictionaryWithObject:itemID forKey:@"workingItemID"];
    } else {
        [_workingItemDict setObject:itemID forKey:@"workingItemID"];
    }
    [itemAdditionTask resume];
}

- (void)requestChangeMainItem:(NSString *)mainItemID forMember:(NSString *)memberToken {
    if (!memberToken) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No member token found" forKey:@"errorType"];
        NSError *error = [NSError errorWithDomain:@"Data" code:1005 userInfo:userInfo];
        [_delegate serverClient:self didFailToDecideUserItemsWithError:error];
        return;
    }
    if (!_memberItemSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.networkServiceType = NSURLNetworkServiceTypeDefault;
        sessionConfig.timeoutIntervalForRequest = 5;
        sessionConfig.timeoutIntervalForResource = 10;
        sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
        sessionConfig.requestCachePolicy = NO;
        sessionConfig.URLCache = nil;
        sessionConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        sessionConfig.HTTPShouldSetCookies = NO;
        
        _memberItemSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    
    assert(_myAppToken);
    NSMutableString *requestBodyString = [NSMutableString stringWithString:@"?"];
    [requestBodyString appendString:@"_aac="]; // App Access Code. Just for management on our environment
    [requestBodyString appendString:_myAppToken];
    [requestBodyString appendString:@"&_mat="];
    [requestBodyString appendString:memberToken];
    [requestBodyString appendString:@"&_main="];
    [requestBodyString appendString:mainItemID];
    
    NSURL *changeRequestURL = [NSURL URLWithString:[kMainItemURL stringByAppendingString:requestBodyString]];
    NSURLRequest *mainItemRequest = [NSURLRequest requestWithURL:changeRequestURL];
    
    // Start to get data
    NSURLSessionTask *itemAdditionTask = [_memberItemSession dataTaskWithRequest:mainItemRequest];
    _taskType = MemberDataTaskTypeChagneMain;
    if (!_workingItemDict) {
        _workingItemDict = [NSMutableDictionary dictionaryWithObject:mainItemID forKey:@"workingItemID"];
    } else {
        [_workingItemDict setObject:mainItemID forKey:@"workingItemID"];
    }
    [itemAdditionTask resume];
}

#pragma mark NSURLSessionDelegate


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}


#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        
        BOOL isError = YES;
        NSDictionary *userInfo = nil;
        NSError *requestError = nil;
        
        switch (statusCode) {
            case 200:
            {
                NSString *mimeType = httpResponse.MIMEType;
                // Just accept JSON format response data
                if ([@"text/json" isEqualToString:mimeType] == NO && [@"text/plain" isEqualToString:mimeType] == NO) {
                    userInfo = [NSDictionary dictionaryWithObject:@"Unexpected MIME Type" forKey:@"reason"];
                    requestError = [[NSError alloc] initWithDomain:@"HTTP" code:001 userInfo:userInfo];
                } else {
                    isError = NO;
                    _expectedDataBytes = [[NSNumber numberWithLongLong:response.expectedContentLength] integerValue];
                    completionHandler(NSURLSessionResponseAllow);
                }
                break;
            }
            case 400:
                userInfo = [NSDictionary dictionaryWithObject:@"400 Bad Request(Invalid Parameter)" forKey:@"reason"];
                requestError = [[NSError alloc] initWithDomain:@"HTTP" code:400 userInfo:userInfo];
                break;

            case 404:
                userInfo = [NSDictionary dictionaryWithObject:@"404 Not Found" forKey:@"reason"];
                requestError = [[NSError alloc] initWithDomain:@"HTTP" code:404 userInfo:userInfo];
                break;
            case 500:
                userInfo = [NSDictionary dictionaryWithObject:@"500 Server Internal Error" forKey:@"reason"];
                requestError = [[NSError alloc] initWithDomain:@"HTTP" code:500 userInfo:userInfo];
                break;
            default:
                NSLog(@"HTTP Status:%ld",(long)statusCode);
                userInfo = [NSDictionary dictionaryWithObject:@"Unkown Error" forKey:@"reason"];
                requestError = [[NSError alloc] initWithDomain:@"HTTP" code:-1 userInfo:userInfo];
                break;
        }
        if (isError) {
            if ([session isEqual:_registerSession]) {
                [_delegate serverClient:self didFailToBecomeMemberWithError:requestError];
            } else if ([session isEqual:_masterDataSession]) {
                [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:requestError];
            } else if ([session isEqual:_memberItemSession]) {
                switch (_taskType) {
                    case MemberDataTaskTypePrepareInitial:
                        [_delegate serverClient:self didFailToDecideUserItemsWithError:requestError];
                        break;
                    case MemberDataTaskTypeAddNew:
                    {
                         NSString *theItemID = [_workingItemDict objectForKey:@"workingItemID"];
                        [_delegate serverClient:self didFailToAddNewMemberItem:theItemID withError:requestError];
                        break;
                    }
                    case MemberDataTaskTypeChagneMain:
                        [_delegate serverClient:self didFailToChangeMainItemWithError:requestError];
                        break;
                    default:
                        break;
                }
            }
        }
    } // Otherwise do nothing
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if ([session isEqual:_registerSession]) {
        if (!_respondData) {
            _respondData = [[NSMutableData alloc] init];
        }
        if (_respondData.length < _expectedDataBytes) {
            [_respondData appendBytes:data.bytes length:data.length];
        }
    } else if ([session isEqual:_masterDataSession]) {
        if (!_masterItemData) {
            _masterItemData = [[NSMutableData alloc] init];
        }
        if (_masterItemData.length < _expectedDataBytes) {
            [_masterItemData appendBytes:data.bytes length:data.length];
        }
    } else if ([session isEqual:_memberItemSession]) {
        if (!_respondData) {
            _respondData = [[NSMutableData alloc] init];
        }
        if (_respondData.length < _expectedDataBytes) {
            [_respondData appendBytes:data.bytes length:data.length];
        }
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s", __func__);
    if (error) {
        if ([session isEqual:_registerSession]) {
            [_delegate serverClient:self didFailToBecomeMemberWithError:error];
        }else if ([session isEqual:_masterDataSession]) {
            [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:error];
        } else if ([session isEqual:_iconDownloadSession]) {
            [_delegate serverClient:self didFailToDownloadIconFileWithError:error forName:[[task.currentRequest URL] lastPathComponent]];
        } else if ([session isEqual:_memberItemSession]) {
            switch (_taskType) {
                case MemberDataTaskTypePrepareInitial:
                    [_delegate serverClient:self didFailToDecideUserItemsWithError:error];
                    break;
                case MemberDataTaskTypeAddNew:
                {
                    NSString *theItemID = [_workingItemDict objectForKey:@"workingItemID"];
                    [_delegate serverClient:self didFailToAddNewMemberItem:theItemID withError:error];
                    break;
                }
                case MemberDataTaskTypeChagneMain:
                    [_delegate serverClient:self didFailToChangeMainItemWithError:error];
                    break;
                default:
                    break;
            }
        }
        return;
    }
    if ([session isEqual:_registerSession]) {
        [self parseReceivedDataAsJSON:_respondData ofSession:session];
    } else if ([session isEqual:_masterDataSession]) {
        [self parseReceivedDataAsJSON:_masterItemData ofSession:session];
    } else if ([session isEqual:_memberItemSession]) {
        [self parseReceivedDataAsJSON:_respondData ofSession:session];
    }
    // Invalidate session
    if (![session isEqual:_iconDownloadSession]) {
        [session invalidateAndCancel];
    }
}

#pragma mark NSURLSessionDownloadTaskDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *fileName = [[downloadTask.currentRequest URL] lastPathComponent];
    NSError *error = nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *iconStorePath = [rootPath stringByAppendingPathComponent:@"Icons"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconStorePath]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:iconStorePath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create icon directory. error:%@", [error userInfo]);
            _downloadedCount = 0;
            [_delegate serverClient:self didFailToDownloadIconFileWithError:error forName:fileName];
            [_iconDownloadSession invalidateAndCancel];
            return;
        } else {
            NSLog(@"Icon directory created");
        }
    }
    NSURL *iconURL = [NSURL fileURLWithPath:[iconStorePath stringByAppendingPathComponent:fileName] isDirectory:NO];
    if ([[NSFileManager defaultManager] moveItemAtURL:location toURL:iconURL error:&error]) {
        _downloadedCount++;
        if (_downloadedCount == _maxNumberOfIcons) {
            [_iconDownloadSession invalidateAndCancel];
        }
        [_delegate serverClient:self didDownloadIconFileForName:fileName];
    } else {
        _downloadedCount = 0;
        [_delegate serverClient:self didFailToDownloadIconFileWithError:error forName:fileName];
        [_iconDownloadSession invalidateAndCancel];
        return;
    }
}

#pragma mark Response data parse

- (void)parseReceivedDataAsJSON:(NSData *)receivedData ofSession:(NSURLSession *)session {
    NSError *parseError = nil;
    NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&parseError];
    
    if (parseError != NULL) {
        if ([session isEqual:_registerSession]) {
            [self clearReceivedData];
            [_delegate serverClient:self didFailToBecomeMemberWithError:parseError];
        } else if ([session isEqual:_masterDataSession]) {
            [self clearMasterSessionData];
            [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:parseError];
        } else if ([session isEqual:_memberItemSession]) {
            [self clearReceivedData];
            switch (_taskType) {
                case MemberDataTaskTypePrepareInitial:
                    [_delegate serverClient:self didFailToDecideUserItemsWithError:parseError];
                    break;
                case MemberDataTaskTypeAddNew:
                {
                NSString *theItemID = [_workingItemDict objectForKey:@"workingItemID"];
                [_delegate serverClient:self didFailToAddNewMemberItem:theItemID withError:parseError];
                    break;
                }
                case MemberDataTaskTypeChagneMain:
                    [_delegate serverClient:self didFailToChangeMainItemWithError:parseError];
                    break;
                default:
                    break;
            }
            
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
            [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:validateError];
            return;
        }
        if ([@"BT001OK" isEqualToString:resultCode]) {
            if ([session isEqual:_registerSession]) {
                NSString *memberToken = [responseJSON objectForKey:@"memberToken"];
                if (memberToken == nil) {
                    [self clearReceivedData];
                    userInfo = [NSDictionary dictionaryWithObject:@"Missing memberToken" forKey:@"errorType"];
                    validateError = [[NSError alloc] initWithDomain:@"Data" code:-1002 userInfo:userInfo];
                    [_delegate serverClient:self didFailToBecomeMemberWithError:validateError];
                    return;
                } else {
                    [_delegate serverClient:self didRegistAsMember:memberToken];
                    return;
                }
            } else if ([session isEqual:_masterDataSession]) {
                NSArray *itemDictArray = [responseJSON objectForKey:@"masterItems"];
                if (itemDictArray == nil) {
                    [self clearMasterSessionData];
                    userInfo = [NSDictionary dictionaryWithObject:@"Missing items" forKey:@"errorType"];
                    validateError = [[NSError alloc] initWithDomain:@"Data" code:-1002 userInfo:userInfo];
                    [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:validateError];
                    return;
                } else {
                    NSMutableArray *retrievedItemDatas = [NSMutableArray array];
                    for (NSDictionary *itemDict in itemDictArray) {
                        Item *anItem = [[Item alloc] init];
                        [anItem setItemID:[itemDict objectForKey:@"itemID"]];
                        [anItem setItemName:[itemDict objectForKey:@"name"]];
                        [anItem setItemRank:[[itemDict valueForKey:@"rank"] integerValue]];
                        [anItem setExplanation:[itemDict objectForKey:@"explanation"]];
                        [anItem setIconName:[itemDict objectForKey:@"icon"]];
                        
                        [retrievedItemDatas addObject:anItem];
                    }
                    [self clearMasterSessionData];
                    // Notifify to delegate complete
                    [_delegate serverClient:self didRetrieveMasterItems:[NSArray arrayWithArray:retrievedItemDatas]];
                    return;
                }
            } else if ([session isEqual:_memberItemSession]){
                // inital item task
                switch (_taskType) {
                    case MemberDataTaskTypePrepareInitial:
                    {
                        NSArray *itemDictArray = [responseJSON objectForKey:@"memberItems"];
                        NSMutableArray *retrievedItemDatas = [NSMutableArray array];
                        for (NSDictionary *itemDict in itemDictArray) {
                            Item *anItem = [[Item alloc] init];
                            [anItem setItemID:[itemDict objectForKey:@"itemID"]];
                            [anItem setMain:[[itemDict objectForKey:@"main"] boolValue]];
                            [retrievedItemDatas addObject:anItem];
                        }
                        [_delegate serverClient:self didDecideUserInitialItems:retrievedItemDatas];
                        break;
                    }
                    case MemberDataTaskTypeAddNew:
                        [_delegate serverClient:self didAddNewMemberItem:[_workingItemDict objectForKey:@"workingItemID"]];
                        break;
                    case MemberDataTaskTypeChagneMain:
                        [_delegate serverClient:self didChangeMainItem:[_workingItemDict objectForKey:@"workingItemID"]];
                        break;
                    default:
                        break;
                }
            }
        } else if ([@"BT004Failed" isEqualToString:resultCode]) {
            [self clearMasterSessionData];
            userInfo = [NSDictionary dictionaryWithObject:@"Failed on Server Side" forKey:@"errorType"];
            parseError = [NSError errorWithDomain:@"Data" code:-1003 userInfo:userInfo];
            if ([session isEqual:_registerSession]) {
                [_delegate serverClient:self didFailToBecomeMemberWithError:parseError];
            } else if ([session isEqual:_masterDataSession]) {
                [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:parseError];
            } else if ([session isEqual:_memberItemSession]) {
                switch (_taskType) {
                    case MemberDataTaskTypePrepareInitial:
                        [_delegate serverClient:self didFailToDecideUserItemsWithError:parseError];
                        break;
                    case MemberDataTaskTypeAddNew:
                    {
                        NSString *theItemID = [_workingItemDict objectForKey:@"workingItemID"];
                        [_delegate serverClient:self didFailToAddNewMemberItem:theItemID withError:parseError];
                        break;
                    }
                    case MemberDataTaskTypeChagneMain:
                        [_delegate serverClient:self didFailToChangeMainItemWithError:parseError];
                        break;
                    default:
                        break;
                }
            }
        } else if ([@"BT005Invalid" isEqualToString:resultCode]) {
            [self clearMasterSessionData];
           userInfo = [NSDictionary dictionaryWithObject:@"Unknown app" forKey:@"errorType"];
            parseError = [NSError errorWithDomain:@"Input" code:-1004 userInfo:userInfo];
            if ([session isEqual:_registerSession]) {
                [_delegate serverClient:self didFailToBecomeMemberWithError:parseError];
            } else if ([session isEqual:_masterDataSession]) {
                [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:parseError];
            } else if ([session isEqual:_memberItemSession]) {
                switch (_taskType) {
                    case MemberDataTaskTypePrepareInitial:
                        [_delegate serverClient:self didFailToDecideUserItemsWithError:parseError];
                        break;
                    case MemberDataTaskTypeAddNew:
                    {
                        NSString *theItemID = [_workingItemDict objectForKey:@"workingItemID"];
                        [_delegate serverClient:self didFailToAddNewMemberItem:theItemID withError:parseError];
                        break;
                    }
                    case MemberDataTaskTypeChagneMain:
                        [_delegate serverClient:self didFailToChangeMainItemWithError:parseError];
                        break;
                    default:
                        break;
                }
            }
        } else {
            [self clearMasterSessionData];
            NSLog(@"parsed resultCode: %@", resultCode);
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Unknown result code" forKey:@"errorType"];
            NSError *parseError = [NSError errorWithDomain:@"Data" code:-1005 userInfo:errorInfo];
            if ([session isEqual:_registerSession]) {
                [_delegate serverClient:self didFailToBecomeMemberWithError:parseError];
            } else if ([session isEqual:_masterDataSession]) {
                [_delegate serverClient:self didFailToRetrieveMasterItemsWithError:parseError];
            }
        } // end of item data handling
    }
}

#pragma mark Cleaning

- (void)clearMasterSessionData {
    _masterItemData = nil;
    _expectedDataBytes = 0;
}

- (void)clearReceivedData {
    _workingItemDict = nil;
    _respondData = nil;
    _expectedDataBytes = 0;
}

@end
