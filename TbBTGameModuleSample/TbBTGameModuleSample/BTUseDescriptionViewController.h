//
//  BTUseDescriptionViewController.h
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/05/06.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTServiceFacade.h"

@interface BTUseDescriptionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIScrollView *guideView;

- (IBAction)closeButtonDidPush:(id)sender;

@end
