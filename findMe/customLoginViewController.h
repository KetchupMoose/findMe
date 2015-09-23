//
//  customLoginViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-09-12.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//


//BRIAN, Actually a signup controller

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface customLoginViewController : PFLogInViewController

@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;

@property (strong,nonatomic) IBOutlet UIButton *facebookButton;
@property (strong,nonatomic) IBOutlet UIButton *googleButton;
@property (strong,nonatomic) IBOutlet UIButton *emailSignupButton;
@property (strong,nonatomic) IBOutlet UIButton *alreadyUserButton;
@property (strong,nonatomic) IBOutlet UIButton *termsButton;

@property (strong,nonatomic) IBOutlet UILabel *emailLabel;
@property (strong,nonatomic) IBOutlet UILabel *facebookLabel;
@property (strong,nonatomic) IBOutlet UILabel *googleLabel;

@property (strong,nonatomic) UILabel *googButtonLabel;


-(IBAction)facebookPress:(id)sender;
-(IBAction)googlePress:(id)sender;
-(IBAction)emailPress:(id)sender;
-(IBAction)alreadyUserPress:(id)sender;
-(IBAction)termsPress:(id)sender;


@end
