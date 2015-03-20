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


@interface HomePageViewController ()


@end

@implementation HomePageViewController

MBProgressHUD *HUD;
@synthesize ViewMyCasesButton;
@synthesize HomePageITSMTLObject;
@synthesize HomePageuserName;
@synthesize testUserTextField;
@synthesize homePageCases;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
        internetOfflineViewController *iovc = [self.storyboard instantiateViewControllerWithIdentifier:@"iovc"];
        [self.navigationController presentViewController:iovc animated:YES completion:nil];
        
    }
    
    self.testUserTextField.delegate = self;

    
}


-(void)LoadingHomePage
{
    [self setPubNubConfigDetails];
    
    
    //create an itsMTL Object if necessary
    [self createParseUser];
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
   

}

-(void) setPubNubConfigDetails
{
    PNConfiguration *configuration = [PNConfiguration configurationForOrigin:@"pubsub.pubnub.com"
                                                                  publishKey:@"pub-c-71127e1e-7bbf-4f65-abd4-67a2907606b2" subscribeKey:@"sub-c-110d37e8-c9b7-11e4-a054-0619f8945a4f" secretKey:@"sec-c-MzUwOTczZTQtMWI3YS00N2ZkLTk4ZTMtZTIyZDk5NGIyMWI1"];
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
    [self ReloadHomePageData];
    
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
    
    if(returnedMTLObjects.count >=1)
    {
        NSLog(@"already have an itsMTL user");
        
        //do nothing, don't create an itsMTLObject
        PFObject *returnedMTLObject = [returnedMTLObjects objectAtIndex:0];
        HomePageuserName = returnedMTLObject.objectId;
        HomePageITSMTLObject = returnedMTLObject;
        
        [HUD hide:NO];
        
    }
    else
    {
        //create new case with this user.
        
        NSLog(@"creating a new its mtl user");
        
        
        HomePageITSMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
        [HomePageITSMTLObject setObject:currentUser forKey:@"ParseUser"];
        [HomePageITSMTLObject setObject:@"newHomeScreenUser" forKey:@"showName"];
        
        // Set the access control list to current user for security purposes
        PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [itsMTLACL setPublicReadAccess:YES];
        [itsMTLACL setPublicWriteAccess:YES];
        
        HomePageITSMTLObject.ACL = itsMTLACL;
        
        [HomePageITSMTLObject save];
        
         HomePageuserName = HomePageITSMTLObject.objectId;
        
        //need to grab these properties later to save them on the user
        /*
         //set user properties to parse true user account
         [currentUser setObject:@"newHomeScreenUser" forKey:@"showName"];
         [currentUser setObject:@"5" forKey:@"cellNumber"];
         [currentUser setObject:@"F" forKey:@"gender"];
         [currentUser save];
         */
        
        [HUD hide:NO];
    }
    
    // Associate the device with a user
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = [PFUser currentUser];
    installation[@"itsMTL"] = HomePageuserName;
    [installation saveInBackground];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)CreateNewCase:(id)sender {
    
    newCaseViewController *ncvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ncvc"];
    
    ncvc.itsMTLObject = HomePageITSMTLObject;
    
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
    
}
- (IBAction)ViewMyCases:(id)sender {
    ViewCasesViewController *vcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"vcvc"];
    vcvc.userName = HomePageuserName;
    vcvc.itsMTLObject = HomePageITSMTLObject;
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
                
                if([matchesArray count] >0)
                {
                    for(NSString *mtlObjectID in matchesArray)
                    {
                        [allMatchesArray addObject:mtlObjectID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        [allMatchesCaseTypes addObject:@"match"];
                        
                    }

                }
                
                if([matchesYesArray count] >0)
                {
                    for(NSString *mtlObjectID in matchesYesArray)
                    {
                        [allMatchesArray addObject:mtlObjectID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        [allMatchesCaseTypes addObject:@"yes"];
                        
                    }

                }
                
                
                if([matchesRejectedYesArray count] >0)
                {
                    for(NSString *mtlObjectID in matchesRejectedYesArray)
                    {
                        [allMatchesArray addObject:mtlObjectID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        [allMatchesCaseTypes addObject:@"rejected"];
                        
                    }
                    
                }

            
            }
        }
    }
    
    mvc.matchesArray = [allMatchesArray copy];
    mvc.matchesCaseObjectArrays = [allMatchCaseObjectsArray copy];
    mvc.matchesCaseItemArrays = [allMatchCaseItemObjectsArray copy];
    mvc.matchTypeArray = [allMatchesCaseTypes copy];
    
    
    mvc.matchesUserName = HomePageuserName;
    mvc.matchViewControllerMode = @"allMatches";
    
    [self.navigationController pushViewController:mvc animated:YES];
    
}
- (IBAction)MyProfile:(id)sender {
    setProfileViewController *spvc = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc"];
    spvc.delegate = self;
    
    [self.navigationController pushViewController:spvc animated:YES];
    
}

- (IBAction)TestProfileButton:(id)sender
{
   
    //set hardcoded value for homepageusername
    //yh5YoZSXRW
    //e9eAifIkyD
    
    //s0sPlhvE34
    
    //yh user LlneiUgZMD
    //sos account match match IQnCnDzMFX
    
    //paulina gretzky NoJW05Xwsq
    
    //chat EiSavyJT4E
    
    if([self.testUserString length] ==0)
    {
         HomePageuserName = @"yh5YoZSXRW";
    }
    else
    {
        HomePageuserName = self.testUserString;
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
    [HUD show:YES];
    
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
        
        bubbleIndicatorCases.backgroundColor = [UIColor redColor];
        
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
    self.HomePageuserName = newITSMTLObject.objectId;
    self.HomePageITSMTLObject = newITSMTLObject;
    
    [self ReloadHomePageData];
    [self.navigationController popViewControllerAnimated:NO];
}

-(IBAction)TestSlidingView:(id)sender
{
    ECSlidingViewController *myecvc = (ECSlidingViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ecsliding"];
    
    originalViewController *ovc = [self.storyboard instantiateViewControllerWithIdentifier:@"originalVC"];
    
    [myecvc setTopViewController:ovc];
    
    
    [self.navigationController pushViewController:myecvc animated:YES];
    
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
    
}

//test cloud code function call
-(void) cloudCodeTest {
    [PFCloud callFunctionInBackground:@"testSecondModule"
                       withParameters:@{}
                                block:^(NSString *responseString, NSError *error)
     {
         NSLog(responseString);
         
     }
     ];
    
}



@end
