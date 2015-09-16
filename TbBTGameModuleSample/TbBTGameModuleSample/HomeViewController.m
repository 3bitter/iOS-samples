//
//  HomeViewController.m
//  TbBTGameModuleSample
//
//  Created by Takefumi Ueda on 2015/07/09.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import <QuartzCore/CAAnimation.h>
#import "HomeViewController.h"
#import "OptionsTableViewController.h"
#import "ItemManagementViewController.h"
#import "AppDelegate.h"
#import "Item.h"
#import "ItemManager.h"
#import "DiscoveredItemsViewController.h"
#import "SharableItemsViewController.h"
#import "ItemDetailViewController.h"
#import "StartupViewController.h"

@interface HomeViewController ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) Item *weaponItem;
@property (assign, nonatomic) CGPoint weaponOrigin;
@property (assign, nonatomic) NSInteger enemyHP;
@property (strong, nonatomic) UITapGestureRecognizer *viewTapRecognizer;
@property (assign, nonatomic) BOOL cleared;

- (void)attackedEnemy;

@end

NSString *kReadyToUse = @"ReadyToUse";
extern NSString *kBTFuncUsing;
extern NSString *kItemCheckType;
extern NSString *kSharedItem;
extern NSString *kContactNotificationTapped;

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ((AppDelegate *)[UIApplication sharedApplication].delegate).playing = YES;
    _cleared = NO;
    
    NSUserDefaults *userDefaluts = [NSUserDefaults standardUserDefaults];
    NSString *nickName = [userDefaluts objectForKey:@"nickName"];
    if (nickName) {
        _nickNameLabel.text = nickName;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 初期導入用の表示
    ItemManager *itemManager = [ItemManager sharedManager];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL readyToUse = [[userDefaults valueForKey:kReadyToUse] boolValue];
    if (!readyToUse) {
        return;
    }
    if (itemManager.allItems.count == 0) {
        [userDefaults setValue:[NSNumber numberWithBool:NO] forKey:kReadyToUse];
        [userDefaults synchronize];
        return;
    }
    
    /* すれ違い機能有効時に表示されるラベル */
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;    
    BOOL btFuncOn = [[appDelegate.currentSettings valueForKey:kBTFuncUsing] boolValue];
    BTServiceFacade *btFacade = [BTServiceFacade sharedFacade];
    // Double check, just in case
    BOOL reallyMonitoring = NO;
    if (btFacade && [btFacade isTargetMonitoring]) {
        reallyMonitoring = YES;
    }
    
    if (btFuncOn && reallyMonitoring) {
        _monitoringLabel.hidden = NO;
    } else {
        _monitoringLabel.hidden = YES;
    }

    NSArray *usingItems = [itemManager usingItems];
    if (usingItems.count > 0) {
        UIImage *baseImage = ((Item *)[usingItems objectAtIndex:0]).itemIcon;
        // Create thumbnail
        CGRect imageRect = CGRectMake(0.0, 0.0, 57.0, 57.0);
        UIGraphicsBeginImageContext(imageRect.size);
        [baseImage drawInRect:imageRect];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _usingItemView1.image = thumbnail;
        UITapGestureRecognizer *tapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usingItem1ButtonDidPush:)];
        
        tapGesture1.numberOfTapsRequired = 1;
        
        [tapGesture1 setDelegate:self];
            
        [_usingItemView1 addGestureRecognizer:tapGesture1];
    }
    if (usingItems.count > 1) {
        UIImage *baseImage = ((Item *)[usingItems objectAtIndex:1]).itemIcon;
        // Create thumbnail
        CGRect imageRect = CGRectMake(0.0, 0.0, 57.0, 57.0);
        UIGraphicsBeginImageContext(imageRect.size);
        [baseImage drawInRect:imageRect];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _usingItemView2.image = thumbnail;
        UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usingItem2ButtonDidPush:)];
            
        tapGesture2.numberOfTapsRequired = 1;
            
        [tapGesture2 setDelegate:self];
            
        [_usingItemView2 addGestureRecognizer:tapGesture2];
    }
    if (usingItems.count > 2) {
        UIImage *baseImage = ((Item *)[usingItems objectAtIndex:2]).itemIcon;
        // Create thumbnail
        CGRect imageRect = CGRectMake(0.0, 0.0, 57.0, 57.0);
        UIGraphicsBeginImageContext(imageRect.size);
        [baseImage drawInRect:imageRect];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        _usingItemView3.image = thumbnail;
        UITapGestureRecognizer *tapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usingItem3ButtonDidPush:)];
            
        tapGesture3.numberOfTapsRequired = 1;
            
        [tapGesture3 setDelegate:self];
            
        [_usingItemView3 addGestureRecognizer:tapGesture3];
    }
    _weaponItem = [usingItems objectAtIndex:0];
    _weapon.image = _usingItemView1.image;
    [self highleightSelectedItemAtIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSharedItemView:) name:kContactNotificationTapped object:nil];
    
    [self generateEnemyHP];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL readyToUse = [[[NSUserDefaults standardUserDefaults] valueForKey:kReadyToUse] boolValue];
    if (!readyToUse) {
        StartupViewController *startupVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"StartupViewController"];
        [self presentViewController:startupVC animated:YES completion:nil];
        return;
    }
    CGFloat weaponX = _attackButton.frame.origin.x + _attackButton.frame.size.width + _weapon.bounds.size.width;
    _weaponOrigin = CGPointMake(weaponX, _attackButton.frame.origin.y);
    _weapon.center = _weaponOrigin;
    _weapon.hidden = YES;
    
    _attackButton.userInteractionEnabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _explosionView.hidden = YES;
    _damageLabel.hidden = YES;
    _fukidasiView.hidden = YES;
    _commentLabel.hidden = YES;
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showSharedItemView:(NSNotification *)notification {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BTItemCheckType checkType = [[notification.userInfo valueForKey:kItemCheckType] integerValue];
    if (checkType == BTItemCheckTypeSingleBeacon) {
        NSDictionary *sharedItemDict = [notification.userInfo objectForKey:kSharedItem];
        NSString *theItemID = [sharedItemDict objectForKey:@"itemID"];
        Item *sharedItem = [[ItemManager sharedManager] itemOfTheID:theItemID];
        sharedItem.main = NO;
        ItemDetailViewController *itemDetailVC = [storyBoard instantiateViewControllerWithIdentifier:@"ItemDetailViewController"];
        itemDetailVC.theItem = sharedItem;
        itemDetailVC.presenType = ItemPresenTypeShared;
        [self presentViewController:itemDetailVC animated:YES completion:nil];
    } else if (checkType == BTItemCheckTypeMultipleBeacon) {
        NSArray *sharedItemsDict = [notification.userInfo objectForKey:kSharedItem];
        NSMutableArray *discoveredItems = [NSMutableArray array];
        assert(sharedItemsDict);
        for (NSDictionary *itemDict in sharedItemsDict) {
            assert([itemDict isKindOfClass:[NSDictionary class]]);
            NSString *theItemID = [itemDict objectForKey:@"itemID"];
            Item *sharedItem = [[ItemManager sharedManager] itemOfTheID:theItemID];
            sharedItem.main = NO;
            [discoveredItems addObject:sharedItem];
        }
        SharableItemsViewController *sharableItemsVC = [storyBoard instantiateViewControllerWithIdentifier:@"SharableItemsViewController"];
        sharableItemsVC.sharableItems = [NSArray arrayWithArray:discoveredItems];
        [self presentViewController:sharableItemsVC animated:YES completion:nil];
    }
}


