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

    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"[SWAMPSample Info] アプリが起動されました。";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];

    _skipSWAMPExec = NO;
    [TbBTPreliminary setUpWithCompletionHandler:^(BOOL success) {
        if (!success) { // Failed to set up
            _skipSWAMPExec = YES;
        } else {
            // Do something if needed
            NSLog(@"SWAMP Setup completed successfully.");
        }
    }];
    // 処理結果が不要なら、これも可能
    // [TbBTPreliminary setUpWithCompletionHandler:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    _autoDetection = YES; // UI操作に入ったら手動測定処理モードに切り替え
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
    _skipSWAMPExec = YES;
}

/* ユーザーによるパーミッションの状態検知してViewControllerに通知 */
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"Location service authorization changed");
    if (status == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Service enabled but auth not determinted. Confirm again for app");
        [[NSNotificationCenter defaultCenter] postNotificationName:kBaseLocServiceEnabled object:self];
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"Callback Allways permitted");
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServicePermitted object:self];
    } else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
         NSLog(@"Callback alwarys denied/restricted");
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServiceDenied object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoroing start for region: %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered to region: %@", region.identifier);
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
            content.title = @"Entered beacon region";
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
                });
            }
        }];
        dispatch_queue_t queue;
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            // レンジング開始を指示します
            [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        });
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
     NSLog(@"Exited to region: %@", region.identifier);
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
            content.title = @"Exited from beacon region";
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
        [manager stopRangingBeaconsInRegion:region];
        return;
    }
    NSArray *beaconKeyDatas = [btManager beaconsTrack:beacons ofRegion:region];
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
                    
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"Found one" content:content trigger:nil];
                    
                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"Notification Error %@", [error userInfo]);
                        }
                    }];

                }
                [manager stopRangingBeaconsInRegion:region];
                _autoDetection = NO;
            } // else keep ranging
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconRangingFailed object:self];
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
