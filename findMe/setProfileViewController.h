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

@protocol SetProfileDelegate

- (void)setNewProfile:(PFObject *)newITSMTLObject;

@end

@interface setProfileViewController : UIViewController <UITextFieldDelegate,MBProgressHUDDelegate>

@property (weak,nonatomic) IBOutlet UITextField *nameTextField;
@property (weak,nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak,nonatomic) IBOutlet UIButton *submitProfileButton;

@property (weak,nonatomic) IBOutlet UIButton *femaleButton;
@property (weak,nonatomic) IBOutlet UIButton *maleButton;


@property (weak,nonatomic) IBOutlet UILabel *setProfileLabel;
@property (weak,nonatomic) IBOutlet UILabel *chooseGenderLabel;
@property (weak,nonatomic) IBOutlet UILabel *nameLabel;
@property (weak,nonatomic) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) id<SetProfileDelegate> delegate;
@property (strong,nonatomic) NSString *openingMode;


-(IBAction)selectedMale:(id)sender;
-(IBAction)selectedFemale:(id)sender;
-(IBAction)submitProfile:(id)sender;

@end
