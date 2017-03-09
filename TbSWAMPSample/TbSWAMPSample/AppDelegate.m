//
//  AppDelegate.m
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "TbBTPreliminary.h"
#import "TbBTManager.h"
#import "TbBTServiceBeaconData.h"

#import "ContentManager.h"

#import <UserNotifications/UserNotifications.h>

NSString *kBaseLocServiceEnabled = @"BaseLocServciceEnabled";
NSString *kAlwaysLocServicePermitted = @"AlwaysLocServicePermitted";
//NSString *kInUseLocServicePermitted = @"WhenInUseLocServicePermitted";
NSString *kAlwaysLocServiceDenied = @"AlwaysLocServiceDenied";
NSString *kRangingStarted = @"RangingStarted";
NSString *kBeaconRangingFailed = @"BeaconRangingFailed";
NSString *kBeaconDidNotDetectedInRegion = @"BeaconNotDetected";
NSString *kBeaconMappedContentsPrepared = @"BeaconMappedContentPrepared";

@interface AppDelegate ()<CLLocationManagerDelegate>

@property (assign, nonatomic) BOOL autoDetection;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgRangingTask;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSString *notificationBodyString = @"[Info] App launched";
    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
        UILocalNotification *launchNotification = [[UILocalNotification alloc] init];
        launchNotification.alertBody = [NSString stringWithString:notificationBodyString];
        launchNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:launchNotification];
    }  else {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Launch message";
        content.body = notificationBodyString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Launch message" content:content trigger:nil];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }
        }];
        
    }
    _skipSWAMPExec = NO;
    
    [TbBTPreliminary setUpWithCompletionHandler:^(BOOL success) {
        if (!success) { // Failed to set up
            _skipSWAMPExec = YES;
            NSString *notificationBodyString = @"[Error] TbBTPreliminary setUpWithCompletionHandler Failed.";
            if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
                UILocalNotification *setupNotification = [[UILocalNotification alloc] init];
                setupNotification.alertBody = notificationBodyString;
                setupNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:setupNotification];
            }  else {
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = @"Debug notificaiton";
                content.body = notificationBodyString;
                content.sound = [UNNotificationSound defaultSound];
                
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"SDK Setup failed" content:content trigger:nil];
                
                [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"Notification Error %@", [error userInfo]);
                    }
                }];
            }
        } else {
            // Do something if needed
            NSLog(@"SWAMP Setup completed successfully.");
            NSString *notificationBodyString = @"[Info] TbBTPreliminary setUpWithCompletionHandler Sucess.";
            if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
                UILocalNotification *setupNotification = [[UILocalNotification alloc] init];
                setupNotification.alertBody = notificationBodyString;
                setupNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:setupNotification];
            }  else {
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = @"Debug notificaiton";
                content.body = notificationBodyString;
                content.sound = [UNNotificationSound defaultSound];
                
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"SDK Setup Success" content:content trigger:nil];
                
                [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"Notification Error %@", [error userInfo]);
                    }
                }];
            }
        }
    }];
    // 処理結果が不要なら、これも可能
    // [TbBTPreliminary setUpWithCompletionHandler:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"%s", __func__);
    _autoDetection = YES; // アプリが非アクティブになったら自動処理モードに切り替え
    NSDictionary *staticRegionDict = [[TbBTDefaults sharedDefaults].usingServiceRegionInfos objectAtIndex:0];
    NSString *uuidString = [staticRegionDict objectForKey:@"UUID"];
    NSString *regionID = [staticRegionDict objectForKey:@"regionID"];
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuidString] identifier:regionID];
    assert(_locManager.delegate == self);
    [_locManager requestStateForRegion:region];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
     _autoDetection = NO; // UI操作に入ったら手動測定処理モードに切り替え
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark CLLocationManagerDelegate method

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {
    NSLog(@"Location Manager failure .. %@", error);
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Location Event Failure";
    content.body = [NSString stringWithFormat:@"Location Manager failure .. %@", error];
    content.sound = [UNNotificationSound defaultSound];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"AuthNotification" content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    _skipSWAMPExec = YES;
}

