//
//  ViewCasesViewMatchesMergedViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-07-10.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "ViewCasesViewMatchesMergedViewController.h"
#import "UIImageView+WebCache.h"
#import "XMLWriter.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "conversationsViewController.h"
#import "conversationJSQViewController.h"
#import "conversationModelData.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "caseDetailsCarouselViewController.h"
#import "newCaseViewControllerv3.h"


@interface ViewCasesViewMatchesMergedViewController ()

@end

@implementation ViewCasesViewMatchesMergedViewController
NSArray *caseListJSON;
NSMutableArray *caseListPruned;
@synthesize casesTableView;
MBProgressHUD *HUD;
UIRefreshControl *refreshControl;
@synthesize userName;
NSMutableArray *caseIDSList;
NSArray *caseObjects;
NSArray *caseProfileObjects;
NSMutableArray *caseImages;
NSMutableArray *caseShowNames;
BOOL waitForSyncCompletedMerge = FALSE;
NSMutableSet* _collapsedSections;
BOOL firstMatchViewLoadMerge = TRUE;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    refreshControl = [[UIRefreshControl alloc]init];
    [self.casesTableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    [casesTableView setDataSource:self];
    [casesTableView setDelegate:self];
    
    caseIDSList = [[NSMutableArray alloc] init];
    
    caseImages = [[NSMutableArray alloc] init];
    caseShowNames = [[NSMutableArray alloc] init];
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Cases";
    [HUD show:NO];
    
    self.navigationItem.title = @"View Cases";
    
    self.casesTableView.backgroundColor = [UIColor clearColor];
    [self.casesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    caseListPruned = [[NSMutableArray alloc] init];
    
    _collapsedSections = [NSMutableSet new];
    self.matchesPerCaseArray = [[NSMutableArray alloc] init];
    self.sectionHeaderCaseObjectArray = [[NSMutableArray alloc] init];
    
    [self.casesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.casesTableView.backgroundColor = [UIColor clearColor];
    
    self.casesTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    float SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    
    findMeBottomTab *bottomTab = [[findMeBottomTab alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT-114,320,50)];
    bottomTab.delegate = self;
    
    [self.view addSubview:bottomTab];
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    
    self.navigationController.navigationBarHidden = NO;
    
    //call waitForSync first and then refresh the table
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Re-Syncing Data";
    [HUD show:YES];
    
    waitForSyncCompletedMerge = FALSE;
    self.casesTableView.userInteractionEnabled = FALSE;
    
    [PFCloud callFunctionInBackground:@"waitForSync"
                       withParameters:@{@"payload": userName}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                     BOOL errorCheck = [self checkForErrors:responseString errorCode:@"v1" returnedError:error];
                                    
                                    if(errorCheck)
                                    {
                                        
                                        dispatch_async(dispatch_get_main_queue(),
                                                       ^{
                                                           [HUD hide:NO];
                                                           self.casesTableView.userInteractionEnabled = TRUE;
                                                           [self refreshTable];
                                                       });
                                        
                                    }
                                    
                                }];
    
    
    
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

-(void)refreshTable
{
    //if response case is ok, refresh the list of cases.
    // Set determinate mode
    [self.matchesPerCaseArray removeAllObjects];
    
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Querying Case Data";
    [HUD show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    //PFQuery *casesQuery = [PFQuery queryWithClassName:@"Cases"];
    
    //example structure for running two queries at once:
    // NSArray *queryArray = [NSArray arrayWithObjects:messageQuery,pokeQuery,commentsQuery,nil];
    //PFQuery *allQueries = [PFQuery orQueryWithSubqueries:queryArray];
    NSError *refreshTableQueryError = nil;
    PFObject *object = [query getObjectWithId:userName error:&refreshTableQueryError];
    
    
    if(refreshTableQueryError)
    {
        NSString *responseString = @"";
        
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"v2" returnedError:refreshTableQueryError];
        return;

    }
    
    /*
     if(error)
     {
     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Query Failed", nil) message:NSLocalizedString([error localizedDescription], nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
     return;
     
     }
     */
    PFObject *latestCaseList = object;
    self.itsMTLObject = latestCaseList;
    
    // NSLog(@"%@", latestCaseList);
    caseListJSON = [latestCaseList objectForKey:@"cases"];
    [caseListPruned removeAllObjects];
    [caseIDSList removeAllObjects];
    
    for (PFObject *caseObject in caseListJSON)
    {
        
        NSString *caseID = [caseObject objectForKey:@"caseId"];
        if (caseID !=nil)
        {
            [caseListPruned addObject:caseObject];
            [caseIDSList addObject:caseID];
            
        }
        
    }
    
    PFQuery *caseQuery = [PFQuery queryWithClassName:@"Cases"];
    [caseQuery whereKey:@"objectId" containedIn:caseIDSList];
    NSError *caseQueryError = nil;
    
    caseObjects = [caseQuery findObjects:&caseQueryError];
    if(caseQueryError)
    {
        NSString *responseString = @"";
          BOOL errorCheck = [self checkForErrors:responseString errorCode:@"v3" returnedError:refreshTableQueryError];
        return;

    }
    
    PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
    [caseProfileQuery whereKey:@"caseID" containedIn:caseIDSList];
    NSError *caseProfileObjsError = nil;
    caseProfileObjects = [caseProfileQuery findObjects:&caseProfileObjsError];
    if(caseProfileObjsError)
    {
        NSString *responseString = @"";
        BOOL errorCheck = [self checkForErrors:responseString errorCode:@"v4" returnedError:caseProfileObjsError];
        return;

    }
    //loop through the incoming array of caseListPruned and assign to a new array the number of matches contained in each of these cases, which will often be 0.
   
    for(PFObject *caseObject in caseListPruned)
    {
        NSString *caseObjectToCompare = [caseObject objectForKey:@"caseId"];
        
        if([self.matchesCaseObjectArrays containsObject:caseObject])
        {
            //count the number of occurrences
            int matchCountInCase = 0;
            for(PFObject *caseObj in self.matchesCaseObjectArrays)
            {
                NSString *caseObjID = [caseObj objectForKey:@"caseId"];
                
                if([caseObjID isEqualToString:caseObjectToCompare])
                {
                        matchCountInCase = matchCountInCase+1;
                }
            
            }
            //upload to array with matchCountInCase
              NSNumber *matchCountPerCaseNum = [NSNumber numberWithInt:matchCountInCase];
            [self.matchesPerCaseArray addObject:matchCountPerCaseNum];
            
        }
        else
        {
            //add to array of 0
            NSNumber *matchCountPerCaseNum = [NSNumber numberWithInt:0];
            
            [self.matchesPerCaseArray addObject:matchCountPerCaseNum];
            
        }
        
    }
    
    [refreshControl endRefreshing];
    
     firstMatchViewLoadMerge = TRUE;
    
    [casesTableView reloadData];
    
    [HUD hide:NO];
    
    firstMatchViewLoadMerge = FALSE;
    
    
}

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //if first load, start them all as 0 and add them to the array
    
    
    //check the number of rows which should be included in this part of the tableview
    NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
    NSInteger rowCount = [objCountNumber integerValue];
    
    if(firstMatchViewLoadMerge==TRUE)
    {
        rowCount =0;
        [_collapsedSections addObject:@(section)];
        
    }
    
    NSInteger valueToReturn = [_collapsedSections containsObject:@(section)] ? 0 : rowCount;
    
    return valueToReturn;
    
}
-(NSArray*) indexPathsForSection:(int)section withNumberOfRows:(int)numberOfRows {
    NSMutableArray* indexPaths = [NSMutableArray new];
    for (int i = 0; i < numberOfRows; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

-(void)sectionButtonTouchUpInside:(UIButton*)sender {
    //sender.backgroundColor = [UIColor greenColor];
    [self.casesTableView beginUpdates];
    int section = sender.tag;
    bool shouldCollapse = ![_collapsedSections containsObject:@(section)];
    if (shouldCollapse) {
        int numOfRows = [self.casesTableView numberOfRowsInSection:section];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numOfRows];
        [self.casesTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_collapsedSections addObject:@(section)];
    }
    else {
        NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
        NSInteger numOfRows = [objCountNumber integerValue];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numOfRows];
        [self.casesTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_collapsedSections removeObject:@(section)];
    }
    [self.casesTableView endUpdates];
    //[_tableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100.0;
}

-(NSString *)checkMatchPropertyDesignation:(NSString *)propertyNum
{
    NSString *sureMatchPropNum;
    NSString *theMatchPropNum;
    for(PFObject *designationProp in self.designationProperties)
    {
        NSString *designation = [designationProp objectForKey:@"designation"];
        if([designation isEqualToString:@"EN~TheMatch"])
        {
            theMatchPropNum = designationProp.objectId;
        }
        
        if([designation isEqualToString:@"EN~SureMatches"])
        {
            sureMatchPropNum = designationProp.objectId;
        }
    }
    
    if([propertyNum isEqualToString:sureMatchPropNum])
    {
        return @"sureMatch";
    }
    if([propertyNum isEqualToString:theMatchPropNum])
    {
        return @"theMatch";
    }
    else
    {
        return @"other";
    }
}


- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.casesTableView.frame.size.width,100)];
    
    sectionView.backgroundColor = [UIColor clearColor];
    
    //get count of matches for this particular section
    NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
    NSInteger matchCount = [objCountNumber integerValue];
    
    UIButton* result = [UIButton buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0,0,self.casesTableView.frame.size.width,100);
    
    [result addTarget:self action:@selector(sectionButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    result.backgroundColor = [UIColor clearColor];
    //[result setTitle:[NSString stringWithFormat:@"Section %ld", (long)section] forState:UIControlStateNormal];
    [result setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    result.tag = section;
    
    //add case specific elements to sectionView
    
    UIView *sectionBGView;
    UIImageView *caseImgView;
    UILabel *matchCountLabel;
    UILabel *caseNameLabel;
    UILabel *dateUpdatedLabel;
    UILabel *bubbleCountLabel;
    UILabel *caseIDLabel;
    
    //add items to sectionBGView
    caseImgView = (UIImageView *)[sectionBGView viewWithTag:2];
    matchCountLabel = (UILabel *)[sectionBGView viewWithTag:3];
    caseNameLabel = (UILabel *)[sectionBGView viewWithTag:4];
    dateUpdatedLabel = (UILabel *)[sectionBGView viewWithTag:5];
    bubbleCountLabel = (UILabel *)[sectionBGView viewWithTag:6];
    caseIDLabel = (UILabel *)[sectionBGView viewWithTag:7];
    
    UIButton *editCaseButton = (UIButton *)[sectionBGView viewWithTag:section+100];
    
    if(caseImgView.tag !=2)
    {
        sectionBGView = [[UIView alloc] initWithFrame:CGRectMake(4,4,312,92)];
        sectionBGView.tag = 1;
        sectionBGView.backgroundColor = [UIColor blackColor];
        sectionBGView.alpha = 1;
        sectionBGView.layer.cornerRadius = 5.0f;
        
        matchCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(98,4,150,20)];
        matchCountLabel.tag = 3;
        
        caseImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,94,90)];
        caseImgView.tag = 2;
        
        caseNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(100,0,200,100)];
        caseNameLabel.tag = 4;
        
        dateUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(sectionBGView.frame.size.width-50,0,50,20)];
        dateUpdatedLabel.textAlignment = NSTextAlignmentRight;
        editCaseButton = [[UIButton alloc] initWithFrame:CGRectMake(205,55,100,30)];
        [editCaseButton setTitle:@"Edit Case" forState:UIControlStateNormal];
        [editCaseButton setBackgroundColor:[UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1]];
        [editCaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        editCaseButton.layer.cornerRadius = 8.0f;
        editCaseButton.tag = section+100;
        
        caseIDLabel = [[UILabel alloc] initWithFrame:CGRectMake(100,0,200,50)];
        caseIDLabel.tag = 7;
        
        [editCaseButton addTarget:self action:@selector(editCaseButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        
        bubbleCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,4,20,20)];
        bubbleCountLabel.tag = 5;

    
        [sectionBGView addSubview:dateUpdatedLabel];
        [sectionBGView addSubview:caseImgView];
        [sectionBGView addSubview:matchCountLabel];
        [sectionBGView addSubview:caseNameLabel];
        [sectionBGView addSubview:result];
        [sectionBGView addSubview:editCaseButton];
        [sectionBGView addSubview:bubbleCountLabel];
        [sectionBGView addSubview:caseIDLabel];
        [sectionView addSubview:sectionBGView];
        
    }
   
    dateUpdatedLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
    dateUpdatedLabel.textColor = [UIColor whiteColor];
    
    caseIDLabel.textColor = [UIColor whiteColor];
    
    
    PFObject *caseObj = [caseListPruned objectAtIndex:section];
    NSString *caseID = [caseObj objectForKey:@"caseId"];
    NSString *caseimgURL;
    NSString *bubbleCount = [caseObj objectForKey:@"bubbleCount"];
    
    
    caseIDLabel.text = caseID;
    
    
    NSString *timestampString = [caseObj objectForKey:@"timestamp"];
    
    BOOL sureMatch = FALSE;
    BOOL theMatch = FALSE;
    //check the caseObj for match type properties and check the matchtypes
    NSArray *caseItems = [caseObj objectForKey:@"caseItems"];
    for (PFObject *propObject in caseItems)
    {
        if([[propObject objectForKey:@"origin"] isEqualToString:@"B"])
        {
            //check this propertyNum against the known match types
            NSString *matchPropNum = [propObject objectForKey:@"propertyNum"];
            
            NSString *checkMatchDesignation = [self checkMatchPropertyDesignation:matchPropNum];
            if([checkMatchDesignation isEqualToString:@"sureMatch"])
            {
                sureMatch = TRUE;
            }
            else
                if([checkMatchDesignation isEqualToString:@"theMatch"])
                {
                    theMatch = TRUE;
                }
        }
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeStyle = NSDateFormatterNoStyle;
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"EST"];
    
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *date = [formatter dateFromString:timestampString];
    
    //convert time from now
    NSString *timeSinceUpdateString = [self calculateStringForTimeSinceLastUpdate:date];
    
    dateUpdatedLabel.text = timeSinceUpdateString;
    dateUpdatedLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
    
    
    for (PFObject *caseProfileObj in caseProfileObjects)
    {
        NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
        if([caseID isEqualToString:caseProfileCaseID])
        {
            //display case information
            //caseShowNameLabel.text = [caseProfileObj objectForKey:@"externalCaseName"];
            PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
            caseimgURL = imgFile.url;
        }
    }
    
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    //NSString *caseImgURL = [caseImages objectAtIndex:indexPath.row];
    if([caseimgURL length] ==0)
    {
        //check to see if there is a user profile set
        PFUser *user = [PFUser currentUser];
        PFFile *profileImg = [user objectForKey:@"profileImage"];
        if(profileImg !=nil)
        {
            caseimgURL = profileImg.url;
        }
        else
        {
            caseimgURL = @"default";
        }
        
    }
    
    if([caseimgURL isEqualToString:@"default"])
    {
        [caseImgView setImage:[UIImage imageNamed:@"Businessman-with-question-mark-on-face.jpg"]];
    }
    else
    {
        [caseImgView setImageWithURL:[NSURL URLWithString:caseimgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    }
    //Brian August 7
    /*
    for(PFObject *propObject in propObjectsArray)
    {
        NSString *designation = [propObject objectForKey:@"designation"];
        BOOL sureMatchFound = FALSE;
        
        if([designation containsString:@"TheMatch"])
        {
            sureMatchFound =TRUE;
        }
    }
     */
    matchCountLabel.backgroundColor = [UIColor redColor];
    
    matchCountLabel.textColor = [UIColor whiteColor];
    matchCountLabel.layer.cornerRadius = 10.0f;
    matchCountLabel.layer.masksToBounds = YES;
    if(sureMatch == TRUE)
    {
        matchCountLabel.text = [[objCountNumber stringValue] stringByAppendingString:@"SURE  Matches"];

    }
    else
    {
        if(theMatch == TRUE)
        {
            matchCountLabel.text = @"The Match has been found!";
        }
        else
        {
         matchCountLabel.text = [[objCountNumber stringValue] stringByAppendingString:@" Matches"];
        }
    }
        [matchCountLabel setTextAlignment:NSTextAlignmentCenter];
    if([objCountNumber intValue] ==0)
    {
        matchCountLabel.alpha = 0;
        
    }
    
    bubbleCountLabel.backgroundColor =[UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1];
    bubbleCountLabel.textColor = [UIColor whiteColor];
    bubbleCountLabel.layer.cornerRadius = 10.0f;
    bubbleCountLabel.layer.masksToBounds = YES;
    [bubbleCountLabel setTextAlignment:NSTextAlignmentCenter];
    if([bubbleCount length] >0)
    {
        bubbleCountLabel.text = bubbleCount;
    }
    else
    {
        bubbleCountLabel.alpha = 0;
    }

    caseNameLabel.textColor = [UIColor whiteColor];
    caseNameLabel.numberOfLines = 2;
    caseNameLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
    caseImgView.layer.cornerRadius = 5.0f;
    
    //get caseName from prunedCaseArray at this index
    caseNameLabel.text = [caseObj objectForKey:@"caseName"];
    
    return sectionView;
}



-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.matchesPerCaseArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"matchCell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    UIImageView *matchImage = (UIImageView *)[cell viewWithTag:1];
    UILabel *matchCaseNameLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *matchIDLabel = (UILabel *)[cell viewWithTag:5];
    UILabel *matchPctLabel = (UILabel *)[cell viewWithTag:3];
    UIView *bgView = [cell viewWithTag:4];
    UILabel *externalMatchName = (UILabel *)[cell viewWithTag:6];
    
    
    matchCaseNameLabel.textColor = [UIColor whiteColor];
    matchPctLabel.textColor = [UIColor whiteColor];
    matchIDLabel.textColor = [UIColor whiteColor];
    externalMatchName.textColor = [UIColor whiteColor];
    
    bgView.layer.cornerRadius = 5.0f;
    bgView.layer.masksToBounds = YES;
    bgView.backgroundColor = [UIColor clearColor];
    
    matchImage.layer.cornerRadius = 2.0f;
    matchImage.layer.masksToBounds = YES;
    
    UIView *topBGView = [bgView viewWithTag:72];
    
    if(topBGView.backgroundColor != [UIColor blackColor])
    {
        topBGView = [[UIView alloc] initWithFrame:bgView.frame];
        topBGView.backgroundColor = [UIColor blackColor];
        topBGView.alpha = 0.8;
        topBGView.tag = 72;
        [bgView addSubview:topBGView];
        [bgView sendSubviewToBack:topBGView];
    }
    
    if([self.matchViewControllerMode isEqualToString:@"allMatches"])
    {
        PFObject *caseObj = [self.matchesCaseObjectArrays objectAtIndex:indexPath.row];
        NSString *caseName = [self.matchesArray objectAtIndex:indexPath.row];
        
        matchCaseNameLabel.text = caseName;
        bgView.alpha = 1;
        matchCaseNameLabel.alpha = 1;
        NSString *caseObjID = [caseObj objectForKey:@"caseId"];
        matchIDLabel.text = [@"MyCaseID: " stringByAppendingString:caseObjID];
        
    }
    else
    {
        bgView.alpha = 0;
        matchCaseNameLabel.alpha = 0;
        
    }
    
    NSString *matchCaseID = [self.matchesArray objectAtIndex:indexPath.row];
    
    //matchNameLabel.text = matchNameString;
    
    //check to see if there is a caseProfile for this caseID
    NSString *caseimgURL;
    for (PFObject *caseProfileObj in self.matchesCaseProfileArrays)
    {
        NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
        if([matchCaseID isEqualToString:caseProfileCaseID])
        {
            //display case information
            externalMatchName.text = [caseProfileObj objectForKey:@"externalCaseName"];
            PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
            caseimgURL = imgFile.url;
        }
    }
    
    UIActivityIndicatorViewStyle *activityStyle = UIActivityIndicatorViewStyleGray;
    
    if([caseimgURL length] ==0)
    {
        NSString *defaultMatchImgFileName = [[NSBundle mainBundle] pathForResource:@"femalesilhouette" ofType:@"jpeg"];
        matchImage.image = [UIImage imageWithContentsOfFile:defaultMatchImgFileName];
        
    }
    else
    {
        [matchImage setImageWithURL:[NSURL URLWithString:caseimgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    }
    
    NSString *matchType = [self.matchTypeArray objectAtIndex:indexPath.row];
    if([matchType isEqualToString:@"yes"])
    {
        matchCaseNameLabel.textColor = [UIColor greenColor];
        
    }
    else if([matchType isEqualToString:@"rejected"])
    {
        matchCaseNameLabel.textColor = [UIColor grayColor];
        
    }
    
    return cell;
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.0f green:0.78f blue:0.0f alpha:1.0]
                                                title:@"Yes"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                               title:@"No"];
    
    /*
     icon:[UIImage imageNamed:@"check.png"]];
     [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:1.0f blue:0.35f alpha:1.0]
     icon:[UIImage imageNamed:@"clock.png"]];
     [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
     icon:[UIImage imageNamed:@"cross.png"]];
     [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.55f green:0.27f blue:0.07f alpha:1.0]
     icon:[UIImage imageNamed:@"list.png"]];
     */
    
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //create a conversation PFObject between the two usernames or look up the conversation object
    PFQuery *query = [PFQuery queryWithClassName:@"Conversations"];
    
    NSString *matchID = [self.matchesArray objectAtIndex:indexPath.row];
    NSMutableArray *twoMatches = [[NSMutableArray alloc] init];
    
    [twoMatches addObject:matchID];
    PFObject *caseObjAtIndex = [self.matchesCaseObjectArrays objectAtIndex:indexPath.row];
    
    NSString *caseForMatch = [caseObjAtIndex objectForKey:@"caseId"];
    
    [twoMatches addObject:caseForMatch];
    NSArray *conversationMembers = [twoMatches mutableCopy];
    
    [query whereKey:@"Members" containsAllObjectsInArray:conversationMembers];
    NSError *returnedConversationsError = nil;
    NSArray *returnedConversations = [query findObjects:&returnedConversationsError];
    if(returnedConversationsError)
    {
        BOOL errorCheck = [self checkForErrors:@"" errorCode:@"v5" returnedError:returnedConversationsError];
        return;
    }
   
    
    PFObject *conversationObject;
    
    if([returnedConversations count] ==0)
    {
        //create a conversation object
        conversationObject = [PFObject objectWithClassName:@"Conversations"];
        [conversationObject setObject:conversationMembers forKey:@"Members"];
        NSError *convoObjSaveError = nil;
        [conversationObject save:&convoObjSaveError];
        if(convoObjSaveError)
        {
              BOOL errorCheck = [self checkForErrors:@"" errorCode:@"v6" returnedError:returnedConversationsError];
            return;
        }
        
    }
    else
    {
        conversationObject = [returnedConversations objectAtIndex:0];
    }
    
    conversationJSQViewController *cJSQvc = [self.storyboard instantiateViewControllerWithIdentifier:@"convojsq"];
    
    //conversationModelData *cmData = [[conversationModelData alloc] initWithConversationObject:conversationObject userName:caseForMatch];
    conversationModelData *cmData = [[conversationModelData alloc] initWithConversationObject:conversationObject arrayOfCaseUsers:conversationMembers];
    
    
    cJSQvc.conversationData = cmData;
    
    [self.navigationController pushViewController:cJSQvc animated:YES];
    
    //commenting out old conversationsViewController to replace with JSQViewController
    /*
     //open the conversationsViewController
     conversationsViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cvc"];
     
     cvc.conversationObject = conversationObject;
     cvc.conversationCaseUserID = caseForMatch;
     
     [self.navigationController pushViewController:cvc animated:YES];
     */
}



