//
//  AdvertiseViewController.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/09/02.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TbBTBeaconizer.h"

@interface AdvertiseViewController : UIViewController<TbBTBeaconizerDelegate>

@property (strong, nonatomic) TbBTBeaconizer *btBeaconizer;

@property (weak, nonatomic) IBOutlet UISwitch *activateSwitch;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *regionIDLabel;

- (IBAction)activateSwitchDidSwitch:(id)sender;

@end
