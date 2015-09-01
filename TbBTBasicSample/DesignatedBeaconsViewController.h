//
//  DesignatedBeaconsViewController.h
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/19.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface DesignatedBeaconsViewController : UITableViewController

@property (assign, nonatomic) id delegate;
@property (strong, nonatomic) CLLocationManager *appLocManager;
@property (strong, nonatomic) NSMutableArray *designatedBeaconInfos;

@end