#pragma mark swipableTableViewCellsDelegateMethods

// click event on left utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    NSLog(@"No button was pressed");
    [self doSwipe:index swipeMode:@"NO"];
}

// click event on right utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    NSLog(@"Yes button was pressed");
    [self doSwipe:index swipeMode:@"YES"];
    
    
}

// utility button open/close event
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    
}

// prevent multiple cells from showing utilty buttons simultaneously
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    
    return YES;
}

// prevent cell(s) from displaying left/right utility buttons
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    return YES;
    
}

-(void)doSwipe:(NSInteger) index swipeMode:(NSString *)yesOrNo
{
    
    NSString *xmlToSwipe = [self createSwipeXML:index withMode:yesOrNo];
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Sending Swipe to Backend";
    [HUD show:YES];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xmlToSwipe}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                     BOOL errorCheck = [self checkForErrors:@"" errorCode:@"v7" returnedError:error];
                                    
                                    if (errorCheck) {
                                        
                                        // NSString *responseText = responseString;
                                        //NSLog(responseText);
                                        
                                        [HUD hide:NO];
                                        
                                        [self refreshMatchViewController];
                                        
                                    }
                                    else
                                    {
                                        //NSString *errorString = error.localizedDescription;
                                        NSLog(@"%@",[error localizedDescription]);
                                        [HUD hide:NO];
                                        
                                        return;
                                        
                                    }
                                }];
}

