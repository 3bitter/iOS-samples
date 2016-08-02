//
//  StartUpViewController.h
//  TbBLTBasicSample
//
//  Created by Ueda on 2016/03/02.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartUpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startButton;

- (IBAction)startButtonDidPush:(id)sender;

@end
