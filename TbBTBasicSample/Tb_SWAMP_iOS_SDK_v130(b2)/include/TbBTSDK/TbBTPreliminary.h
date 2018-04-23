//
//  TbBTPreliminary.h
//  TbBTSDK
//
//  Created by Ueda on 2016/02/23.
//  Copyright © 2016年 3bitter.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TbBTPreliminary : NSObject

+ (void)setUpWithCompletionHandler:(void (^)(BOOL success))completionHandler;
+ (BOOL)clearSetupData;

@end
