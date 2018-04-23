//
//  ItemViewController.h
//  TbBTBasicSample
//
//  Created by Takefumi Ueda on 2015/07/08.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemViewController : UIViewController

@property (strong, nonatomic) UIImage *selectedItemImage;
@property (weak, nonatomic) IBOutlet UIImageView *itemImageView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end
