//
//  AppDelegate.h
//  TbBTGameModuleSample
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTServiceFacade.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSMutableDictionary *currentSettings;

// ビーコン機能窓口クラス
@property (strong, nonatomic) BTServiceFacade *btFacade;

@property (assign, nonatomic) BOOL playing;

- (void)loadSettings;

@end

