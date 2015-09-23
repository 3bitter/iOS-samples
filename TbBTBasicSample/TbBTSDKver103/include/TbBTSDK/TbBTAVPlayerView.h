//
//  TbBTAVPlayerView.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/18.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TbBTAVPlayerView : UIView

- (AVPlayer *)player;
- (void)setPlayer:(AVPlayer *)player;

@end
