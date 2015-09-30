//
//  DesignatedBeaconsViewController.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/05/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "DesignatedBeaconsViewController.h"
#import "AppDelegate.h"
#import "BTServiceFacade.h"
#import "MyBeacon.h"

@interface DesignatedBeaconsViewController ()

@property (strong, nonatomic) BTServiceFacade *btFacade;
@property (strong, nonatomic) NSTimer *timeoutTimer;

- (void)startIndicationWithMessage:(NSString *)message;
- (void)stopIndication;

@end

static NSString *cellIdentifier = @"InfoCell";

extern NSString *kBRMonitoringDidFail;
extern NSString *kRangingDidFail;
extern NSString *kFoundNewBeacon;
extern NSString *kRangingTimeOverNotification;
extern NSString *kRangingStoppedOnBackgroundState;

extern NSString *kBeaconKeyRegistered;
extern NSString *kBeaconKeyRegistFailed;
extern NSString *kBeaconKeyDeactivated;
extern NSString *kBeaconKeyDeactivateFailed;

extern NSString *kBTFuncUsing;
extern NSString *kBeaconInfoLabel;
extern NSString *kRegionLabel;



@implementation DesignatedBeaconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL btFuncUsing = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    if (btFuncUsing) {
        _registButton.enabled = NO;
        _infoLabel.hidden = NO;
    }
    _customHeaderView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 180.0);
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    // Do not use delegate
    _btFacade = [BTServiceFacade sharedFacade];
    if (_btFacade.designatedBeacons.count > 0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reflectResult) name:kBeaconKeyRegistered object:_btFacade];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reflectResult) name:kBeaconKeyDeactivated object:_btFacade];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockChanging) name:kBeaconKeyRegistFailed object:_btFacade];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blockChanging) name:kBeaconKeyDeactivateFailed object:_btFacade];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

- (IBAction)registerButtonDidPush:(id)sender {
    /* BTServiceFacadeからの通知を受け取る用意をしています */
    assert(_btFacade);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kBRMonitoringDidFail object:_btFacade];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kRangingDidFail object:_btFacade];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBeaconKeyList:) name:kFoundNewBeacon object:_btFacade];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeacons) name:kRangingTimeOverNotification object:_btFacade];
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateSearchMyBeaconsSilently) name:kRangingStoppedOnBackgroundState object:_btFacade];
    [self searchMyBeacons];
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
    NSInteger numberOfRows = 1;

    if (_btFacade.designatedBeacons.count > 0) {
        numberOfRows = _btFacade.designatedBeacons.count;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:12.0];
    NSString *nonExistDescription = @"指定のビーコンはありません";

    if (_btFacade.designatedBeacons.count > 0) {
            MyBeacon *beacon = [_btFacade.designatedBeacons objectAtIndex:indexPath.row];
            NSMutableString *cellText = [NSMutableString stringWithString:beacon.beaconName];
            [cellText appendString:@"("];
            [cellText appendString:beacon.keycode];
            [cellText appendString:@")"];
            cell.textLabel.text = cellText;
        if (beacon.useForGame) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main"]];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
        }
    } else {
        cell.textLabel.text = nonExistDescription;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }

    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (_btFacade.designatedBeacons.count == 0) {
        return NO;
    }
    return YES;
}


// Override to support editing the table view./*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    /*if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if ([_btFacade deleteRegisteredBeaconAtIndex:indexPath.row]) {
            if (_btFacade.designatedBeacons.count > 0) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            [tableView reloadData];
        }
    } */
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *editActions = nil;
    if (!_btFacade || _btFacade.designatedBeacons.count == 0) {
        return nil;
    }
    void (^changeHandler)(UITableViewRowAction *action, NSIndexPath *indexPath);
            // Deactivate for game use
    MyBeacon *theBeacon = [_btFacade.designatedBeacons objectAtIndex:indexPath.row];
    if (_btFacade.designatedBeacons.count == 1 && theBeacon.useForGame) {
            UITableViewRowAction *rowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"登録抹消" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                [self startIndicationWithMessage:@"メイン解除しています..."];
               [_btFacade deactivateUserBeacon:theBeacon]; // Save to server and update my beacons
            }];
            rowAction.backgroundColor = [UIColor blueColor];
            editActions = [NSArray arrayWithObject:rowAction];
    } else {
        void (^deleteHandler)(UITableViewRowAction *action, NSIndexPath *indexPath);
        if (_btFacade.designatedBeacons.count > 0) {
            changeHandler = ^(UITableViewRowAction *action, NSIndexPath *indexPath){
                [self startIndicationWithMessage:@"メイン登録しています..."];
                [self setMainBeaconAtIndex:indexPath.row];
            };
            deleteHandler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                BOOL released = [_btFacade deleteRegisteredBeaconAtIndex:indexPath.row];
                if (released &&_btFacade.designatedBeacons.count > 0) {
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                } else if (!released) {
                    NSLog(@"Not released !!!");
                }
                [self.tableView reloadData];
            };
            UITableViewRowAction *changeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"メインに" handler:changeHandler];
            changeAction.backgroundColor = [UIColor blueColor];
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"削除" handler:deleteHandler];
            deleteAction.backgroundColor = [UIColor redColor];
            if (!theBeacon.useForGame) {
                editActions = [NSArray arrayWithObjects:deleteAction, changeAction, nil];
            } else {
                editActions = nil;
            }
        }
    }
    return editActions;
}

