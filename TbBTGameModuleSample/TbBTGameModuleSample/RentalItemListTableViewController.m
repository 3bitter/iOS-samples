//
//  RentalItemListTableViewController.m
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/26.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "RentalItemListTableViewController.h"
#import "Item.h"
#import "ItemManager.h"

@interface RentalItemListTableViewController ()

@end

@implementation RentalItemListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    //_wishItems = [[ItemManager sharedManager] wishItems];
    
    [super viewWillAppear:animated];
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
    NSArray *wishItems = [ItemManager sharedManager].wishItems;
    NSArray *shareItems = [ItemManager sharedManager].shareItems;
    if (ItemPresenTypeMaster == _presenType && wishItems.count > 0) {
        numberOfRows = wishItems.count;
    } else if (ItemPresenTypeOwn == _presenType && shareItems.count > 0) {
        numberOfRows = shareItems.count;
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *listTitle = @"レンタル機能用";
    if (ItemPresenTypeMaster == _presenType) {
        listTitle = @"ウィッシュリスト";
    } else if (ItemPresenTypeOwn == _presenType) {
        listTitle =  @"貸出アイテム";
    }
    return listTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
    if (ItemPresenTypeMaster == _presenType) {
        NSArray *wishItems = [ItemManager sharedManager].wishItems;
        if (wishItems.count > 0) {
            Item *wishItem = [wishItems objectAtIndex:indexPath.row];
            cell.textLabel.text = wishItem.itemName;
            cell.imageView.image = wishItem.itemIcon;
        } else {
            cell.textLabel.text = @"登録無し";
            cell.imageView.image = nil;
        }
    } else if (ItemPresenTypeOwn == _presenType) {
            NSArray *shareItems = [ItemManager sharedManager].shareItems;
        if (shareItems.count > 0) {
            Item *shareItem = [shareItems objectAtIndex:indexPath.row];
            cell.textLabel.text = shareItem.itemName;
            cell.imageView.image = shareItem.itemIcon;
        }else {
            cell.textLabel.text = @"登録無し";
            cell.imageView.image = nil;
        }
    }
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (ItemPresenTypeMaster == _presenType) {
        if ([ItemManager sharedManager].wishItems.count > 0) {
            return YES;
        }
    } else if (ItemPresenTypeOwn == _presenType) {
        if ([ItemManager sharedManager].shareItems.count > 0) {
            return YES;
        }
    }
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ItemManager *itemManager =[ItemManager sharedManager];
        if (ItemPresenTypeMaster == _presenType) {
            Item *theItem = [[ItemManager sharedManager].wishItems objectAtIndex:indexPath.row];
            [itemManager removeFromWishList:theItem];
            if ([ItemManager sharedManager].wishItems.count > 0) {
                // Delete the row from the data source
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [tableView reloadData];
            }
        } else if (ItemPresenTypeOwn == _presenType) {
            Item *theItem = [[ItemManager sharedManager].shareItems objectAtIndex:indexPath.row];
            [itemManager removeFromShareList:theItem];
            if ([ItemManager sharedManager].wishItems.count > 0) {
                // Delete the row from the data source
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            } else {
                [tableView reloadData];
            }
        }
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
