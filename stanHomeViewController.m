//
//  stanHomeViewController.m
//  findMe
//
//  Created by Brian Allen on 10/15/15.
//  Copyright © 2015 Avial Ltd. All rights reserved.
//

#import "stanHomeViewController.h"
#import "ViewCasesViewMatchesMergedViewController.h"
#import "setProfileViewController2.h"
#import "ErrorHandlingClass.h"
#import "matchesViewController.h"
#import "newCaseViewControllerv3.h"
#import "newCaseViewController.h"
#import "reachabilitySingleton.h"
#import "Reachability.h"
#import "PNImports.h"
#import "AppDelegate.h"
#import "sharedUserDataSingleton.h"

@interface stanHomeViewController ()

@end

@implementation stanHomeViewController

@synthesize HomePageuserName;
@synthesize HomePageITSMTLObject;
@synthesize locManager;
CLLocation *location;
BOOL shouldUpdateLocationHome = YES;
MBProgressHUD *HUD;

NSString *homePageManualLocationPropertyNum;
NSString *homePageTheMatchPropertyNum;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    float SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    float SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    findMeBottomTab *bottomTab = [[findMeBottomTab alloc] initWithFrame:CGRectMake(0,0,SCREEN_WIDTH,70)];
    bottomTab.delegate = self;
    
    
    [self.bottomBarContainer addSubview:bottomTab];
    
    //location manager instance variable allocs
   
    locManager = [[CLLocationManager alloc] init];
    [self getLocation:self];
    
    self.HomePageUser = [PFUser currentUser];
    
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
    
    //send xml to retrieve templates and check for home page style templates
    [self getLocalTemplates:self];
    
    [self setupScrollViewContents:self];
    
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
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H4" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        
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
            BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H5" returnedError:connectionError ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
            return;
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
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H9" returnedError:errorObj ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        return;
    }
    if(returnedMTLObjects.count >1)
    {
        //double check this code brianNov8
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:@"" errorCode:@"H10 Multiple MTL Objects" returnedError:nil ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        
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

-(void)setDesignationProperties
{
    PFQuery *designationPropertiesQuery = [PFQuery queryWithClassName:@"Properts"];
    [designationPropertiesQuery whereKey:@"designation" notEqualTo:@""];
    [designationPropertiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSString *responseString = @"";
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H2" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        
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
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H3" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        
        if(errorCheck)
        {
            homePageTheMatchPropertyNum= object.objectId;
        }
        
    }];
}


-(void)setupScrollViewContents:(id)sender
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,15,self.templatesScrollView.frame.size.width,20)];
    titleLabel.text = @"HAPPENING NEAR YOU";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:11];
    
    
    [self.templatesScrollView addSubview:titleLabel];
    
    UILabel *whoopsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,titleLabel.frame.size.height+40+titleLabel.frame.origin.y,self.templatesScrollView.frame.size.width,22)];
    whoopsLabel.textAlignment = NSTextAlignmentCenter;
    whoopsLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:14];
    whoopsLabel.text = @"WOOOOPS!";
    
    UILabel *description1Label = [[UILabel alloc] initWithFrame:CGRectMake(0,whoopsLabel.frame.size.height+whoopsLabel.frame.origin.y+10,self.templatesScrollView.frame.size.width,15)];
    description1Label.text = @"Seems like there is nothing happening near you.";
    description1Label.textAlignment = NSTextAlignmentCenter;
    description1Label.font = [UIFont fontWithName:@"ProximaNova-Regular" size:12];
    
    UILabel *description2Label = [[UILabel alloc] initWithFrame:CGRectMake(0,description1Label.frame.size.height+description1Label.frame.origin.y+10,self.templatesScrollView.frame.size.width,15)];
    description2Label.text = @"Be the first one to Find Something!";
    description2Label.textAlignment = NSTextAlignmentCenter;
    description2Label.font = [UIFont fontWithName:@"ProximaNova-Regular" size:12];
    
    //23, 14, 36
    description2Label.textColor = [UIColor colorWithRed:23/255.0f green:14/255.0f blue:36/255.0f alpha:.5];
    description1Label.textColor = [UIColor colorWithRed:23/255.0f green:14/255.0f blue:36/255.0f alpha:.5];
    whoopsLabel.textColor = [UIColor colorWithRed:23/255.0f green:14/255.0f blue:36/255.0f alpha:.5];
    
    //106x204
    float arrowWidth = 106/2;
    float arrowHeight = 204/2;
    
    UIImageView *icoArrow = [[UIImageView alloc] initWithFrame:CGRectMake(self.templatesScrollView.frame.size.width/2-arrowWidth/2,description2Label.frame.size.height+description2Label.frame.origin.y+25,arrowWidth,arrowHeight)];
    [icoArrow setImage:[UIImage imageNamed:@"ico_arrow@3x.png"]];
     
    
    [self.templatesScrollView addSubview:whoopsLabel];
    [self.templatesScrollView addSubview:description1Label];
    [self.templatesScrollView addSubview:description2Label];
    [self.templatesScrollView addSubview:icoArrow];
    
    
    
}

