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
#import "setProfileViewController2.h"
#import "internetOfflineViewController.h"
#import "conversationModelData.h"
#import "findMeBaseViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "findMeBottomTab.h"

@interface HomePageViewController : findMeBaseViewController <MBProgressHUDDelegate,SetProfileDelegate,UITextFieldDelegate,internetOfflineViewControllerDelegate,findMeBottomTabDelegate>
@property (strong, nonatomic) IBOutlet UIButton *CreateNewCaseButton;
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
@property (weak, nonatomic) IBOutlet UILabel *connectedMTLLabel;
@property (strong,nonatomic) IBOutlet UIWebView *gifBG;
@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong,nonatomic) NSArray *designationProperties;
-(IBAction)showPrivatelyView:(id)sender;


@end
