//
//  HomePageViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-11-16.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "setProfileViewController.h"
#import "internetOfflineViewController.h"
#import "conversationModelData.h"

@interface HomePageViewController : UIViewController <MBProgressHUDDelegate,SetProfileDelegate,UITextFieldDelegate,internetOfflineViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *CreateNewCaseButton;
- (IBAction)CreateNewCase:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *ViewMyCasesButton;
- (IBAction)ViewMyCases:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *MyMatchesButton;
- (IBAction)MyMatches:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *MyProfileButton;
- (IBAction)MyProfile:(id)sender;
- (IBAction)TestProfileButton:(id)sender;
@property (strong,nonatomic) PFObject *HomePageITSMTLObject;
@property (strong,nonatomic) NSString *HomePageuserName;
-(IBAction)TestSlidingView:(id)sender;
@property (weak,nonatomic) IBOutlet UITextField *testUserTextField;
@property (strong,nonatomic) NSString *testUserString;
@property (strong,nonatomic ) NSArray *homePageCases;
@property (strong, atomic) conversationModelData *conversationData;
@end
