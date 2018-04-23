//
//  RangedBeaconInfoViewController.h
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RangedBeaconInfoViewController : UITableViewController

// 領域情報
@property (strong, nonatomic) CLBeaconRegion *theRegion;
// SDKを介して取得したビーコン情報
@property (strong, nonatomic) NSMutableArray *tbBTBeaconInfos;
// ユーザに選択されたビーコンの情報
@property (strong, nonatomic) NSMutableArray *selectedInfos;

@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *cancelButton;

- (void)selectOwnBeacons:(NSArray *)beaconInfos;

@end
