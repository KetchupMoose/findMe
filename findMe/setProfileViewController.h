//
//  setProfileViewController.h
//  findme
//
//  Created by Brian Allen on 2014-10-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface setProfileViewController : UIViewController <UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UITableViewDataSource,UITableViewDelegate>

@property (weak,nonatomic) IBOutlet UITextField *nameTextField;
@property (weak,nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak,nonatomic) IBOutlet UIButton *submitProfileButton;

@property (weak,nonatomic) IBOutlet UIButton *femaleButton;
@property (weak,nonatomic) IBOutlet UIButton *maleButton;

@property (weak,nonatomic) IBOutlet UIPickerView *templatePickerView;
@property (weak,nonatomic) IBOutlet UITableView *childTemplateTableView;


-(IBAction)selectedMale:(id)sender;
-(IBAction)selectedFemale:(id)sender;
-(IBAction)submitProfile:(id)sender;

@end
