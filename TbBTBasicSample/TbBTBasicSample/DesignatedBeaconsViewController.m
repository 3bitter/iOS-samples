//
//  DesignatedBeaconsViewController.m
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "DesignatedBeaconsViewController.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTManager.h"
#import "SecondViewController.h"
#import "AppDelegate.h"

@interface DesignatedBeaconsViewController ()

@property (strong, nonatomic) NSTimer *timeoutTimer;

@end

static NSString *cellIdentifier = @"beaconKeyCell";

extern NSString *kBeaconInfoLabel;
extern NSString *kRegionLabel;

extern NSString *kAnnounceLogFile;

extern NSString *kUsingBeaconFlag;
extern NSString *kMonitoringAllowed;

extern NSString *kMonitoringDidFail;
extern NSString *kRangingDidFail;
extern NSString *kRangingStarted;
extern NSString *kFoundNewBeacon;
extern NSString *kRangingTimeOverNotification;
extern NSString *kFoundNewBeacon;

@implementation DesignatedBeaconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];

    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 220.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    headerView.backgroundColor = [UIColor lightGrayColor];
    self.tableView.tableHeaderView = headerView;
    
    NSUInteger centerX = self.view.frame.size.width / 2;
    CGRect newButtonFrame = CGRectMake(centerX - 100.0, 180.0, 200.0, 30.0);
    _registButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _registButton.frame = newButtonFrame;
    [_registButton setTitle:@"新規登録" forState:UIControlStateNormal];
    [_registButton setTintColor:[UIColor redColor]];
    [_registButton addTarget:self action:@selector(registerButtonDidPush)  forControlEvents:UIControlEventTouchUpInside];
    [self.tableView.tableHeaderView addSubview:_registButton];
    
    CGRect descriptionLabelFrame = CGRectMake(centerX - 150.0, 30.0, 300.0, 160.0);
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    descriptionLabel.center = self.tableView.tableHeaderView.center;
    descriptionLabel.numberOfLines = 6;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    descriptionLabel.textColor = [UIColor whiteColor];
    NSMutableString *descriptionText = [NSMutableString stringWithString:@"登録するビーコンを指定するときはビーコンの電源をオンにして、「新規登録」をタップして発見されたビーコンのキーコードを確認して選択してください。\n"];
    [descriptionText appendString:@"反応しない場合は、一旦ビーコンの電源をオフにし数十秒待機して、再度電源をオンにしてください"];
    descriptionLabel.text = descriptionText;
    [self.tableView.tableHeaderView addSubview:descriptionLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // ビーコン機能スイッチがオンにされていたら新規登録ボタンを有効にしています
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL usingBeaconFunc = [[defaults valueForKey:kUsingBeaconFlag] boolValue];
    if (usingBeaconFunc) {
        _registButton.enabled = YES;
        // このアプリ（サンプル）ではAppDelegateからメインのmanagerをコピーしています
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        assert(appDelegate.appLocManager);
        _appLocManager = appDelegate.appLocManager;
    } else {
        _registButton.enabled = NO;
    }

    TbBTManager *btManager = [TbBTManager sharedManager];
    if (btManager) {
        // 既に登録済みのビーコン情報をSDKから取得します
        _designatedBeaconInfos = [NSMutableArray arrayWithArray:[btManager currentUsableServiceBeaconDatas]];
    }
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_designatedBeaconInfos.count > 0) {
        return _designatedBeaconInfos.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
 
    // 登録済みのビーコン情報からキーコード情報を抜き出して表示します
    if (_designatedBeaconInfos.count > 0) {
        TbBTServiceBeaconData *beaconData = [_designatedBeaconInfos objectAtIndex:indexPath.row];
        cell.textLabel.text = beaconData.keycode;
    }
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_appLocManager == nil) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    /* CLLocationManagerとTbBTManagerの両方が必要です */
    TbBTManager *btManager = [TbBTManager sharedManager];
    assert(_appLocManager);
    assert(btManager);
    if (btManager && _appLocManager) {
        // 指定ビーコンのモニタリングを停止し、登録抹消します
        NSUInteger numberOfDeleted = [btManager releaseUsableServiceBeacon:[_designatedBeaconInfos objectAtIndex:indexPath.row] locationManager:_appLocManager];
        NSLog(@"No. of deleted and monitoring stopped beacons: %lu", (unsigned long)numberOfDeleted);
        // SDK管理の登録ビーコン情報から抹消されたら、現在使用されているビーコンリストからも削除します
        [_designatedBeaconInfos removeObjectAtIndex:indexPath.row];
        NSLog(@"No. of designatedBeacons: %lu", (unsigned long)_designatedBeaconInfos.count);
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if (numberOfDeleted > 0) {
            NSString *infoMessage = @"指定ビーコンのモニタリングを解除して指定から外しました";
            [self saveAnnounceLogToFile:infoMessage];
        }
    }
}

