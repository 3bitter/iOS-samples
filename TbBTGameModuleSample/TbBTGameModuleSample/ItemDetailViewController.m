//
//  ItemDetailViewController.m
//  SharedItemEncounters
//
//  Created by Takefumi Ueda on 2015/05/26.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "ItemDetailViewController.h"
#import "ItemManagementViewController.h"
#import "ItemManager.h"
#import "BaseItemListViewController.h"
#import "AppDelegate.h"

@interface ItemDetailViewController ()

@end

extern NSString *kBTFuncUsing;
extern NSString *kMyItemAdded;
extern NSString *kItemAdditionFailed;
extern NSString *kMainItemChanged;
extern NSString *kMainChangeFailed;

@implementation ItemDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    assert(_theItem);
    _itemNameLabel.text = _theItem.itemName;
    _itemImageView.image = _theItem.itemIcon;
    _explanationLabel.text = _theItem.explanation;
    NSString *rankDescription = [@"ランク" stringByAppendingFormat:@"%lu", (unsigned long)_theItem.itemRank];
    _itemRankLabel.text = rankDescription;
    
    _acceptButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_acceptButton setTitle:@"このアイテムをゲットする" forState:UIControlStateNormal];
     _acceptButton.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_acceptButton addTarget:self action:@selector(acceptButtonDidPush) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_presenType == ItemPresenTypeOwn) {
        _useButton.hidden = NO;
        if (_theItem.usingInGame) {
            [_useButton setTitle:@"バトル使用中" forState:UIControlStateNormal];
            _useButton.enabled = NO;
        }
    }
    if (!_theItem.main && _presenType == ItemPresenTypeOwn) {
        _mainButton.hidden = NO;
    }
    // すれ違いゲット機能専用ボタン
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    BOOL useBTFunction = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    if (useBTFunction) {
        if (ItemPresenTypeShared == _presenType) {
            [_baseView addSubview:_acceptButton];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
 
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
     BOOL useBTFunction = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    if (useBTFunction) {
        switch(_presenType) {
            case ItemPresenTypeMaster:
                break;
            case ItemPresenTypeOwn:
                  break;
            case ItemPresenTypeShared: // すれ違いゲット機能専用
            {
                CGFloat acceptButtonPositionY = _baseView.bounds.size.height - 40.0;
                _acceptButton.frame = CGRectMake(50.0, acceptButtonPositionY, 200.0, 40.0);
                
                CGRect conditionFrame = CGRectMake(42.0, _baseView.bounds.size.height - 80.0, 230.0, 40.0);
                UILabel *conditionLabel = [[UILabel alloc] initWithFrame:conditionFrame];
                conditionLabel.numberOfLines = 2;
                conditionLabel.font = [UIFont systemFontOfSize:13.0];
                conditionLabel.textColor = [UIColor redColor];
                conditionLabel.text = @"このサンプルではアイテムを自分のものにできます";
                [_baseView addSubview:conditionLabel];
            }
                break;
            default:
                break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (ItemPresenTypeShared == _presenType) {
        if (_acceptButton.superview) {
            [_acceptButton removeFromSuperview];
        }
    }
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonDidPush:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)useButtonDidPush:(id)sender {
    [[ItemManager sharedManager] addToUseList:_theItem];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)mainButtonDidPush:(id)sender {
    ItemManager *itemManager = [ItemManager sharedManager];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishItemHandling) name:kMainItemChanged object:itemManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyFailureToUser) name:kMainChangeFailed object:itemManager];
    [itemManager setNewMainItem:_theItem];
    [self startIndicationWithMessage:@"切り替えています.."];
}

- (void)acceptButtonDidPush {
    ItemManager *itemManager = [ItemManager sharedManager];
    if ([itemManager isInMyItems:_theItem]) { // Unexpected case. (Data may be unexpected on server)
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"お知らせ" message:@"このアイテムはすでに所持していますね..." preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:@"O.K." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
    } else {
         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishItemHandling) name:kMyItemAdded object:itemManager];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyFailureToUser) name:kItemAdditionFailed object:itemManager];
        _acceptButton.enabled = NO;
        [self startIndicationWithMessage:@"ゲット手続き中です..."];
        [itemManager addAndPersistMyItem:_theItem];
    }
}

- (void)finishItemHandling {
    [self performSelectorOnMainThread:@selector(dismissInteractionViews) withObject:nil waitUntilDone:NO];
}

- (void)dismissInteractionViews {
    [self stopIndication];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)notifyFailureToUser {
    [self performSelectorOnMainThread:@selector(showFailureAlert) withObject:nil waitUntilDone:YES];
}

- (void)showFailureAlert {
    [self stopIndication];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"エラー" message:@"申し訳ありません。処理に失敗してしまいました" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"許す" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)startIndicationWithMessage:(NSString *)message {
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.frame = CGRectMake(0.0, 0.0, 120.0, 120.0);
    _indicator.backgroundColor = [UIColor grayColor];
    _indicator.color = [UIColor whiteColor];
    _indicator.center = self.view.center;
    CGRect descLabelFrame = CGRectMake(10.0, 90.0, 100.0, 30.0);
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:descLabelFrame];
    descriptionLabel.numberOfLines = 2;
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.font = [UIFont systemFontOfSize:12.0];
    descriptionLabel.text = message;
    [_indicator addSubview:descriptionLabel];
    [self.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)stopIndication {
    if (_indicator) {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
        _indicator = nil;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
