//
//  SharableItemsViewController.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/20.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharableItemsViewController : UIViewController

@property (copy, nonatomic) NSArray *sharableItems;
@property (weak, nonatomic) UIView *containerView;

@end
