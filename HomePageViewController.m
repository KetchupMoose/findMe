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
#import "ViewCasesViewMatchesMergedViewController.h"
#import "setProfileViewController2.h"
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
#import "findMeBottomTab.h"
#import "addPhoneViewController.h"

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
@synthesize locManager;

NSString *homePageManualLocationPropertyNum;
NSString *homePageTheMatchPropertyNum;
-(void)setManualLocationProperty
{
    //query for the property number to use
    PFQuery *locationPropertyQuery = [PFQuery queryWithClassName:@"Properts"];
    [locationPropertyQuery whereKey:@"designation" equalTo:@"EN~PinDrop"];
    
    [locationPropertyQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSString *responseString = @"";
       BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H1" returnedError:error];
        if(errorCheck)
        {
            homePageManualLocationPropertyNum = object.objectId;
        }
        
    }];
    
}

-(void)setDesignationProperties
{
    PFQuery *designationPropertiesQuery = [PFQuery queryWithClassName:@"Properts"];
    [designationPropertiesQuery whereKey:@"designation" notEqualTo:@""];
    [designationPropertiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H2" returnedError:error];
        
        if(errorCheck)
        {
            //filter through this array to get a smaller array
            NSMutableArray *cleanPropsArray = [[NSMutableArray alloc] init];
            for(PFObject *propObject in objects)
            {
                NSString *propDescr = [propObject objectForKey:@"propertyDescr"];
                NSString *designation = [propObject objectForKey:@"designation"];
                
                if([propDescr length]>0 && [designation length] >0)
                {
                    [cleanPropsArray addObject:propObject];
                }
            }
            self.designationProperties = [cleanPropsArray copy];
        }
        
        
    }];
}

