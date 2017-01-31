//
//  DungeonsViewController.h
//  TbSWAMPSample
//
//  Created by Ueda on 2017/01/30.
//  Copyright © 2016年 3bitter Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DungeonsViewController : UITableViewController

@property (copy, nonatomic) NSArray *limitedContents;

/* [サンプル専用] シンプル化のためユーザーパーミッションの状態をスキップするためのフラグ */
@property (assign, nonatomic) BOOL ignoreUserSettings;

@end
