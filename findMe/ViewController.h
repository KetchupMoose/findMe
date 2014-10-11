//
//  ViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface ViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MBProgressHUDDelegate>
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak,nonatomic) IBOutlet UITableView *casesTableView;
-(IBAction)newCase:(id)sender;


@end
