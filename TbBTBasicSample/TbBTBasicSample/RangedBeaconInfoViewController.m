//
//  RangedBeaconInfoViewController.m
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "RangedBeaconInfoViewController.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTManager.h"
#import "AppDelegate.h"
#import "DesignatedBeaconsViewController.h"

@interface RangedBeaconInfoViewController ()

// チェックマーク用の選択インデックス処理
@property (strong, nonatomic) NSMutableArray *selectedIndexArray;

@end

static NSString * cellIdentifier = @"KeycodeCell";

extern NSString * kAnnounceLogFile;

@implementation RangedBeaconInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 200.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    self.tableView.tableHeaderView = headerView;
    
    CGFloat centerX = self.view.frame.size.width / 2;
    CGRect descriptionLabelFrame = CGRectMake(centerX - 140.0, 20.0, 280.0, 120.0);
    _descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    _descriptionLabel.numberOfLines = 2;
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    NSMutableString *descriptionText = [NSMutableString stringWithString:@"ビーコンが見つかりました"];
    [descriptionText appendString:@"\n"];
    [descriptionText appendString:@"今後使用するビーコンを指定してください"];
    _descriptionLabel.text = descriptionText;
    [self.tableView.tableHeaderView addSubview:_descriptionLabel];
    
    _saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _saveButton.frame = CGRectMake(centerX - 90.0, 100.0, 180.0, 60.0);
    [_saveButton addTarget:self action:@selector(saveButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton setTitle:@"選択したものに使用を制限" forState:UIControlStateNormal];
    _saveButton.titleLabel.textColor = [UIColor blueColor];
    [self.tableView.tableHeaderView addSubview:_saveButton];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _cancelButton.frame = CGRectMake(headerView.frame.size.width - 100.0, 40.0, 80.0, 30.0);
    [_cancelButton addTarget:self action:@selector(cancelButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
    [_cancelButton setTitle:@"キャンセル" forState:UIControlStateNormal];
    _cancelButton.titleLabel.textColor = [UIColor redColor];
    [self.tableView.tableHeaderView addSubview:_cancelButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (_tbBTBeaconInfos.count > 1) {
        return _tbBTBeaconInfos.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (_tbBTBeaconInfos.count > 0) {
        // 見つかったビーコン情報から得られるキーコードを表示しています
        TbBTServiceBeaconData *theBeaconData = [_tbBTBeaconInfos objectAtIndex:indexPath.row];
        NSString *keyCode = theBeaconData.keycode;
        cell.textLabel.text = keyCode;
        if (_selectedIndexArray && [_selectedIndexArray containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        cell.textLabel.text = @"N/A";
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_selectedInfos) {
        _selectedInfos = [NSMutableArray array];
    }
    if (!_selectedIndexArray) {
        _selectedIndexArray = [NSMutableArray array];
    }
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    UITableViewCell *targetCell = [tableView cellForRowAtIndexPath:indexPath];
    if (targetCell.accessoryType == UITableViewCellAccessoryNone) {
        [_selectedIndexArray addObject:[NSNumber numberWithInteger:indexPath.row]];
        [_selectedInfos addObject:[_tbBTBeaconInfos objectAtIndex:indexPath.row]];
        targetCell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (targetCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        [_selectedInfos removeObject:[_tbBTBeaconInfos objectAtIndex:indexPath
                                      .row ]];
        [_selectedIndexArray removeObject:[NSNumber numberWithInteger:indexPath.row]];
        targetCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark User Interaction

- (void)saveButtonDidPush {
    [self selectOwnBeacons:_selectedInfos];
}

- (void)cancelButtonDidPush {
    // Reset progress state
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.addProcessing = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)selectOwnBeacons:(NSArray *)beaconInfos {
    if (beaconInfos.count == 0) {
        return;
    }
    TbBTManager *btManager = [TbBTManager sharedManager];
    if (btManager == nil) {
        return;
    }
    // このメソッド内でしか使わないので、LocationManagerはAppDelegateで保持されているインスタンスを直接していしています
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.appLocManager == nil) {
        return;
    }
    NSString *infoMessage = nil;
    // 初期モニタリングした3bitterビーコンの領域を、指定ビーコンの領域に置き換えます
    BOOL isSaved = [btManager specifyNewUsableServiceBeaconWithCodes:beaconInfos forRegion:_theRegion locationManager:appDelegate.appLocManager];
    infoMessage = @"指定ビーコンを登録して3bitterビーコン領域のモニタリング対象を切り替えました";
    if (isSaved) {
        // Show registered beacon info
        DesignatedBeaconsViewController *designatedBeaconVC = [((UITabBarController *)self.presentingViewController).childViewControllers objectAtIndex:2];
        designatedBeaconVC.designatedBeaconInfos = [NSMutableArray arrayWithArray:beaconInfos];
        [designatedBeaconVC.tableView reloadData];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSLog(@"Failed to save beacon ...");
        infoMessage = @"指定ビーコンの登録に失敗しました";
    }
    [self saveAnnounceLogToFile:infoMessage];
}

#pragma mark Event Logging

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
