//
//  DesignatedBeaconsViewController.m
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "DesignatedBeaconsViewController.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTManager.h"
#import "SecondViewController.h"

@interface DesignatedBeaconsViewController ()

@end

static NSString *cellIdentifier = @"beaconKeyCell";

extern NSString *kAnnounceLogFile;

@implementation DesignatedBeaconsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 200.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    headerView.backgroundColor = [UIColor grayColor];
    self.tableView.tableHeaderView = headerView;
    
    CGRect descriptionLabelFrame = CGRectMake(0.0, 0.0, 300.0, 120.0);
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    descriptionLabel.center = self.tableView.tableHeaderView.center;
    descriptionLabel.numberOfLines = 4;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.text = @"サービス連動するビーコンを指定するときは、「領域更新」タブの画面を表示した後で、ビーコンのスイッチをオンにしてください";
    [self.tableView.tableHeaderView addSubview:descriptionLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    TbBTManager *btManager = [TbBTManager sharedManager];
    if (btManager) {
        // 既に登録済みのビーコン情報をSDKから取得します
        _designatedBeaconInfos = [NSMutableArray arrayWithArray:[btManager currentUsableServiceBeaconDatas]];
    }
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
    SecondViewController *secondViewController = [((UITabBarController *)self.view.window.rootViewController).viewControllers objectAtIndex:1];
    _appLocManager = secondViewController.myLocManager;

    if (_appLocManager == nil) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
            NSString *infoMessage = @"指定ビーコンのモニタリングを解除して指定から外しました（注：サンプルの実装では、指定ビーコン数が0の場合、次回の反応で自動的に制限用のビーコン選択のビューを表示します）";
            [self saveAnnounceLogToFile:infoMessage];
        }
    }
}

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
