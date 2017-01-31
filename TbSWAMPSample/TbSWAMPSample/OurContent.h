//
//  OurContent.h
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OurContent : NSObject

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *contentDescription;
@property (strong, nonatomic) UIImage *icon;

@end
