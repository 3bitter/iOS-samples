//
//  RangedBeaconInfoViewController.h
//  TbBTSDKBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RangedBeaconInfoViewController : UITableViewController

@property (strong, nonatomic) CLLocationManager *appLocManager;
@property (strong, nonatomic) CLBeaconRegion *theRegion;
@property (strong, nonatomic) NSMutableArray *tbBTBeaconInfos;
@property (strong, nonatomic) NSMutableArray *selectedInfos;

- (void)selectOwnBeacons:(NSArray *)beaconInfos;

@end
