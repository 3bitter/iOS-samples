//
//  AppDelegate.m
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "TbBTPreliminary.h"
#import "TbBTManager.h"
#import "TbBTServiceBeaconData.h"

#import "ContentManager.h"

NSString *kAlwaysLocServicePermitted = @"AlwaysLocServicePermitted";
NSString *kAlwaysLocServiceDenied = @"AlwaysLocServiceDenied";
NSString *kBeaconRangingFailed = @"BeaconRangingFailed";
NSString *kBeaconDidNotDetectedInRegion = @"BeaconNotDetected";
NSString *kBeaconMappedContentsPrepared = @"BeaconMappedContentPrepared";

@interface AppDelegate ()<CLLocationManagerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    _skipBLT = NO;
    [TbBTPreliminary setUpWithCompletionHandler:^(BOOL success) {
        if (!success) { // Failed to set up
            _skipBLT = YES;
        }
    }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark CLLocationManagerDelegate method

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(nonnull NSError *)error {
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"Location service authorization changed");
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServicePermitted object:self];
    } else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlwaysLocServiceDenied object:self];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons inRegion:(nonnull CLBeaconRegion *)region {
    _btManager = [TbBTManager sharedManager];
    NSArray *beaconKeyDatas = [_btManager beaconsTrack:beacons ofRegion:region];
    if (beaconKeyDatas) { // may be inside of 3b beacon region
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

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Faield to range");
    [manager stopRangingBeaconsInRegion:region];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeaconRangingFailed object:self];
}

# pragma mark Content Handling method

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
