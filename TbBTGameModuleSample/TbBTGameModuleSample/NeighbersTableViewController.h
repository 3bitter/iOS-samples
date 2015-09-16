//
//  NeighbersTableViewController.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface NeighbersTableViewController : UITableViewController

@property (strong, nonatomic) UILabel *descriptionLabel;

@property (copy, nonatomic) NSArray *neighberBeaconOwners;

@end
