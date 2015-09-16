//
//  DesignatedBeaconsViewController.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/05/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RangedBeaconInfoViewController.h"

@interface DesignatedBeaconsViewController : UITableViewController

// For size control
@property (weak, nonatomic) IBOutlet UIView *customHeaderView;
@property (weak, nonatomic) IBOutlet UIButton *registButton;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) RangedBeaconInfoViewController *rangedBeaconVC;

- (IBAction)registerButtonDidPush:(id)sender;

@end
