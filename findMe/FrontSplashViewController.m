//
//  FrontSplashViewController.m
//  Pick Something
//
//  Created by Macbook on 2014-01-09.
//  Copyright (c) 2014 bricorp. All rights reserved.
//

#import "FrontSplashViewController.h"
#import "FindMeLoginViewController.h"
#import "AppDelegate.h"


@interface FrontSplashViewController ()

@end

@implementation FrontSplashViewController
@synthesize dataObject;
@synthesize index;
@synthesize selection1Image,selection2Image,selection3Image;
@synthesize titleText,screenText;
@synthesize fsplashDelegate;
@synthesize pageControl;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
    AppDelegate *myad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    /*
    if(myad.internet==NO)
    {
        InternetOfflineViewController *iovc = [[InternetOfflineViewController alloc] init];
        
        [self addChildViewController:iovc];
        iovc.iovcdelegate = self;
        
        [self.view addSubview:iovc.view];
    }
     */
    if(index==0)
    {
        self.titleText.text = @"Find Missed Connections";
        self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:22];
        self.selection2Image.alpha = 0.3;
        self.selection3Image.alpha = 0.3;
        self.selection1Image.alpha = 1;
        self.screenText.text = @"Find that special someone you saw on the bus, subway, or coffee shop!";
        self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:15];
        
        NSString *crfileName = [[NSBundle mainBundle] pathForResource:@"missedConnection" ofType:@"jpg"];
        UIImage *crimage = [UIImage imageWithContentsOfFile:crfileName];
        
        [self.selection1Image setImage:crimage];
        
        NSString *crefileName = [[NSBundle mainBundle] pathForResource:@"officerelationship" ofType:@"jpg"];
        UIImage *creimage = [UIImage imageWithContentsOfFile:crefileName];
        
        [self.selection2Image setImage:creimage];
        
        NSString *chmfileName = [[NSBundle mainBundle] pathForResource:@"lostdog" ofType:@"jpg"];
        UIImage *chmimage = [UIImage imageWithContentsOfFile:chmfileName];
        
        [self.selection3Image setImage:chmimage];

        
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"missedConnection" ofType:@"jpg"];
        UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
        self.screenshot.image = bgimage;
        
        [self.fsplashDelegate makestuffnotvisible];
        
          if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
          {
                    self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:40];
              self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:30];
              NSString *fileName = [[NSBundle mainBundle] pathForResource:@"critictutescreen" ofType:@"png"];
              UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
              self.screenshot.image = bgimage;
                self.screenText.numberOfLines = 2;
          }
    }
    
    if(index==1)
    {
        NSString *crfileName = [[NSBundle mainBundle] pathForResource:@"missedConnection" ofType:@"jpg"];
        UIImage *crimage = [UIImage imageWithContentsOfFile:crfileName];
        
        [self.selection1Image setImage:crimage];
        
        NSString *crefileName = [[NSBundle mainBundle] pathForResource:@"officerelationship" ofType:@"jpg"];
        UIImage *creimage = [UIImage imageWithContentsOfFile:crefileName];
        
        [self.selection2Image setImage:creimage];
        
        NSString *chmfileName = [[NSBundle mainBundle] pathForResource:@"lostdog" ofType:@"jpg"];
        UIImage *chmimage = [UIImage imageWithContentsOfFile:chmfileName];
        
        [self.selection3Image setImage:chmimage];
        
        self.titleText.text = @"See if someone nearby likes you!";
        self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:22];
        self.selection2Image.alpha = 1;
        self.selection3Image.alpha = 0.3;
        self.selection1Image.alpha = 0.3;
        self.screenText.text = @"Find out if that cute guy in the office likes you without risking embarassment!";
        self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:15];
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"officerelationship" ofType:@"jpg"];
        UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
        self.screenshot.image = bgimage;
        
        [self.fsplashDelegate makestuffnotvisible];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:40];
            self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:30];
            self.screenText.numberOfLines = 2;
            
            NSString *fileName = [[NSBundle mainBundle] pathForResource:@"ipadbrowsescreen" ofType:@"jpg"];
            UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
            self.screenshot.image = bgimage;
            
        }
    }
    
    if(index==2)
    {
        NSString *crfileName = [[NSBundle mainBundle] pathForResource:@"missedConnection" ofType:@"jpg"];
        UIImage *crimage = [UIImage imageWithContentsOfFile:crfileName];
        
        [self.selection1Image setImage:crimage];
        
        NSString *crefileName = [[NSBundle mainBundle] pathForResource:@"officerelationship" ofType:@"jpg"];
        UIImage *creimage = [UIImage imageWithContentsOfFile:crefileName];
        
        [self.selection2Image setImage:creimage];
        
        NSString *chmfileName = [[NSBundle mainBundle] pathForResource:@"lostdog" ofType:@"jpg"];
        UIImage *chmimage = [UIImage imageWithContentsOfFile:chmfileName];
        
        [self.selection3Image setImage:chmimage];
        
        self.titleText.text = @"Find Everything Else";
        self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:22];
        self.selection2Image.alpha = 0.3;
        self.selection3Image.alpha = 1;
        self.selection1Image.alpha = 0.3;
        self.screenText.text = @"Lost Pets, Keys, Location of the Secret Artifact of Quel'Manar, you name it, we'll help you find it!";
        self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:15];
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"lostdog" ofType:@"jpg"];
        UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
        self.screenshot.image = bgimage;
          [self.fsplashDelegate makestuffnotvisible];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.titleText.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:40];
            self.screenText.font =[UIFont fontWithName:@"Futura-CondensedMedium" size:30];
            NSString *fileName = [[NSBundle mainBundle] pathForResource:@"ipadbrowsescreen" ofType:@"jpg"];
            UIImage *bgimage = [UIImage imageWithContentsOfFile:fileName];
            self.screenshot.image = bgimage;
              self.screenText.numberOfLines = 2;
        }
    }
    
    if(index==3)
    {
        //self.view.alpha = 0;
        self.view.userInteractionEnabled = NO;
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidLayoutSubviews
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iPhone Classic
            
            /*
            CGRect bdgframe = self.selection1Image.frame;
            bdgframe.origin.y = bdgframe.origin.y+23;
            self.selection1Image.frame = bdgframe;
            
            CGRect cbdgframe = self.selection3Image.frame;
            cbdgframe.origin.y = cbdgframe.origin.y+23;
            self.selection3Image.frame = cbdgframe;
            
            CGRect rbdgframe = self.selection2Image.frame;
            rbdgframe.origin.y = rbdgframe.origin.y+23;
            self.selection2Image.frame = rbdgframe;
            */
            
            
            
        }
        if(result.height == 568)
        {
            // iPhone 5
            //give stage extra dimensions
           // NSLog(@"iphone 5");
            
            //move stage down 50 pixels on y dimension
            
            CGRect btnframe = self.startPlayingButton.frame;
            btnframe.origin.y = btnframe.origin.y+50;
            
            self.startPlayingButton.frame = btnframe;
            
            
            CGRect txtframe = self.screenText.frame;
            txtframe.origin.y = txtframe.origin.y+10;
            self.screenText.frame = txtframe;
            
            
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    

    
    if(index==3)
    {
       // self.view.alpha = 0;
        
        //make login stuff visible
        //[self.fsplashDelegate makestuffvisible];
        
    }
    
   
    
	// Do any additional setup after loading the view.
}

-(IBAction) startPlayingClick:(id) sender
{
    [self.fsplashDelegate gotologin];
    
}
/*
-(void)DismissIOVC:(InternetOfflineViewController *) iovc
{
    [iovc.view removeWithZoomOutAnimation:1 option:UIViewAnimationOptionCurveEaseIn];
    
    
}
 */


@end
