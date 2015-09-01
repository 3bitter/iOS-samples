//
//  AppDelegate.m
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "AppDelegate.h"

#import "TbBTDefaults.h"
#import "TbBTBuiltInUIActionDispatcher.h"
#import "TbBTManager.h"

#import "FirstViewController.h"

@interface AppDelegate ()

@end

NSString *kAnnounceLogFile = @"AnnounceLogFile.txt";

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* Clear log file */
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error = nil;
    NSString *logFilePath = [rootPath stringByAppendingPathComponent:kAnnounceLogFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&error];
    }

    /* For notification tap when app was not running */
    UILocalNotification *tappedNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (tappedNotification != nil) {
        NSDictionary *theUserInfo = [tappedNotification userInfo];
        if ([theUserInfo objectForKey:@"presenter"] != nil && [[theUserInfo objectForKey:@"presenter"] isEqualToString:[TbBTDefaults sharedDefaults].SDKIdentifier]) {
            NSString *infoMessage = @"非稼働時に3bitterからの通知がタップされました";
            [self saveAnnounceLogToFile:infoMessage];
            
                UIViewController *firstViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FirstViewController"];
            TbBTBuiltInUIActionDispatcher *dispatcher = [TbBTBuiltInUIActionDispatcher sharedDispatcher];
            [dispatcher dispatchActionWithNotification:tappedNotification presentFromViewController:firstViewController];
            // Request for tap
            NSString *presentationID = [theUserInfo objectForKey:@"presentationID"];
            TbBTManager *btManager = [TbBTManager sharedManager];
            [btManager fireRequestForPresenTap:presentationID];
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
    NSDictionary *userInfo = [notification userInfo];
    NSString *presenterID = [userInfo objectForKey:@"presenter"];
    /* notification userInfo内に、presenter:TbBTSDK.SDKIdentifierのキーバリューがある場合にキャンペーンの表示処理をします */
    if (presenterID == nil || [[TbBTDefaults sharedDefaults].SDKIdentifier isEqualToString:presenterID] == NO) {
        // Do app's own operation
        NSLog(@"アプリケーション独自の通知の処理をします");
        return;
    }
    if (UIApplicationStateActive == application.applicationState) {
        NSLog(@"アプリ使用中の場合は、なんらかのGUI処理を挟みます");
        NSString *infoMessage = @"アプリ使用中に通知タップされました";
        [self saveAnnounceLogToFile:infoMessage];
       
        UIViewController *firstViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FirstViewController"];
        ((UITabBarController *)self.window.rootViewController).selectedViewController = firstViewController;
        
        TbBTBuiltInUIActionDispatcher *dispatcher = [TbBTBuiltInUIActionDispatcher sharedDispatcher];
        [dispatcher showForeNotificationView:notification fromViewController:firstViewController];
    } else if (UIApplicationStateInactive == application.applicationState
               ||UIApplicationStateBackground == application.applicationState) {
       NSString *infoMessage = @"アプリ未使用中またはバックグラウンド処理中に通知タップされました";
        [self saveAnnounceLogToFile:infoMessage];
        
        UITabBarController *tabBarContorller = (UITabBarController *)self.window.rootViewController;
        UIViewController *firstViewController = (UIViewController *)[tabBarContorller.childViewControllers firstObject];
        assert(firstViewController.view);
        TbBTBuiltInUIActionDispatcher *dispatcher = [TbBTBuiltInUIActionDispatcher sharedDispatcher];
        [dispatcher dispatchActionWithNotification:notification presentFromViewController:firstViewController];
        // Request for tap
        NSString *presentationID = [userInfo objectForKey:@"presentationID"];
        TbBTManager *btManager = [TbBTManager sharedManager];
        [btManager fireRequestForPresenTap:presentationID];
    }
}

// Just for debug
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
    //[message writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    if (error != NULL) {
        NSLog(@"save message error: %@", [error userInfo]);
    }
}

@end
