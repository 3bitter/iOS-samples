//
//  TbSandboxCredential.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/11.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TbSandboxCredential : NSObject

+ (instancetype)myCredential;
- (NSString *)appToken;

@end