- (void)usingItem1ButtonDidPush:(id)sender {
    [self clearAttackEffect];
    
    NSArray *usingItems = [ItemManager sharedManager].usingItems;
    _weaponItem = [usingItems objectAtIndex:0];
    _weapon.image = _usingItemView1.image;
    
    [self highleightSelectedItemAtIndex:0];
}

- (void)usingItem2ButtonDidPush:(id)sender {
    [self clearAttackEffect];
    
    NSArray *usingItems = [ItemManager sharedManager].usingItems;
    _weaponItem = [usingItems objectAtIndex:1];
    _weapon.image = _usingItemView2.image;
    
    [self highleightSelectedItemAtIndex:1];
}

- (void)usingItem3ButtonDidPush:(id)sender {
    [self clearAttackEffect];
    
    NSArray *usingItems = [ItemManager sharedManager].usingItems;
    _weaponItem = [usingItems objectAtIndex:2];
    _weapon.image = _usingItemView3.image;
    
    [self highleightSelectedItemAtIndex:2];
}

- (void)highleightSelectedItemAtIndex:(NSUInteger)usingItemIndex {
    UIImage *choise = [UIImage imageNamed:@"weapon_choise"];
    UIImageView *choiseView = [[UIImageView alloc] initWithImage:choise];
    choiseView.frame = CGRectMake(0.0, 0.0, choise.size.width, choise.size.height);
    
    CGPoint itemViewCenter = CGPointZero;
    CGRect highlightedItemViewRect = CGRectNull;
    [self resetToDefaultItemView];
    switch (usingItemIndex) {
        case 0:
             itemViewCenter = _usingItemView1.center;
             highlightedItemViewRect = CGRectMake(itemViewCenter.x - 32.0, itemViewCenter.y - 32.0, 64.0, 64.0);
            _usingItemView1.frame = highlightedItemViewRect;
            _usingItemView1.image = [self drawHeighlightItemImage];
            [_usingItemView1 addSubview:choiseView];
            break;
        case 1:
            itemViewCenter = _usingItemView2.center;
            highlightedItemViewRect  = CGRectMake(itemViewCenter.x - 32.0, itemViewCenter.y - 32.0, 64.0, 64.0);
            _usingItemView2.frame = highlightedItemViewRect;
            _usingItemView2.image = [self drawHeighlightItemImage];
            [_usingItemView2 addSubview:choiseView];
            break;
        case 2:
            itemViewCenter = _usingItemView3.center;
            highlightedItemViewRect  = CGRectMake(itemViewCenter.x - 32.0, itemViewCenter.y - 32.0, 64.0, 64.0);
            _usingItemView3.frame = highlightedItemViewRect;
            _usingItemView3.image = [self drawHeighlightItemImage];
            [_usingItemView3 addSubview:choiseView];
            break;
        default:
            break;
    }
}

