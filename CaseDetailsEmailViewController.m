//
//  CaseDetailsEmailViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "CaseDetailsEmailViewController.h"
#import "popupViewController.h"
#import "XMLWriter.h"
#import "SWTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "UIViewController+ECSlidingViewController.h"
#import "matchesViewController.h"

@interface CaseDetailsEmailViewController ()

@end

@implementation CaseDetailsEmailViewController
@synthesize selectedCaseIndex;
@synthesize itsMTLObject;
@synthesize locationManager;
@synthesize jsonObject;
@synthesize jsonDisplayMode;


NSArray *caseItems;
NSMutableArray *sortedCaseItems;
NSMutableArray *suggestedProperties;
NSMutableArray *suggestedCases;
NSMutableArray *answeredProperties;
NSMutableArray *answeredCases;
NSMutableArray *answeredPropertiesIndex;
NSMutableArray *infoMessageProperties;
NSMutableArray *infoCases;
NSMutableArray *NoAnswerCases;
NSMutableArray *NoAnswerProperties;
NSMutableArray *suggestedCaseIndex;
NSMutableArray *updatedPropertiesIndex;
NSMutableArray *customAnsweredCases;
NSMutableArray *customAnsweredProperties;
NSMutableArray *customAnsweredPropertiesIndex;
NSMutableArray *browseCases;
NSMutableArray *browseProperties;
NSMutableArray *browsePropertiesIndex;
NSMutableArray *newlyCreatedPropertiesIndex;
NSMutableArray *changedCaseItemsIndex;
NSMutableArray *priorCaseIDS;
NSMutableArray *templateOptionsCounts;

PFObject *returnedITSMTLObject;
//this variable stores the case being updated so it's clear which one to show when the json returns.  Used for a case where we're not in "template mode".
NSString *caseBeingUpdated;
BOOL templateMode;

int suggestedCaseDisplayedIndex;
int updatedCaseTicker = 0;

NSArray *selectedCaseItemAnswersList;
NSArray *optionsArray;
NSArray *ansStaticArray;
NSMutableArray *propsArray;
NSMutableArray *propertyIDSArray;
NSMutableArray *answersArray;
//need to set selectedPropertyQuestion from the question picked by the pickerView
NSString *selectedPropertyQuestion;
NSInteger newTextFieldIndex;
NSInteger selectedItemForUpdate;
MBProgressHUD *HUD;
NSDate *updateDate;
NSDate *secondUpdateCompare;
NSNumber *lastTimestamp;
int EmailTimerTickCaseDetails =0;
int EmailsecondaryTimerTicks = 0;


//location manager variables

CLGeocoder *geocoder;
CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;

//used for calcaulting swipe gestures
CGPoint startLocation;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.popupVC =  (popupViewController *)self.slidingViewController.underLeftViewController;
    
    //set up delegates
    self.caseDetailsEmailTableView.delegate = self;
    self.caseDetailsEmailTableView.dataSource = self;
    
    //location manager instance variable allocs
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    
    PFObject *caseObject;
    if([self.jsonDisplayMode isEqualToString:@"template"])
    {
        caseObject = (PFObject *)jsonObject;
        templateMode =1;
        
    }
    else
    {
        int selectedCaseInt = (int)[selectedCaseIndex integerValue];
        
        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
        
        caseObject = [allCases objectAtIndex:selectedCaseInt];
    }
    
    
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    int length = (int)[caseObjectID length];
    
    if(length==0)
    {
        self.submitAnswersButton.titleLabel.text = @"Create Case";
        templateMode = 1;
    }
    else
    {
        templateMode= 0;
        caseBeingUpdated = caseObjectID;
        
    }
    caseItems= [caseObject objectForKey:@"caseItems"];
    
    //sort the incoming caseItems by priority
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    
    //setting up arrays for storing three sets of properties and cases based on type: info messages, already answered properties, and new suggested properties
    
    propertyIDSArray = [[NSMutableArray alloc] init];
    answeredPropertiesIndex =[[NSMutableArray alloc] init];
    answeredProperties = [[NSMutableArray alloc] init];
    answeredCases = [[NSMutableArray alloc] init];
    infoCases = [[NSMutableArray alloc] init];
    infoMessageProperties = [[NSMutableArray alloc] init];
    suggestedProperties = [[NSMutableArray alloc] init];
    suggestedCases = [[NSMutableArray alloc] init];
    suggestedCaseIndex = [[NSMutableArray alloc] init];
    updatedPropertiesIndex = [[NSMutableArray alloc] init];
    customAnsweredCases = [[NSMutableArray alloc] init];
    customAnsweredProperties = [[NSMutableArray alloc] init];
    customAnsweredPropertiesIndex = [[NSMutableArray alloc] init];
    browseCases = [[NSMutableArray alloc] init];
    browseProperties = [[NSMutableArray alloc] init];
    browsePropertiesIndex = [[NSMutableArray alloc] init];
    newlyCreatedPropertiesIndex= [[NSMutableArray alloc] init];
    suggestedCaseDisplayedIndex = -1;
    changedCaseItemsIndex =[[NSMutableArray alloc] init];
    priorCaseIDS = [[NSMutableArray alloc] init];
    templateOptionsCounts = [[NSMutableArray alloc] init];
    
    //fill an array of the prior cases so the client can look for a new previously non-existing caseId if the user is submitting a new template
    NSArray *cases = [self.itsMTLObject objectForKey:@"cases"];
    for (PFObject *eachCase in cases)
    {
        NSString *caseID = [eachCase objectForKey:@"caseId"];
        if([caseID length] >0)
            [priorCaseIDS addObject:caseID];
    }
    
    //get all the property ID's from each item in the selected case.
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *propNum = [eachCaseItem objectForKey:@"propertyNum"];
        [propertyIDSArray addObject:propNum];
    }
    
    //get all the property information for the list of properties to consider
    PFQuery *propertsQuery = [PFQuery queryWithClassName:@"Properts"];
    [propertsQuery whereKey:@"objectId" containedIn:propertyIDSArray];
   
    
    propsArray = [[propertsQuery findObjects] mutableCopy];
    
    //sort the propsArray based on the order in sortedCaseItems
    NSMutableArray *sortingPropsArray = [[NSMutableArray alloc] init];
    
    for(PFObject *caseItem in sortedCaseItems)
    {
        NSString *propID = [caseItem objectForKey:@"propertyNum"];
        
        for (PFObject *propObject in propsArray)
        {
            NSString *propObjectID = propObject.objectId;
            
            if([propObjectID isEqualToString:propID])
            {
                [sortingPropsArray addObject:propObject];
                
            }
        }
    }
    
    propsArray = sortingPropsArray;
    
    //sort the properties into four categories based on their type: info messages, answerableQuestions, customAnswerableQuestions, and new suggestions
    int g = 0;
    for (PFObject *property in propsArray)
    {
        NSString *propType = [property objectForKey:@"propertyType"];
        NSString *options = [property objectForKey:@"options"];
        
        if([propType  isEqual:@"I"])
        {
            //property is an info message
            [infoMessageProperties addObject:property];
            [infoCases addObject:sortedCaseItems[g]];
        }
        else if([propType isEqual:@"N"])
        {
            [NoAnswerProperties addObject:property];
            [NoAnswerCases addObject:sortedCaseItems[g]];
        }
        
        else if([propType isEqual:@"B"])
        {
            [browseProperties addObject:property];
            [browseCases addObject:sortedCaseItems[g]];
        }
        
        else if([options length]==0)
        {
            [customAnsweredProperties addObject:property];
            [customAnsweredProperties addObject:sortedCaseItems[g]];
        }
        else
            
        {
            PFObject *caseItemObject = sortedCaseItems[g];
            NSArray *answers = [caseItemObject objectForKey:@"answers"];
            
            if(answers.count>=1)
            {
                NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
                [answeredPropertiesIndex addObject:indexNum];
                //array for keeping track of the properties with answers.  Some of these may be info messages so that is dealt with further down.  It is assumed info messages can not have answers.
                //add the property to the list of answeredProperties
                [answeredProperties addObject:property];
                [answeredCases addObject:sortedCaseItems[g]];
                
            }
            else
            {
                [suggestedProperties addObject:property];
                [suggestedCases addObject:sortedCaseItems[g]];
                NSNumber *caseIndex = [NSNumber numberWithInt:g];
                [suggestedCaseIndex addObject:caseIndex];
            }
        }
        g=g+1;
    }
    
    
    //submit answers button is set to disabled and gray until the user makes a change
    self.submitAnswersButton.enabled = 0;
    self.submitAnswersButton.backgroundColor = [UIColor lightGrayColor];
    
    //set the last timestamp value for cases where it's not the first template
    NSArray *casesArray = [self.itsMTLObject objectForKey:@"cases"];
    
    if(templateMode==0)
    {
       //do nothing, the popupViewController will control refreshing
        
    }
    else
    //this view controller will control refreshing after all data is entered
    {
       
        
        for (PFObject *eachReturnedCase in sortedCaseItems)
        {
            //set the last timestamp if polling on the client is required
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] <=0)
            {
                NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                lastTimestamp = [f numberFromString:timeStampReturn];
                
            }
            
            //set the templateOptionsArray so the popupViewController can keep track of how many options were originally submitted for determinining whether an answer should be marked as "a" or "custom"
            NSString *propNum = [eachReturnedCase objectForKey:@"propertyNum"];
            for(PFObject *propObj in propsArray)
            {
                if([propObj.objectId isEqualToString:propNum])
                {
                    NSString *options = [propObj objectForKey:@"options"];
                    
                    //get array from semi-colon delimited text so we can get the count.
                    NSArray *templateOptionsArray = [options componentsSeparatedByString:@";"];
                    NSNumber *templateOptionCountNum = [NSNumber numberWithInteger:[templateOptionsArray count]];
                    
                    [templateOptionsCounts addObject:templateOptionCountNum];
                    
                    
                }
            }
            
        }

    }
    [self.caseDetailsEmailTableView reloadData];

}

