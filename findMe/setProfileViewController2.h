//
//  setProfileViewController2.h
//  findMe
//
//  Created by Brian Allen on 2015-08-10.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "GKImagePicker.h"
#import "mapPinViewController.h"
#import <CoreLocation/CoreLocation.h>

@protocol SetProfileDelegate

- (void)setNewProfile2:(PFObject *)newITSMTLObject;

@end

@interface setProfileViewController2 : UIViewController<UITextFieldDelegate,MBProgressHUDDelegate,GKImagePickerDelegate,UIPickerViewDataSource,UIPickerViewDelegate,mapPinViewControllerDelegate,CLLocationManagerDelegate>

//profileObject
@property (strong,nonatomic) PFObject *itsMTLObject;

//scrollview and content view controls include sub pieces
@property (strong,nonatomic) IBOutlet UIView *contentView;
@property (strong,nonatomic) IBOutlet UIScrollView *scrollView;

//image controls
@property (strong) GKImagePicker *imagePicker;
-(IBAction) setImage:(id)sender;
@property (strong,nonatomic) IBOutlet UIImageView *selectedProfileImageView;
@property (strong,nonatomic) IBOutlet UIButton *selectProfileImgButton;

//text controls
@property (weak,nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong,nonatomic) IBOutlet UITextField *firstNameTextField;
@property (strong,nonatomic) IBOutlet UITextField *lastNameTextField;

//locationControls
-(IBAction)locationPicker;
@property (strong,nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) CLLocationManager *locationManager;


//genderPickerControls
-(IBAction)selectedMale:(id)sender;
-(IBAction)selectedFemale:(id)sender;
@property (strong,nonatomic) IBOutlet UIButton *maleButton;
@property (strong,nonatomic) IBOutlet UIButton *femaleButton;

@property (weak,nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak,nonatomic) IBOutlet UIButton *submitProfileButton;

@property (weak,nonatomic) IBOutlet UILabel *setProfileLabel;
@property (weak,nonatomic) IBOutlet UILabel *chooseGenderLabel;
@property (weak,nonatomic) IBOutlet UILabel *nameLabel;
@property (weak,nonatomic) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) id<SetProfileDelegate> delegate;
@property (strong,nonatomic) NSString *openingMode;

@property (strong,nonatomic) IBOutlet UILabel *locationPermissionLabel;

@property (weak,nonatomic) IBOutlet UISwitch *locationSwitch;
-(IBAction) locationToggle:(id)sender;
@property BOOL locationPermission;


@property (strong,nonatomic) UIView *locationPermissionPopup;


-(IBAction)selectGender:(id)sender;

@property (strong,nonatomic) IBOutlet UIButton *genderSelectBtn;

@property (strong,nonatomic) UIPickerView *genderPicker;
@property (strong,nonatomic) UIView *genderPickerBGView;
@property (strong,nonatomic) UIButton *confirmGenderBTN;



-(IBAction)submitProfile:(id)sender;

@property (strong,nonatomic) NSString *username;
@property (strong,nonatomic) NSString *phoneNumber;
@property (strong,nonatomic) NSString *emailAddress;
@property (strong,nonatomic) NSString *firstName;
@property (strong,nonatomic) NSString *lastName;
@property (strong,nonatomic) NSString *gender;

@property (strong,nonatomic) NSString *cityName;
@property (strong,nonatomic) NSString *stateName;
@property (strong,nonatomic) NSString *countryName;

@property (strong,nonatomic) NSString *homeScreenMTLObjectID;

@property (strong,nonatomic) UITextField *activeTextField;

@end
