//
//  StartupViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "StartupViewController.h"
#import "ItemManager.h"
#import "HomeViewController.h"
#import "TbSandboxCredential.h"

extern NSString *kMasterItemPrepared;
extern NSString *kInitialItemPrepared;
extern NSString *kItemPreparationFailed;

extern NSString *kReadyToUse;

extern NSString *kOneThirdIconsDownloaded;
extern NSString *kTwoThirdIconsDownloaded;

@interface StartupViewController()

- (void)stopIndication;

@end

@implementation StartupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _nickNameField.returnKeyType = UIReturnKeyDone;
    _nickNameField.delegate = self;
    _closeButton.hidden = YES;
    
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    if (appToken.length == 0) {
        _nickNameField.enabled = NO;
        _startButton.enabled = NO;
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"本アプリの使用にはデモ環境用の試用キーが必要です" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startButtonDidPush:(id)sender {
    [_nickNameField resignFirstResponder];
    // Simple validation
    if (_nickNameField.text.length == 0 || [_nickNameField.text isEqualToString:@" "]) {
        _infoLabel.text = @"ニックネームに1文字以上いれてください";
        _infoLabel.textColor = [UIColor redColor];
        return;
    }
    if (_nickNameLabel.text.length > 6) {
        _infoLabel.text = @"6文字以内でお願いします";
        _infoLabel.textColor = [UIColor redColor];
        return;
    }
    NSString *regEx = @"[\"\']";
    
    NSRange invalidCharRange = [_nickNameField.text rangeOfString:regEx options:NSRegularExpressionSearch];
    if (NSNotFound != invalidCharRange.location) {
        _infoLabel.text = @"ニックネームに\"と\'は使用できません";
        _infoLabel.textColor = [UIColor redColor];
        return;

    }
     [self startIndicationWithMessage:@"初期データの登録とゲームデータのダウンロード中です..."];
     [self requestMemberRegistration];
}

- (IBAction)closeButtonDidPush:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissKeyboard:(id)sender {
    [sender resignFirstResponder];
}

- (void)requestMemberRegistration {
    NSString *nickName = _nickNameField.text;
    DefaultServerClient *serverClient = [[DefaultServerClient alloc] init];
    serverClient.delegate = self;
    NSString *appToken = [[TbSandboxCredential myCredential] appToken];
    serverClient.myAppToken = appToken;
    [serverClient requestBecomeAMember:nickName];
}

- (void)prepareMasterItem {
    [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:0.2] waitUntilDone:NO];
    NSLog(@"Start to get master items");
    [[ItemManager sharedManager] prepareMasterItem];
}

- (void)decideUserInitialItems {
    [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:0.8] waitUntilDone:NO];
    NSLog(@"Start to choose user items");
    [[ItemManager sharedManager] decideUserInitialItems];
}

- (void)notifyOneThird {
    [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:0.4] waitUntilDone:NO];
}

- (void)notifyTwoThird {
    [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:0.6] waitUntilDone:NO];
}

- (void)finishInitialSetup {
    [self performSelectorOnMainThread:@selector(markSetupCompletion) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(stopIndication) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(changeToCompleteContents) withObject:nil waitUntilDone:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notifyFailureToUser {
    [self performSelectorOnMainThread:@selector(alertSetupFailure) withObject:nil waitUntilDone:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)alertSetupFailure {
    [self stopIndication];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"エラー" message:@"初期設定に失敗しました。申し訳ありませんが、再度お試しください" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"仕方ない..." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)startIndicationWithMessage:(NSString *)message {
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.frame = CGRectMake(0.0, 0.0, 200.0, 140.0);
    _indicator.backgroundColor = [UIColor grayColor];
    _indicator.color = [UIColor whiteColor];
    _indicator.center = self.view.center;
    
    _progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progress.frame = CGRectMake(10.0, 20.0, 180.0, 20.0);
    [_progress setProgress:0.0 animated:NO];
    [_indicator addSubview:_progress];

    CGRect descLabelFrame = CGRectMake(10.0, 90.0, 180.0, 40.0);
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:descLabelFrame];
    descriptionLabel.numberOfLines = 2;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.font = [UIFont systemFontOfSize:12.0];
    descriptionLabel.text = message;
    [_indicator addSubview:descriptionLabel];
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)stopIndication {
    if (_progress) {
        [_progress setProgress:1.0 animated:YES];
    }
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
}

- (void)updateProgress:(NSNumber *)progress {
    [_progress setProgress:[progress floatValue] animated:YES];
}

- (void)changeToCompleteContents {
    _infoLabel.text = @"初期設定が完了しました。プレイを開始できます";
    _requirementLabel.text = nil;
    [_requirementLabel removeFromSuperview]; // just in case
    _closeButton.hidden = NO;
    _startButton.enabled = NO;
    [_startButton removeFromSuperview];
    _nickNameField.enabled = NO;
    [_nickNameField removeFromSuperview];
    [_nickNameLabel removeFromSuperview];
}

- (void)markSetupCompletion {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *storedNickName = [userDefaults objectForKey:@"nickName"];
    [userDefaults setValue:[NSNumber numberWithBool:YES] forKey:kReadyToUse];
    [userDefaults synchronize];
    ((HomeViewController *)[self.presentingViewController.childViewControllers objectAtIndex:0]).nickNameLabel.text = storedNickName;
}

#pragma mark DefaultServerClientDelegate

- (void)serverClient:(DefaultServerClient *)client didRegistAsMember:(NSString *)memberToken {
    NSString *nickName = _nickNameField.text;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:memberToken forKey:@"token"];
    [userDefaults setObject:nickName forKey:@"nickName"];
    [userDefaults synchronize];
    
    // マスタアイテムを取得 (by ItemManager)
    ItemManager *itemManager = [ItemManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decideUserInitialItems) name:kMasterItemPrepared object:itemManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishInitialSetup) name:kInitialItemPrepared object:itemManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyFailureToUser) name:kItemPreparationFailed object:itemManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOneThird) name:kOneThirdIconsDownloaded object:itemManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyTwoThird) name:kTwoThirdIconsDownloaded object:itemManager];
    
    [self prepareMasterItem];
}

- (void)serverClient:(DefaultServerClient *)client didFailToBecomeMemberWithError:(NSError *)error {
    NSLog(@"%@", error);
    [self notifyFailureToUser];
}

@end