-(void) viewDidAppear:(BOOL)animated
{
    PFObject *caseItemObject;
    
    if([self.jsonDisplayMode isEqualToString:@"template"])
    {
        caseItemObject = (PFObject *)jsonObject;
        templateMode =1;
        
    }
    else
    {
        int selectedCaseInt = (int)[selectedCaseIndex integerValue];
        
        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
        caseItemObject = [allCases objectAtIndex:selectedCaseInt];
    }
   
    NSString *caseObjectID = [caseItemObject objectForKey:@"caseId"];
    
    int length = (int)[caseObjectID length];
    
    if(length==0)
    {
        self.submitAnswersButton.titleLabel.text = @"Create Case";
        templateMode = 1;
    }
    else
    {
        templateMode= 0;
        caseBeingUpdated = caseObjectID;
    }

}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    
    // Tell it which view should be created under Right
    
    /*
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[popupViewController class]]) {
        self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"popupvc"];
    }
     */
    self.navigationController.navigationBarHidden = NO;
    
    
    [self getLocation:self];
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
    int caseItemsCount = (int)[sortedCaseItems count];
    
    return caseItemsCount +1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"caseDetailsEmailCell"];
    
    if(cell==nil)
    {
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"caseDetailsEmailCell"];
    }
    
    
    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor clearColor];
    [cell setSelectedBackgroundView:bgColorView];
    
    UILabel *propertyDescrLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *answersLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:3];
    UIImageView *iconImgView = (UILabel *)[cell viewWithTag:4];
    
    int sortedCaseItemCount = (int)[sortedCaseItems count];
    
    if(indexPath.row == sortedCaseItemCount)
    {
        //show a button to create a new caseItem instead
        
        propertyDescrLabel.text = @"Create a New Case Item";
        answersLabel.text = @"";
        NSString *imgURL = @"http://www.primaryclassroomresources.co.uk/teaching-resources/promotion_new.png";
        
        UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
        
        [iconImgView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
        
        return cell;
        
    }
    
    PFObject *propAtIndex;
 
    //check to see the type of property and assign different values to the "answersLabel" accordingly.
    
    PFObject *caseItemPicked = [sortedCaseItems objectAtIndex:indexPath.row];
    selectedItemForUpdate = indexPath.row;
    
    NSString *caseItemPickedPropertyNum = [caseItemPicked objectForKey:@"propertyNum"];
    
    //check to see if the object is a new property--new properties are set as NSDictionaries and cannot be accessed by .objectId
     if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:(int)indexPath.row]])
     {
         propAtIndex = [propsArray objectAtIndex:indexPath.row];
         
     }
    else
    {
        for(PFObject *propObject in propsArray)
        {
            if([propObject.objectId isEqualToString:caseItemPickedPropertyNum])
            {
                propAtIndex = propObject;
                break;
                
            }
        }
  
    }
    
    NSString *propertyDescr = [propAtIndex objectForKey:@"propertyDescr"];
    propertyDescrLabel.text = propertyDescr;
    
    NSString *newFlag = [caseItemPicked objectForKey:@"new"];
    if([newFlag isEqualToString:@"X"])
    {
        //color the border of the cell blue
        UIColor *lightBlueColor = [UIColor colorWithRed:215.0f/255.0f green:249.0f/255.0f blue:253.0f/255.0f alpha:1];
        cell.backgroundColor = lightBlueColor;
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
        
    }
    
    NSArray *CaseItemAnswersListAtIndex = [caseItemPicked objectForKey:@"answers"];
    //setting global var
    
    NSString *propertyType = [propAtIndex objectForKey:@"propertyType"];
    NSString *options = [propAtIndex objectForKey:@"options"];
    NSString *imgURL = [propAtIndex objectForKey:@"iconImageURL"];
    
    
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    
    [iconImgView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    
    if([propertyType isEqualToString:@"I"])
    {
        //display an info message, hide the options view
    
        answersLabel.text = @"Click to View More";
       
         //use this code later if this entry is selected
        //for the caseItem of this index, take the params value
         /*
        NSString *params = [questionItemPicked objectForKey:@"params"];
        
        NSArray * paramsArray = [params componentsSeparatedByString:@";"];
        
        //loop through the infoMsg and replace instances of &# with the values in the param array.
        int i = 1;
        if (paramsArray.count>=1)
        {
            for (i=1;i<paramsArray.count+1;i++)
            {
                NSString *numString = [NSString stringWithFormat:@"%i",i];
                NSLog(numString);
                NSString *stringToReplace = [@"&" stringByAppendingString:numString];
                
                [infoMsg stringByReplacingOccurrencesOfString:stringToReplace withString:[paramsArray objectAtIndex:i-1]];
            }
        }
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info Message", nil) message:NSLocalizedString(infoMsg, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        */
    }
    else
    if([propertyType isEqualToString:@"N"])
        {
            //do nothing, hide the options view
            answersLabel.text = @"Property Type N";
            
        }
    else if([propertyType isEqualToString:@"B"])
        {
            //do nothing for now.  in the future, query for match information based on shown fields.
            answersLabel.text = @"Click to Browse Your Matches";
            
        }
    else
        {
            //check to see if this row is one of the custom answer types.  It is if option length is 0.
            if([options length] ==0)
            {
                //display just one custom answer
                NSString *customAns;
                //check to see if the custom answer is there
                for (PFObject *eachAnsObj in CaseItemAnswersListAtIndex)
                {
                    customAns = [eachAnsObj valueForKey:@"custom"];
                }
                answersLabel.text = customAns;
                
            }
            else
            {
                answersArray = [[NSMutableArray alloc] init];
                [answersArray removeAllObjects];
                
                for (NSString *eachAnsObj in CaseItemAnswersListAtIndex)
                {
                    NSString *ansNum = [eachAnsObj valueForKey:@"a"];
                    if([ansNum length] ==0)
                    {
                        ansNum = [eachAnsObj valueForKey:@"custom"];
                    }
                    [answersArray addObject:ansNum];
                    
                }
                ansStaticArray = [answersArray mutableCopy];
                
                //retrieve the property choices for this caseItemObject from Parse.
                
                NSString *optionsString = [propAtIndex objectForKey:@"options"];
                
                //NSLog(@"%@",optionsString);
                
                //need to convert options string to an array of objects with ; separators.
                NSString *finalAnsString = @"";
                
                optionsArray = [optionsString componentsSeparatedByString:@";"];
                
                for(NSString *optString in optionsArray)
                {
                    if([answersArray containsObject:optString])
                    {
                        NSLog(@"hi");
                        
                    }
                }
                
                int indexMatcher = 1;
                for(NSString *optString in optionsArray)
                {
                    NSString *numMatcher = [[NSNumber numberWithInt:indexMatcher] stringValue];
                    if([answersArray containsObject:numMatcher] || [answersArray containsObject:optString])
                    {
                        if(indexMatcher==optionsArray.count)
                        {
                             finalAnsString = [finalAnsString stringByAppendingString:optString];
                        }
                        else
                        {
                            finalAnsString = [[finalAnsString stringByAppendingString:optString]stringByAppendingString:@";"];
                        }
                    }
                      indexMatcher = indexMatcher+1;
                }
                answersLabel.text = finalAnsString;
            }
              
    }
        return cell;
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
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
    
    return leftUtilityButtons;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self doTableViewSelectionChange:indexPath];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self doTableViewSelectionChange:indexPath];
    
}

