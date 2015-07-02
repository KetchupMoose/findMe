//
//  HomePageViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-11-16.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//
//

#import "HomePageViewController.h"
#import "newCaseViewController.h"
#import "newCaseViewControllerv2.h"
#import "newCaseViewControllerv3.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "ViewCasesViewController.h"
#import "setProfileViewController.h"
#import "matchesViewController.h"
#import "UIViewController+ECSlidingViewController.h"
#import "originalViewController.h"
#import "reachabilitySingleton.h"
#import "Reachability.h"
#import "PNImports.h"
#import "AppDelegate.h"
#import "JSQSystemSoundPlayer+JSQMessages.h"
#import "UIView+Animation.h"
#import "sharedUserDataSingleton.h"
#import "CarouselTestViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "privatelyViewController.h"

@interface HomePageViewController ()


@end

@implementation HomePageViewController

MBProgressHUD *HUD;
@synthesize ViewMyCasesButton;
@synthesize HomePageITSMTLObject;
@synthesize HomePageuserName;
@synthesize testUserTextField;
@synthesize homePageCases;
@synthesize connectedMTLLabel;
NSString *homePageManualLocationPropertyNum;

-(void)setManualLocationProperty
{
    //query for the property number to use
    PFQuery *locationPropertyQuery = [PFQuery queryWithClassName:@"Properts"];
    [locationPropertyQuery whereKey:@"designation" equalTo:@"EN~PinDrop"];
    
    [locationPropertyQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        homePageManualLocationPropertyNum = object.objectId;
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    //UIImageView *titleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,40,40)];
    //titleImageView.image = [UIImage imageNamed:@"findMeCursive3.png"];
    
    
   // self.navigationItem.titleView = titleImageView;
    
    //[self.navigationItem.titleView addSubview:titleImageView];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           shadow, NSShadowAttributeName,
                                                           [UIFont fontWithName:@"Futura-Medium" size:25.0], NSFontAttributeName, nil]];
    
    
    self.CreateNewCaseButton.layer.borderColor = (__bridge CGColorRef)([UIColor whiteColor]);
    self.CreateNewCaseButton.layer.borderWidth = 12.0f;
    self.CreateNewCaseButton.layer.cornerRadius = 8.0f;
    self.CreateNewCaseButton.layer.masksToBounds = YES;
    

    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    //check to see if the parse connection is available.  If not, remove the HomePageViewController and show a ParseUnavailableViewController
    Reachability *singletonReach = [[reachabilitySingleton sharedReachability] reacher];
    
    NetworkStatus *status = [singletonReach currentReachabilityStatus];
    
   if (status !=NotReachable)
    {
        NSLog(@"reached it!");
        [self LoadingHomePage];

    }
    else
    {
        NSLog(@"no connection");
        //show the internet offline view controller
        internetOfflineViewController *iovc = [[internetOfflineViewController alloc] init];
        iovc = [self.storyboard instantiateViewControllerWithIdentifier:@"iovc"];
        
        iovc.delegate = self;
        
        //[self.view addSubview:iovc.view];
        
        [self.navigationController presentViewController:iovc animated:YES completion:nil];
        
    }
    
    self.testUserTextField.delegate = self;

    /*
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"manOnPhone" ofType:@"mp4"];
    NSData *gif = [NSData dataWithContentsOfFile:filePath];
    
    [self.gifBG loadData:gif MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
    self.gifBG.userInteractionEnabled = NO;
    */
    
    NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"2195521" ofType:@"mp4"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    
    // load movie
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    self.moviePlayer.view.frame = self.view.frame;
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.view addSubview:self.moviePlayer.view];
    [self.view sendSubviewToBack:self.moviePlayer.view];
    [self.moviePlayer play];
    
    // loop movie
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replayMovie:)
                                                 name: MPMoviePlayerPlaybackDidFinishNotification
                                               object: self.moviePlayer];
     
    
}

-(void)replayMovie:(NSNotification *)notification
{
    [self.moviePlayer play];
}