-(NSString *)createSwipeXML:(NSInteger) index withMode:(NSString *)YesOrNo;
{
    //hardcoded XML for sending a swipe
    /*
     <PAYLOAD><USEROBJECTID>NoJW05Xwsq</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>77rmIIxX9z</CASEOBJECTID><CASENAME>I just saw you</CASENAME><BUBBLEBURST>22</BUBBLEBURST><ITEM><CASEITEM>18</CASEITEM><PROPERTYNUM>8ZKsAhHzak</PROPERTYNUM><SWIPE><YES>OKXDu5YEJF</YES></SWIPE></ITEM></PAYLOAD>
     */
    
    
    NSString *selectedMatch = [self.matchesArray objectAtIndex:index];
    PFObject *caseObject = [self.matchesCaseObjectArrays objectAtIndex:index];
    NSString *caseItem = [self.matchesCaseItemArrays objectAtIndex:index];
    
    NSArray *caseObjectCaseItems = [caseObject objectForKey:@"caseItems"];
    NSString *propertyNum;
    NSString *caseName;
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    
    caseName = [caseObject objectForKey:@"caseName"];
    
    for(PFObject *caseItemObject in caseObjectCaseItems)
    {
        NSString *caseItemString = [caseItemObject objectForKey:@"caseItem"];
        if([caseItemString isEqualToString:caseItem])
        {
            propertyNum = [caseItemObject objectForKey:@"propertyNum"];
        }
    }
    
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:self.matchesUserName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"LAISO"];
    [xmlWriter writeCharacters:@"EN"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CASEOBJECTID"];
    [xmlWriter writeCharacters:caseObjectID];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CASENAME"];
    [xmlWriter writeCharacters:caseName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"ITEM"];
    
    [xmlWriter writeStartElement:@"CASEITEM"];
    [xmlWriter writeCharacters:caseItem];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"PROPERTYNUM"];
    [xmlWriter writeCharacters:propertyNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"SWIPE"];
    
    [xmlWriter writeStartElement:YesOrNo];
    [xmlWriter writeCharacters:selectedMatch];
    [xmlWriter writeEndElement];
    
    //close swipe element
    [xmlWriter writeEndElement];
    
    // close ITEM element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
}