-(void)doTableViewSelectionChange:(NSIndexPath*) indexPath
{
    if([self.slideoutDisplayed isEqualToString:@"yes"])
    {
        [self.slidingViewController resetTopViewAnimated:YES];
        
    }
    
    //if the selected row is greater than the count of caseItems, show the NewPropertyViewController
    
    if(indexPath.row==sortedCaseItems.count)
    {
        NSLog(@"create a new case");
        NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
        npvc.userName = self.userName;
        npvc.delegate = self;
        
        [self.navigationController pushViewController:npvc animated:YES];
        
        return;
        
    }
    
    //popup a small window for editing the selection of this entry
    
    UIView *popupView = [[UIView alloc] initWithFrame:CGRectMake(20,50,280,400)];
    UIColor *lightYellowColor = [UIColor colorWithRed:252.0f/255.0f green:252.0f/255.0f blue:150.0f/255.0f alpha:1];
    popupView.backgroundColor = lightYellowColor;
    
    
    popupViewController *popVC = self.popupVC;
    
    //set data for popupViewController
    
    if([self.jsonDisplayMode isEqualToString:@"template"])
    {
        popVC.popupjsonDisplayMode = @"template";
        popVC.popupjsonObject = self.jsonObject;
        popVC.originalTemplateOptionsCounts = templateOptionsCounts;
    }
    else if([self.jsonDisplayMode isEqualToString:@"singleCase"])
    {
        popVC.popupjsonDisplayMode = @"singleCase";
        popVC.popupjsonObject = self.jsonObject;
        
    }
    else
    {
        
        popVC.popupitsMTLObject = self.itsMTLObject;
        popVC.selectedCase = self.selectedCaseIndex;
        
        popVC.popupjsonDisplayMode = @"no";
    }
    NSNumber *selectedCaseItem = [NSNumber numberWithInteger:indexPath.row];
    popVC.selectedCaseItem = selectedCaseItem;
    PFObject *caseItemPicked = [sortedCaseItems objectAtIndex:indexPath.row];
    PFObject *selectedPropObject;
    NSString *caseItemPickedPropertyNum = [caseItemPicked objectForKey:@"propertyNum"];
    
    if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:indexPath.row]])
    {
        selectedPropObject = [propsArray objectAtIndex:indexPath.row];
        
    }
    else
    {
        for(PFObject *propObject in propsArray)
        {
            if([propObject.objectId isEqualToString:caseItemPickedPropertyNum])
            {
                selectedPropObject = propObject;
                break;
                
            }
        }
    }
    
    popVC.selectedPropertyObject = selectedPropObject;
    popVC.sortedCaseItems = sortedCaseItems;
    popVC.locationLatitude = locationLatitude;
    popVC.locationLongitude = locationLongitude;
    popVC.locationRetrieved = locationRetrieved;
    popVC.UCIdelegate = self;
    popVC.popupUserName = self.userName;
    //check the property type of the property at this selected index and set different modes on the popup accordingly.
    
    //check the property type and show different UI accordingly.
    NSString *propType = [selectedPropObject objectForKey:@"propertyType"];
    NSString *options = [selectedPropObject objectForKey:@"options"];
    
    //If the property is type I, show an info Message
    //If the property is type N, do nothing.
    //If the property is type B, show the matches view controller
    if([propType  isEqual:@"I"])
    {
        //property is an info message
        //display a UI alert with the info in the info message
        NSString *infoMsg = [selectedPropObject objectForKey:@"propertyDescr"];
        
        //for the caseItem of this index, take the params value
        NSString *params = [caseItemPicked objectForKey:@"params"];
        
        NSArray * paramsArray = [params componentsSeparatedByString:@";"];
        
        //loop through the infoMsg and replace instances of &# with the values in the param array.
        
        int i = 1;
        if (paramsArray.count>=1)
        {
            for (i=1;i<paramsArray.count+1;i++)
            {
                NSString *numString = [NSString stringWithFormat:@"%i",i];
                NSLog(numString);
                NSString *stringToReplace = [@"&" stringByAppendingString:numString];
                
                [infoMsg stringByReplacingOccurrencesOfString:stringToReplace withString:[paramsArray objectAtIndex:i-1]];
            }
        }
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info Message", nil) message:NSLocalizedString(infoMsg, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    else if([propType isEqual:@"N"])
    {
        
    }
    
    else if([propType isEqual:@"B"])
    {
        //display matches view controller (to be created)
        matchesViewController *mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mvc"];
        
        [mvc.matchViewControllerMode isEqualToString:@"singleCaseMatches"];
        
        //loop through the itsMTLObject and gather all the user's matches
        NSMutableArray *allMatchesArray = [[NSMutableArray alloc] init];
        NSMutableArray *allMatchCaseObjectsArray = [[NSMutableArray alloc] init];
        NSMutableArray *allMatchCaseItemObjectsArray = [[NSMutableArray alloc] init];
        NSMutableArray *allMatchesCaseTypes = [[NSMutableArray alloc] init];
        
        NSString *matchesString = [caseItemPicked objectForKey:@"browse"];
        NSString *matchesYesString = [caseItemPicked objectForKey:@"yeses"];
        NSString *matchesRejectedYesString = [caseItemPicked objectForKey:@"rejectedYeses"];
        NSArray *matchesArray = [matchesString componentsSeparatedByString:@";"];
        NSArray *matchesYesArray = [matchesYesString componentsSeparatedByString:@";"];
        NSArray *matchesRejectedYesArray= [matchesRejectedYesString componentsSeparatedByString:@";"];
        
        PFObject *caseObject;
        int selectedCaseInt = (int)[selectedCaseIndex integerValue];
        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
        
        caseObject = [allCases objectAtIndex:selectedCaseInt];
        if([matchesRejectedYesArray count] >0)
        {
            for(NSString *caseMatchID in matchesRejectedYesArray)
            {
                [allMatchesArray addObject:caseMatchID];
                [allMatchCaseObjectsArray addObject:caseObject];
                NSString *caseItemObjectString = [caseItemPicked objectForKey:@"caseItem"];
                
                [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                [allMatchesCaseTypes addObject:@"rejected"];
                
            }
            
        }
        
        if([matchesYesArray count] >0)
        {
            for(NSString *caseMatchID in matchesYesArray)
            {
               // if(![allMatchesArray containsObject:caseMatchID])
                //{
                    [allMatchesArray addObject:caseMatchID];
                    [allMatchCaseObjectsArray addObject:caseObject];
                    NSString *caseItemObjectString = [caseItemPicked objectForKey:@"caseItem"];
                    
                    [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                    [allMatchesCaseTypes addObject:@"yes"];
               // }
                
            }
            
        }
        
        if([matchesArray count] >0)
        {
            for(NSString *caseMatchID in matchesArray)
            {
               // if(![allMatchesArray containsObject:caseMatchID])
                //{
                    [allMatchesArray addObject:caseMatchID];
                    [allMatchCaseObjectsArray addObject:caseObject];
                    NSString *caseItemObjectString = [caseItemPicked objectForKey:@"caseItem"];
                    
                    [allMatchCaseItemObjectsArray addObject:caseItemObjectString];
                    [allMatchesCaseTypes addObject:@"match"];
                //}
            }
            
        }
        mvc.matchesArray = [allMatchesArray copy];
        mvc.matchesCaseObjectArrays = [allMatchCaseObjectsArray copy];
        mvc.matchesCaseItemArrays = [allMatchCaseItemObjectsArray copy];
        mvc.matchTypeArray = [allMatchesCaseTypes copy];
        
        mvc.matchesUserName = self.userName;
        
        [self.navigationController pushViewController:mvc animated:YES];
        
        return;
        
        
    }
    else if([options length]==0)
    {
        //show the popup in custom answer mode
        popVC.displayMode = @"custom";
    }
    else
    {
        //show the popup in the normal mode with the tableView
        popVC.displayMode = @"table";
    }
    
    //[self setPresentationStyleForSelfController:self presentingController:popVC];
    //[self presentViewController:popVC animated:NO completion:nil];
    
    popVC.popupOrSlideout = @"slideout";
    
    self.slidingViewController.underLeftViewController = self.popupVC;
    
    self.slideoutDisplayed = @"yes";
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
    
    //self.navigationController.navigationBar.alpha = 0;
    
    return;

}

-(void)setPresentationStyleForSelfController:(UIViewController *)selfController presentingController:(UIViewController *)presentingController
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
     
    
    {
        presentingController.providesPresentationContextTransitionStyle = YES;
        presentingController.definesPresentationContext = YES;
        
        [presentingController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    }
    else
    {
        [selfController setModalPresentationStyle:UIModalPresentationCurrentContext];
        [selfController.navigationController setModalPresentationStyle:UIModalPresentationCurrentContext];
    }
}

- (void)reloadData:(PFObject *) myObject reloadMode:(NSString *)reloadModeString
{
    
   //code for old refresh/poll mode where the entire itsMTLobject is returned on the refresh
    NSArray *casesArray;
    int indexOfCase = 0;
    PFObject *caseItemObject;

    if([reloadModeString isEqualToString:@"polledForMTL"])
    {
        self.itsMTLObject = myObject;
        
       
        casesArray = [self.itsMTLObject objectForKey:@"cases"];
        
        
        int i = 0;
        
        if(templateMode ==1)
        {
            for (PFObject *eachReturnedCase in casesArray)
            {
                NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
                //make sure CaseString is not nil/blank
                if([caseString length] >0)
                {
                    if([priorCaseIDS containsObject:caseString])
                    {
                        //continue
                    }
                    else
                    {
                        indexOfCase = i;
                        break;
                    }
                }
                i = i+1;
            }
        }
        else if (templateMode ==0)
        {
            for (PFObject *eachReturnedCase in casesArray)
            {
                NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
                if([caseBeingUpdated isEqualToString:caseString])
                {
                    indexOfCase = i;
                    NSLog(@"match found on case");
                    break;
                }
                else
                {
                    //continue
                }
                i = i+1;
            }
            
        }

    self.selectedCaseIndex = [NSNumber numberWithInt:indexOfCase];
    caseItemObject = [casesArray objectAtIndex:indexOfCase];
        
    }
   else //case where reload data is not called as a result of polling but is given case directly
   {
       caseItemObject = myObject;
       self.jsonDisplayMode = @"singleCase";
       self.jsonObject = (PFObject *)caseItemObject;
   }
    caseBeingUpdated = [caseItemObject objectForKey:@"caseId"];
    templateMode =0;
   
    //define sort descriptors for sorting caseItems by priority
    NSArray *sortDescriptors;
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    caseItems= [caseItemObject objectForKey:@"caseItems"];
    sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    
    //setting up arrays for storing three sets of properties and cases based on type: info messages, already answered properties, and new suggested properties
    
    [propertyIDSArray removeAllObjects];
    [answeredPropertiesIndex removeAllObjects];
    [answeredProperties removeAllObjects];
    [answeredCases removeAllObjects];
    [infoCases removeAllObjects];
    [infoMessageProperties removeAllObjects];
    [suggestedProperties removeAllObjects];
    [suggestedCases removeAllObjects];
    [suggestedCaseIndex removeAllObjects];
    [updatedPropertiesIndex removeAllObjects];
    [customAnsweredCases removeAllObjects];
    [customAnsweredProperties removeAllObjects];
    [customAnsweredPropertiesIndex removeAllObjects];
    [browseCases removeAllObjects];
    [browseProperties removeAllObjects];
    [browsePropertiesIndex removeAllObjects];
    [newlyCreatedPropertiesIndex removeAllObjects];
    suggestedCaseDisplayedIndex = -1;
    [changedCaseItemsIndex removeAllObjects];
    
    //get all the property ID's from each item in the selected case.
    
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *propNum = [eachCaseItem objectForKey:@"propertyNum"];
        [propertyIDSArray addObject:propNum];
    }
    
    //get all the property information for the list of properties to consider
    PFQuery *propertsQuery = [PFQuery queryWithClassName:@"Properts"];
    [propertsQuery whereKey:@"objectId" containedIn:propertyIDSArray];
    
    [propsArray removeAllObjects];
 
     propsArray = [[propertsQuery findObjects] mutableCopy];
    
    //check the propsArray and re-query if one of them doesn't have a property description filled in yet
    
    BOOL queryGood = 0;
    /*
    while (queryGood==0)
    {
         propsArray = [[propertsQuery findObjects] mutableCopy];
        int gj = 0;
        for (PFObject *property in propsArray)
        {
            NSString *propDescr =[property objectForKey:@"propertyDescr"];
            if([propDescr length] ==0)
            {
                [propsArray removeAllObjects];
                queryGood =0;
                break;
                
            }
            gj=gj+1;
            if(gj== [propsArray count])
            {
                queryGood =1;
                
            }
        }
        NSLog(@"re-querying properties due to empty propertyDescr");
        
    }
    */
    
    //sort the propsArray based on the order in sortedCaseItems
    NSMutableArray *sortingPropsArray = [[NSMutableArray alloc] init];
    
    for(PFObject *caseItem in sortedCaseItems)
    {
        NSString *propID = [caseItem objectForKey:@"propertyNum"];
        
        for (PFObject *propObject in propsArray)
        {
            NSString *propObjectID = propObject.objectId;
            
            if([propObjectID isEqualToString:propID])
            {
                [sortingPropsArray addObject:propObject];
                
            }
        }
    }
    
    propsArray = sortingPropsArray;
    
    //sort the properties into four categories based on their type: info messages, answerableQuestions, customAnswerableQuestions, and new suggestions
    int g = 0;
    for (PFObject *property in propsArray)
    {
        NSString *propType = [property objectForKey:@"propertyType"];
        NSString *options = [property objectForKey:@"options"];
        
        if([propType  isEqual:@"I"])
        {
            //property is an info message
            [infoMessageProperties addObject:property];
            [infoCases addObject:sortedCaseItems[g]];
        }
        else if([propType isEqual:@"N"])
        {
            [NoAnswerProperties addObject:property];
            [NoAnswerCases addObject:sortedCaseItems[g]];
        }
        
        else if([propType isEqual:@"B"])
        {
            [browseProperties addObject:property];
            [browseCases addObject:sortedCaseItems[g]];
        }
        
        else if([options length]==0)
        {
            [customAnsweredProperties addObject:property];
            [customAnsweredProperties addObject:sortedCaseItems[g]];
        }
        else
            
        {
            PFObject *caseItemObject = sortedCaseItems[g];
            NSArray *answers = [caseItemObject objectForKey:@"answers"];
            
            if(answers.count>=1)
            {
                NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
                [answeredPropertiesIndex addObject:indexNum];
                //array for keeping track of the properties with answers.  Some of these may be info messages so that is dealt with further down.  It is assumed info messages can not have answers.
                //add the property to the list of answeredProperties
                [answeredProperties addObject:property];
                [answeredCases addObject:sortedCaseItems[g]];
                
            }
            else
            {
                [suggestedProperties addObject:property];
                [suggestedCases addObject:sortedCaseItems[g]];
                NSNumber *caseIndex = [NSNumber numberWithInt:g];
                [suggestedCaseIndex addObject:caseIndex];
            }
        }
        g=g+1;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    [self.caseDetailsEmailTableView reloadData];
    //remove the updating HUD
    [HUD hide:YES];
    });
    
    if([reloadModeString isEqualToString:@"fromSingleNewProperty"])
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
        
    //set the last timestamp for the case if there needs to be polling.
    NSString *timeStampReturn = [caseItemObject objectForKey:@"timestamp"];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    lastTimestamp = [f numberFromString:timeStampReturn];
    
    if([self.popupVC.popupOrSlideout isEqualToString:@"slideout"])
       {
           [self.slidingViewController resetTopViewAnimated:YES];
       }
    else
    {
         [self dismissViewControllerAnimated:NO completion:nil];
    }
  
    
    
}
-(IBAction)doUpdate:(id)sender
{
    
    NSString *xmlForUpdate = [self createXMLTemplateModeFunction];
    
    if([xmlForUpdate isEqualToString:@"no"])
    {
      [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Update", nil) message:@"New Case Must Include At Least One Answered Question" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];

    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Updating The Properties And Answers";
    [HUD show:YES];

    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                   withParameters:@{@"payload": xmlForUpdate}
                            block:^(NSString *responseString, NSError *error) {
                                
                                if (!error)
                                {
                                    NSString *responseText = responseString;
                                    NSLog(responseText);
                                    
                                    [HUD hide:NO];
                                    
                                    //setting timestamp to compare to for the subsequent update
                                    NSString *timeStampReturn;
                                    if([self.jsonDisplayMode isEqualToString:@"template"])
                                    {
                                        timeStampReturn = [self.jsonObject objectForKey:@"timestamp"];
                                        
                                    }
                                    else
                                    {
                                        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
                                        PFObject *caseObject = [allCases objectAtIndex:[selectedCaseIndex integerValue]];
                                        caseBeingUpdated = [caseObject objectForKey:@"caseId"];
                                        
                                        timeStampReturn = [caseObject objectForKey:@"timestamp"];
                                       
                                    }
                                    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                                    f.numberStyle = NSNumberFormatterDecimalStyle;
                                    lastTimestamp = [f numberFromString:timeStampReturn];
                                    
                                    //convert to NSDictionaryHere
                                    
                                    NSString *responseTextWithoutHeader = [responseText
                                                                           stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                                    NSError *jsonError;
                                    NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                         options:NSJSONReadingMutableContainers
                                                                                           error:&jsonError];
                                    
                                    NSMutableDictionary *jsonCaseChange = [json mutableCopy];
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                    [self reloadData:jsonCaseChange reloadMode:@"fromJSON"];
                                    });
                                    
                                    //[self pollForCaseRefresh];
                                    
                                }
                                else
                                {
                                    NSLog(error.localizedDescription);
                                    [HUD hide:YES];
                                }
        }];
}

