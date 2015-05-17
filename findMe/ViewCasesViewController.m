//
//  ViewCasesViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "ViewCasesViewController.h"
#import <Parse/Parse.h>
#import "XMLWriter.h"
#import "CaseBuilder.h"
#import "CaseDetailsViewController.h"
#import "CaseDetailsEmailViewController.h"
#import "caseDetailsCarouselViewController.h"
#import "BaseCaseDetailsSlidingViewController.h"
#import "MBProgressHUD.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"


@interface ViewCasesViewController ()

@end

@implementation ViewCasesViewController
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


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
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
    
    caseListPruned = [[NSMutableArray alloc] init];
   // [self refreshTable];
    
    
    /*
    //MAR27 experimentation failed
    
    //MAR 27 remove this from view did load, it's being handled on appear
    
    //[self refreshTable];
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Cases";
    [HUD show:YES];
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query getObjectInBackgroundWithId:userName block:^(PFObject *latestCaseList, NSError *error) {
        // Do something with the returned PFObject
        
        NSLog(@"%@", latestCaseList);
       caseListJSON = [latestCaseList objectForKey:@"cases"];
        
        
        //this represents the overall list of cases
        caseListPruned = [[NSMutableArray alloc] init];
        caseIDSList = [[NSMutableArray alloc] init];
    
        for (PFObject *caseObject in caseListJSON)
        {
            
            NSString *caseID = [caseObject objectForKey:@"caseId"];
            if (caseID !=nil)
            {
                [caseListPruned addObject:caseObject];
                [caseIDSList addObject:caseID];
                
            }
            
        }
        
        //query for cases for showNames and ImageViews
        PFQuery *casesQuery = [PFQuery queryWithClassName:@"Cases"];
        [casesQuery whereKey:@"objectId" containedIn:caseIDSList];
        [casesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            //set the images and shownames
            NSLog(@"mar27 found these objects");
            NSLog(@"%luli",(unsigned long)objects.count);
            
            for(PFObject *caseObject in objects)
            {
                NSString *showName = [caseObject objectForKey:@"caseShowName"];
                NSString *imgURL = [caseObject objectForKey:@"caseImgURL"];
                
                if([showName length] >2)
                {
                    NSLog(@"got a lengther");
                    
                }
                [caseImages addObject:imgURL];
                [caseShowNames addObject:showName];
                
            }
            [casesTableView reloadData];
            
            [HUD hide:YES];
            
        }];
       
       
        
       // NSArray *myCases = [CaseBuilder casesFromJSON:[latestCase objectForKey:@"cases"] error:nil];
        
       // NSLog(@"%i",myCases.count);
        
        //NSString *jsonBlob1 = [jsonBlobArray objectAtIndex:0];
        
       // NSLog(jsonBlob1);
        
    }];
    */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshTable
{
    //if response case is ok, refresh the list of cases.
    // Set determinate mode
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Querying Case Data";
    [HUD show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    //PFQuery *casesQuery = [PFQuery queryWithClassName:@"Cases"];
    
    //example structure for running two queries at once:
   // NSArray *queryArray = [NSArray arrayWithObjects:messageQuery,pokeQuery,commentsQuery,nil];
    //PFQuery *allQueries = [PFQuery orQueryWithSubqueries:queryArray];
    
    
        
        PFObject *object = [query getObjectWithId:userName];
    
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
        caseObjects = [caseQuery findObjects];
    
        PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
        [caseProfileQuery whereKey:@"caseID" containedIn:caseIDSList];
        caseProfileObjects = [caseProfileQuery findObjects];
    
        
        [refreshControl endRefreshing];
        [casesTableView reloadData];
        
        [HUD hide:NO];
        
 

    
  
}
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    
    //[casesTableView reloadData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    
    self.navigationController.navigationBarHidden = NO;
    
    //call waitForSync first and then refresh the table
    
    [PFCloud callFunctionInBackground:@"waitForSync"
                       withParameters:@{@"payload": userName}
                                block:^(NSString *responseString, NSError *error) {
                                    NSLog(responseString);
                                    
                                if([responseString containsString:@"ERROR"])
                                {
                                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WaitForSync Failed", nil) message:NSLocalizedString(responseString, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                    [HUD hide:NO];
                                    
                                    return;
                                    
                                }
                                    else
                                    {
                                        
                                        dispatch_async(dispatch_get_main_queue(),
                                                       ^{
                                        [HUD hide:NO];
                                        [self refreshTable];
                                                       });
                                        
                                    }
                                
                                }];
    
    
    
}