- (void)resetToDefaultItemView {
    CGPoint itemViewCenter = CGPointZero;
    CGRect defaultItemViewRect = CGRectNull;
    if (_usingItemView1.subviews) {
        for (UIView *subView in _usingItemView1.subviews) {
            [subView removeFromSuperview];
        }
    }
    itemViewCenter = _usingItemView1.center;
    defaultItemViewRect = CGRectMake(itemViewCenter.x - 28.5, itemViewCenter.y - 28.5, 57.0, 57.0);
    _usingItemView1.frame = defaultItemViewRect;
    itemViewCenter = _usingItemView2.center;
    defaultItemViewRect = CGRectMake(itemViewCenter.x - 28.5, itemViewCenter.y - 28.5, 57.0, 57.0);
    if (_usingItemView2.subviews) {
        for (UIView *subView in _usingItemView2.subviews) {
            [subView removeFromSuperview];
        }
    }
    _usingItemView2.frame = defaultItemViewRect;
    if (_usingItemView3.subviews) {
        for (UIView *subView in _usingItemView3.subviews) {
            [subView removeFromSuperview];
        }
    }
    itemViewCenter = _usingItemView3.center;
    defaultItemViewRect = CGRectMake(itemViewCenter.x - 28.5, itemViewCenter.y - 28.5, 57.0, 57.0);
    _usingItemView3.frame = defaultItemViewRect;
}

// Use _weapon.image
- (UIImage *)drawHeighlightItemImage {
    // Create thumbnail
    CGRect imageRect = CGRectMake(0.0, 0.0, 64.0, 64.0);
    UIGraphicsBeginImageContext(imageRect.size);
    [_weapon.image drawInRect:imageRect];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnail;
}

- (void)viewDidTap:(id)sender {
    [self clearAttackEffect];
}

