//
//  AppDelegate.swift
//  TbSWAMPSwiftSample
//
//  Created by Ueda on 2019/05/11.
//  Copyright © 2019 3bitter.com. All rights reserved.
//

import UIKit

let kLocationServicePermissionNotDetermied = "NotDetermined"
let kLocationServicePermissionRestricted = "Restricted"
let kLocationServicePermissionDened = "Denied"
let kLocationServicePermissionWhenInUse = "WhenInUse"

@UIApplicationMain
// CoreLocationのデリゲートになります(※ 他の箇所でも可）
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var skipSearchBeacon = false
    var locManager: CLLocationManager?
    var stopCheckTimer: Timer?
    var inCheckProcess = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        TbBTPreliminary.setUpWithCompletionHandler({success in
            if (!success) {
                self.skipSearchBeacon = true
            } else {
                print("SWAMP Setup completed successfully.")
            }
        })
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    /*
     *  位置情報サービス使用時のデリゲートメソッド
     */
    // 位置情報サービス許可の状態変化コールバック（実装必須）
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location service authorization changed")
        switch status {
        case .notDetermined:// 許可リクエスト
            print("Not determined")
            // 状態をブロードキャストします（本サンプルではUIControllerで受信）
            let notDetermineNotification = Notification.Name(kLocationServicePermissionNotDetermied)
            NotificationCenter.default.post(name: notDetermineNotification, object: self)
        case .restricted: // ビーコン検出不可
            print("Restricted")
            let restrictedNotification = Notification.Name(kLocationServicePermissionRestricted)
            NotificationCenter.default.post(name: restrictedNotification, object: self)
        case .denied: // ビーコン検出不可
            print("Denied")
            let deniedNotification = Notification.Name(kLocationServicePermissionDened)
            NotificationCenter.default.post(name: deniedNotification, object: self)
        case .authorizedWhenInUse: // ビーコン検出可能
            print("Authorized When In Use")
            let whenInUseNotification = NSNotification.Name(kLocationServicePermissionWhenInUse)
            NotificationCenter.default.post(name: whenInUseNotification, object: self)
        default:
            print("Other permission status.")
        }
    }
    
    // 位置情報サービス自体の使用失敗時のコールバック（実装必須）
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("%@", error)
    }
    
    /* ビーコン計測系処理のコールバック */
    // ビーコン計測結果のコールバック（実装必須）
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if (beacons.count == 0) {
            print("ビーコンは見つけられていません")
            return
        }
        
    }
    // ビーコン計測失敗時のコールバック（実装必須）
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        //
        print("ビーコン計測に失敗しました")
        
        skipSearchBeacon = true
    }
    
    
    
    
    
    /* （ビーコン）領域モニタリング系処理のコールバック */
    /*
    // 領域モニタリング開始時のコールバック（モニタリング機能使用時に必須）
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        //
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        //
    }
    //
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        //
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        //
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        <#code#>
    }
    */
    
}