/* ユーザーによるパーミッションの状態検知してViewControllerに通知 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"Location service authorization changed");
     if (UIApplicationStateActive != [UIApplication sharedApplication].applicationState) {
         UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
         content.title = @"Auth State";
         content.body = @"didChangeAuthorizationStatus";
         content.sound = [UNNotificationSound defaultSound];
         
         UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"AuthNotification" content:content trigger:nil];
         [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
     }
    if (status == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Service enabled but auth not determinted. Confirm again for app");
        if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kBaseLocServiceEnabled object:self];
        }
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"Callback Always permitted");
        if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServicePermitted object:self];
        }
    } else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
         NSLog(@"Callback alwarys denied/restricted");
         if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
             [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServiceDenied object:self];
         }
    }
    NSString *notificationBodyString = @"[Info] didChangeAuthroizationStatus";
    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
        UILocalNotification *authNotification = [[UILocalNotification alloc] init];
        authNotification.alertBody = notificationBodyString;
        authNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:authNotification];
    }  else {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Debug notificaiton";
        content.body = notificationBodyString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Auth Status" content:content trigger:nil];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }
        }];
    }

}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"%s", __func__);
    NSMutableString *bodyString = [NSMutableString stringWithFormat:@"%@ : ", region.identifier];
    switch (state) {
        case CLRegionStateInside:
            [bodyString appendString:@"Inside"];
            break;
        case CLRegionStateOutside:
            [bodyString appendString:@"Outside"];
            break;
        case CLRegionStateUnknown:
            [bodyString appendString:@"Unknown"];
            break;
        default:
            break;
    }
    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
        UILocalNotification *stateNotification = [[UILocalNotification alloc] init];
        stateNotification.alertBody = [NSString stringWithString:bodyString];
        stateNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:stateNotification];
    } else {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"region state";
        content.body = bodyString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:2 repeats:NO];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Region state" content:content trigger:trigger];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }  else {
                NSLog(@"Notification Success");
            }
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoroing start for region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered to region: %@", region.identifier);
    NSString *bodyString = @"Entered region";
    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
        UILocalNotification *enterNotification = [[UILocalNotification alloc] init];
        enterNotification.alertBody = [NSString stringWithString:bodyString];
        enterNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:enterNotification];
    } else {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Entered beacon region";
        content.body = bodyString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Entered to some region" content:content trigger:nil];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }
        }];
    }

    TbBTManager *btManager = [TbBTManager sharedManager];
    if (!btManager) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = @"[Warning] TbBTManagerが使える状態になっていません(アイテム検索の後で有効になります）";
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        return;
    }
    if ([btManager isInitialRegion:(CLBeaconRegion *)region]) {
        _autoDetection = YES; // マニュアル操作でないビーコン計測を開始
        NSMutableString *bodyString = [NSMutableString stringWithString:@"ビーコン領域["];
        [bodyString appendString:region.identifier];
        [bodyString appendString:@"] に入りました"];
        if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
            UILocalNotification *enterNotification = [[UILocalNotification alloc] init];
            enterNotification.alertBody = [NSString stringWithString:bodyString];
            enterNotification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:enterNotification];
        } else {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"Entered 3bitter beacon region";
            content.body = bodyString;
            content.sound = [UNNotificationSound defaultSound];
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Just entered" content:content trigger:nil];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Notification Error %@", [error userInfo]);
                }
            }];
        }
        // バックグラウンドで計測してキーコードの取得を試行
        _bgRangingTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (_bgRangingTask != UIBackgroundTaskInvalid) {
                // レンジングストップを指示してタスクを終了
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [[UIApplication sharedApplication] endBackgroundTask:_bgRangingTask];
                    _bgRangingTask = UIBackgroundTaskInvalid;
                    [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                    NSMutableString *notificationBodyString = [NSMutableString stringWithString:@"Stop ranging of background thread (by expiration handler)"];
                    [notificationBodyString appendFormat:@"%@", [NSDate date]];
                    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
                        UILocalNotification *taskNotification = [[UILocalNotification alloc] init];
                        taskNotification.alertBody = [NSString stringWithString:notificationBodyString];
                        taskNotification.soundName = UILocalNotificationDefaultSoundName;
                        [[UIApplication sharedApplication] presentLocalNotificationNow:taskNotification];
                    } else {
                        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                        content.title = @"Stop ranging";
                        content.body = notificationBodyString;
                        content.sound = [UNNotificationSound defaultSound];
                        
                        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Ranging Task Stop" content:content trigger:nil];
                        
                        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"Notification Error %@", [error userInfo]);
                            }
                        }];
                    }

                });
            }
        }];
        dispatch_queue_t queue;
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            // レンジング開始を指示します
            [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        });
        NSString *notificationBodyString = @"Start ranging in background thread";
        if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
            UILocalNotification *taskNotification = [[UILocalNotification alloc] init];
            taskNotification.alertBody = [NSString stringWithString:notificationBodyString];
            taskNotification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:taskNotification];
        } else {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"Begin ranging";
            content.body = notificationBodyString;
            content.sound = [UNNotificationSound defaultSound];
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Ranging Task Start" content:content trigger:nil];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Notification Error %@", [error userInfo]);
                }
            }];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
     NSLog(@"Exited from region: %@", region.identifier);
    NSString *bodyString = @"Exited from some region";
    if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
        UILocalNotification *exitNotification = [[UILocalNotification alloc] init];
        exitNotification.alertBody = [NSString stringWithString:bodyString];
        exitNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:exitNotification];
    } else {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Exited from beacon region";
        content.body = bodyString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Just exited" content:content trigger:nil];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }
        }];
    }

    TbBTManager *btManager = [TbBTManager sharedManager];
    if (!btManager) {
        return;
    }
    // サンプル実装：全ての3Bビーコンの電波領域から出たことを通知
    if ([btManager isInitialRegion:(CLBeaconRegion *)region]) {
        NSMutableString *bodyString = [NSMutableString stringWithString:@"ビーコン領域["];
        [bodyString appendString:region.identifier];
        [bodyString appendString:@"] から出ました"];
        if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
            UILocalNotification *exitNotification = [[UILocalNotification alloc] init];
            exitNotification.alertBody = [NSString stringWithString:bodyString];
            exitNotification.soundName = UILocalNotificationDefaultSoundName;
            [[UIApplication sharedApplication] presentLocalNotificationNow:exitNotification];
        }  else {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"Exited from 3bitter beacon region";
            content.body = bodyString;
            content.sound = [UNNotificationSound defaultSound];
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Exited Some times ago" content:content trigger:nil];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Notification Error %@", [error userInfo]);
                }
            }];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons inRegion:(nonnull CLBeaconRegion *)region {
    TbBTManager *btManager = [TbBTManager sharedManager];
    if (!btManager) {
        NSString *infoString = @"TbBTManager is nil";
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Failed in didRange";
        content.body = infoString;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"StopRange" content:content trigger:trigger];
        
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification Error %@", [error userInfo]);
            }
        }];
        if (_bgRangingTask != UIBackgroundTaskInvalid) {
            // レンジングストップを指示してタスクを終了
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[UIApplication sharedApplication] endBackgroundTask:_bgRangingTask];
                _bgRangingTask = UIBackgroundTaskInvalid;
                [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
            });
        } else {
            [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        }
        return;
    }
    NSArray *beaconKeyDatas = nil;

    if (_skipSWAMPExec) { // Do not track
        beaconKeyDatas = [btManager keyCodesForBeacons:beacons ofRegion:region];
    } else {
        // TODO:just for test
        beaconKeyDatas = [btManager keyCodesForBeacons:beacons ofRegion:region];
        //beaconKeyDatas = [btManager beaconsTrack:beacons ofRegion:region];
    }
    if (_autoDetection) { // Non-UI operation
        if (beaconKeyDatas) { // データが取得できれば、3Bビーコン領域内
            if (beaconKeyDatas.count > 0) {
                // サンプル実装：見つかった一番近めのビーコンのキーコードを取得して通知
                TbBTServiceBeaconData *firstBeacon = (TbBTServiceBeaconData *)[beaconKeyDatas objectAtIndex:0];
                NSMutableString *bodyString = [NSMutableString stringWithString:@"ビーコン領域["];
                [bodyString appendString:region.identifier];
                [bodyString appendString:@"] by ("];
                [bodyString appendString:firstBeacon.keycode];
                [bodyString appendString:@") に入りました"];
                if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
                    UILocalNotification *enterNotification = [[UILocalNotification alloc] init];
                    enterNotification.alertBody = [NSString stringWithString:bodyString];
                    enterNotification.soundName = UILocalNotificationDefaultSoundName;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:enterNotification];
                } else {
                    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                    content.title = @"Found beacon in region";
                    content.body = bodyString;
                    content.sound = [UNNotificationSound defaultSound];
                    
                    UNNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Found one" content:content trigger:trigger];
                    
                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"Notification Error %@", [error userInfo]);
                        }
                    }];

                }
                NSString *notificationBodyString = nil;
                if (_bgRangingTask != UIBackgroundTaskInvalid) {
                    notificationBodyString = @"Stop ranging (of background)";
                    // レンジングストップを指示してタスクを終了
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [[UIApplication sharedApplication] endBackgroundTask:_bgRangingTask];
                        _bgRangingTask = UIBackgroundTaskInvalid;
                        [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                    });
                } else {
                    [manager stopRangingBeaconsInRegion:region];
                    notificationBodyString = @"Stop ranging (of non-background)";
                }

                if (NSFoundationVersionNumber10_0 > NSFoundationVersionNumber) {
                    UILocalNotification *taskNotification = [[UILocalNotification alloc] init];
                    taskNotification.alertBody = [NSString stringWithString:notificationBodyString];
                    taskNotification.soundName = UILocalNotificationDefaultSoundName;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:taskNotification];
                } else {
                    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                    content.title = @"Stop ranging";
                    content.body = notificationBodyString;
                    content.sound = [UNNotificationSound defaultSound];
                    
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Ranging Task Stop" content:content trigger:nil];
                    
                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"Notification Error %@", [error userInfo]);
                        }
                    }];
                }
                _autoDetection = NO;
            } else {// else keep ranging
                NSString *infoString = @"did range (not found 3b beacon)";
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = @"DidRange";
                content.body = infoString;
                content.sound = [UNNotificationSound defaultSound];
                
                UNNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"DidRange" content:content trigger:trigger];
                
                [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"Notification Error %@", [error userInfo]);
                    }
                }];
            }
        }
    } else { // Called from UI thread
        if (!_cancelTimerStopped) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kRangingStarted object:self];
        }
        if (beaconKeyDatas) {  // データが取得できれば、3Bビーコン領域内
            if (beaconKeyDatas.count > 0) {
                NSMutableArray *beaconKeys = [NSMutableArray array];
                for(TbBTServiceBeaconData *beaconData in beaconKeyDatas) {
                    [beaconKeys addObject:beaconData.keycode];
                }
                // stop ranging for 3b beacon
                [manager stopRangingBeaconsInRegion:region];
                // get beacon region mapped contents
                [self execMappedContentFetch:beaconKeys];
            } else {
                // stop ranging for 3b beacon
                [manager stopRangingBeaconsInRegion:region];
                // could not detected 3b beacon
                [self execThisActionBeacauseBeaconsNotDetectedInRegion];
                NSLog(@"Ranging finished.");
            }
        } // else do not stop (called again)
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Faield to range");
    [manager stopRangingBeaconsInRegion:region];
    if (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconRangingFailed object:self];
    }
}

# pragma mark Content handling sample method

- (void)execMappedContentFetch:(NSArray *)beaconKeys {
    NSLog(@"-- %s --", __func__);
    // Get content from content store
    ContentManager *contentManager = [ContentManager sharedManager];
    NSUInteger numOfFoundContents = [contentManager prepareContentsForTbBeacons:beaconKeys];
    NSLog(@"No. of beacon mapped contents in this timing : %lu", (unsigned long)numOfFoundContents);
    // Post notification to the controller
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconMappedContentsPrepared object:self];
}

# pragma mark Beacon region event alternative method

- (void)execThisActionBeacauseBeaconsNotDetectedInRegion {
    NSLog(@"-- %s --", __func__);
    // Post notification to the controller
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconDidNotDetectedInRegion object:self];
}

@end
