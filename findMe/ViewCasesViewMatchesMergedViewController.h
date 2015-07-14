//
//  ViewCasesViewMatchesMergedViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-07-10.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "SWTableViewCell.h"
#import "findMeBaseViewController.h"
@interface ViewCasesViewMatchesMergedViewController : findMeBaseViewController<UITableViewDataSource,UITableViewDelegate,MBProgressHUDDelegate,SWTableViewCellDelegate>

@property (weak,nonatomic) IBOutlet UITableView *casesTableView;
@property (strong,nonatomic) NSString *userName;
@property (strong,nonatomic) PFObject *itsMTLObject;
@property (strong,nonatomic) NSString *manualLocationPropertyNum;

@property (strong,nonatomic) NSArray *matchesArray;
@property (strong,nonatomic) NSArray *matchesCaseObjectArrays;
@property (strong,nonatomic) NSArray *matchesCaseItemArrays;
@property (strong,nonatomic) NSArray *matchesCaseProfileArrays;

@property (strong,nonatomic) NSString *matchesUserName;
@property (strong,nonatomic) NSString *matchViewControllerMode;
@property (strong,nonatomic) NSArray *matchTypeArray;

@property (strong,nonatomic) NSMutableArray *matchesPerCaseArray;
@property (strong,nonatomic) NSMutableArray *sectionHeaderCaseObjectArray;


@end
