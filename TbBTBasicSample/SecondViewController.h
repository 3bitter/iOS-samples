//
//  SecondViewController.h
//  TbBTSDKUseSample3
//
//  Created by Takefumi Ueda on 2015/03/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TbBTManager.h"

#import "TbBTAgreementViewController.h"


@interface SecondViewController : UIViewController<CLLocationManagerDelegate, TbBTManagerDelegate>

@property (strong, nonatomic) CLLocationManager *myLocManager;
@property (strong, nonatomic) TbBTManager *btManager;
@property (assign, nonatomic) BOOL monitoringAndSDKServiceAgreed;
@property (assign, nonatomic) BOOL monitoringAndSDKServiceDisagreed;

@property (strong, nonatomic) UIButton *updateRegionButton;
@property (strong, nonatomic) UILabel *stateDescriptionLabel;

@property (assign, nonatomic) BOOL addProcessing;

- (void)updateRegionButtonDidPushed:(id)sender;

- (void)showBeaconDesignateViewWithCodes:(NSArray *)beaconDatas forRegion:(CLBeaconRegion *)region;

@end

