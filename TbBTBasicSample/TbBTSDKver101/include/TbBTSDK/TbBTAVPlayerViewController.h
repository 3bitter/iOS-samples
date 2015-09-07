//
//  TbBTAVPlayerViewController.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TbBTAVPlayerViewController : UIViewController<AVAssetResourceLoaderDelegate>

// UI parts
@property (strong, nonatomic) UIView *playBaseView;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) UIButton *closeButton;
@property (strong, nonatomic) UIButton *playButton;
@property (strong, nonatomic) UIButton *pauseButton;
@property (strong, nonatomic) UILabel *sorryLabel;

- (id)initWithURLString:(NSString *)urlString;
- (BOOL)isPreparing;

@end
