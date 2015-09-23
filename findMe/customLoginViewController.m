//
//  customLoginViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-09-12.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "customLoginViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@interface customLoginViewController ()

@end

@implementation customLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   
    // loop movie
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replayMovie:)
                                                 name: MPMoviePlayerPlaybackDidFinishNotification
                                               object: self.moviePlayer];
    
    
    self.emailLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:18];
    self.googleLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:18];
    self.facebookLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:18];
    
    self.googButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,0,320,45)];
    self.googButtonLabel.text = @"CONNECT WITH GOOGLE +";
     self.googButtonLabel.textAlignment = NSTextAlignmentLeft;
     self.googButtonLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:12];
     self.googButtonLabel.textColor = [UIColor whiteColor];
        
}

-(void)viewDidAppear:(BOOL)animated
{
    
    NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"2195521" ofType:@"mp4"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    // load movie
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    CGRect movFrame = self.view.frame;
    
    self.moviePlayer.view.frame = self.view.frame;
    
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    self.moviePlayer.view.backgroundColor = [UIColor redColor];
    
    //add the movie view to the background
    //[self.logInView insertSubview:self.moviePlayer.view atIndex:1];
    //[self.view sendSubviewToBack:self.moviePlayer.view];
    //[self.logInView addSubview:self.moviePlayer.view];
    [self.logInView insertSubview:self.moviePlayer.view atIndex:1];
    
    //[self.view bringSubviewToFront:self.moviePlayer.view];
    
    
    [self.moviePlayer play];
}

-(void)replayMovie:(NSNotification *)notification
{
    [self.moviePlayer play];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)facebookPress:(id)sender
{
    [self _loginWithFacebook];
    
}
-(IBAction)googlePress:(id)sender
{
    
}
-(IBAction)emailPress:(id)sender
{
    //display sign up controller
    
}
-(IBAction)alreadyUserPress:(id)sender
{
    
}
-(IBAction)termsPress:(id)sender
{
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UILabel *alreadyUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(140,20,110,30)];
    alreadyUserLabel.text = @"Already User?";
    alreadyUserLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:17];
    //145,141,226
    alreadyUserLabel.textColor = [UIColor colorWithRed:145/255.0f green:141/255.0f blue:226/255.0f alpha:1];
    alreadyUserLabel.backgroundColor = [UIColor yellowColor];
    
    [self.logInView addSubview:alreadyUserLabel];
    
    UIButton *logInActivateButton = [[UIButton alloc] initWithFrame:CGRectMake(260,20,55,30)];
    logInActivateButton.backgroundColor = [UIColor greenColor];
    [logInActivateButton setTitle:@"Login" forState:UIControlStateNormal];
    
    [logInActivateButton.titleLabel setFont:[UIFont fontWithName:@"ProximaNova-Bold" size:17]];
    [logInActivateButton.titleLabel setTextColor:[UIColor whiteColor]];
    
    [logInActivateButton addTarget:self action:@selector(logInDisplay:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.logInView addSubview:logInActivateButton];
    
                                             
    
   [self.logInView.facebookButton setFrame:CGRectMake(0,400,320,45)];
    [self.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"butt_facebook@3x.png"] forState:UIControlStateNormal];
    
    [self.logInView.facebookButton setImage:nil forState:UIControlStateNormal];
    
    [self.logInView.facebookButton setTitle:@"" forState:UIControlStateNormal];
    
    UILabel *facebookButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(95,0,320,45)];
    facebookButtonLabel.text = @"CONNECT WITH FACEBOOK";
    facebookButtonLabel.textAlignment = NSTextAlignmentLeft;
    facebookButtonLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:12];
    facebookButtonLabel.textColor = [UIColor whiteColor];
    
    [self.logInView.facebookButton addSubview:facebookButtonLabel];
    
    
    
    
    UIButton *googlePlusButton = [[UIButton alloc] initWithFrame:CGRectMake(0,355,320,45)];
    [googlePlusButton setBackgroundImage:[UIImage imageNamed:@"butt_google@3x.png"] forState:UIControlStateNormal];
    [googlePlusButton setImage:nil forState:UIControlStateNormal];
    [googlePlusButton setTitle:@"" forState:UIControlStateNormal];
    
    [googlePlusButton addSubview: self.googButtonLabel];
    
    [self.logInView addSubview:googlePlusButton];
    
    //580 × 241 pixels
    //232w
    //96.4h
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(44,120,232,96.4)];
    [logo setImage:[UIImage imageNamed:@"logo@3x.png"]];
    [self.logInView addSubview:logo];
    
    

    [self.logInView.signUpButton setFrame:CGRectMake(0, 280.0f, 320.0f, 45.0f)];
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"butt_signup@3x.png"] forState:UIControlStateNormal];
    [self.logInView.signUpButton setTitle:@"SIGN UP WITH EMAIL" forState:UIControlStateNormal];
    [self.logInView.signUpButton.titleLabel setFont:[UIFont fontWithName:@"ProximaNova-Bold" size:12]];
    
    self.logInView.logo.alpha = 0;
     self.logInView.usernameField.alpha =0;
    self.logInView.passwordField.alpha = 0;
    self.logInView.logInButton.alpha = 0;
   
}

-(void)logInDisplay:(id)sender
{
    //show the username, password, and login button fields.
    self.logInView.logInButton.alpha = 1;
    self.logInView.usernameField.alpha = 1;
    self.logInView.passwordField.alpha = 1;
    
    self.logInView.logo.alpha =0;
    self.logInView.signUpButton.alpha = 0;
    
    
}

- (void)_loginWithFacebook {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_birthday", @"user_location"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        //did log in here
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
            [self.delegate logInViewControllerDidCancelLogIn:self];
            
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            //dismiss this view controller
            [self.delegate logInViewController:self didLogInUser:user];
            
            
        } else {
            NSLog(@"User logged in through Facebook!");
            [self.delegate logInViewController:self didLogInUser:user];
        }
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
