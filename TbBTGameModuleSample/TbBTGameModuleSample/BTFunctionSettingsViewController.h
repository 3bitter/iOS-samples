//
//  BTFunctionSettingsViewController.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/10.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface BTFunctionSettingsViewController : UITableViewController

@property (strong, nonatomic) NSMutableDictionary *settings;
@property (weak, nonatomic) IBOutlet UISwitch *btFunctionSwitch;

- (IBAction)functionUseSwitched:(id)sender;

@end
