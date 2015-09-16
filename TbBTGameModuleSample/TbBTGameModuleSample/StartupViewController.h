//
//  StartupViewController.h
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefaultServerClient.h"

@interface StartupViewController : UIViewController<DefaultServerClientDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nickNameField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *requirementLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) UIProgressView *progress;

- (IBAction)startButtonDidPush:(id)sender;
- (IBAction)closeButtonDidPush:(id)sender;

- (IBAction)dismissKeyboard:(id)sender;

@end