-(void)pollForCaseRefresh
{
    //run a timer in the background to look for the moment the case is updated with a template maker
    
    //show progress HUD
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Polling for Case Update";
    [HUD show:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(timerFired:)
                                   userInfo:nil
                                    repeats:YES];
    
}

- (void)timerFired:(NSTimer *)timer {
    
    NSLog(@"timer fired tick %i", EmailTimerTickCaseDetails);
    
    //check the parse object to see if it is updated
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query includeKey:@"cases"];
    
    PFObject *returnedITSMTLObject = [query getObjectWithId:self.userName];
    
    NSArray *returnedCases = [returnedITSMTLObject objectForKey:@"cases"];
    
    BOOL updateSuccess = 0;
    
    if(templateMode ==1 || [self.jsonDisplayMode isEqualToString:@"template"])
    {
        for (PFObject *eachReturnedCase in returnedCases)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            //make sure CaseString is not nil/blank
            if([caseString length] >0)
            {
                if([priorCaseIDS containsObject:caseString])
                {
                    //continue
                }
                else
                {
                    updateSuccess=1;
                    
                    break;
                }
            }
            
        }
    }
       else
    {
        for (PFObject *eachReturnedCase in returnedCases)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] >0)
            {
                if([caseBeingUpdated isEqualToString:caseString])
                {
                    //check the timestamp, see if newer than prior timestamp
                    NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                    f.numberStyle = NSNumberFormatterDecimalStyle;
                    
                    NSNumber *timestamp = [f numberFromString:timeStampReturn];
                    
                    if([timestamp doubleValue] > [lastTimestamp doubleValue])
                    {
                        NSLog(@"newer timestamp found");
                        //the update was newer and we verified it from actual case data, set boolean to true
                        updateSuccess =1;
                        break;
                    }
                }
            }
        }
    }

    if(updateSuccess ==1)
    {
        NSLog(@"update successful");
        
        //stop the timer
        [timer invalidate];
        EmailTimerTickCaseDetails = 0;
        
        //clear the progress hud
        [HUD hide:NO];
        
        //trigger caseDetailsEmailViewController to reload its data
        [self reloadData:returnedITSMTLObject reloadMode:@"polledForMTL"];
    
    }
    else
    {
        NSLog(@"running the loop again to query again");
        
    }
    
    EmailTimerTickCaseDetails=EmailTimerTickCaseDetails+1;
    if(EmailTimerTickCaseDetails==40)
    {
        [timer invalidate];
        NSLog(@"ran into maximum time");
        [HUD hide:YES];
    }
    
}


