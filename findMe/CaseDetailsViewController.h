//
//  CaseDetailsViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaseDetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;

@property (weak,nonatomic) IBOutlet UITableView *caseDetailsTableView;

-(IBAction)doUpdate:(id)sender;



@property (weak,nonatomic) NSArray *caseListData;
@property (weak,nonatomic) NSNumber *selectedCaseIndex;

@property (weak,nonatomic) IBOutlet UILabel *questionLabel;


@end
