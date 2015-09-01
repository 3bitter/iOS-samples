//
//  DesignatedBeaconsViewController.h
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RangedBeaconInfoViewController.h"

@interface DesignatedBeaconsViewController : UITableViewController

@property (strong, nonatomic) CLLocationManager *appLocManager;
@property (strong, nonatomic) NSMutableArray *designatedBeaconInfos;
@property (strong, nonatomic) UIButton *registButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

@property (strong, nonatomic) RangedBeaconInfoViewController *rangedBeaconVC;


- (void)startSearchIndication;
- (void)stopSearchIndication;

@end