-(NSString *)createXMLTemplateModeFunction
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    NSInteger selectedCaseInt = [selectedCaseIndex integerValue];
    //the case object includes the list of all caseItems and the caseId
    
    PFObject *caseObject;
    if([self.jsonDisplayMode isEqualToString:@"template"])
    {
        caseObject = self.jsonObject;
    }
    else
    {
        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
        
        caseObject = [allCases objectAtIndex:selectedCaseInt];
    }
    
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:self.userName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"LAISO"];
    [xmlWriter writeCharacters:@"EN"];
    [xmlWriter writeEndElement];
    
    //if it's a brand new case, this will be nil
    if(caseObjID != nil)
    {
        
        [xmlWriter writeStartElement:@"CASEOBJECTID"];
        [xmlWriter writeCharacters:caseObjID];
        [xmlWriter writeEndElement];
    }
    
    
    [xmlWriter writeStartElement:@"CASENAME"];
    [xmlWriter writeCharacters:caseName];
    [xmlWriter writeEndElement];
    
    if([locationRetrieved length]>0)
    {
        //[xmlWriter writeStartElement:@"LOCATIONTEXT"];
        //[xmlWriter writeCharacters:locationRetrieved];
        //[xmlWriter writeEndElement];
    }
    
    if([locationLatitude length]>0)
    {
        [xmlWriter writeStartElement:@"LATITUDE"];
        [xmlWriter writeCharacters:locationLatitude];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"LONGITUDE"];
        [xmlWriter writeCharacters:locationLongitude];
        [xmlWriter writeEndElement];
    }
    //Jan 18
    //updating to put ALL NEW property tags first before caseItem tags
    int j = 0;
    
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        
        //check to see if this caseItem is a brand new property
        
        if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:j]])
            
        {
            PFObject *newPropObject = [propsArray objectAtIndex:j];
             NSString *propertyDescr = [newPropObject objectForKey:@"propertyDescr"];
            //add the XML for a new or updated property here
            [xmlWriter writeStartElement:@"PROPERTY"];
            
            [xmlWriter writeStartElement:@"PROPERTYNUM"];
            NSString *propNumString = [NSString stringWithFormat:@"%d",j];
            [xmlWriter writeCharacters:propNumString];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"PROPERTYDESCR"];
            [xmlWriter writeCharacters:propertyDescr];
            [xmlWriter writeEndElement];
            
            //get the options value from the property object
            NSString *fullCharsString = [newPropObject objectForKey:@"options"];
            
            if([fullCharsString length]>0)
            {
                
                [xmlWriter writeStartElement:@"OPTIONS"];
                [xmlWriter writeCharacters:fullCharsString];
                [xmlWriter writeEndElement];
            }
            //close property element
            [xmlWriter writeEndElement];
        }
        j = j+1;
        
    }
    
    int h = 0;
    for (PFObject *eachCaseItem in sortedCaseItems)
        {
        
            NSString *caseItemPickedPropertyNum = [eachCaseItem objectForKey:@"propertyNum"];
            PFObject *propAtIndex;
            
            if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:h]])
            {
                propAtIndex = [propsArray objectAtIndex:h];
                
            }
            
            else
            {
                
            
                for(PFObject *propObject in propsArray)
                {
                    if([propObject.objectId isEqualToString:caseItemPickedPropertyNum])
                    {
                        propAtIndex = propObject;
                        break;
                    }
                }
            }
            
           
            
            
            PFObject *updatedProperty = propAtIndex;
           
            
            NSString *propertyNum = [eachCaseItem objectForKey:@"propertyNum"];
        
            //write logic for updating the caseItem
            //build strings for building item
            [xmlWriter writeStartElement:@"ITEM"];
            
            //check to see if this caseItem has a number.  Otherwise give it a number of 9000 to indicate it is a brand new caseItem.
            NSString *myCaseItem = [eachCaseItem objectForKey:@"caseItem"];
            NSString *caseItemNumber;
        
            int caseNum = 12000+h;
        
            if(myCaseItem==nil)
            {
                caseItemNumber =[NSString stringWithFormat:@"%d",caseNum];;
                
            }
            else
            {
                caseItemNumber = myCaseItem;
                
            }
            
            [xmlWriter writeStartElement:@"CASEITEM"];
            [xmlWriter writeCharacters:caseItemNumber];
            [xmlWriter writeEndElement];
        
            NSString *propNumString;
           if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:h]])
           {
               propNumString = [NSString stringWithFormat:@"%d",h];
           }
           else
            {
            propNumString = propertyNum;
            }
        
            h = h+1;
            [xmlWriter writeStartElement:@"PROPERTYNUM"];
            [xmlWriter writeCharacters:propNumString];
            [xmlWriter writeEndElement];
            
            //write out the answers value of this case Item
            
            //need to check if the case type is custom answers
            
            //if case type is I or N, don't update anything for answers
            NSString *propertyType = [updatedProperty objectForKey:@"propertyType"];
            NSString *optionText = [updatedProperty objectForKey:@"options"];
            NSArray *cdeAnswersDictionary = [eachCaseItem objectForKey:@"answers"];
        
            if([propertyType isEqualToString:@"I"] || [propertyType isEqualToString:@"N"] || [propertyType isEqualToString:@"B"])
            {
                //do nothing
            }
            else if([optionText length] == 0)
            {
                //write the answer as type Custom
                
                for (PFObject *ansObj in cdeAnswersDictionary)
                {
                    NSString *ansString = [ansObj objectForKey:@"custom"];
                    [xmlWriter writeStartElement:@"ANSWER"];
                    
                    [xmlWriter writeStartElement:@"CUSTOM"];
                    [xmlWriter writeCharacters:ansString];
                    [xmlWriter writeEndElement];
                    
                    [xmlWriter writeEndElement];
                    
                }
                
            }
            else
            {
                NSString *semiColonDelimitedCustomAnswers;
                NSString *semiColonDelimitedAAnswers;
                NSMutableArray *arrayOfCustomAnswers = [[NSMutableArray alloc] init];
                NSMutableArray *arrayOfAAnswers = [[NSMutableArray alloc] init];
                
                for (PFObject *ansObj in cdeAnswersDictionary)
                {
                    
                    //if the object responds to the key a, then write it as an answer a
                    NSString *ansString = [ansObj objectForKey:@"a"];
                    if([ansString length] ==0)
                    {
                        ansString = [ansObj objectForKey:@"custom"];
                        if([ansString length] >0)
                        {
                            [arrayOfCustomAnswers addObject:ansString];
                        }
                    }
                    else
                    {
                        [arrayOfAAnswers addObject:ansString];
                        
                    }
                }
            
                semiColonDelimitedAAnswers = [arrayOfAAnswers componentsJoinedByString:@";"];
                semiColonDelimitedCustomAnswers  = [arrayOfCustomAnswers componentsJoinedByString:@";"];
                
                if ([semiColonDelimitedAAnswers length] ==0 && [semiColonDelimitedCustomAnswers length] ==0)
                {
                    
                    //don't write any answers, do nothing
                    /*
                    [xmlWriter writeStartElement:@"ANSWER"];
                    [xmlWriter writeStartElement:@"A"];
                    [xmlWriter writeCharacters:@"1"];
                    [xmlWriter writeEndElement];
                    [xmlWriter writeEndElement];
                     */
                }
                else
                {
                    [xmlWriter writeStartElement:@"ANSWER"];
                    if([semiColonDelimitedAAnswers length]>0)
                    {
                        [xmlWriter writeStartElement:@"A"];
                        [xmlWriter writeCharacters:semiColonDelimitedAAnswers];
                        [xmlWriter writeEndElement];
                        
                    }
                    if([semiColonDelimitedCustomAnswers length]>0)
                    {
                        [xmlWriter writeStartElement:@"CUSTOM"];
                        [xmlWriter writeCharacters:semiColonDelimitedCustomAnswers];
                        [xmlWriter writeEndElement];
                        
                    }
                    //close answer element
                    [xmlWriter writeEndElement];
                }
                
            }

            //close item element
            [xmlWriter writeEndElement];
        
    }
  
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
    
}

