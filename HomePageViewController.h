//
//  HomePageViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-11-16.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface HomePageViewController : UIViewController <MBProgressHUDDelegate>
@property (weak, nonatomic) IBOutlet UIButton *CreateNewCaseButton;
- (IBAction)CreateNewCase:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *ViewMyCasesButton;
- (IBAction)ViewMyCases:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *MyMatchesButton;
- (IBAction)MyMatches:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *MyProfileButton;
- (IBAction)MyProfile:(id)sender;

@end
