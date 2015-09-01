//
//  RangedBeaconInfoViewController.m
//  TbBTSDKBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "RangedBeaconInfoViewController.h"
#import "TbBTServiceBeaconData.h"
#import "TbBTManager.h"

@interface RangedBeaconInfoViewController ()

@end

static NSString * cellIdentifier = @"KeycodeCell";

extern NSString * kAnnounceLogFile;

@implementation BeaconDesignateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 200.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    self.tableView.tableHeaderView = headerView;
    
    CGFloat centerX = self.view.frame.size.width / 2;
    CGRect descriptionLabelFrame = CGRectMake(centerX - 140.0, 20.0, 280.0, 120.0);
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    descriptionLabel.numberOfLines = 2;
    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    descriptionLabel.text = @"ビーコンが見つかりました。今後使用するビーコンを指定してください";
    [self.tableView.tableHeaderView addSubview:descriptionLabel];
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    saveButton.frame = CGRectMake(centerX - 90.0, 100.0, 180.0, 60.0);
    [saveButton addTarget:self action:@selector(saveButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
    [saveButton setTitle:@"選択したものに使用を制限" forState:UIControlStateNormal];
    saveButton.titleLabel.textColor = [UIColor blueColor];
    [self.tableView.tableHeaderView addSubview:saveButton];
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
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (_tbBTBeaconInfos.count > 0) {
        // 見つかったビーコン情報から得られるキーコードを表示しています
        TbBTServiceBeaconData *theBeaconData = [_tbBTBeaconInfos objectAtIndex:indexPath.row];
        NSString *keyCode = theBeaconData.keycode;
        cell.textLabel.text = keyCode;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text = @"N/A";
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_selectedInfos == nil) {
        _selectedInfos = [NSMutableArray array];
    }
    UITableViewCell *targetCell = [tableView cellForRowAtIndexPath:indexPath];
    if (targetCell.accessoryType == UITableViewCellAccessoryNone) {
        [_selectedInfos addObject:[_tbBTBeaconInfos objectAtIndex:indexPath.row]];
        targetCell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (targetCell.accessoryType == UITableViewCellAccessoryCheckmark) {
        [_selectedInfos removeObjectAtIndex:indexPath.row];
        targetCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)saveButtonDidPush {
    [self selectOwnBeacons:_selectedInfos];
}

- (void)selectOwnBeacons:(NSArray *)beaconInfos {
    if (beaconInfos.count == 0) {
        return;
    }
    TbBTManager *btManager = [TbBTManager sharedManager];
    if (btManager == nil) {
        return;
    }
    if (_appLocManager == nil) {
        return;
    }
    NSString *infoMessage = nil;
    // 初期モニタリングした3bitterビーコンの領域を、指定ビーコンの領域に置き換えます
    BOOL isSaved = [btManager specifyNewUsableServiceBeaconWithCodes:beaconInfos forRegion:_theRegion locationManager:_appLocManager];
    infoMessage = @"指定ビーコンを登録して3bitterビーコン領域のモニタリング対象を切り替えました";
    if (isSaved) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSLog(@"Failed to save beacon ...");
        infoMessage = @"指定ビーコンの登録に失敗しました";
    }
    [self saveAnnounceLogToFile:infoMessage];
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
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    if (error != NULL) {
        NSLog(@"save message error: %@", [error userInfo]);
    }
}


@end
