//
//  ItemManagementViewController.m
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/25.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "ItemManagementViewController.h"
#import "BaseItemListViewController.h"
#import "ItemManager.h"

@interface ItemManagementViewController ()

@end

@implementation ItemManagementViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    assert(_itemSegmentControl);
    _itemSegmentControl.frame = CGRectMake(20.0, 40.0, 200.0, 50.0);
    _itemSegmentControl.selectedSegmentIndex = 0;
    [_itemSegmentControl addTarget:self action:@selector(itemSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_itemSegmentControl];
   
    _explanationLabel.text = @"アイテムの一覧です";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *nickName = [userDefaults objectForKey:@"nickName"];
    _nickNameLabel.text = nickName;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)itemSegmentChanged:(id)sender {
    BaseItemListViewController *baseItemListVC = [self.childViewControllers objectAtIndex:0];
    switch (_itemSegmentControl.selectedSegmentIndex) {
        case 0:
            _explanationLabel.text = @"自分のアイテムから選択します";
            baseItemListVC.presenType = ItemPresenTypeOwn;
            [baseItemListVC.tableView reloadData];
            break;
        case 1:
             _explanationLabel.text = @"アイテム図鑑を確認します";
            baseItemListVC.presenType = ItemPresenTypeMaster;
            [baseItemListVC.tableView reloadData];
            break;
        default:
            break;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    switch (_itemSegmentControl.selectedSegmentIndex) {
        case 0:
            if ([segue.identifier isEqualToString:@"BaseItemListSegue"]) {
                ((BaseItemListViewController *)[segue destinationViewController]).presenType = ItemPresenTypeOwn;
            }
            break;
        case 1:
            if ([segue.identifier isEqualToString:@"BaseItemListSegue"]) {
                ((BaseItemListViewController *)[segue destinationViewController]).presenType = ItemPresenTypeMaster;
            }
            break;
        default:
            break;
    }
}
@end
