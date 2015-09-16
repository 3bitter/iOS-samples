//
//  RangedBeaconInfoViewController.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/01.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "RangedBeaconInfoViewController.h"
#import "AppDelegate.h"
#import "TbBTManager.h"
#import "TbBTRegionNotificationSettingOptions.h"
#import "BTServiceFacade.h"
#import "MyBeacon.h"
#import "DesignatedBeaconsViewController.h"

@interface RangedBeaconInfoViewController ()

@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *cancelButton;
// Just for check mark handling
@property (strong, nonatomic) NSMutableArray *selectedIndexArray;

@end

static NSString *cellIdentifier = @"KeycodeCell";
extern NSString *kNotifyOnTypeLabel;
extern NSString *kNotifyOnDisplayLabel;
extern NSString *kBeaconKeyRegistered;
extern NSString *kBeaconKeyRegistFailed;

@implementation RangedBeaconInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];

    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 220.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    self.tableView.tableHeaderView = headerView;
    
    CGFloat centerX = self.view.frame.size.width / 2;
    CGRect descriptionLabelFrame = CGRectMake(centerX - 140.0, 40.0, 280.0, 120.0);
    _descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    _descriptionLabel.numberOfLines = 5;
    _descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableString *descriptionText = [NSMutableString stringWithString:@"ビーコンが見つかりました"];
    [descriptionText appendString:@"\n\n"];
    [descriptionText appendString:@"※他ユーザーのビーコンと区別するために、アプリに反応させたくない"];
    [descriptionText appendString:@"（自分が持っている）ビーコンを指定してください"];
    _descriptionLabel.text = descriptionText;
    [self.tableView.tableHeaderView addSubview:_descriptionLabel];
    
    _saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _saveButton.frame = CGRectMake(centerX - 90.0, 160.0, 180.0, 30.0);
    [_saveButton addTarget:self action:@selector(saveButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton setTitle:@"選択したものを登録" forState:UIControlStateNormal];
    _saveButton.titleLabel.textColor = [UIColor redColor];
    [self.tableView.tableHeaderView addSubview:_saveButton];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _cancelButton.frame = CGRectMake(self.view.bounds.size.width - 90.0, 40.0, 80.0, 30.0);
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tbBTBeaconInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (_tbBTBeaconInfos.count > 0) {
        TbBTServiceBeaconData *beaconData = [_tbBTBeaconInfos objectAtIndex:indexPath.row];
        cell.textLabel.text = beaconData.keycode;
        if (_selectedIndexArray && [_selectedIndexArray containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_selectedInfos == nil) {
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

// Override to support conditional editing of the table view.
/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark BeaconInfo

- (void)cancelButtonDidPush {
    // Reset progress state
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    assert(btFacade);
    btFacade.addProcessing = NO;
    btFacade.addProcessTimeoutTime = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonDidPush {
    [self startIndication];
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    assert(btFacade);
    if ([btFacade saveOwnBeacons:_selectedInfos ofRegion:_theRegion]) {
        btFacade.addProcessing = NO;
        [self refreshBeaconView];
    } else {
        btFacade.addProcessing = NO;
        [self showFailureAlert];
    }
}

- (void)startIndication {
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
    descriptionLabel.text = @"ビーコンを登録中です...";
    [_indicator addSubview:descriptionLabel];
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)stopIndication{
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
}

- (void)refreshBeaconView {
    DesignatedBeaconsViewController *designatedBeaconsVC = (DesignatedBeaconsViewController *)[self.presentingViewController.childViewControllers objectAtIndex:2]; // options - bt settings - my beacons
    assert(designatedBeaconsVC);
    [designatedBeaconsVC.tableView reloadData];
    [self stopIndication];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showFailureAlert {
    [self stopIndication];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"エラー" message:@"登録に失敗しました。後ほどやり直してみてください" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"仕方ない.." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