- (void)attackButtonDidPush:(id)sender {
    ((AppDelegate *)[UIApplication sharedApplication].delegate).playing = YES;
    _attackButton.userInteractionEnabled = NO;
    [self clearAttackEffect];
    [self.view removeGestureRecognizer:_viewTapRecognizer];
 
    CGPoint target = CGPointMake(_enemy.center.x, _enemy.center.y);
    
    CABasicAnimation *attack = [CABasicAnimation animationWithKeyPath:@"position.y"];
    attack.delegate = self;
    attack.fromValue = [NSNumber numberWithInt:_weaponOrigin.y];
    attack.toValue = [NSNumber numberWithInt:target.y];
    attack.autoreverses = NO;
    attack.removedOnCompletion = NO;
    attack.repeatCount = 1;
    attack.fillMode = kCAFillModeForwards;
    _weapon.center = target;
    switch (_weaponItem.itemRank) {
        case 1:
            attack.duration = 2;
            break;
        case 2:
            attack.duration = 1.5;
            break;
        case 3:
            attack.duration = 1.0;
            break;
        case 4:
            attack.duration = 0.8;
            break;
        case 5:
            attack.duration = 0.5;
            break;
        default:
            attack.duration = 2;
            break;
    }
    [_weapon.layer addAnimation:attack forKey:@"position"];
    
    _helpButton.userInteractionEnabled = NO;
    _usingItemView1.userInteractionEnabled = NO;
    _usingItemView2.userInteractionEnabled = NO;
    _usingItemView3.userInteractionEnabled = NO;
}

- (void)attackedEnemy {
    [_weapon.layer removeAnimationForKey:@"position.y"];
    _weapon.hidden = YES;
    if (CGRectIntersectsRect(_weapon.frame, _enemy.frame)) {
        _fukidasiView.hidden = NO;
        _commentLabel.hidden = NO;
        _explosionView.hidden = NO;
        NSInteger damagePoint = 0;
        switch (_weaponItem.itemRank) {
            case 1:
                damagePoint = 10;
                break;
            case 2:
                damagePoint = 100;
                break;
            case 3:
                damagePoint = 1000;
                break;
            case 4:
                damagePoint = 10000;
                break;
            case 5:
                damagePoint = 50000;
                break;
            default:
                damagePoint = -10;
                break;
        }
        _enemyHP -= damagePoint;
        
        NSString *damageString = [NSString stringWithFormat:@"%ld", (long)damagePoint];
        _damageLabel.hidden = NO;
        _damageLabel.text = damageString;
        if (_enemyHP <= 0) {
            _cleared = YES;
            _commentLabel.text = @"ヤラレター";
            _enemy.image = [UIImage imageNamed:@"enemy1_defeated"];
            _clearLabel.hidden = NO;
        } else {
            _commentLabel.text = @"マダマダ。ボクは死にましぇん";
            _enemy.image = [UIImage imageNamed:@"enemy1_default"];
        }
        
        if (!_viewTapRecognizer) {
            _viewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidTap:)];
        }
        [self.view addGestureRecognizer:_viewTapRecognizer];
        _usingItemView1.userInteractionEnabled = YES;
        _usingItemView2.userInteractionEnabled = YES;
        _usingItemView3.userInteractionEnabled = YES;
        _helpButton.userInteractionEnabled = YES;
    }
}

- (void)generateEnemyHP {
    NSDate *currentTime = [NSDate date];
    NSCalendar *userCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [userCalendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:currentTime];
    NSUInteger randomPoint = ([components hour] + [components minute]) % 84;
    _enemyHP = 20000 + randomPoint;
}

- (void)clearAttackEffect {
    _explosionView.hidden = YES;
    _damageLabel.hidden = YES;
    _fukidasiView.hidden = YES;
    _commentLabel.hidden = YES;
    _clearLabel.hidden = YES;
    _enemy.image = [UIImage imageNamed:@"enemy1_default"];
    _weaponOrigin = CGPointMake(_enemy.center.x, _attackButton.frame.origin.y);
    _weapon.center = _weaponOrigin;
    _weapon.hidden = NO;
    
    if (_cleared) {
        _cleared = NO;
        
        [self generateEnemyHP];
    }
}

#pragma mark CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        [self attackedEnemy];
        ((AppDelegate *)[UIApplication sharedApplication].delegate).playing = NO;
        _attackButton.userInteractionEnabled = YES;
    }
}


@end