- (void)setMainBeaconAtIndex:(NSInteger)index {
    if (!_btFacade || _btFacade.designatedBeacons.count == 0) {
        return;
    }
    MyBeacon *theBeacon = [_btFacade.designatedBeacons objectAtIndex:index];
    [_btFacade registerUserMainBeacon:theBeacon]; // Wait call back notification
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)searchMyBeacons {
    NSLog(@"-- searchMyBeacons --");
    
    [self startIndicationWithMessage:@"ビーコンを探しています..."];
    assert(_btFacade);
    _btFacade.addProcessTimeoutTime = [NSDate dateWithTimeIntervalSinceNow:30];
    _btFacade.addProcessing = YES;
    
    // 新規登録処理のタイムアウトを30秒にしています
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(terminateSearchMyBeacons) userInfo:nil repeats:NO];
    [_btFacade startSearchForRegister];
}

// 停止処理メソッド
- (void)terminateSearchMyBeacons {
    assert(_btFacade);
    if (!_btFacade.addProcessing) {
        return;
    }
    [_btFacade stopSearchForRegister];
    _btFacade.addProcessTimeoutTime = nil;
    _btFacade.addProcessing = NO;
    // フォアグラウンド処理
    [self performSelectorOnMainThread:@selector(terminationUIFeedBack) withObject:nil waitUntilDone:NO];
}

// バックグラウンドに入った場合にコールされる停止処理メソッド
- (void)terminateSearchMyBeaconsSilently {
    NSLog(@"-- %s --", __func__);
    assert(_btFacade);
    [_btFacade stopSearchForRegister];
    _btFacade.addProcessTimeoutTime = nil;
    _btFacade.addProcessing = NO;
    [self performSelectorOnMainThread:@selector(stopIndication) withObject:nil waitUntilDone:NO];
}

- (void)terminationUIFeedBack {
    [self stopIndication];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"ビーコンの検知ができませんでした。設定（位置情報、Bluetooth）の確認後、再度お試しください。" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark search indication

- (void)startIndicationWithMessage:(NSString *)message {
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.frame = CGRectMake(0.0, 0.0, 120.0, 120.0);
    _indicator.backgroundColor = [UIColor grayColor];
    _indicator.color = [UIColor whiteColor];
    _indicator.center = self.view.center;
    CGRect descLabelFrame = CGRectMake(10.0, 90.0, 100.0, 30.0);
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
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
}

// ビーコンキーコードリストをモーダルビュー形式で表示します
- (void)showBeaconKeyList:(NSNotification *)notification {
    NSDictionary *beaconInfoDict = [notification userInfo];
    NSArray *beaconInfos = [beaconInfoDict objectForKey:kBeaconInfoLabel];
    CLBeaconRegion *region = [beaconInfoDict objectForKey:kRegionLabel];
    
    _rangedBeaconVC = [[RangedBeaconInfoViewController alloc] init];
    _rangedBeaconVC.theRegion = region;
    _rangedBeaconVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    _rangedBeaconVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:_rangedBeaconVC animated:YES completion:nil];
    _rangedBeaconVC.tbBTBeaconInfos = [NSMutableArray arrayWithArray:beaconInfos];
    [self stopIndication];
}

- (void)reflectResult {
    [self stopIndication];
    [self.tableView reloadData];
}

- (void)blockChanging {
    [self stopIndication];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"処理に失敗しました。後ほど再度お試しください。" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
