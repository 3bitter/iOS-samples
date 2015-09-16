//
//  DiscoveredItemsViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/18.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "DiscoveredItemsViewController.h"
#import "Item.h"
#import "ItemDetailViewController.h"
#import "SharableItemsViewController.h"

@interface DiscoveredItemsViewController ()<UIGestureRecognizerDelegate>

@property (assign, nonatomic) NSUInteger checkedCount;

@end

@implementation DiscoveredItemsViewController

static NSString * const reuseIdentifier = @"ItemCollectionCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _discoveredItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    Item *anItem = [_discoveredItems objectAtIndex:indexPath.row];
    CGRect imageRect = CGRectMake(0.0, 0.0, 57.0, 57.0);
    UIGraphicsBeginImageContext(imageRect.size);
    [anItem.itemIcon drawInRect:imageRect];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [cell.contentView addSubview:[[UIImageView alloc] initWithImage:thumbnail]];
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ItemDetailViewController *itemDetailVC = [storyBoard instantiateViewControllerWithIdentifier:@"ItemDetailViewController"];
    itemDetailVC.theItem = [_discoveredItems objectAtIndex:indexPath.row];
    itemDetailVC.presenType = ItemPresenTypeShared;
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [[cell.contentView.subviews objectAtIndex:0] removeFromSuperview];
    [cell.contentView addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checked"]]];
    [self presentViewController:itemDetailVC animated:YES completion:nil];
    _checkedCount++;
    if (_discoveredItems.count == _checkedCount) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(finishGetItems)];
        
        tapGesture.numberOfTapsRequired = 1;
        [tapGesture setDelegate:self];
        
        [self.view addGestureRecognizer:tapGesture];
        
        UILabel *guideLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 30.0)];
        guideLabel.backgroundColor = [UIColor whiteColor];
        guideLabel.textColor = [UIColor blueColor];
        guideLabel.font = [UIFont systemFontOfSize:13.0];
        guideLabel.text = @"Tap view to close";
        guideLabel.textAlignment = NSTextAlignmentCenter;
        guideLabel.center = self.view.center;
        [self.view addSubview:guideLabel];
    }
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (void)finishGetItems {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