-(void)refreshMatchViewController
{
    if([self.matchViewControllerMode isEqualToString:@"allMatches"])
    {
        [self refreshAllMatches];
        
    }
}

-(void)refreshAllMatches
{
    //query the itsMTLObject for the updated data
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Data After Swipe";
    [HUD show:YES];
    
    //needs to query for the user and pull some info
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    
    [query getObjectInBackgroundWithId:self.matchesUserName block:^(PFObject *latestCaseList, NSError *error) {
        
         BOOL errorCheck = [self checkForErrors:@"" errorCode:@"v8" returnedError:error];
        if(errorCheck)
        {
        // Do something with the returned PFObject
        NSLog(@"%@", latestCaseList);
        
        [HUD hide:NO];
        
        //loop through the itsMTLObject and gather all the user's matches
        NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
        NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
        NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
        NSArray *cases = [latestCaseList objectForKey:@"cases"];
        
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
                    NSString *matchesYesString = [caseItemObject objectForKey:@"yes"];
                    NSArray *matchesArray = [matchesString componentsSeparatedByString:@";"];
                    
                    for(NSString *mtlObjectID in matchesArray)
                    {
                        [allMatchesArray addObject:mtlObjectID];
                        [allMatchCaseObjectsArray addObject:caseObj];
                        NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                        
                        [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                        
                    }
                }
            }
        }
        
        self.matchesArray = [allMatchesArray copy];
        self.matchesCaseObjectArrays = [allMatchCaseObjectsArray copy];
        self.matchesCaseItemArrays = [allMatchCaseItemObjectsArray copy];
        
        [self.casesTableView reloadData];
            
        }
    }];
    
    
}