-(void)setTheMatchProperty
{
    //query for the property number to use
    PFQuery *locationPropertyQuery = [PFQuery queryWithClassName:@"Properts"];
    [locationPropertyQuery whereKey:@"designation" equalTo:@"EN~TheMatch"];
    
    [locationPropertyQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H3" returnedError:error];
    
        if(errorCheck)
        {
           homePageTheMatchPropertyNum= object.objectId;
        }
       
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    for (NSString* family in [UIFont familyNames])
    {
        NSLog(@"%@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"  %@", name);
        }
    }
    
    PFObject *customObj = [PFObject objectWithClassName:@"BrianTestClass"];
    NSString *customClassString = customObj.objectId;
    
    [customObj setObject:@"blah2" forKey:@"testData"];
    [customObj save];
    
    NSString *checkStringAgain = customObj.objectId;
    
    
    //location manager instance variable allocs
    locManager = [[CLLocationManager alloc] init];
    [self getLocation:self];
    
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
    
    
    
    //[[UINavigationBar appearance] setAlpha:0];
    
    
    self.CreateNewCaseButton.layer.borderColor = (__bridge CGColorRef)([UIColor whiteColor]);
    self.CreateNewCaseButton.layer.borderWidth = 12.0f;
    self.CreateNewCaseButton.layer.cornerRadius = 8.0f;
    self.CreateNewCaseButton.layer.masksToBounds = YES;
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    //check to see if the parse connection is available.  If not, remove the HomePageViewController and show a ParseUnavailableViewController
    Reachability *singletonReach = [[reachabilitySingleton sharedReachability] reacher];
    
    NetworkStatus status = [singletonReach currentReachabilityStatus];
    
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
    
    float SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    
    findMeBottomTab *bottomTab = [[findMeBottomTab alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT-114,320,50)];
    bottomTab.delegate = self;
    
    [self.view addSubview:bottomTab];
    
}

-(void)getLocation:(id)sender
{
    locManager.delegate = self;
    locManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //show progress HUD
    /*
     HUD.mode = MBProgressHUDModeDeterminate;
     HUD.delegate = self;
     HUD.labelText = @"Retrieving Location Data";
     [HUD show:YES];
     */
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locManager requestWhenInUseAuthorization];
    }
    
    [locManager startUpdatingLocation];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSString *responseString = @"";
    BOOL errorCheck = [self checkForErrors:responseString errorCode:@"h101" returnedError:error];
    
    return;
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        //longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        //latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        
        self.locationLongitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.locationLatitude =[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Stop Location Manager
    [locManager stopUpdatingLocation];
    
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
    [self setDesignationProperties];
    //[self setManualLocationProperty];
    //[self setTheMatchProperty];
    
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
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H4" returnedError:error];

    }];
    
    [[PNObservationCenter defaultCenter] addClientConnectionStateObserver:appDelegate withCallbackBlock:^(NSString *origin, BOOL connected, PNError *connectionError){
        if (connected)
        {
            NSLog(@"OBSERVER: Successful Connection!");
        }
        else if (!connected || connectionError)
        {
            NSLog(@"OBSERVER: Error %@, Connection Failed!", connectionError.localizedDescription);
            NSString *responseString = @"";
            BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H5" returnedError:connectionError];
            return;
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
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H6" returnedError:error];
        
        if(errorCheck)
        {
            
        
        NSLog(@"retrieved this many conversation objects");
        NSLog(@"%lu",(unsigned long)objects.count);
        
        NSMutableArray *channelsToSubscribeTo = [[NSMutableArray alloc] init];
        //remove all pubnub subscribes
        NSArray *subscribedToChannels = [PubNub subscribedObjectsList];
        
        [PubNub unsubscribeFrom:subscribedToChannels withCompletionHandlingBlock:^(NSArray *channels, PNError *error) {
            NSString *responseString = @"";
            BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H7" returnedError:error];
            
            if(errorCheck)
         
            {
                //subscribe on channels for each conversation object
                for(PFObject *conversationObj in objects)
                {
                    NSString *conversationID = conversationObj.objectId;
                    [channelsToSubscribeTo addObject:conversationID];
                }
                NSArray *channelsArray = [PNChannel channelsWithNames:channelsToSubscribeTo];
        
                        [PubNub subscribeOn:channelsArray withCompletionHandlingBlock:^(PNSubscriptionProcessState state, NSArray *channels, PNError *error) {
                        
                            NSString *responseString = @"";
                            BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H8" returnedError:error];
                            if(errorCheck)
                            {
                                
                            
                            //subscribe successful.
                            NSLog(@"successfully subscribed on channels");
                            NSLog(@"%lu",(unsigned long)channels.count);
                            }
                        }];
            }
        }];
        }
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
    NSError *errorObj = nil;
    NSArray *returnedMTLObjects = [newQuery findObjects:&errorObj];
    if(errorObj)
    {
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H9" returnedError:errorObj];
        return;
    }
    if(returnedMTLObjects.count >1)
    {
        [self displayErrorsBoolean:@"Multiple MTL Objects for this User--Error H10"];
        
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
        setProfileViewController2 *spvc2 = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc2"];
        spvc2.delegate = self;
        
        //[self presentViewController:spvc animated:NO completion:nil];
        [self.navigationController pushViewController:spvc2 animated:YES];
        
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
    //ncvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    ncvc.designationProperties = self.designationProperties;
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
}


- (IBAction)CreateNewCase:(id)sender {
    
    newCaseViewController *ncvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ncvc"];
    
    ncvc.itsMTLObject = HomePageITSMTLObject;
    ncvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    ncvc.designationProperties = self.designationProperties;
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
    
}
- (IBAction)ViewMyCases:(id)sender {
    /*
    ViewCasesViewController *vcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"vcvc"];
     
     
    vcvc.userName = HomePageuserName;
    vcvc.itsMTLObject = HomePageITSMTLObject;
    vcvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    [self.navigationController pushViewController:vcvc animated:YES];
    */
    
    //BrianJuly13 upgrade to showing viewCasesViewMatchesMergedViewController
    //viewCasesMerge
    ViewCasesViewMatchesMergedViewController *vcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"viewCasesMerge"];
    //ViewCasesViewMatchesMergedViewController *vcvc = [[ViewCasesViewMatchesMergedViewController alloc] init];
    vcvc.userName = HomePageuserName;
    vcvc.itsMTLObject = HomePageITSMTLObject;
    vcvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
    vcvc.designationProperties = self.designationProperties;
    //set matches properties also
    //loop through the itsMTLObject and gather all the user's matches
    
    //stores the caseID's of the other users you are matching with
    NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
    //stores the caseObjects of this user that led to the matches
    NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
    
    //stores a string of the caseItemObject that contains the matches
    NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
    //stores a string of whether the match is a yes, rejected yes, or normal match.
    
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
    
    vcvc.matchesArray = [allMatchesArray copy];
    vcvc.matchesCaseObjectArrays = [allMatchCaseObjectsArray copy];
    vcvc.matchesCaseItemArrays = [allMatchCaseItemObjectsArray copy];
    vcvc.matchTypeArray = [allMatchesCaseTypes copy];
    
    //query for caseProfiles
    PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
    [caseProfileQuery whereKey:@"caseID" containedIn:allMatchesArray];
    NSError *caseProfilesError = nil;
    NSArray *returnedCaseProfiles = [caseProfileQuery findObjects:&caseProfilesError];
    if(caseProfilesError)
    {
        NSString *responseString = @"";
          BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H11" returnedError:caseProfilesError];
        return;
    }
    
    vcvc.matchesCaseProfileArrays = returnedCaseProfiles;
    
    //query for UserProfiles of these caseUsers
    
    vcvc.matchesUserName = HomePageuserName;
    vcvc.matchViewControllerMode = @"allMatches";
    
    [self.navigationController pushViewController:vcvc animated:YES];
    
}
- (IBAction)MyMatches:(id)sender {
    
    matchesViewController *mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mvc"];
    
    //loop through the itsMTLObject and gather all the user's matches
    
    //stores the caseID's of the other users you are matching with
    NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
    //stores the caseObjects of this user that led to the matches
    NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
    
    //stores a string of the caseItemObject that contains the matches
    NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
    //stores a string of whether the match is a yes, rejected yes, or normal match.
    
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
    NSError *caseProfileError = nil;
    NSArray *returnedCaseProfiles = [caseProfileQuery findObjects:&caseProfileError];
    if(caseProfileError)
    {
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H12" returnedError:caseProfileError];
        return;
    }
    
    mvc.matchesCaseProfileArrays = returnedCaseProfiles;
    
    //query for UserProfiles of these caseUsers
    
    
    mvc.matchesUserName = HomePageuserName;
    mvc.matchViewControllerMode = @"allMatches";
    
    [self.navigationController pushViewController:mvc animated:YES];
    
        
}
- (IBAction)MyProfile:(id)sender {
    setProfileViewController2 *spvc2 = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc2"];
    spvc2.delegate = self;
   spvc2.openingMode = @"HomeScreen";
    spvc2.itsMTLObject = self.HomePageITSMTLObject;
    spvc2.homeScreenMTLObjectID = self.HomePageITSMTLObject.objectId;
    [self.navigationController pushViewController:spvc2 animated:YES];
    
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
    NSError *mtlObjectQueryError = nil;
   
    HomePageITSMTLObject = [query getObjectWithId:HomePageuserName error:&mtlObjectQueryError];
    if(mtlObjectQueryError)
    {
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H13" returnedError:mtlObjectQueryError];
        return;
    }
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
        
        
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"H14" returnedError:error];
        if(errorCheck)
        {
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
          }
    }];
    
}

