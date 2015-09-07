//
//  TbBTAgreementViewController.h
//  TbBTSDK
//
//  Created by Takefumi Ueda on 2014/11/01.
//  Copyright (c) 2014年 3bitter, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TbBTAgreementViewControllerDelegate;

@interface TbBTAgreementViewController : UIViewController

@property (weak, nonatomic) id<TbBTAgreementViewControllerDelegate> delegateVC;
@property (assign, nonatomic) BOOL allowed;
@property (copy, nonatomic, readonly) NSString *bodyString;
@property (strong, nonatomic) UIView *baseView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UITextView *contentView;
@property (strong, nonatomic) UIButton *agreeButton;
@property (strong, nonatomic) UIButton *nonAgreeButton;

- (id)initWithTextData:(NSData *)text;

@end

@protocol TbBTAgreementViewControllerDelegate <NSObject>

- (void)didAgreeByUser;
- (void)didDisagreeByUser;

@end
