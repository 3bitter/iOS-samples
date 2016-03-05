//
//  AppDelegate.h
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TbBTManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, TbBTManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *locManager;

@property (assign, nonatomic) BOOL skipBLT; // Optional


@end

