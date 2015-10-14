//
//  matchesViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-02-11.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "matchesViewController.h"
#import "UIImageView+WebCache.h"
#import "XMLWriter.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "conversationsViewController.h"
#import "conversationJSQViewController.h"
#import "conversationModelData.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface matchesViewController ()

@end

@implementation matchesViewController

 NSMutableSet* _collapsedSections;
MBProgressHUD *HUD;
BOOL firstMatchViewLoad = TRUE;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _collapsedSections = [NSMutableSet new];
    // Do any additional setup after loading the view.
    self.matchesTableView.delegate = self;
    self.matchesTableView.dataSource = self;
    
    self.matchesPerCaseArray = [[NSMutableArray alloc] init];
    self.sectionHeaderCaseObjectArray = [[NSMutableArray alloc] init];
    
    //loop through the incoming array of data on matches and create two arrays to separate them into separate sections
    NSString *previousCaseIDLooped;
    int matchCountInCase = 1;
    int startLoop = 0;
    for(PFObject *caseObject in self.matchesCaseObjectArrays)
    {
        NSString *caseObjID = [caseObject objectForKey:@"caseId"];
       
    if(startLoop == 0)
    {
            previousCaseIDLooped = caseObjID;
            startLoop = startLoop+1;
            
    }
    else
    {
        
        if([caseObjID isEqualToString:previousCaseIDLooped])
        {
            matchCountInCase = matchCountInCase+1;
            //add a new item to the array keeping track of item count in each array
            if(startLoop+1 == self.matchesCaseObjectArrays.count)
            {
                NSNumber *matchCountPerCaseNum = [NSNumber numberWithInt:matchCountInCase];
                
                [self.matchesPerCaseArray addObject:matchCountPerCaseNum];
                [self.sectionHeaderCaseObjectArray addObject:caseObject];
                
            }
        }
        else
        {
            NSNumber *matchCountPerCaseNum = [NSNumber numberWithInt:matchCountInCase];
            
            [self.matchesPerCaseArray addObject:matchCountPerCaseNum];
            [self.sectionHeaderCaseObjectArray addObject:caseObject];
            
            matchCountInCase=1;
            previousCaseIDLooped = caseObjID;

        }
        startLoop = startLoop +1;
        
       
    }
    }
    
    [self.matchesTableView reloadData];
    
     [self.matchesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.matchesTableView.backgroundColor = [UIColor clearColor];
    
    self.matchesTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    firstMatchViewLoad = FALSE;

    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.matchesTableView reloadData];
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    self.navigationController.navigationBarHidden = NO;
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

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   //if first load, start them all as 0 and add them to the array
    
  
    //check the number of rows which should be included in this part of the tableview
    NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
    NSInteger rowCount = [objCountNumber integerValue];
    
    if(firstMatchViewLoad==TRUE)
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
    sender.backgroundColor = [UIColor greenColor];
    [self.matchesTableView beginUpdates];
    int section = sender.tag;
    bool shouldCollapse = ![_collapsedSections containsObject:@(section)];
    if (shouldCollapse) {
        int numOfRows = [self.matchesTableView numberOfRowsInSection:section];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numOfRows];
        [self.matchesTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_collapsedSections addObject:@(section)];
    }
    else {
        NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
        NSInteger numOfRows = [objCountNumber integerValue];
        NSArray* indexPaths = [self indexPathsForSection:section withNumberOfRows:numOfRows];
        [self.matchesTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [_collapsedSections removeObject:@(section)];
    }
    [self.matchesTableView endUpdates];
    //[_tableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50.0;
}


- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.matchesTableView.frame.size.width,50)];
    
    //get count of matches for this particular section
    NSNumber *objCountNumber = [self.matchesPerCaseArray objectAtIndex:section];
    NSInteger matchCount = [objCountNumber integerValue];
    
    UILabel *updateCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.matchesTableView.frame.size.width-20,0,20,20)];
    
    updateCountLabel.backgroundColor = [UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1];
    updateCountLabel.textColor = [UIColor whiteColor];
    updateCountLabel.layer.cornerRadius = 10.0f;
    updateCountLabel.layer.masksToBounds = YES;
    updateCountLabel.text = [objCountNumber stringValue];
    
    [updateCountLabel setTextAlignment:NSTextAlignmentCenter];
    
    UIButton* result = [UIButton buttonWithType:UIButtonTypeCustom];
    result.frame = CGRectMake(0,0,self.matchesTableView.frame.size.width,50);
    
    [result addTarget:self action:@selector(sectionButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    result.backgroundColor = [UIColor clearColor];
    [result setTitle:[NSString stringWithFormat:@"Section %ld", (long)section] forState:UIControlStateNormal];
    result.tag = section;
    return result;
    
    [sectionView addSubview:result];
    [sectionView addSubview:updateCountLabel];
    //show some details about the case
    
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
    UILabel *matchPctLabel = (UILabel *)[cell viewWithTag:3];
    UIView *bgView = [cell viewWithTag:4];
    
    matchCaseNameLabel.textColor = [UIColor whiteColor];
    matchPctLabel.textColor = [UIColor whiteColor];
    
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
           matchCaseNameLabel.text = [caseProfileObj objectForKey:@"externalCaseName"];
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
    
    NSArray *returnedConversations = [query findObjects];
    
    PFObject *conversationObject;
    
    if([returnedConversations count] ==0)
    {
        //create a conversation object
        conversationObject = [PFObject objectWithClassName:@"Conversations"];
        [conversationObject setObject:conversationMembers forKey:@"Members"];
        [conversationObject save];
        
        
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
                                    if (!error) {
                                        
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
        
        [self.matchesTableView reloadData];
        
        }];
    

}


@end
