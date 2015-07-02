//
//  privatelyViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-06-17.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "privatelyViewController.h"
#import "UIView+Animation.h"
@interface privatelyViewController ()

@end

@implementation privatelyViewController
int SCREEN_WIDTH;
int SCREEN_HEIGHT;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    
    SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    
    int xmargin = 20;
    int ymargin = 20;
    self.privatelyDescriptionView = [[UIView alloc] initWithFrame:CGRectMake(xmargin,ymargin,SCREEN_WIDTH-xmargin*2,SCREEN_HEIGHT-ymargin*5)];
    self.privatelyDescriptionView.backgroundColor = [UIColor whiteColor];
    self.privatelyDescriptionView.layer.cornerRadius = 8.0f;
    self.privatelyDescriptionView.layer.masksToBounds = YES;
    
    UIImage *shhImage = [UIImage imageNamed:@"shhhblurrcrop.jpg"];
    //UIImage *shhImage = [UIImage imageNamed:@"shhhcropped.jpg"];
    UIImageView *shhImageView = [[UIImageView alloc] initWithFrame:self.privatelyDescriptionView.bounds];
    [shhImageView setImage:shhImage];
    
    
    shhImageView.contentMode = UIViewContentModeScaleAspectFill;
    shhImageView.alpha = 0.8;
    
    [self.privatelyDescriptionView addSubview:shhImageView];
    
    int labelxmargin = 10;
    int labelymargin = 5;
    UILabel *privateDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelxmargin+5,labelymargin,self.privatelyDescriptionView.frame.size.width-labelxmargin*2,50)];
    privateDescriptionLabel.text = @"Find Me Privacy Policy";
    privateDescriptionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:20];
    privateDescriptionLabel.textAlignment = NSTextAlignmentLeft;
    
    [self.privatelyDescriptionView addSubview:privateDescriptionLabel];
    
    int buttonsizeX = 40;
    int buttonsizeY = 40;
    UIButton *closePrivateViewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.privatelyDescriptionView.bounds.size.width-buttonsizeX-2,2,buttonsizeX,buttonsizeY)];
    UIImage *closeImage = [UIImage imageNamed:@"cancel-circled-outline-512-000000.png"];
    [closePrivateViewButton setBackgroundImage:closeImage forState:UIControlStateNormal];
    [self.privatelyDescriptionView addSubview:closePrivateViewButton];
    [closePrivateViewButton addTarget:self action:@selector(closePopup:) forControlEvents:UIControlEventTouchUpInside];
    
    int privacylabelxmargin = 15;
    int startingyposition = 50;
    UILabel *point1PrivacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(privacylabelxmargin,startingyposition,self.privatelyDescriptionView.frame.size.width-privacylabelxmargin*2,110)];
    point1PrivacyLabel.numberOfLines = 4;
    point1PrivacyLabel.text = @"Find Me is a safe app to discretely find others who meet your exact criteria.";
    point1PrivacyLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
    
    [self.privatelyDescriptionView addSubview:point1PrivacyLabel];
    
    int privacy2labelxmargin = 15;
    int startingyposition2 = 140;
    UILabel *point2PrivacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(privacy2labelxmargin,startingyposition2,self.privatelyDescriptionView.frame.size.width-privacy2labelxmargin*2,110)];
    point2PrivacyLabel.numberOfLines = 4;
    point2PrivacyLabel.text = @"We never show your profile to anyone unless you explicitly allow it.";
    point2PrivacyLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
    
    int privacy3labelxmargin = 15;
    int startingyposition3 = 230;
    UILabel *point3PrivacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(privacy3labelxmargin,startingyposition3,self.privatelyDescriptionView.frame.size.width-privacy3labelxmargin*2,110)];
    point3PrivacyLabel.numberOfLines = 4;
    point3PrivacyLabel.text = @"You decide how specific you want your match to be. Do they know your secret inside joke or just like tennis?";
    point3PrivacyLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
    
    int privacy4labelxmargin = 15;
    int startingyposition4 = 320;
    UILabel *point4PrivacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(privacy4labelxmargin,startingyposition4,self.privatelyDescriptionView.frame.size.width-privacy4labelxmargin*2,110)];
    point4PrivacyLabel.numberOfLines = 4;
    point4PrivacyLabel.text = @"Your location is anonymized and not revealed until you are matched on other details";
    point4PrivacyLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
    
    [self.privatelyDescriptionView addSubview:point2PrivacyLabel];
    [self.privatelyDescriptionView addSubview:point3PrivacyLabel];
    [self.privatelyDescriptionView addSubview:point4PrivacyLabel];
    
    [self.view addSubview:self.privatelyDescriptionView];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closePopup:(id)sender
{
    [self.privatelyDescriptionView removeWithZoomOutAnimation:0.5f option:UIViewAnimationOptionCurveLinear];
    
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