#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[caseListPruned count];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseCell" forIndexPath:indexPath];
    
    UILabel *caseShowNameLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *matchesCountLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *caseDetail1 = (UILabel *)[cell viewWithTag:3];
    UILabel *caseDetail2 = (UILabel *)[cell viewWithTag:4];
    UILabel *caseDetail3 = (UILabel *)[cell viewWithTag:5];
    UIImageView *caseImgView = (UIImageView *)[cell viewWithTag:6];
    UIButton *viewMatchButton = (UIButton *)[cell viewWithTag:7];
    PFObject *caseObject = [caseListPruned objectAtIndex:indexPath.row];
    
   /* NSString *caseShowName = [caseShowNames objectAtIndex:indexPath.row];
    
    caseShowNameLabel.text = caseShowName;
    if([caseShowName length] ==0)
    {
        caseShowNameLabel.text = @"Default User Name";
        
    }
    */
    PFObject *caseObj =  [caseListPruned objectAtIndex:indexPath.row];
    
   NSString *caseID = [caseObj objectForKey:@"caseId"];
    caseDetail1.text = caseID;
    //check to see if there is a caseProfile for this caseID
    NSString *caseimgURL;
    for (PFObject *caseProfileObj in caseProfileObjects)
    {
        NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
        if([caseID isEqualToString:caseProfileCaseID])
        {
            //display case information
            caseShowNameLabel.text = [caseProfileObj objectForKey:@"internalCaseName"];
            PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
            caseimgURL = imgFile.url;
        }
    }
    
    UIActivityIndicatorViewStyle *activityStyle = UIActivityIndicatorViewStyleGray;

    //NSString *caseImgURL = [caseImages objectAtIndex:indexPath.row];
    if([caseimgURL length] ==0)
    {
        caseimgURL = @"http://www.carascravings.com/wp-content/uploads/2012/07/profile-photo-220x183.jpg";
    }
    [caseImgView setImageWithURL:[NSURL URLWithString:caseimgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    //check number of matches in case
    NSArray *caseItems = [caseObj objectForKey:@"caseItems"];
    
    //loop through the itsMTLObject and gather all the user's matches
    NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
    NSMutableArray *allMatchesCaseTypes = [[NSMutableArray alloc] init];
  
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
    NSInteger numOfMatches = [allMatchesArray count];
    NSString *numOfMatchesString = [[NSString stringWithFormat:@"%ld",(long)numOfMatches] stringByAppendingString:@" Matches"];
    matchesCountLabel.text = numOfMatchesString;
   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:indexPath.row];
    
    caseDetailsCarouselViewController *cdcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdcvc"];
    
    cdcvc.selectedCaseIndex=selectedIndex;
    
    cdcvc.userName = userName;
    cdcvc.itsMTLObject = self.itsMTLObject;
    cdcvc.manualLocationPropertyNum = self.manualLocationPropertyNum;
    
    [self.navigationController pushViewController:cdcvc animated:NO];
    
    
    /*
    //bring up the case details view controller
    
    UIView *caseDetailsSelectorPopup = [[UIView alloc] initWithFrame:CGRectMake(25,50,250,250)];
    
    UIButton *classicViewButton = [[UIButton alloc] initWithFrame:CGRectMake(15,25,100,100)];
    UIButton *emailViewButton = [[UIButton alloc] initWithFrame:CGRectMake(140,25,100,100)];
    UIButton *carouselViewButton = [[UIButton alloc] initWithFrame:CGRectMake(15,135,100,100)];
    
    [classicViewButton setTitle:@"Classic View" forState:UIControlStateNormal];
    [emailViewButton setTitle:@"Email View" forState:UIControlStateNormal];
    [carouselViewButton setTitle:@"Carousel View" forState:UIControlStateNormal];
    
    classicViewButton.tag = indexPath.row;
    emailViewButton.tag = indexPath.row;
    carouselViewButton.tag = indexPath.row;
    
    classicViewButton.backgroundColor = [UIColor blueColor];
    emailViewButton.backgroundColor = [UIColor greenColor];
    carouselViewButton.backgroundColor = [UIColor redColor];
    
    
    classicViewButton.titleLabel.textColor = [UIColor blackColor];
    emailViewButton.titleLabel.textColor = [UIColor blackColor];
    carouselViewButton.titleLabel.textColor = [UIColor blackColor];
    
    [classicViewButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [emailViewButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [carouselViewButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    
    [classicViewButton addTarget:self action:@selector(classicButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [emailViewButton addTarget:self action:@selector(emailButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [carouselViewButton addTarget:self action:@selector(carouselButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [caseDetailsSelectorPopup addSubview:classicViewButton];
    [caseDetailsSelectorPopup  addSubview:emailViewButton];
    [caseDetailsSelectorPopup  addSubview:carouselViewButton];
    
    caseDetailsSelectorPopup.backgroundColor = [UIColor lightGrayColor];
    
    [self.view addSubview:caseDetailsSelectorPopup];
    */
    
    /*
    NSNumber *selectedIndex = [NSNumber numberWithInteger:indexPath.row];
    
    CaseDetailsViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdvc"];
    
    cdvc.selectedCaseIndex=selectedIndex;
   
    cdvc.userName = userName;
    cdvc.itsMTLObject = self.itsMTLObject;
    
    [self.navigationController pushViewController:cdvc animated:YES];
    */
}