-(void)getLocalTemplates:(id)sender
{
    //show progress HUD
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Gathering Local Templates";
    [HUD show:YES];
    
    self.allTemplates = [[NSArray alloc] init];
    
    self.totalSetsOfParentTemplates = [[NSMutableArray alloc] init];
    
    self.templatePickerActiveChoices = [[NSMutableArray alloc] init];
    self.parentTemplateCategories = [[NSMutableArray alloc] init];
    
    //use parse cloud code function
    NSString *mtlObjID = self.HomePageITSMTLObject.objectId;
    NSString *payload = @"nottest";
    BOOL payloadString;
    if([mtlObjID isEqualToString:@"yh5YoZSXRW"])
    {
        payloadString = TRUE;
        payload = @"payload";
        [self callStartFunctionID:mtlObjID];
        
    }
    else
    {
        mtlObjID = @"nottest";
        [self callStartFunctionNOID];
        
    }
    
}


-(void)callStartFunctionNOID
{
    NSMutableArray *templateParentChoices = [[NSMutableArray alloc] init];
    [PFCloud callFunctionInBackground:@"getStartMenu"
                       withParameters:@{}
                                block:^(NSArray *returnedObjects, NSError *error)
    {
                                    
    BOOL errorCheck = [ErrorHandlingClass checkForErrors:@"blah" errorCode:@"STH-1" returnedError:error ParseUser:self.HomePageUser MTLOBJ:self.HomePageITSMTLObject];
                                    
    if (errorCheck)
        {
            self.allTemplates = returnedObjects;
                                        
            //self.allTemplates = (NSMutableArray *)[templateQuery findObjects];
            for(PFObject *templateObject in self.allTemplates)
        {
        NSLog(@"numberofKeys");
        NSLog(@"%lu",(unsigned long)templateObject.allKeys.count);
                                            
        PFObject *theParentObj = [templateObject objectForKey:@"parenttemplateid"];
                                            
        if([theParentObj isEqual:[NSNull null]])
          {
          //check the designation
          [templateParentChoices addObject:templateObject];
          }
        }
        //filter parent choices into different categories
        NSString *previousCategory = @"";
        NSMutableArray *templateArray;
        int lastObject = (int)templateParentChoices.count;
        int j = 1;
                                        
        //brian sep6
        //sort this array by their category field before going into this.
        NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"category" ascending:YES];
        NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
        NSArray *sortedTemplateParentArray = [templateParentChoices sortedArrayUsingDescriptors:descriptors];
                                        
        for (PFObject *parentTemplateObject in sortedTemplateParentArray)
            {
            NSString *category = [parentTemplateObject objectForKey:@"category"];
                if(category ==nil)
                {
                category = @"";
                }
            //handle very first case
                if(j==1)
               {
              //create a new templatearray and add it to total sets of templates
               templateArray = [[NSMutableArray alloc] init];
               [templateArray addObject:parentTemplateObject];
               previousCategory = category;
                    if(j == lastObject)
                    {
                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                    }
                }
                else if([previousCategory isEqualToString:category])
                {
                [templateArray addObject:parentTemplateObject];
                    if(j == lastObject)
                    {
                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                    }
                }
                else
                {
                //if there are already some objects, add this one and finish the array
                    if(templateArray.count >=1)
                    {
                     [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                     [templateArray removeAllObjects];
                     templateArray = [[NSMutableArray alloc] init];
                     [templateArray addObject:parentTemplateObject];
                     previousCategory = category;
                        if(previousCategory ==nil)
                        {
                         previousCategory = @"";
                        }
                        if(j == lastObject)
                        {
                         [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                        }
                    }
                    else //if not already some objects, start a new templateArray
                    {
                         [templateArray removeAllObjects];
                         templateArray = [[NSMutableArray alloc] init];
                         [templateArray addObject:parentTemplateObject];
                         previousCategory = category;
                        if(previousCategory ==nil)
                        {
                         previousCategory = @"";
                        }
                        if(j == lastObject)
                        {
                          [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                        }
                    }
                 }
                                            
                   j = j+1;
            }
                                        
        }
                                    
         int numberOfCategories = (int)self.totalSetsOfParentTemplates.count;
        //collection view height: 180
        //collection view cell: 145 width, 130 height
        //collection view image: 31 width, 8 height,82 width, 82height
        //collection view titleLabel 8 width, 95 height,129 width, 27 height
                                    
        int yMarginBetweenCollectionViews= 40;
        int cViewHeight = 180;
    
        [HUD hide:YES];
        
    }];
    
}

-(void)callStartFunctionID:(NSString *)mtlID
{
    NSMutableArray *templateParentChoices = [[NSMutableArray alloc] init];
    [PFCloud callFunctionInBackground:@"getStartMenu"
                       withParameters:@{@"payload": mtlID}
                                block:^(NSArray *returnedObjects, NSError *error) {
                                    
                                    BOOL errorCheck = [ErrorHandlingClass checkForErrors:@"blah" errorCode:@"STH-2" returnedError:error ParseUser:self.HomePageUser MTLOBJ:self.HomePageITSMTLObject];

                                    
                                    if (errorCheck)
                                    {
                                        self.allTemplates = returnedObjects;
                                        
                                        //self.allTemplates = (NSMutableArray *)[templateQuery findObjects];
                                        for(PFObject *templateObject in self.allTemplates)
                                        {
                                            NSLog(@"numberofKeys");
                                            NSLog(@"%lu",(unsigned long)templateObject.allKeys.count);
                                            
                                            PFObject *theParentObj = [templateObject objectForKey:@"parenttemplateid"];
                                            
                                            if([theParentObj isEqual:[NSNull null]])
                                            {
                                                //check the designation
                                                [templateParentChoices addObject:templateObject];
                                            }
                                        }
                                        
                                        //filter parent choices into different categories
                                        NSString *previousCategory = @"";
                                        NSMutableArray *templateArray;
                                        int lastObject = (int)templateParentChoices.count;
                                        int j = 1;
                                        
                                        //brian sep6
                                        //sort this array by their category field before going into this.
                                        NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"category" ascending:YES];
                                        NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
                                        NSArray *sortedTemplateParentArray = [templateParentChoices sortedArrayUsingDescriptors:descriptors];
                                        
                                        for (PFObject *parentTemplateObject in sortedTemplateParentArray)
                                        {
                                            NSString *category = [parentTemplateObject objectForKey:@"category"];
                                            if(category ==nil)
                                            {
                                                category = @"";
                                                
                                            }
                                            //handle very first case
                                            if(j==1)
                                            {
                                                //create a new templatearray and add it to total sets of templates
                                                templateArray = [[NSMutableArray alloc] init];
                                                [templateArray addObject:parentTemplateObject];
                                                previousCategory = category;
                                                
                                                if(j == lastObject)
                                                {
                                                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                                                    
                                                }
                                            }
                                            else if([previousCategory isEqualToString:category])
                                            {
                                                [templateArray addObject:parentTemplateObject];
                                                if(j == lastObject)
                                                {
                                                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                                                    
                                                }
                                            }
                                            else
                                            {
                                                //if there are already some objects, add this one and finish the array
                                                if(templateArray.count >=1)
                                                {
                                                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                                                    [templateArray removeAllObjects];
                                                    templateArray = [[NSMutableArray alloc] init];
                                                    [templateArray addObject:parentTemplateObject];
                                                    previousCategory = category;
                                                    if(previousCategory ==nil)
                                                    {
                                                        previousCategory = @"";
                                                    }
                                                    if(j == lastObject)
                                                    {
                                                        [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                                                        
                                                    }
                                                }
                                                else //if not already some objects, start a new templateArray
                                                {
                                                    [templateArray removeAllObjects];
                                                    templateArray = [[NSMutableArray alloc] init];
                                                    [templateArray addObject:parentTemplateObject];
                                                    previousCategory = category;
                                                    if(previousCategory ==nil)
                                                    {
                                                        previousCategory = @"";
                                                    }
                                                    if(j == lastObject)
                                                    {
                                                        [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                                                        
                                                    }
                                                }
                                            }
                                            
                                            j = j+1;
                                        }
                                        
                                    }
                                    
                                    int numberOfCategories = (int)self.totalSetsOfParentTemplates.count;
                                    
                                    
                                        [HUD hide:YES];
                                
                }
     
     ];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"h101" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
    
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
        
        if(shouldUpdateLocationHome)
        {
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 800, 800);
            [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
            shouldUpdateLocationHome = NO;
             self.mapView.showsUserLocation = YES;
            
        }
    }
    
    // Stop Location Manager
    [locManager stopUpdatingLocation];
    
}


- (IBAction)MyProfile:(id)sender {
    setProfileViewController2 *spvc2 = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc2"];
    spvc2.delegate = self;
    spvc2.openingMode = @"HomeScreen";
    spvc2.itsMTLObject = self.HomePageITSMTLObject;
    spvc2.homeScreenMTLObjectID = self.HomePageITSMTLObject.objectId;
    [self.navigationController pushViewController:spvc2 animated:YES];
    
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
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H11" returnedError:caseProfilesError ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
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
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"H12" returnedError:caseProfileError ParseUser:[PFUser currentUser] MTLOBJ:HomePageITSMTLObject];
        return;
    }
    
    mvc.matchesCaseProfileArrays = returnedCaseProfiles;
    
    //query for UserProfiles of these caseUsers
    
    
    mvc.matchesUserName = HomePageuserName;
    mvc.matchViewControllerMode = @"allMatches";
    
    [self.navigationController pushViewController:mvc animated:YES];
    
    
}

-(void)displayNewSearch:(id)sender
{
    newCaseViewControllerv3 *ncvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ncvc3"];
    
    
    ncvc.itsMTLObject = self.HomePageITSMTLObject;
    ncvc.totalSetsOfParentTemplates = self.totalSetsOfParentTemplates;
  
    ncvc.allTemplates = self.allTemplates;
    ncvc.parentTemplateCategories = self.parentTemplateCategories;
    ncvc.templatePickerActiveChoices = self.templatePickerActiveChoices;
    
    
    [self.navigationController pushViewController:ncvc animated:YES];
    
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
        [self displayNewSearch:self];
        
    }
    if(selectedTab==3)
    {
       
        
    }
    
    if(selectedTab==4)
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


@end
