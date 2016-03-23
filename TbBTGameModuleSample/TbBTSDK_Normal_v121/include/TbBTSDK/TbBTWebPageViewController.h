//
//  TbBTWebPageViewController.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TbBTWebPageViewController : UIViewController<UIWebViewDelegate>

// UI parts
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIButton *closeButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) UILabel *sorryLabel;

- (id)initWithURLString:(NSString *)urlString;
                     
@end
