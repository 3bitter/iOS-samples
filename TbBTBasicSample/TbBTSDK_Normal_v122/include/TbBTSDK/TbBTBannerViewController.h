//
//  TbBTBannerViewController.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TbBTBannerViewController : UIViewController<NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>;

// UI parts
@property (strong, nonatomic) UIImageView *bannerFrameView;
@property (strong, nonatomic) UIImageView *bannerView;
@property (strong, nonatomic) UIView *sorryView;
@property (strong, nonatomic) UILabel *sorryLabel;
@property (strong, nonatomic) UIButton *closeButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

- (id)initWithURLString:(NSString *)urlString;
- (BOOL)isPreparing;

@end
