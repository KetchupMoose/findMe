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
#import "BaseCaseDetailsSlidingViewController.h"
#import "MBProgressHUD.h"


@interface ViewCasesViewController ()

@end

@implementation ViewCasesViewController
NSArray *caseListJSON;
NSMutableArray *caseListPruned;
@synthesize casesTableView;
MBProgressHUD *HUD;
UIRefreshControl *refreshControl;
@synthesize userName;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    
    refreshControl = [[UIRefreshControl alloc]init];
    [self.casesTableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    [casesTableView setDataSource:self];
    [casesTableView setDelegate:self];
    
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
        
    
        for (PFObject *caseObject in caseListJSON)
        {
            
            NSString *caseID = [caseObject objectForKey:@"caseId"];
            if (caseID !=nil)
            {
                [caseListPruned addObject:caseObject];
                
            }
            
        }
       
        [casesTableView reloadData];
        
        [HUD hide:YES];
        
       // NSArray *myCases = [CaseBuilder casesFromJSON:[latestCase objectForKey:@"cases"] error:nil];
        
       // NSLog(@"%i",myCases.count);
        
        //NSString *jsonBlob1 = [jsonBlobArray objectAtIndex:0];
        
       // NSLog(jsonBlob1);
        
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshTable
{
    //if response case is ok, refresh the list of cases.
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    
    [query getObjectInBackgroundWithId:userName block:^(PFObject *object, NSError *error) {
        
        if(error)
        {
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Query Failed", nil) message:NSLocalizedString([error localizedDescription], nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            return;
            
        }
        
        PFObject *latestCaseList = object;
        self.itsMTLObject = latestCaseList;
        
        // NSLog(@"%@", latestCaseList);
        caseListJSON = [latestCaseList objectForKey:@"cases"];
        [caseListPruned removeAllObjects];
        
        for (PFObject *caseObject in caseListJSON)
        {
            
            NSString *caseID = [caseObject objectForKey:@"caseId"];
            if (caseID !=nil)
            {
                [caseListPruned addObject:caseObject];
                
            }
            
        }
        
        [refreshControl endRefreshing];
        
        [casesTableView reloadData];
        
        [HUD hide:YES];

    }];
    
  
}
-(void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

-(void) viewDidAppear:(BOOL)animated
{
    //refresh the itsMTLObject so it grabs the latest data
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Running Wait For Sync";
    [HUD show:YES];
    
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
                                      [self refreshTable];
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
    
    UILabel *caseNameLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *caseIDLabel = (UILabel *)[cell viewWithTag:3];
    PFObject *caseObject = [caseListPruned objectAtIndex:indexPath.row];
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    caseNameLabel.text = caseName;
    
    NSString *caseId = [caseObject objectForKey:@"caseId"];
    caseIDLabel.text = caseId;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 
    //bring up the case details view controller
    
    UIView *caseDetailsSelectorPopup = [[UIView alloc] initWithFrame:CGRectMake(25,50,250,250)];
    
    UIButton *classicViewButton = [[UIButton alloc] initWithFrame:CGRectMake(15,25,100,100)];
    UIButton *emailViewButton = [[UIButton alloc] initWithFrame:CGRectMake(140,25,100,100)];

    
    [classicViewButton setTitle:@"Classic View" forState:UIControlStateNormal];
    [emailViewButton setTitle:@"Email View" forState:UIControlStateNormal];
    
    classicViewButton.tag = indexPath.row;
    emailViewButton.tag = indexPath.row;
    
    classicViewButton.backgroundColor = [UIColor blueColor];
    emailViewButton.backgroundColor = [UIColor greenColor];
    
    classicViewButton.titleLabel.textColor = [UIColor blackColor];
    emailViewButton.titleLabel.textColor = [UIColor blackColor];
    
    [classicViewButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [emailViewButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    
    [classicViewButton addTarget:self action:@selector(classicButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [emailViewButton addTarget:self action:@selector(emailButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [caseDetailsSelectorPopup addSubview:classicViewButton];
    [caseDetailsSelectorPopup  addSubview:emailViewButton];

    
    caseDetailsSelectorPopup.backgroundColor = [UIColor lightGrayColor];
    
    [self.view addSubview:caseDetailsSelectorPopup];
    
    
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
    
    [self.navigationController pushViewController:bcdsvc animated:YES];
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
