//
//  AppDelegate.m
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "AppDelegate.h"

#import "TbBTManager.h"

#import "FirstViewController.h"
#import "SecondViewController.h"

@interface AppDelegate ()

@end

NSString *kAnnounceLogFile = @"AnnounceLogFile.txt";
NSString *kUsingBeaconFlag = @"usingBeacon";
NSString *kMonitoringAllowed = @"locationMonitoringAgreed";
NSString *kNumberOfMonitoredRegions = @"numberOfMonitoredRegions";

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* Clear log file */
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error = nil;
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&error];
    }

    /* 起動時にビーコン機能が有効にされていれば位置情報マネージャを用意します（本アプリでは１つのインスタンスを参照させます）*/
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL usingBeaconFunc = [[defaults valueForKey:kUsingBeaconFlag] boolValue];
    BOOL monitoringAndSDKServiceAgreed = [[defaults valueForKey:kMonitoringAllowed] boolValue];
    
    if (monitoringAndSDKServiceAgreed && usingBeaconFunc) {
        // 他のクラスにはこのインタンスを参照させます
        _appLocManager = [[CLLocationManager alloc] init];
        UITabBarController *tabBarVC = (UITabBarController *)self.window.rootViewController;
        assert(tabBarVC);
        SecondViewController *secondVC = [tabBarVC.childViewControllers objectAtIndex:1];
        assert(secondVC);
        // CLLocationManagerのdelegateはSecondViewControllerにしています
        _appLocManager.delegate = secondVC;
    }
    
    _sampleItemArray = [NSArray arrayWithObjects:@"sw_item1", @"sw_item2", @"sw_item3", nil];
    
    //  ローカル通知から起動された場合の処理
    UILocalNotification *tappedNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (tappedNotification != nil) {
        NSDictionary *theUserInfo = [tappedNotification userInfo];
        if ([theUserInfo objectForKey:@"selection"] != nil) {
            NSString *infoMessage = @"非稼働時にプッシュ通知がタップされました";
            [self saveAnnounceLogToFile:infoMessage];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"localNotificationTapped" object:self userInfo:theUserInfo];
        }
    }
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


# pragma mark LocalNotification Handling（When user tap)

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"-- didReceiveLocalNotification --");
    NSString *infoMessage = nil;
    NSDictionary *theUserInfo = [notification userInfo];
    NSString *selected = [theUserInfo objectForKey:@"selection"];
    if (!selected) {
        return;
    }

    if (UIApplicationStateActive == application.applicationState) {
        NSLog(@"アプリ使用中の場合は、なんらかのGUI処理を挟みます");
        infoMessage = @"アプリ使用中に通知タップされました";
    } else if (UIApplicationStateInactive == application.applicationState
               ||UIApplicationStateBackground == application.applicationState) {
        infoMessage = @"アプリ未使用中またはバックグラウンド処理中に通知タップされました";
    }
    if (infoMessage) {
        [self saveAnnounceLogToFile:infoMessage];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"localNotificationTapped" object:self userInfo:theUserInfo];
}

#pragma mark Sample beacon triggered function

- (id)selectItemWithEntryTiming {
    id theItem = nil;
    
    NSDate *currentTime = [NSDate date];
    NSCalendar *userCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [userCalendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:currentTime];
    NSUInteger judgementNumber = ([components hour] + [components minute]) % 84;
    if (judgementNumber < 30) {
        theItem = [_sampleItemArray objectAtIndex:0];
    } else if (judgementNumber < 60) {
        theItem = [_sampleItemArray objectAtIndex:1];
    } else  {
        theItem = [_sampleItemArray objectAtIndex:2];
    }
    return theItem;
}


#pragma mark Event log

- (void)saveAnnounceLogToFile:(NSString *)announceLog {
    if (announceLog == nil) {
        return;
    }
    NSMutableString *message = [NSMutableString stringWithString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle]];
    [message appendString:@" -- "];
    [message appendString:announceLog];
    [message appendString:@"\n\n"];
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
    }
    NSError *error = nil;

    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    if (error != NULL) {
        NSLog(@"save message error: %@", [error userInfo]);
    }
}

@end