- (void)setNewProfile2:(PFObject *)newITSMTLObject
{
    NSLog(@"calling setProfileDelegateFunction");
    
    if([newITSMTLObject.objectId length] >0)
    {
        self.HomePageuserName = newITSMTLObject.objectId;
        sharedUserDataSingleton *sharedUData = [sharedUserDataSingleton sharedUserData];
        [sharedUData setUserName:HomePageuserName];
        self.connectedMTLLabel.text = [@"Current MTL User: " stringByAppendingString:HomePageuserName];
        self.HomePageITSMTLObject = newITSMTLObject;
    }
    
    //[self ReloadHomePageData];
    //[self.navigationController popViewControllerAnimated:YES];
    addPhoneViewController *apvc = [self.storyboard instantiateViewControllerWithIdentifier:@"apvc"];
    apvc.delegate = self;
    apvc.itsMTLID = newITSMTLObject.objectId;
    
    
    [self.navigationController pushViewController:apvc animated:YES];
    
}

-(void)confirmPhoneNumber:(id)sender
{
   [self.navigationController popViewControllerAnimated:YES];
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
         //NSLog(responseString);
         
     }
     ];
    
}

-(IBAction)showPrivatelyView:(id)sender
{
    privatelyViewController *mypvc = [[privatelyViewController alloc] init];
    
    [self.navigationController pushViewController:mypvc animated:YES];
    
    
    
}

- (void)tabSelected:(NSInteger)selectedTab
{
    if(selectedTab==0)
    {
        //home screen selected, do nothing.
    }
    if(selectedTab==1)
    {
        //progress tab selected, show view progress controller
        [self ViewMyCases:(self)];
        
    }
    if(selectedTab==2)
    {
        [self MyMatches:(self)];
        
    }
    if(selectedTab==3)
    {
        [self MyProfile:(self)];
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==101)
    {
        strcpy(0, "bla");
    }
}

//brian Sep5
-(BOOL) checkForErrors:(NSString *) returnedString errorCode:(NSString *)customErrorCode returnedError:(NSError *)error;
{
    [HUD hide:NO];
    
    if(error)
    {
        NSString *errorString = error.localizedDescription;
        NSLog(errorString);
        
        NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
        
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        errorView.tag = 101;
        [errorView show];
        
        return NO;
    }
    if([returnedString containsString:@"BROADCAST"])
    {
        //show a ui alertview with the response text
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Broadcast Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
    }
    
    if([returnedString containsString:@"ERROR"])
    {
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for Sync Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
        
        
    }
    else
    {
        return YES;
    }
    
}

//brian Sep5
-(BOOL) displayErrorsBoolean:(NSString *)customErrorCode;
{
    [HUD hide:NO];
    
    NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
    
    UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    errorView.tag = 101;
    [errorView show];
    
    return NO;
}



@end