- (void)searchMyBeacons {
    NSLog(@"-- searchMyBeacons --");
    assert(_appLocManager);
    [self startSearchIndication];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // 検索タイムアウトを30秒に指定
    appDelegate.addProcessTimeoutTime = [NSDate dateWithTimeIntervalSinceNow:30];
    appDelegate.addProcessing = YES;
    
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(terminateSearchMyBeacons) userInfo:nil repeats:NO];
    [[TbBTManager sharedManager] startMonitoringTbBTInitialRegions:appDelegate.appLocManager];
}

- (void)terminateSearchMyBeacons {
    NSLog(@"-- terminateSearchMyBeacons --");
    assert(_appLocManager);
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.addProcessing) {
        return;
    }
    // 指定されていない3bitterビーコン領域のモニタリングを停止します
    [[TbBTManager sharedManager] stopMonitoringTbBTInitialRegions:_appLocManager];
    appDelegate.addProcessTimeoutTime = nil;
    appDelegate.addProcessing = NO;
    [self stopSearchIndication];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"お知らせ" message:@"ビーコンの検知ができませんでした。設定の確認後、再度お試しください。" delegate:self cancelButtonTitle:@"了解" otherButtonTitles:nil];
    [alertView show];
}

- (void)showBeaconKeyList:(NSNotification *)notification {
    NSDictionary *beaconInfoDict = [notification userInfo];
    NSArray *beaconInfos = [beaconInfoDict objectForKey:kBeaconInfoLabel];
    CLBeaconRegion *region = [beaconInfoDict objectForKey:kRegionLabel];
    
    _rangedBeaconVC = [[RangedBeaconInfoViewController alloc] init];
    _rangedBeaconVC.theRegion = region;
    _rangedBeaconVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    _rangedBeaconVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    _rangedBeaconVC.tbBTBeaconInfos = [NSMutableArray arrayWithArray:beaconInfos];
    [self presentViewController:_rangedBeaconVC animated:YES completion:nil];

    [self stopSearchIndication];
}

#pragma mark search indication

- (void)startSearchIndication {
    NSLog(@"-- startSearchIndicaiton --");
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.frame = CGRectMake(0.0, 0.0, 50.0, 50.0);
    _indicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _indicator.opaque = NO;
    _indicator.backgroundColor = [UIColor blackColor];
    _indicator.color = [UIColor whiteColor];
    _indicator.center = self.view.center;
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)stopSearchIndication {
    NSLog(@"-- stopSearchIndication--");
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
}

- (void)registerButtonDidPush {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL serviceAgreed = [[defaults valueForKey:kMonitoringAllowed] boolValue];
    if (serviceAgreed) {
        // 自分のビーコンを登録する処理を開始します
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kMonitoringDidFail object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kRangingDidFail object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelTimeoutTimer) name:kRangingStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBeaconKeyList:) name:kFoundNewBeacon object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kRangingTimeOverNotification object:nil];
        [self searchMyBeacons];
    } else {
        // 本サンプルでは規約同意していなければ登録ボタンを無効にするのでこのブロックには入りません
        // cf. viewWillAppear
        //[self showAlert];
        return;
    }
}

- (void)cancelTimeoutTimer {
    if (_timeoutTimer) {
        [_timeoutTimer invalidate];
        _timeoutTimer = nil;
    }
}

#pragma mark event log

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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
