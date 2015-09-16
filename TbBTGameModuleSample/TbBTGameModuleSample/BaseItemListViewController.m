//
//  BaseItemListViewController.m
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/26.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "BaseItemListViewController.h"
#import "ItemManager.h"
#import "ItemDetailViewController.h"

@interface BaseItemListViewController ()

@property (copy, nonatomic) NSArray *allItems;
@property (copy, nonatomic) NSArray *myItems;

@end

@implementation BaseItemListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ItemManager *itemManager = [ItemManager sharedManager];
    _allItems = itemManager.allItems;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ItemManager *itemManager = [ItemManager sharedManager];
    _myItems = [itemManager myItems];
    [self.tableView reloadData];
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
    NSInteger numOfItems = 0;
    if (ItemPresenTypeMaster == _presenType) {
        numOfItems = _allItems.count;
    } else if (ItemPresenTypeOwn == _presenType) {
        numOfItems = _myItems.count;
    }
    return numOfItems;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (ItemPresenTypeMaster == _presenType) {
        return @"アイテム図鑑 （ゲットしたアイテムのみ表示されます）";
    } else if (ItemPresenTypeOwn) {
        return @"所有しているアイテム";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
    if (cell.imageView.subviews.count > 0) {
        for (UIView  *subView in cell.imageView.subviews) {
            [subView removeFromSuperview];
        }
    }
    switch (_presenType) {
        case ItemPresenTypeOwn:
            if (_myItems.count > 0) {
                Item *item = [_myItems objectAtIndex:indexPath.row];
                cell.imageView.image = item.itemIcon;
                UIImage *selectedIcon = [UIImage imageNamed:@"weapon_choise"];
                UIImageView *selectedIconView = [[UIImageView alloc] initWithImage:selectedIcon];
                selectedIconView.image = selectedIcon;
                if (item.usingInGame) {
                    [cell.imageView addSubview:selectedIconView];
                    selectedIconView.frame = CGRectMake(28.0, 0.0, 16.0, 16.0);
                }
                NSMutableString *cellText = [NSMutableString stringWithFormat:@"[No.%@] ", item.itemID];
                [cellText appendString:item.itemName];
                cell.textLabel.text = cellText;
                if (item.main) {
                    UIImageView *mainItemView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main"]];
                    cell.accessoryView = mainItemView;
                } else {
                    cell.accessoryView = nil;
                }
            }
            break;
        case ItemPresenTypeMaster:
            if (_allItems.count > 0) {
                Item *item = [_allItems objectAtIndex:indexPath.row];
                if ([[ItemManager sharedManager] isInMyItems:item]) {
                    cell.imageView.image = item.itemIcon;
                    NSMutableString *cellText = [NSMutableString stringWithFormat:@"[No.%@] ", item.itemID];
                    [cellText appendString:item.itemName];
                    [cellText appendString:@"　(ランク"];
                    [cellText appendString:[NSString stringWithFormat:@"%lu", (unsigned long)item.itemRank]];
                    [cellText appendString:@")"];
                    cell.textLabel.text = cellText;
                } else {
                    cell.imageView.image = [UIImage imageNamed:@"secret"];
                    cell.textLabel.text = @"Unknown";
                }
            }
            cell.accessoryView = nil;
            break;
               default:
            break;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        // Show detail view with use command
    ItemDetailViewController *detailVC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"ItemDetailViewController"];
    switch (_presenType) {
        case ItemPresenTypeMaster:
        {
            Item *target = [_allItems objectAtIndex:indexPath.row];
            if ([[ItemManager sharedManager] isInMyItems:target]) {
                detailVC.theItem = target;
                detailVC.presenType = ItemPresenTypeMaster;
                detailVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentViewController:detailVC animated:YES completion:nil];
            }
            break;
        }
        case ItemPresenTypeOwn:
             detailVC.theItem = [_myItems objectAtIndex:indexPath.row];
            detailVC.presenType = ItemPresenTypeOwn;
            detailVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:detailVC animated:YES completion:nil];
            break;
        default:
            break;
    }
}

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

@end
