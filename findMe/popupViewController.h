//
//  popupViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "CaseDetailsEmailViewController.h"
@interface popupViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,MBProgressHUDDelegate>


@property (weak, nonatomic) IBOutlet UIView *testView;
@property (weak, nonatomic) IBOutlet UITableView *answersTableView;

@property (weak,nonatomic) IBOutlet UIButton *updateButton;

-(IBAction)closePopup:(id)sender;
-(IBAction)updateAnswers:(id)sender;


@property (weak,nonatomic) PFObject *popupitsMTLObject;
@property (weak,nonatomic) NSNumber *selectedCase;
@property (weak,nonatomic) NSNumber *selectedCaseItem;
@property (weak,nonatomic) PFObject *selectedPropertyObject;
@property (weak,nonatomic) NSString *displayMode;

@property (weak,nonatomic) IBOutlet UITextField *customAnswerTextField;
@property (weak,nonatomic) CaseDetailsEmailViewController *cdevc;


@end
