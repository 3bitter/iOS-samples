//
//  TbSandboxCredential.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/11.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "TbSandboxCredential.h"

@interface TbSandboxCredential()

@property (copy, nonatomic) NSString *appToken;

@end

@implementation TbSandboxCredential

+ (instancetype)myCredential {
    static dispatch_once_t predicate;
    static id instance = nil;
    dispatch_once(&predicate, ^{
        instance = [[TbSandboxCredential alloc] init];
        if (instance) {
            [instance loadToken];
        }
    });
    return instance;
}

- (NSString *)myToken {
    return _appToken;
}

- (void)loadToken {
    NSError *error = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"TbSandboxCredential.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"TbSandboxCredential" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *dictionary = (NSDictionary *)[NSPropertyListSerialization propertyListWithData:plistXML options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (!dictionary) {
        NSLog(@"Error reading plist: %@, format: %u", [error userInfo], (unsigned)format);
    }
    
    _appToken = [dictionary objectForKey:@"SandboxClientAppToken"];
}


@end
