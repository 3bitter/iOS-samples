//
//  SampleSettingViewController.h
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2017年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SampleSettingViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *monitoringSwitch;

- (IBAction)monitoringSwitchDidChange:(id)sender;

@end
