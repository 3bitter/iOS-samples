//
//  AppAgreementViewController.h
//  TbBTBasicSample
//
//  Created by Ueda on 2017/04/11.
//  Copyright © 2017年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppAgreementViewControllerDelegate;

@interface AppAgreementViewController : UIViewController

@property (weak, nonatomic) id<AppAgreementViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (weak, nonatomic) IBOutlet UIButton *disagreeButton;

- (IBAction)agreeButtonDisPush:(id)sender;
- (IBAction)disagreeButtonDidPush:(id)sender;

@end

@protocol AppAgreementViewControllerDelegate <NSObject>

- (void)didAgreeByUser;
- (void)didDisagreeByUser;

@end
