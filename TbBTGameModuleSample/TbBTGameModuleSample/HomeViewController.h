//
//  HomeViewController.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *monitoringLabel;

@property (weak, nonatomic) IBOutlet UIButton *attackButton;

@property (weak, nonatomic) IBOutlet UIImageView *usingItemView1;
@property (weak, nonatomic) IBOutlet UIImageView *usingItemView2;
@property (weak, nonatomic) IBOutlet UIImageView *usingItemView3;

@property (weak, nonatomic) IBOutlet UIImageView *weapon;
@property (weak, nonatomic) IBOutlet UIImageView *enemy;

@property (weak, nonatomic) IBOutlet UIImageView *fukidasiView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@property (weak, nonatomic) IBOutlet UILabel *damageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *explosionView;
@property (weak, nonatomic) IBOutlet UILabel *clearLabel;

@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;

@property (strong, nonatomic) IBOutlet UIButton *helpButton;

- (IBAction)attackButtonDidPush:(id)sender;

@end



