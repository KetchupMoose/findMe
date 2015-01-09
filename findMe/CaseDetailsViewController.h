//
//  CaseDetailsViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import "NewPropertyViewController.h"

@interface CaseDetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate,MBProgressHUDDelegate,UIAlertViewDelegate,CLLocationManagerDelegate,MyDataDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;

@property (weak,nonatomic) IBOutlet UITableView *caseDetailsTableView;

-(IBAction)doUpdate:(id)sender;
-(IBAction)NewProperty:(id)sender;
-(IBAction)getLocation:(id)sender;
-(IBAction)getPreviousAnswers:(id)sender;

@property (weak,nonatomic) IBOutlet UIButton *checkPreviousAnswersButton;
@property (weak,nonatomic) IBOutlet UIButton *submitAnswersButton;


@property (strong,nonatomic) IBOutlet UILabel *suggestedQuestion;

@property(weak,nonatomic) IBOutlet UIPickerView *pickerView;


@property (weak,nonatomic) NSArray *caseListData;
@property (weak,nonatomic) NSNumber *selectedCaseIndex;

@property (weak,nonatomic) IBOutlet UILabel *questionLabel;
@property (weak,nonatomic) IBOutlet UILabel *percentMatchingLabel;

@property (weak,nonatomic) NSString *userName;

@property (weak,nonatomic) IBOutlet UITextField *customAnswerTextField;


@end
