//
//  AppDelegate.h
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/06/23.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreLocation/CoreLocation.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *appLocManager;

@property (assign, nonatomic) BOOL addProcessing;
@property (strong, nonatomic) NSDate *addProcessTimeoutTime;

@property (copy, nonatomic) NSArray *sampleItemArray;

- (id)selectItemWithEntryTiming;

@end

