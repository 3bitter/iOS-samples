//
//  ItemDetailViewController.h
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/26.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Item.h"

@interface ItemDetailViewController : UIViewController

@property (strong, nonatomic) Item *theItem;
@property (assign, nonatomic) ItemPresenType presenType;
@property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemRankLabel;
@property (weak, nonatomic) IBOutlet UIImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;

@property (strong, nonatomic) UIButton *acceptButton;

@property (strong, nonatomic) UILabel *conditionLabel;

@property (weak, nonatomic) IBOutlet UIButton *useButton;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;


- (IBAction)closeButtonDidPush:(id)sender;
- (IBAction)useButtonDidPush:(id)sender;
- (IBAction)mainButtonDidPush:(id)sender;

@end