-(void)editCaseButtonPress:(id)sender
{
    UIButton *sendingButton = (UIButton *)sender;
    
    //case to edit is tag-100
    NSInteger caseToEdit = sendingButton.tag-100;
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:caseToEdit];
    
    caseDetailsCarouselViewController *cdcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdcvc2"];
    
    cdcvc.selectedCaseIndex=selectedIndex;
    
    cdcvc.userName = userName;
    cdcvc.itsMTLObject = self.itsMTLObject;
    cdcvc.manualLocationPropertyNum = self.manualLocationPropertyNum;
    cdcvc.designationProperties = self.designationProperties;
    PFObject *caseObj =  [caseListPruned objectAtIndex:[selectedIndex intValue]];
    
    NSString *caseID = [caseObj objectForKey:@"caseId"];
    
    NSString *caseimgURL;
    for (PFObject *caseProfileObj in caseProfileObjects)
    {
        NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
        if([caseID isEqualToString:caseProfileCaseID])
        {
            //display case information
            cdcvc.externalCaseName = [caseProfileObj objectForKey:@"externalCaseName"];
            PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
            caseimgURL = imgFile.url;
            NSData *imgData = [imgFile getData];
            
            UIImage *myCaseImage = [UIImage imageWithData:imgData];
            cdcvc.caseImage = myCaseImage;
            
        }
    }
    
    
    [self.navigationController pushViewController:cdcvc animated:NO];
}

