//
//  BeaconUserInfoCell.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/07/31.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeaconUserInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityLabel;
@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;

@end
