//
//  CaseDetailsViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaseDetailsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;

@property (weak,nonatomic) IBOutlet UITableView *caseDetailsTableView;

-(IBAction)doUpdate:(id)sender;

@property(weak,nonatomic) IBOutlet UIPickerView *pickerView;


@property (weak,nonatomic) NSArray *caseListData;
@property (weak,nonatomic) NSNumber *selectedCaseIndex;

@property (weak,nonatomic) IBOutlet UILabel *questionLabel;

@property (weak,nonatomic) NSString *userName;

@end
