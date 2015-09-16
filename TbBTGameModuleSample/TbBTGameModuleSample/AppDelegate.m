//
//  AppDelegate.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "AppDelegate.h"
#import "ItemManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

NSString *kContactNotificationTapped = @"NotificationTapped";
extern NSString *kSettings;
extern NSString *kBTFuncUsing;
extern NSString *kSharedItem;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    application.statusBarHidden = NO;
    application.statusBarStyle = UIStatusBarStyleLightContent;
    
    // プッシュ通知の許可がされていなければ確認
    if (NSFoundationVersionNumber_iOS_7_1 < NSFoundationVersionNumber) { // Just in case
        if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
            [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound|UIUserNotificationTypeAlert|UIUserNotificationTypeBadge categories:nil]];
        }
    }
    
    // Load settings
    [self loadSettings];
    
    /* ビーコン使用機能が有効になっていたら窓口クラスを用意しています */
    BOOL usingBTFunction = [[_currentSettings valueForKey:kBTFuncUsing] boolValue];
    if (usingBTFunction) {
        _btFacade = [BTServiceFacade sharedFacade];
        ItemManager *itemManager = [ItemManager sharedManager];
        // delegateクラスはアイテム管理クラス
        _btFacade.delegate = itemManager;
    }
    
    // アプリ非稼動時のアイテム通知タップ
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if (notification.userInfo) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kContactNotificationTapped object:self userInfo:notification.userInfo];
        }
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*  フォアグラウンド専用のビーコン処理が動いていたら処理を止めておきます */
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    if (btFacade) {
        // マイビーコン登録処理の停止
        if (btFacade.addProcessing) {
            [btFacade stopSearchForRegister];
        }
        // ご近所オーナー検索処理の停止
        if (btFacade.neighbersSearching) {
            [btFacade stopSearchNeighbers];
        }
        btFacade.addProcessing = NO;
        btFacade.neighbersSearching = NO;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Save current items
    [[ItemManager sharedManager] saveItems];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UITabBarController *rootVC = (UITabBarController *)self.window.rootViewController;
    rootVC.selectedIndex = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:kContactNotificationTapped object:self userInfo:notification.userInfo];
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults dictionaryForKey:kSettings]) {
        _currentSettings = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:kSettings]];
    } else {
        _currentSettings = [NSMutableDictionary dictionary];
        [_currentSettings setValue:[NSNumber numberWithBool:NO] forKey:kBTFuncUsing];
    }
}

@end
