//
//  HomePageViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-11-16.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "HomePageViewController.h"
#import "newCaseViewController.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "ViewCasesViewController.h"

@interface HomePageViewController ()


@end

@implementation HomePageViewController

NSString *HomePageuserName;
PFObject *HomePageITSMTLObject;
MBProgressHUD *HUD;
@synthesize ViewMyCasesButton;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    //create an itsMTL Object if necessary
    [self createParseUser];
    
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Cases";
    [HUD show:YES];
    
    //needs to query for the user and pull some info
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query getObjectInBackgroundWithId:HomePageuserName block:^(PFObject *latestCaseList, NSError *error) {
        // Do something with the returned PFObject
        NSLog(@"%@", latestCaseList);
       
        [HUD hide:NO];
        
        //do some logic to sort through these cases and see how many have matches, how many are awaiting more info.
        NSArray *cases = [latestCaseList objectForKey:@"cases"];
        
        int caseCount = (int)cases.count;
        
        UIView *bubbleIndicatorCases = [[UIView alloc] init];
        int bubbleWidth = 20;
        int bubbleHeight = 20;
        
        [bubbleIndicatorCases setFrame:CGRectMake(ViewMyCasesButton.frame.origin.x+ViewMyCasesButton.frame.size.width-bubbleWidth/2,ViewMyCasesButton.frame.origin.y-bubbleHeight/2,bubbleWidth,bubbleHeight)];
        
        bubbleIndicatorCases.backgroundColor = [UIColor redColor];
        
        UILabel *bubbleNumber = [[UILabel alloc] initWithFrame:bubbleIndicatorCases.bounds];
        
        bubbleNumber.text = [NSString stringWithFormat:@"%i",caseCount];
        
        [bubbleNumber setTextAlignment:NSTextAlignmentCenter];
        
        [bubbleIndicatorCases addSubview:bubbleNumber];
        
        bubbleIndicatorCases.layer.cornerRadius = 9.0;
        bubbleIndicatorCases.layer.masksToBounds = YES;
        
        [self.view addSubview:bubbleIndicatorCases];
                
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    
}
- (IBAction)MyProfile:(id)sender {
    
}

- (IBAction)TestProfileButton:(id)sender
{
    //set hardcoded value for homepageusername
    //yh5YoZSXRW
    //e9eAifIkyD
    HomePageuserName = @"yh5YoZSXRW";
    
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
        NSLog(@"%@", latestCaseList);
        
        [HUD hide:NO];
        
        //do some logic to sort through these cases and see how many have matches, how many are awaiting more info.
        NSArray *cases = [latestCaseList objectForKey:@"cases"];
        
        int caseCount = (int)cases.count;
        
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
        
    }];

    
}

@end