- (void)updateCaseItem:(NSString *)caseItemID AcceptableAnswersList:(NSArray *)Answers
{
    NSLog(@"got this");
    
    //update the data and modify the sortedCaseItems and propsArray to take on the new data coming back
    
    //loop through the caseItems and select the one with this caseItemID
    PFObject *selectedCaseItem;
    
    for(PFObject *eachCaseItem in sortedCaseItems)
    {
        if([[eachCaseItem objectForKey:@"caseItem"] isEqualToString:caseItemID])
        {
            selectedCaseItem = eachCaseItem;
            
        }
    }
    //set the answers for this case to an array of a-value NSDicts
    
    [selectedCaseItem setObject:Answers forKey:@"answers"];
    
    NSString *propNum = [selectedCaseItem objectForKey:@"propertyNum"];
    
    //add to the list of options for the relevant property if the answer is a custom answer
    
    //check only the latest answer added.  Assumes right now that no custom answers are added and then deleted by user.
    
  NSDictionary *ansDict = [Answers objectAtIndex:Answers.count-1];
   NSString *ansCustomVal = [ansDict objectForKey:@"custom"];
    
    if([ansCustomVal length] >0)
    {
        //loop through the propsArray to get the matching property and add to it only if this answer hasn't already been added.
            for (PFObject *propObject in propsArray)
            {
                if([propObject.objectId isEqualToString:propNum])
                {
                    NSString *options = [propObject objectForKey:@"options"];
                    
                    //loop through op
                    
                    options = [[options stringByAppendingString:@"; "] stringByAppendingString:ansCustomVal];
                    [propObject setObject:options forKey:@"options"];
                    
                }
            }


    }
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
    [self.caseDetailsEmailTableView reloadData];
    
    if([self.popupVC.popupOrSlideout isEqualToString:@"slideout"])
    {
        [self.slidingViewController resetTopViewAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
   
}
//brian march 9
//don't think this is ever called now.  May need to delete this function.
- (void)updateNewCaseItem:(NSString *)caseItemID AcceptableAnswersList:(NSArray *)Answers NewPropertyDescr:(NSString *) newPropDescr optionsList:(NSArray *) optionList
{
    NSMutableDictionary *propertyObject = [[NSMutableDictionary alloc] init];
    
    updatedCaseTicker = updatedCaseTicker +1;
    int newCaseNumber = 9000 +updatedCaseTicker;
    
    NSString *newPropNum = [NSString stringWithFormat:@"%d",updatedCaseTicker];
    NSString *newCaseNum = [NSString stringWithFormat:@"%d",newCaseNumber];
    [propertyObject setObject:optionList forKey:@"options"];
    [propertyObject setObject:newPropDescr forKey:@"propertyDescr"];
    [propertyObject setObject:newPropNum forKey:@"propertyNum"];
    [propertyObject setObject:@"U" forKey:@"propertyType"];
    
    NSMutableDictionary *caseItemObject = [[NSMutableDictionary alloc] init];
   
    
    [caseItemObject setObject:newCaseNum forKey:@"caseItem"];
    [caseItemObject setObject:Answers forKey:@"answers"];
    
    int g = (int)sortedCaseItems.count;
    
    [sortedCaseItems addObject:caseItemObject];
    [propsArray addObject:propertyObject];
    
    NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
    [newlyCreatedPropertiesIndex addObject:indexNum];
    [changedCaseItemsIndex addObject:indexNum];

}

#pragma mark DataDelegateMethods
- (void)recieveData:(NSString *)OptionsList AcceptableAnswersList:(NSArray *)Answers QuestionText:(NSString *) question {
    
    updatedCaseTicker = updatedCaseTicker +1;
    int newCaseNumber = 9000 +updatedCaseTicker;
    
    NSString *newPropNum = [NSString stringWithFormat:@"%d",updatedCaseTicker];
    NSString *newCaseNum = [NSString stringWithFormat:@"%d",newCaseNumber];
    
    //loop through the incoming array of answers and set them to an array of NSMutableDictionaries
    
    //add the data to the list sortedCaseList and propertiesArray
    
    NSMutableDictionary *propertyObject = [[NSMutableDictionary alloc] init];
    [propertyObject setObject:OptionsList forKey:@"options"];
    [propertyObject setObject:question forKey:@"propertyDescr"];
    [propertyObject setObject:newPropNum forKey:@"propertyNum"];
    [propertyObject setObject:@"U" forKey:@"propertyType"];
    [propertyObject setObject:newPropNum forKey:@"objectId"];
    
    
    NSMutableDictionary *caseItemObject = [[NSMutableDictionary alloc] init];
    [caseItemObject setObject:newCaseNum forKey:@"caseItem"];
    [caseItemObject setObject:Answers forKey:@"answers"];
    [caseItemObject setObject:newPropNum forKey:@"propertyNum"];
    
    
    //[self.pickerView reloadAllComponents];
  //  [self.caseDetailsTableView reloadData];
    
    //Do something with data here
    NSLog(@"this fired");
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
    
    
    
    //reload data
    if(templateMode==0)
    {
        //add a progress HUD to show it is retrieving list of properts
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        // Set determinate mode
        HUD.mode = MBProgressHUDModeDeterminate;
        HUD.delegate = self;
        HUD.labelText = @"Updating With The New Case Item";
        [HUD show:YES];
        
        [self updateNewCaseItem:propertyObject CaseItemObject:caseItemObject];
        
    }
    else
    {
        int g = (int)sortedCaseItems.count;
        
        [sortedCaseItems addObject:caseItemObject];
        [propsArray addObject:propertyObject];
        
        NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
        [newlyCreatedPropertiesIndex addObject:indexNum];
        [changedCaseItemsIndex addObject:indexNum];
        
        [self.navigationController popViewControllerAnimated:NO];
        
        [self.caseDetailsEmailTableView reloadData];
    }
    
    
}

#pragma mark swipableTableViewCellsDelegateMethods

// click event on left utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    
}

// click event on right utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            NSLog(@"More button was pressed");
            break;
        case 1:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.caseDetailsEmailTableView indexPathForCell:cell];
            [self deleteItemAtIndex:(int)cellIndexPath.row];
            
            
            //[_testArray removeObjectAtIndex:cellIndexPath.row];
            /*
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
             */
            break;
        }
        default:
            break;
    }
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

