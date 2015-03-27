//
//  ViewCasesViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "findMeBaseViewController.h"
@interface ViewCasesViewController : findMeBaseViewController <UITableViewDataSource,UITableViewDelegate,MBProgressHUDDelegate>

@property (weak,nonatomic) IBOutlet UITableView *casesTableView;
-(IBAction)newCase:(id)sender;
@property (strong,nonatomic) NSString *userName;
@property (strong,nonatomic) PFObject *itsMTLObject;

@end