-(void) classicButtonClick:(id)sender;
{
    //get index from tag
    UIButton *sendingButton = (UIButton *) sender;
    int buttonTag = (int)sendingButton.tag;
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:buttonTag];
    
    CaseDetailsViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdvc"];
    
    cdvc.selectedCaseIndex=selectedIndex;
    
    cdvc.userName = userName;
    cdvc.itsMTLObject = self.itsMTLObject;
    
    //close the popupView
    UIView *popupView = sendingButton.superview;
    [popupView removeFromSuperview];
    
    
    [self.navigationController pushViewController:cdvc animated:YES];
    
}

-(void) emailButtonClick:(id)sender;
{
    //get index from tag
    UIButton *sendingButton = (UIButton *) sender;
    int buttonTag = (int)sendingButton.tag;
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:buttonTag];
    
    CaseDetailsEmailViewController *cdevc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdevc"];
    
    cdevc.selectedCaseIndex=selectedIndex;
    
    cdevc.userName = userName;
    cdevc.itsMTLObject = self.itsMTLObject;
    
    //close the popupView
    UIView *popupView = sendingButton.superview;
    [popupView removeFromSuperview];
    
    BaseCaseDetailsSlidingViewController *bcdsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"bcdsvc"];
    
    [bcdsvc setTopViewController:cdevc];
    
    [self.navigationController pushViewController:bcdsvc animated:NO];
}

-(void)carouselButtonClick:(id)sender
{
    //get index from tag
    UIButton *sendingButton = (UIButton *) sender;
    int buttonTag = (int)sendingButton.tag;
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:buttonTag];
    
    caseDetailsCarouselViewController *cdcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdcvc"];
    
    cdcvc.selectedCaseIndex=selectedIndex;
    
    cdcvc.userName = userName;
    cdcvc.itsMTLObject = self.itsMTLObject;
    cdcvc.manualLocationPropertyNum = self.manualLocationPropertyNum;
    //close the popupView
    UIView *popupView = sendingButton.superview;
    [popupView removeFromSuperview];
    
    [self.navigationController pushViewController:cdcvc animated:NO];

}

-(IBAction)newCase:(id)sender
{
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Creating Case";
    [HUD show:YES];
    
    
    //create a new case via XML
    NSString *generatedXMLString = [self createXMLFunction];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": generatedXMLString}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        [HUD hide:YES];
                                                                                
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Case Uploaded Successfully!", nil) message:NSLocalizedString(@"Case Uploaded Correctly.  Pull Down To Refresh And View", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                        
                                    }
                                    else
                                    {
                                          [HUD hide:YES];
                                        NSLog(error.localizedDescription);
                                        
                                    }
                                }];

}

-(NSString *)createXMLFunction
{
    //show user list of choices if there are multiple templates based on their entered user info/preferences
    
    //pull templatemaker jsons
    
    //create new case based on their templatemaker jsons
    
    //hard coded value:
    NSString *hardcodedXML =@"<PAYLOAD><USEROBJECTID>exTJgfgotY</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID></CASEOBJECTID><CASENAME>refresh test 3</CASENAME><ITEM><CASEITEM>1</CASEITEM><PROPERTYNUM>GSU3bVVIxF</PROPERTYNUM><MYVALUE>1</MYVALUE></ITEM><ITEM><CASEITEM>2</CASEITEM><PROPERTYNUM>Hwww7qnXNn</PROPERTYNUM></ITEM><ITEM><CASEITEM>3</CASEITEM><PROPERTYNUM>pkxK92zhKh</PROPERTYNUM><MYVALUE>1</MYVALUE></ITEM><ITEM><CASEITEM>4</CASEITEM><PROPERTYNUM>mk6CND8PaH</PROPERTYNUM><ANSWER><A>36</A></ANSWER></ITEM></PAYLOAD>";
    
    
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:userName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"LAISO"];
    [xmlWriter writeCharacters:@"EN"];
    [xmlWriter writeEndElement];
    
    //blank case objectID for starting new case
    [xmlWriter writeStartElement:@"CASEOBJECTID"];
    [xmlWriter writeEndElement];
    
    
    [xmlWriter writeStartElement:@"CASENAME"];
    [xmlWriter writeCharacters:@"CrazyNewCase"];
    [xmlWriter writeEndElement];
    
    
        //build strings for building item
    [xmlWriter writeStartElement:@"ITEM"];
    
    [xmlWriter writeStartElement:@"CASEITEM"];
    [xmlWriter writeCharacters:@"9002"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"PROPERTYNUM"];
    [xmlWriter writeCharacters:@"Satl6b79yh"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"MYVALUE"];
    [xmlWriter writeCharacters:@"Ontario"];
    [xmlWriter writeEndElement];
      
    [xmlWriter writeStartElement:@"THEIRVALUE"];
    [xmlWriter writeCharacters:@"Ontario"];
    [xmlWriter writeEndElement];
    
    //close item element
    [xmlWriter writeEndElement];
    
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
   // return xml;
    
    return hardcodedXML;
    
}


@end