-(void)deleteItemAtIndex:(int) caseItemIndex
{
    PFObject *caseItemObject = [sortedCaseItems objectAtIndex:caseItemIndex];
    
    //if in template mode, remove the object locally.  If dealing with an already existing case, delete the item right away server-side.
    
    if(templateMode ==1)
    {
        //remove case item object locally
        [sortedCaseItems removeObjectAtIndex:caseItemIndex];
        [propsArray removeObjectAtIndex:caseItemIndex];
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:caseItemIndex inSection:0];
        
        [self.caseDetailsEmailTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        
        [self.caseDetailsEmailTableView reloadData];
        
    }
    
    else
    {
        //delete the item server side
        [self deleteACaseItem:caseItemObject];
        
    }
    
    
}

- (void)deleteACaseItem:(PFObject *)itemObject
{
    //construct XML to delete the caseItemObject
    //hardcoded example:
    /*
     <PAYLOAD>
     <USEROBJECTID>iGsK0mxn1A</USEROBJECTID>
     <LAISO>EN</LAISO>
     <CASEOBJECTID>kqIKYJnTj8</CASEOBJECTID>
     <CASENAME>Multiple answers example</CASENAME>
     <ITEM>
     <CASEITEM>1</CASEITEM>
     <PROPERTYNUM>cpJqMRQnSs</PROPERTYNUM>
     <DELETIONFLAG>X</DELETIONFLAG>
     </ITEM>
     </PAYLOAD>
     */
    
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    PFObject *caseObject = [allCases objectAtIndex:selectedCaseInt];
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    NSString *caseItem = [itemObject objectForKey:@"caseItem"];
    NSString *propertyNum = [itemObject objectForKey:@"propertyNum"];
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:self.itsMTLObject.objectId];
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
    
    [xmlWriter writeStartElement:@"DELETIONFLAG"];
    [xmlWriter writeCharacters:@"X"];
    [xmlWriter writeEndElement];
    
    // close ITEM element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Deleting the CaseItem";
    [HUD show:YES];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xml}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        
                                        
                                        //commented out as no longer polling
                                        /*
                                        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
                                        
                                        PFObject *caseObject = [allCases objectAtIndex:[selectedCaseIndex integerValue]];
                                        caseBeingUpdated = [caseObject objectForKey:@"caseId"];
                                        
                                        
                                        NSString *timeStampReturn = [caseObject objectForKey:@"timestamp"];
                                        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                                        f.numberStyle = NSNumberFormatterDecimalStyle;
                                        lastTimestamp = [f numberFromString:timeStampReturn];
                                        */
                                        //[self pollForCaseRefresh];
                                        
                                        //load data from synchronous data return
                                        NSString *responseTextWithoutHeader = [responseString
                                                                               stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                                        NSError *jsonError;
                                        NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                             options:NSJSONReadingMutableContainers
                                                                                               error:&jsonError];
                                        
                                        NSMutableDictionary *jsonCaseChange = [json mutableCopy];
                                        [self reloadData:jsonCaseChange reloadMode:@"fromJSON"];
                                        [HUD hide:NO];
                                    }
                                    else
                                    {
                                        //NSString *errorString = error.localizedDescription;
                                         NSLog(@"%@",[error localizedDescription]);
                                        [HUD hide:NO];
                                      
                                    }
                                }];
    
}

