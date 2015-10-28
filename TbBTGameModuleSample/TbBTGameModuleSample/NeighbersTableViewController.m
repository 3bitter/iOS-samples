//
//  NeighbersTableViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "NeighbersTableViewController.h"
#import "BeaconUserInfoCell.h"
#import "AppDelegate.h"
#import "BeaconOwner.h"
#import "BTServiceFacade.h"

@interface NeighbersTableViewController ()<BTServiceFacadeDelegate>

@property (assign, nonatomic) BOOL ranging;
@property (assign, nonatomic) NSUInteger failureCount;
@property (assign, nonatomic) BOOL finishWithError;

@property (strong, nonatomic) NSTimer *timeoutTimer;

@end

extern NSString *kBTFuncUsing;
extern NSString *kOutsideOfRegion;

static const NSUInteger ABORT_THRESHOLD = 3;

@implementation NeighbersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect headerFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 120.0);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    headerView.backgroundColor = [UIColor lightGrayColor];
    self.tableView.tableHeaderView = headerView;
    
    CGFloat centerX = self.view.frame.size.width / 2;
    CGRect descriptionLabelFrame = CGRectMake(centerX - 140.0, 40.0, 280.0, 80.0);
    _descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelFrame];
    _descriptionLabel.numberOfLines = 4;
    _descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _descriptionLabel.font = [UIFont systemFontOfSize:13.0];
    _descriptionLabel.textAlignment = NSTextAlignmentCenter;
    _descriptionLabel.textColor = [UIColor whiteColor];
    NSMutableString *descriptionText = [NSMutableString stringWithString:@"近くのオーナー"];
    [descriptionText appendString:@"\n"];
    [descriptionText appendString:@"（※最大で10まで探します）"];
    _descriptionLabel.text = descriptionText;
    
    [headerView addSubview:_descriptionLabel];
    
    self.tableView.tableHeaderView = headerView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateRegionState) name:kOutsideOfRegion object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL btFuncUsing = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    
    if (btFuncUsing) {
        [self checkNeighbers];
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"この機能は「すれ違いアイテムゲット」機能が有効な場合に使用できます" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL btFuncUsing = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    
    //  ビューが消える場合は検索終了
    if (btFuncUsing) {
        [self terminateCheckNeighbers];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"見つかったビーコンオーナー";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
    if (_neighberBeaconOwners.count > 0) {
        numberOfRows = _neighberBeaconOwners.count;
    }
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BeaconUserInfoCell" forIndexPath:indexPath];
    if (_neighberBeaconOwners.count > 0) {
        cell.textLabel.text = nil;
        
        BeaconOwner *owner = [_neighberBeaconOwners objectAtIndex:indexPath.row];
        if (owner.usingBeaconForGame) {
            ((BeaconUserInfoCell *)cell).nickNameLabel.textColor = [UIColor blueColor];
             ((BeaconUserInfoCell *)cell).nickNameLabel.text = [@"[すれ違い機能使用中] " stringByAppendingString:owner.userName];
        } else {
             ((BeaconUserInfoCell *)cell).nickNameLabel.text = owner.userName;
        }
        ((BeaconUserInfoCell *)cell).proximityLabel.text = owner.proximityDescription;
        ((BeaconUserInfoCell *)cell).indicatorLabel.text =[NSString stringWithFormat:@"%ld", (long)owner.dummyIndicator];

    } else if (_ranging) {
        cell.textLabel.text = @"チェック中 ...";
        cell.textLabel.textColor = [UIColor redColor];
    } else if (_finishWithError) {
        cell.textLabel.text = @"通信エラーによりチェックができませんでした。後ほどお試しください";
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.text = @"チェック停止中（近くに誰も居ないようです）";
        cell.textLabel.textColor = [UIColor redColor];
    }
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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

- (void)checkNeighbers {
    /* Sample specified block. (Block BTServiceFacadeDelegate switching) */
    BOOL gamePlaying = ((AppDelegate *)[UIApplication sharedApplication].delegate).playing;
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    if (gamePlaying || [btFacade isChecking]) {
        while ([btFacade isChecking]) {
            [NSThread sleepForTimeInterval:0.1];
        }
    }
    btFacade.delegate = self;
    
    // タイムアウトを30秒にしています
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(updateRegionState) userInfo:nil repeats:NO];
    
    [btFacade startSearchNeighbers];
    _finishWithError = NO;
    _failureCount = 0;
    _ranging = YES;
    [self.tableView reloadData];
}

- (void)terminateCheckNeighbers {
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    btFacade.delegate = self;
    [btFacade stopSearchNeighbers];
    _ranging = NO;
}

- (void)updateRegionState {
    if (_neighberBeaconOwners.count == 0) {
        _neighberBeaconOwners = nil;
        [self terminateCheckNeighbers];
        [self.tableView reloadData];
    }
}

#pragma mark BTFacadeDelegate

- (void)btFacade:(BTServiceFacade *)facade didProfileNewNeighbers:(NSArray *)discoveredNeighbers {
    // プロパティにコピー、リロード
    _neighberBeaconOwners = [NSArray arrayWithArray:discoveredNeighbers];
    [self.tableView reloadData];
}

- (void)btFacade:(BTServiceFacade *)facade didFailToProfileNeighbersWithError:(NSError *)error {
    NSLog(@"Error occured:%@", error);
    _failureCount++;
    if (_failureCount >= ABORT_THRESHOLD) {
    // Stop search and alert
        [self terminateCheckNeighbers];
        _finishWithError = YES;
        [self.tableView reloadData];
    }
}

- (void)btFacade:(BTServiceFacade *)facade didUpdateNeighberInfos:(NSArray *)currentNeighbers {
    // Reset failure count
    _failureCount = 0;
    
    _neighberBeaconOwners = [NSArray arrayWithArray:currentNeighbers];
    [self.tableView reloadData];
}


@end