-(NSString *)calculateStringForTimeSinceLastUpdate:(NSDate *) date
{
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    
    NSTimeInterval distanceBetweenDates = [currentDate timeIntervalSinceDate:date];
    double secondsInAnHour = 3600;
    NSInteger hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
    
    //june29 convert hours between dates into string
    NSInteger daysRemaining = hoursBetweenDates/24;
    NSInteger leftoverHoursRemaining = hoursBetweenDates-(daysRemaining*24);
    
    NSNumber *daysRemainingNum = [NSNumber numberWithInteger:daysRemaining];
    NSNumber *leftoverHoursNum = [NSNumber numberWithInteger:leftoverHoursRemaining];
    
    NSString *daysRemainingString = [daysRemainingNum stringValue];
    NSString *leftoverHoursString = [leftoverHoursNum stringValue];
    
    NSString *part1;
    if([daysRemainingNum intValue] ==0)
    {
        part1 = @"";
    }
    else
    {
        part1 = [daysRemainingString stringByAppendingString:@"d "];
    }
    
    NSString *part2 = [leftoverHoursString stringByAppendingString:@"h"];
    
    NSString *timeSinceLastUpdateString = [part1 stringByAppendingString:part2];
    
    return timeSinceLastUpdateString;
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==101)
    {
        strcpy(0, "bla");
    }
}
- (void)tabSelected:(NSInteger)selectedTab
{
    if(selectedTab==0)
    {
        //return the user to the homescreen
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    if(selectedTab==1)
    {
       //do nothing, this is selected
        
    }
    if(selectedTab==2)
    {
        //start a new search
        newCaseViewControllerv3 *ncvc = [[newCaseViewControllerv3 alloc] init];
        
        ncvc.itsMTLObject = self.itsMTLObject;
        //ncvc.manualLocationPropertyNum = homePageManualLocationPropertyNum;
        ncvc.designationProperties = self.designationProperties;
        //UINavigationController *uinc = self.navigationController;
        
        [self.navigationController pushViewController:ncvc animated:YES];
        
        
    }
    if(selectedTab==3)
    {
       //show a new screen for tracking current conversations
        
    }
    if(selectedTab==4)
    {
        //show profile screen
        //BA Comment Aug 23, may want to revisit the delegate structure for setting profile since now it can be accessed from multiple screens
        /*
        setProfileViewController2 *spvc2 = [self.storyboard instantiateViewControllerWithIdentifier:@"spvc2"];
        spvc2.delegate = self;
        spvc2.openingMode = @"HomeScreen";
        spvc2.itsMTLObject = self.HomePageITSMTLObject;
        spvc2.homeScreenMTLObjectID = self.HomePageITSMTLObject.objectId;
        [self.navigationController pushViewController:spvc2 animated:YES];
         */
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



@end
