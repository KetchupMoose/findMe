//
//  matchesViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-02-11.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "findMeBaseViewController.h"
@interface matchesViewController : findMeBaseViewController <UITableViewDataSource, UITableViewDelegate,SWTableViewCellDelegate>

@property (strong,nonatomic) IBOutlet UITableView *matchesTableView;
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
