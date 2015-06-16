//
//  setProfileViewController.h
//  findme
//
//  Created by Brian Allen on 2014-10-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "GKImagePicker.h"


@protocol SetProfileDelegate

- (void)setNewProfile:(PFObject *)newITSMTLObject;

@end

@interface setProfileViewController : UIViewController <UITextFieldDelegate,MBProgressHUDDelegate,GKImagePickerDelegate,UIPickerViewDataSource,UIPickerViewDelegate>

@property (weak,nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong,nonatomic) IBOutlet UITextField *firstNameTextField;
@property (strong,nonatomic) IBOutlet UITextField *lastNameTextField;
@property (strong,nonatomic) IBOutlet UITextField *emailTextField;


@property (weak,nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak,nonatomic) IBOutlet UIButton *submitProfileButton;

@property (weak,nonatomic) IBOutlet UILabel *setProfileLabel;
@property (weak,nonatomic) IBOutlet UILabel *chooseGenderLabel;
@property (weak,nonatomic) IBOutlet UILabel *nameLabel;
@property (weak,nonatomic) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) id<SetProfileDelegate> delegate;
@property (strong,nonatomic) NSString *openingMode;

@property (strong,nonatomic) IBOutlet UIImageView *profileImage1;


@property (weak,nonatomic) IBOutlet UILabel *locationLabel;
@property (strong,nonatomic) IBOutlet UILabel *locationPermissionLabel;

@property (weak,nonatomic) IBOutlet UISwitch *locationSwitch;
-(IBAction) locationToggle:(id)sender;
@property BOOL locationPermission;

-(IBAction) setImage:(id)sender;
@property (strong) GKImagePicker *imagePicker;

-(IBAction)selectGender:(id)sender;

@property (strong,nonatomic) IBOutlet UIButton *genderSelectBtn;

@property (strong,nonatomic) UIPickerView *genderPicker;
@property (strong,nonatomic) UIView *genderPickerBGView;
@property (strong,nonatomic) UIButton *confirmGenderBTN;


-(IBAction)selectedMale:(id)sender;
-(IBAction)selectedFemale:(id)sender;
-(IBAction)submitProfile:(id)sender;

@property (strong,nonatomic) NSString *username;
@property (strong,nonatomic) NSString *phoneNumber;
@property (strong,nonatomic) NSString *emailAddress;
@property (strong,nonatomic) NSString *firstName;
@property (strong,nonatomic) NSString *lastName;
@property (strong,nonatomic) NSString *gender;



@end
