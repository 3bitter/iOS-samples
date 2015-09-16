//
//  OptionsTableViewController.m
//  TbBTGameModuleSample
//
//  Created by Ueda on 2015/08/16.
//  Copyright (c) 2015年 3bitter.com. All rights reserved.
//

#import "OptionsTableViewController.h"
#import "BTUseDescriptionViewController.h"
#import "BTFunctionSettingsViewController.h"

@interface OptionsTableViewController ()

@end

static NSString *cellIdentifier = @"OptionsCell";

@implementation OptionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"help1"];
    cell.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showDescriptionView:)];
    
    tapGesture1.numberOfTapsRequired = 1;
     [tapGesture1 setDelegate:self];
    [cell.imageView addGestureRecognizer:tapGesture1];
    cell.textLabel.text = @"すれ違いゲット";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        BTFunctionSettingsViewController *btSettingsVC = [self.view.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"BTFunctionSettingsViewController"];
        [self.navigationController pushViewController:btSettingsVC animated:YES];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)showDescriptionView:(id)sender {
    BTUseDescriptionViewController *descriptionVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"BTUseDescriptionViewController"];
    descriptionVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    descriptionVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:descriptionVC animated:YES completion:nil];
                                                     
}


@end
