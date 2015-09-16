//
//  RangedBeaconInfoViewController.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/01.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RangedBeaconInfoViewController : UITableViewController

@property (strong, nonatomic) CLBeaconRegion *theRegion;
@property (strong, nonatomic) NSMutableArray *tbBTBeaconInfos;
@property (strong, nonatomic) NSMutableArray *selectedInfos;

@property (strong, nonatomic) UIActivityIndicatorView *indicator;

@end
