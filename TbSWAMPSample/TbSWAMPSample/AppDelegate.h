//
//  AppDelegate.h
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TbBTManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CLLocationManager *locManager;

@property (assign, nonatomic) BOOL skipSWAMPExec; // Optional

@property (assign, nonatomic) BOOL cancelTimerStopped;
// For bluetooth off by control center (BluetoothStatePowerOff but beacons can be ranged)
@property (strong, nonatomic) NSTimer *stopCheckRangingTimer;
@property (assign, nonatomic) BOOL inCheckProcess;

@end

