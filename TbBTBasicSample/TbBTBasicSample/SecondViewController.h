//
//  SecondViewController.h
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TbBTManager.h"

#import "TbBTAgreementViewController.h"


@interface SecondViewController : UIViewController<CLLocationManagerDelegate, TbBTManagerDelegate, TbBTAgreementViewControllerDelegate>

@property (strong, nonatomic) CLLocationManager *appLocManager;
@property (strong, nonatomic) TbBTManager *btManager;
// ビーコン機能使用規約同意／未同意フラグ
@property (assign, nonatomic) BOOL monitoringAndSDKServiceAgreed;
@property (assign, nonatomic) BOOL monitoringAndSDKServiceDisagreed;

@property (weak, nonatomic) IBOutlet UISwitch *beaconFunctionSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *targetMonitoringSwitch;
@property (weak, nonatomic) IBOutlet UILabel *stateDescriptionLabel;

- (IBAction)beaconFunctionSwitched:(id)sender;
- (IBAction)targetMonitoringChanged:(id)sender;

@end

