//
//  BTFunctionSettingsViewController.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/10.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "BTFunctionSettingsViewController.h"
#import "BTServiceFacade.h"
#import "AppDelegate.h"
#import "BTUseDescriptionViewController.h"
#import "ItemManager.h"
#import "TbBTAgreementViewController.h"
#import "TbBTBuiltInUIActionDispatcher.h"

@interface BTFunctionSettingsViewController ()<TbBTAgreementViewControllerDelegate>

@property (assign, nonatomic) BOOL btServiceAgreed; // 規約同意フラグ
@property (assign, nonatomic) BOOL btAgreementSkipped; // 規約再表示防止フラグ
@property (strong, nonatomic) BTServiceFacade *btFacade;

- (void)controlAndSaveBTFunctionSettings;

@end

// Authorization（Location Service)
extern NSString *kLocAuthAuthorizedAlways;
extern NSString *kLocAuthRestricted;
extern NSString *kLocAuthDenied;

// Monitoring
extern NSString *kBRMonitoringDidFail;

// Settings
NSString *kSettings = @"Settings";
NSString *kBTConditionAgreed = @"BTAgreed";
NSString *kBTFuncUsing = @"UsingBTFunction";

@implementation BTFunctionSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //　規約への同意確認
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _btServiceAgreed = [[userDefaults valueForKey:kBTConditionAgreed] boolValue];
   
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    
    if (!_btServiceAgreed && !_btAgreementSkipped) { // 規約ビューの表示　（ここでは個別に3bitter側で用意している規約をそのまま表示しているが、アプリ自体の規約内に関連重要事項を包含なら不要）
        TbBTBuiltInUIActionDispatcher *dispatcher = [TbBTBuiltInUIActionDispatcher sharedDispatcher];
        [dispatcher presentTbBTAgreementViewControllerFromVC:self];
        return;
    }
    // ビーコン関連機能のファサードクラスのBTServiceFacadeを保持します
    //　ただしBTFunctionSettingsViewControllerはnotificationベースで通知を受けるため、delegateにはなりません
    // cf. BTServiceFacade.h
    _btFacade = [BTServiceFacade sharedFacade];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _settings = [NSMutableDictionary dictionaryWithDictionary:appDelegate.currentSettings];
    if (_btAgreementSkipped) {
        _btFunctionSwitch.enabled = NO;
    } else {
        _btFunctionSwitch.enabled = YES;
    }
    BOOL usingBTFunc = [[_settings valueForKey:kBTFuncUsing] boolValue];
    if (!usingBTFunc) {
        _btFunctionSwitch.on = NO;
    }  else {
        _btFunctionSwitch.on = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _btAgreementSkipped = NO;
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
} 
*/

- (void)saveNewSettings {
    assert(_settings);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_settings forKey:kSettings];
    [userDefaults synchronize];
    // Replace currentSettings
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.currentSettings = _settings;
}

- (void)controlAndSaveBTFunctionSettings {
    assert(_settings);
    [_settings setValue:[NSNumber numberWithBool:_btFunctionSwitch.isOn] forKey:kBTFuncUsing];
    [self saveNewSettings];
    if (_btFunctionSwitch.isOn) { // モニタリングを開始
        BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
        [btFacade startMonitoringForCandidatesRegion];
    } else { // モニタリングを停止
        [_btFacade stopMonitoringForServiceRegion];
    }
}

// Show description & my beacon registration view
- (IBAction)functionUseSwitched:(id)sender {
    if ([(UISwitch *)sender isOn]) {
        /* 規約に同意した状態下での、ビーコン機能使用可否のチェック
         デバイスやユーザ設定がビーコンをモニタリングできる状態かチェックします */
        BOOL canUse = [BTServiceFacade isLocationEventConditionMet];
        BOOL notDetermined = YES;
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined) {
            notDetermined = NO;
        }
        if (!canUse) {
            if (notDetermined) { // おそらく、初めての機能オン
                /* ユーザによる位置情報使用許可の状態変更コールバック通知を受け取る準備をします */
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                [notificationCenter addObserver:self selector:@selector(showBTEnabledDialog) name:kLocAuthAuthorizedAlways object:_btFacade];
                [notificationCenter addObserver:self selector:@selector(showAlertAndBlock) name:kLocAuthRestricted object:_btFacade];
                [notificationCenter addObserver:self selector:@selector(showAlertAndBlock) name:kLocAuthDenied object:_btFacade];
                /* ユーザに位置情報の使用の許可確認を求めます */
                [self requestUserAuthorization];
            } else { /* 位置情報の使用が許可されていないので、機能のオンをブロックしています */
                [self showAlertAndBlock];
            }
        } else { // 機能が使用できる状態です
            [self controlAndSaveBTFunctionSettings];
        }

    } else {
        [self controlAndSaveBTFunctionSettings];
    }
    
}

#pragma mark TbBTAgreementViewControllerDelegate

- (void)didAgreeByUser {
    _btServiceAgreed = YES;
    _btAgreementSkipped = NO;
    [self saveAgreement];
    [self dismissViewControllerAnimated:YES completion:^{
        _btFacade = [BTServiceFacade sharedFacade];
        // ユーザ設定が許可がされていなければ許可を依頼します
        if (NSFoundationVersionNumber_iOS_7_1 < NSFoundationVersionNumber) {
            [self requestUserAuthorization];
        }
    }];
}

- (void)didDisagreeByUser {
    _btServiceAgreed = NO;
    _btAgreementSkipped = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark function agreement

- (void)saveAgreement {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithBool:YES] forKey:kBTConditionAgreed];
    [defaults synchronize];
}

#pragma mark user settings request

- (void)requestUserAuthorization {
    // プッシュ通知の使用許可（既に設定されていれば何もしない）
    UIApplication *application = [UIApplication sharedApplication];
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound|UIUserNotificationTypeAlert|UIUserNotificationTypeBadge categories:nil]];
    }
    
    // 位置情報の使用許可（既に設定されていれば何もしない）
    [_btFacade requestUserAuthorization];
}

#pragma mark navigation

/* 機能説明 ＆ 除外ビーコン（自前）の新規登録用ビューを表示しています */
- (void)showBTUseDescriptionVC {
    
    BTUseDescriptionViewController *descriptionVC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"BTUseDescriptionViewController"];
    descriptionVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    descriptionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:descriptionVC animated:YES completion:nil];
}

- (void)showBTEnabledDialog {
    _btFunctionSwitch.enabled = YES;
    _btFunctionSwitch.on = YES;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"「すれ違いゲット」が使用できるようになりました" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/* 位置情報の使用許可がされていないので、機能の使用をブロックします */
- (void)showAlertAndBlock {
    _btFunctionSwitch.on = NO;
    _btFunctionSwitch.enabled = NO;
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お願い" message:@"この機能のご利用には、位置情報の取得を許可していただく必要があります" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}
@end