-(void)LoadingHomePage
{
    [self setPubNubConfigDetails];
    
    //create an itsMTL Object if necessary
    [self createParseUser];
    
    [self setManualLocationProperty];
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    //set up notification channels
    //[self setUpNotificationChannels];
}


-(void) setPubNubConfigDetails
{
    PNConfiguration *configuration = [PNConfiguration configurationForOrigin:@"pubsub.pubnub.com"
                                                                  publishKey:@"pub-c-52642b11-2177-44d9-9321-1e5bceb28507" subscribeKey:@"sub-c-cffdd2bc-c9ca-11e4-801b-02ee2ddab7fe" secretKey:@"sec-c-YWRhYjRjZDUtNDljMC00YjAwLWIxZTktMzg1MmYxZTU1ZTAw"];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [PubNub setConfiguration:configuration];
    
    
    [PubNub connectWithSuccessBlock:^(NSString *origin) {
        //NSLog(origin);
        NSLog(@"success flagged here brian");
        
    } errorBlock:^(PNError *error) {
        NSLog(error.localizedDescription);
    }];
    
    [[PNObservationCenter defaultCenter] addClientConnectionStateObserver:appDelegate withCallbackBlock:^(NSString *origin, BOOL connected, PNError *connectionError){
        if (connected)
        {
            NSLog(@"OBSERVER: Successful Connection!");
        }
        else if (!connected || connectionError)
        {
            NSLog(@"OBSERVER: Error %@, Connection Failed!", connectionError.localizedDescription);
        }
    }];
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    //self.navigationController.navigationBarHidden = YES;
    [self.moviePlayer play];
    
    [self ReloadHomePageData];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) subscribeToConversationChannels
{
    //query the Cases object to get all the cases belonging to the home page user
    //query the Conversations object on parse to get all conversations where the array of users contains one of the home page user's cases
    PFQuery *newQuery = [PFQuery queryWithClassName:@"Conversations"];
    
    NSMutableArray *homePageCaseNames = [[NSMutableArray alloc] init];
    for(PFObject *caseObj in self.homePageCases)
    {
        NSString *caseID = [caseObj objectForKey:@"caseId"];
        [homePageCaseNames addObject:caseID];
        
    };
    
    [newQuery whereKey:@"Members" containedIn:[homePageCaseNames copy]];
    
    [newQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //for each conversation object, subscribe to that channel on pubnub'
        
        NSLog(@"retrieved this many conversation objects");
        NSLog(@"%lu",(unsigned long)objects.count);
        
        NSMutableArray *channelsToSubscribeTo = [[NSMutableArray alloc] init];
        //remove all pubnub subscribes
        NSArray *subscribedToChannels = [PubNub subscribedObjectsList];
        
        [PubNub unsubscribeFrom:subscribedToChannels withCompletionHandlingBlock:^(NSArray *channels, PNError *error) {
            
            if(error)
            {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unsubscribe Error", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                return;
            }
            else
         
            {
                //subscribe on channels for each conversation object
                for(PFObject *conversationObj in objects)
                {
                    NSString *conversationID = conversationObj.objectId;
                    [channelsToSubscribeTo addObject:conversationID];
                }
                NSArray *channelsArray = [PNChannel channelsWithNames:channelsToSubscribeTo];
        
                        [PubNub subscribeOn:channelsArray withCompletionHandlingBlock:^(PNSubscriptionProcessState state, NSArray *channels, PNError *error) {
                            if(error)
                            {
                                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Subscribe Error", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                            }
                            //subscribe successful.
                            NSLog(@"successfully subscribed on channels");
                            NSLog(@"%lu",(unsigned long)channels.count);
                
                        }];
            }
        }];
        
    }];
     
    
}

