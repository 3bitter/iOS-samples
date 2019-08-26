//
//  OurContent.h
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OurContent : NSObject

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *contentDescription;
@property (strong, nonatomic) UIImage *icon;

@end