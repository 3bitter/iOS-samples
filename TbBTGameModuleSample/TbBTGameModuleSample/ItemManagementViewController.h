//
//  ItemManagementViewController.h
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/25.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemManagementViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *itemSegmentControl;

- (IBAction)itemSegmentChanged:(id)sender;

@end