-(void) createParseUser {
    
     //create parse objects and create the new case for the template
     PFUser *currentUser = [PFUser currentUser];
    
    //query to see if there is an ITSMTLObject for this user already
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Checking if there's an MTL Object";
    [HUD show:YES];
    
    PFQuery *newQuery = [PFQuery queryWithClassName:@"ItsMTL"];
    
    [newQuery whereKey:@"ParseUser" equalTo:currentUser];
    
    NSArray *returnedMTLObjects = [newQuery findObjects];
    if(returnedMTLObjects.count >1)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Multiple MTL Objects for this User" message:currentUser.objectId delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        
        return;
        
    }
    if(returnedMTLObjects.count >=1)
    {
        NSLog(@"already have an itsMTL user");
        
        //do nothing, don't create an itsMTLObject
        PFObject *returnedMTLObject = [returnedMTLObjects objectAtIndex:0];
        HomePageuserName = returnedMTLObject.objectId;
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
        self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
        
        HomePageITSMTLObject = returnedMTLObject;
        
        [HUD hide:NO];
        
    }
    else
    {
        //create new case with this user.
        
        NSLog(@"need to create mtl user from the template screen");
        
        //brian Apr4
        //MTLobject will be created later on profile screen, commenting this out for now
        /*
        HomePageITSMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
        [HomePageITSMTLObject setObject:currentUser forKey:@"ParseUser"];
        //[HomePageITSMTLObject setObject:@"newHomeScreenUser" forKey:@"showName"];
        
        // Set the access control list to current user for security purposes
        PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [itsMTLACL setPublicReadAccess:YES];
        [itsMTLACL setPublicWriteAccess:YES];
        
        HomePageITSMTLObject.ACL = itsMTLACL;
        
        [HomePageITSMTLObject save];
        
         HomePageuserName = HomePageITSMTLObject.objectId;
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
          self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
        //need to grab these properties later to save them on the user
        
         //set user properties to parse true user account
         [currentUser setObject:@"newHomeScreenUser" forKey:@"showName"];
         [currentUser setObject:@"5" forKey:@"cellNumber"];
         [currentUser setObject:@"F" forKey:@"gender"];
         [currentUser save];
         
        */
        setProfileViewController *spvc = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc"];
        spvc.delegate = self;
        
        //[self presentViewController:spvc animated:NO completion:nil];
        [self.navigationController pushViewController:spvc animated:YES];
        
        //[self.navigationController pushViewController:spvc animated:YES];
        
        [HUD hide:NO];
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(IBAction)GabcoTest:(id)sender
{
    newCaseViewControllerv3 *ncvc = [[newCaseViewControllerv3 alloc] init];
    
    
    ncvc.itsMTLObject = HomePageITSMTLObject;
    ncvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
   
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
}


- (IBAction)CreateNewCase:(id)sender {
    
    newCaseViewController *ncvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ncvc"];
    
    ncvc.itsMTLObject = HomePageITSMTLObject;
    ncvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
    
}
- (IBAction)ViewMyCases:(id)sender {
    ViewCasesViewController *vcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"vcvc"];
    vcvc.userName = HomePageuserName;
    vcvc.itsMTLObject = HomePageITSMTLObject;
    vcvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    [self.navigationController pushViewController:vcvc animated:YES];
    
}
- (IBAction)MyMatches:(id)sender {
    
    matchesViewController *mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mvc"];
    
    //loop through the itsMTLObject and gather all the user's matches
    NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchesCaseTypes = [[NSMutableArray alloc] init];
    NSArray *cases = [HomePageITSMTLObject objectForKey:@"cases"];
    for(PFObject *caseObj in cases)
    {
        NSArray *caseItems = [caseObj objectForKey:@"caseItems"];
        //get the properties
        
        for(PFObject *caseItemObject in caseItems)
        {
            NSString *origin = [caseItemObject objectForKey:@"origin"];
            if([origin isEqualToString:@"B"])
            {
                NSString *matchesString = [caseItemObject objectForKey:@"browse"];
                
                NSString *matchesYesString = [caseItemObject objectForKey:@"yeses"];
                
                NSString *matchesRejectedYesString = [caseItemObject objectForKey:@"rejectedYeses"];
                
                NSArray *matchesArray = [matchesString componentsSeparatedByString:@";"];
                NSArray *matchesYesArray = [matchesYesString componentsSeparatedByString:@";"];
                NSArray *matchesRejectedYesArray= [matchesRejectedYesString componentsSeparatedByString:@";"];
                
                
                if([matchesRejectedYesArray count] >0)
                {
                    for(NSString *caseMatchID in matchesRejectedYesArray)
                    {
                        [allMatchesArray addObject:caseMatchID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        [allMatchesCaseTypes addObject:@"rejected"];
                        
                    }
                    
                }
                
                if([matchesYesArray count] >0)
                {
                    for(NSString *caseMatchID in matchesYesArray)
                    {
                        
                        //if(![allMatchesArray containsObject:caseMatchID])
                       // {
                            [allMatchesArray addObject:caseMatchID];
                            [allMatchCaseObjectsArray addObject:caseObj];
                            NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                            
                            [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                            [allMatchesCaseTypes addObject:@"yes"];
                      //  }
                        
                    }
                    
                }
                
                if([matchesArray count] >0)
                {
                    for(NSString *caseMatchID in matchesArray)
                    {
                       // if(![allMatchesArray containsObject:caseMatchID])
                        //{
                        [allMatchesArray addObject:caseMatchID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        [allMatchesCaseTypes addObject:@"match"];
                       // }
                    }

                }
            }
        }
    }
    
    mvc.matchesArray = [allMatchesArray copy];
    mvc.matchesCaseObjectArrays = [allMatchCaseObjectsArray copy];
    mvc.matchesCaseItemArrays = [allMatchCaseItemObjectsArray copy];
    mvc.matchTypeArray = [allMatchesCaseTypes copy];
    
    //query for caseProfiles
    PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
    [caseProfileQuery whereKey:@"caseID" containedIn:allMatchesArray];
    NSArray *returnedCaseProfiles = [caseProfileQuery findObjects];
    mvc.matchesCaseProfileArrays = returnedCaseProfiles;
    
    
    mvc.matchesUserName = HomePageuserName;
    mvc.matchViewControllerMode = @"allMatches";
    
    [self.navigationController pushViewController:mvc animated:YES];
    
        
}
- (IBAction)MyProfile:(id)sender {
    setProfileViewController *spvc = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc"];
    spvc.delegate = self;
   spvc.openingMode = @"HomeScreen";
    spvc.homeScreenMTLObjectID = self.HomePageITSMTLObject.objectId;
    [self.navigationController pushViewController:spvc animated:YES];
    
}

- (IBAction)TestProfileButton:(id)sender
{
   
    //set hardcoded value for homepageusername
    //yh5YoZSXRW
    //e9eAifIkyD
    //NoJW05Xwsq
    //s0sPlhvE34
    
    //yh user LlneiUgZMD
    //sos account match match IQnCnDzMFX
    
    //paulina gretzky NoJW05Xwsq
    
    //chat EiSavyJT4E
    //wbdZqUP5NJ
    if([self.testUserString length] ==0)
    {
        HomePageuserName = @"yh5YoZSXRW";
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
          self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
    }
    else
    {
        HomePageuserName = self.testUserString;
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
          self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
    }
   
    //set the HomePageITSMTLOject to this object.
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query includeKey:@"cases"];
    
    HomePageITSMTLObject = [query getObjectWithId:HomePageuserName];
    //query for data based on this itsMTLobject and reload data on the home page
    
    [self ReloadHomePageData];
   
}

-(void)ReloadHomePageData {

    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Cases";
    [HUD show:NO];
    
    //needs to query for the user and pull some info
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
   
    [query getObjectInBackgroundWithId:HomePageuserName block:^(PFObject *latestCaseList, NSError *error) {
        // Do something with the returned PFObject
        
        [HUD hide:NO];
        
        if(error)
        {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Test User or Parse Connection Failed", nil) message:NSLocalizedString([error localizedDescription], nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            return;
            
        }
        
        //do some logic to sort through these cases and see how many have matches, how many are awaiting more info.
       homePageCases = [latestCaseList objectForKey:@"cases"];
        
        UIView *bubbleIndicatorCases = [[UIView alloc] init];
        int bubbleWidth = 20;
        int bubbleHeight = 20;
        
        [bubbleIndicatorCases setFrame:CGRectMake(ViewMyCasesButton.frame.origin.x+ViewMyCasesButton.frame.size.width-bubbleWidth/2,ViewMyCasesButton.frame.origin.y-bubbleHeight/2,bubbleWidth,bubbleHeight)];
        
        bubbleIndicatorCases.backgroundColor = [UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1];
        
        UILabel *bubbleNumber = [[UILabel alloc] initWithFrame:bubbleIndicatorCases.bounds];
        
        NSString *bubbleCountString = [latestCaseList objectForKey:@"bubbleCount"];
        
        bubbleNumber.text = [NSString stringWithFormat:@"%@",bubbleCountString];
        
        [bubbleNumber setTextAlignment:NSTextAlignmentCenter];
        
        [bubbleIndicatorCases addSubview:bubbleNumber];
        
        bubbleIndicatorCases.layer.cornerRadius = 9.0;
        bubbleIndicatorCases.layer.masksToBounds = YES;
        
        [self.view addSubview:bubbleIndicatorCases];
        
        [self subscribeToConversationChannels];
        
    }];
    
}

- (void)setNewProfile:(PFObject *)newITSMTLObject
{
    if([newITSMTLObject.objectId length] >0)
    {
        self.HomePageuserName = newITSMTLObject.objectId;
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
        self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
        self.HomePageITSMTLObject = newITSMTLObject;
    }
    
    //[self ReloadHomePageData];
    [self.navigationController popViewControllerAnimated:YES];
    
}

-(IBAction)TestSlidingView:(id)sender
{
    /*
    ECSlidingViewController *myecvc = (ECSlidingViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ecsliding"];
    
    originalViewController *ovc = [self.storyboard instantiateViewControllerWithIdentifier:@"originalVC"];
    
    [myecvc setTopViewController:ovc];
    
    
    [self.navigationController pushViewController:myecvc animated:YES];
    */
    //[self cloudCodeTest];
    
    CarouselTestViewController *ctvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ctest"];
    [self.navigationController pushViewController:ctvc animated:YES];
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    [self animateTextField:textField up:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
    self.testUserString = textField.text;
    
    
}


- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int animatedDistance;
    int moveUpValue = textField.frame.origin.y+ textField.frame.size.height;
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        
        animatedDistance = 216-(460-moveUpValue-5);
    }
    else
    {
        animatedDistance = 162-(320-moveUpValue-5);
    }
    
    if(animatedDistance>0)
    {
        const int movementDistance = animatedDistance;
        const float movementDuration = 0.3f;
        int movement = (up ? -movementDistance : movementDistance);
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
        [UIView commitAnimations];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //put the string of the text field onto a label now in the same cell
    //put -100 so it doesn't interfere with the uilabel tag of 3 in every cell
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}

#pragma mark internetOfflineViewController delegate function

- (void)dismissIOVC
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self LoadingHomePage];
    
    
}

//test cloud code function call
-(void) cloudCodeTest {
    [PFCloud callFunctionInBackground:@"pushNotificationForUser"
                       withParameters:@{@"userMTLID": self.HomePageuserName, @"messageStr":@"testing push notification!"}
                                block:^(NSString *responseString, NSError *error)
     {
         NSLog(responseString);
         
     }
     ];
    
}

-(IBAction)showPrivatelyView:(id)sender
{
    privatelyViewController *mypvc = [[privatelyViewController alloc] init];
    
    [self.navigationController pushViewController:mypvc animated:YES];
    
    
    
}



@end