-(NSString *)createXMLFunctionSingleCaseItem:(NSDictionary *) propertyObject CaseItemObject:(NSDictionary *)caseItemObjForXML
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    PFObject *caseObject = [allCases objectAtIndex:selectedCaseInt];
    
    //newCaseItem is always the last on sortedCaseItems because it was just added
    PFObject *caseItemObject = (PFObject *)caseItemObjForXML;
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
    PFObject *selectedPropertyObject = (PFObject *)propertyObject;
    NSString *propertyNum = [selectedPropertyObject objectForKey:@"propertyNum"];
    NSString *propertyDescr = [selectedPropertyObject objectForKey:@"propertyDescr"];
    
    if(propertyNum==nil)
    {
        propertyNum =@"1";
        
    }
    
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    NSString *itsMTLObjectUserName = self.itsMTLObject.objectId;
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:itsMTLObjectUserName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"LAISO"];
    [xmlWriter writeCharacters:@"EN"];
    [xmlWriter writeEndElement];
    
    //if it's a brand new case, this will be nil
    if(caseObjID != nil)
    {
        
        [xmlWriter writeStartElement:@"CASEOBJECTID"];
        [xmlWriter writeCharacters:caseObjID];
        [xmlWriter writeEndElement];
    }
    
    [xmlWriter writeStartElement:@"CASENAME"];
    [xmlWriter writeCharacters:caseName];
    [xmlWriter writeEndElement];
    
    if([locationRetrieved length]>0)
    {
        //[xmlWriter writeStartElement:@"LOCATIONTEXT"];
        //[xmlWriter writeCharacters:locationRetrieved];
        //[xmlWriter writeEndElement];
    }
    
    if([locationLatitude length]>0)
    {
        [xmlWriter writeStartElement:@"LATITUDE"];
        [xmlWriter writeCharacters:locationLatitude];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"LONGITUDE"];
        [xmlWriter writeCharacters:locationLongitude];
        [xmlWriter writeEndElement];
    }
    
            //check to see if this caseItem is a brand new property
    
            //add the XML for a new or updated property here
            [xmlWriter writeStartElement:@"PROPERTY"];
            
            [xmlWriter writeStartElement:@"PROPERTYNUM"];
    
            [xmlWriter writeCharacters:propertyNum];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"PROPERTYDESCR"];
            [xmlWriter writeCharacters:propertyDescr];
            [xmlWriter writeEndElement];
            
            //get the options value from the property object
            NSString *fullCharsString = [selectedPropertyObject objectForKey:@"options"];
            
            if([fullCharsString length]>0)
            {
                
                [xmlWriter writeStartElement:@"OPTIONS"];
                [xmlWriter writeCharacters:fullCharsString];
                [xmlWriter writeEndElement];
            }
            //close property element
            [xmlWriter writeEndElement];
    
    //write logic for updating the caseItem
    //build strings for building item
    [xmlWriter writeStartElement:@"ITEM"];
    
    //check to see if this caseItem has a number.  Otherwise give it a number of 9000 to indicate it is a brand new caseItem.
    NSString *myCaseItem = [caseItemObject objectForKey:@"caseItem"];
    NSString *caseItemNumber;
    if(myCaseItem==nil)
    {
        caseItemNumber =@"9000";
        
    }
    else
    {
        caseItemNumber = myCaseItem;
        
    }
    
    [xmlWriter writeStartElement:@"CASEITEM"];
    [xmlWriter writeCharacters:caseItemNumber];
    [xmlWriter writeEndElement];
    
   
    [xmlWriter writeStartElement:@"PROPERTYNUM"];
    [xmlWriter writeCharacters:propertyNum];
    [xmlWriter writeEndElement];
    
    //write out the answers value of this case Item
    
    //need to check if the case type is custom answers
    
    //if case type is I or N, don't update anything for answers
    NSString *propertyType = [selectedPropertyObject objectForKey:@"propertyType"];
    NSString *optionText = [selectedPropertyObject objectForKey:@"options"];
    
    NSArray *cdeanswersDictionary = [caseItemObject objectForKey:@"answers"];
    
    if([propertyType isEqualToString:@"I"] || [propertyType isEqualToString:@"N"] || [propertyType isEqualToString:@"B"])
    {
        //do nothing
    }
    else if([optionText length] == 0)
    {
        //write the answer as type Custom
        
        for (PFObject *ansObj in cdeanswersDictionary)
        {
            NSString *ansString = [ansObj objectForKey:@"custom"];
            [xmlWriter writeStartElement:@"ANSWER"];
            
            [xmlWriter writeStartElement:@"CUSTOM"];
            [xmlWriter writeCharacters:ansString];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeEndElement];
            
        }
        
    }
    else
    {
        NSString *semiColonDelimitedCustomAnswers;
        NSString *semiColonDelimitedAAnswers;
        NSMutableArray *arrayOfCustomAnswers = [[NSMutableArray alloc] init];
        NSMutableArray *arrayOfAAnswers = [[NSMutableArray alloc] init];
        
        for (PFObject *ansObj in cdeanswersDictionary)
        {
            
            //if the object responds to the key a, then write it as an answer a
            NSString *ansString = [ansObj objectForKey:@"a"];
            if([ansString length] ==0)
            {
                ansString = [ansObj objectForKey:@"custom"];
                if([ansString length] >0)
                {
                    [arrayOfCustomAnswers addObject:ansString];
                }
            }
            else
            {
                [arrayOfAAnswers addObject:ansString];
                
            }
        }
        semiColonDelimitedAAnswers = [arrayOfAAnswers componentsJoinedByString:@";"];
        semiColonDelimitedCustomAnswers  = [arrayOfCustomAnswers componentsJoinedByString:@";"];
        
        if ([semiColonDelimitedAAnswers length] ==0 && [semiColonDelimitedCustomAnswers length] ==0)
        {
            
            
        }
        else
        {
            [xmlWriter writeStartElement:@"ANSWER"];
        }
        
        if([semiColonDelimitedAAnswers length]>0)
        {
            [xmlWriter writeStartElement:@"A"];
            [xmlWriter writeCharacters:semiColonDelimitedAAnswers];
            [xmlWriter writeEndElement];
            
        }
        if([semiColonDelimitedCustomAnswers length]>0)
        {
            [xmlWriter writeStartElement:@"CUSTOM"];
            [xmlWriter writeCharacters:semiColonDelimitedCustomAnswers];
            [xmlWriter writeEndElement];
            
        }
        if ([semiColonDelimitedAAnswers length] ==0 && [semiColonDelimitedCustomAnswers length] ==0)
        {
            
        }
        else
        {
            [xmlWriter writeEndElement];
        }
    }
    
    //close item element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
}

-(void)updateNewCaseItem:(NSDictionary *)propertyObject CaseItemObject:(NSDictionary *)caseItemObject
{
    
    NSString *xmlForUpdate = [self createXMLFunctionSingleCaseItem:propertyObject CaseItemObject:caseItemObject];
    
    if([xmlForUpdate isEqualToString:@"no"])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Update", nil) message:@"New Case Must Include At Least One Answered Question" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
   
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xmlForUpdate}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                    if (!error)
                                    {
                                        
                                        NSString *responseText = responseString;
                                        //NSLog(responseText);
                                        
                                    
                                        
                                        //commenting out as it was needed for polling
                                        /*
                                        NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
                                        PFObject *caseObject = [allCases objectAtIndex:[selectedCaseIndex integerValue]];
                                        caseBeingUpdated = [caseObject objectForKey:@"caseId"];
                                        
                                        NSString *timeStampReturn = [caseObject objectForKey:@"timestamp"];
                                        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                                        f.numberStyle = NSNumberFormatterDecimalStyle;
                                        lastTimestamp = [f numberFromString:timeStampReturn];
                                         
                                        [self pollForCaseRefresh];
                                         */
                                        
                                        //convert to NSDictionaryHere
                                        
                                        NSString *responseTextWithoutHeader = [responseText
                                                                               stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                                        NSError *jsonError;
                                        NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                             options:NSJSONReadingMutableContainers
                                                                                               error:&jsonError];
                                        
                                        NSMutableDictionary *jsonCaseChange = [json mutableCopy];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self reloadData:jsonCaseChange reloadMode:@"fromSingleNewProperty"];
                                         });
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                    }
                                }];
}

-(void)getLocation:(id)sender
{
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //show progress HUD
    /*
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Location Data";
    [HUD show:YES];
    */
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [locationManager startUpdatingLocation];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        //longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        //latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        
        locationLongitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        locationLatitude =[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
       // NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
            
            NSString *locationText =[NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                     placemark.subThoroughfare, placemark.thoroughfare,
                                     placemark.postalCode, placemark.locality,
                                     placemark.administrativeArea,
                                     placemark.country];
             locationRetrieved = placemark.locality;
            
           /*UIAlertView *successAlert = [[UIAlertView alloc]
                                         initWithTitle:@"Success" message:@"Retrieved Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [successAlert show];
            */
            
            [HUD hide:NO];
        } else {
            NSLog(@"%@", error.debugDescription);
            
            [HUD hide:NO];
        }
    } ];
    
}


@end
