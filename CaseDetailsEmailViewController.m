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

@interface CaseDetailsEmailViewController ()

@end

@implementation CaseDetailsEmailViewController
@synthesize selectedCaseIndex;
@synthesize itsMTLObject;

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
CLLocationManager *locationManager;
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
    
    //set up delegates
    self.caseDetailsEmailTableView.delegate = self;
    self.caseDetailsEmailTableView.dataSource = self;
    
    //location manager instance variable allocs
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    PFObject *caseItemObject = [allCases objectAtIndex:selectedCaseInt];
    
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
    caseItems= [caseItemObject objectForKey:@"caseItems"];
    
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
    [propertsQuery orderByDescending:@"priority"];
    
    propsArray = [[propertsQuery findObjects] mutableCopy];
    
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
        for (PFObject *eachReturnedCase in casesArray)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] <=0)
            {
                NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                lastTimestamp = [f numberFromString:timeStampReturn];
                
            }
        }

    }
    [self.caseDetailsEmailTableView reloadData];

}

-(void) viewDidAppear:(BOOL)animated
{
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    PFObject *caseItemObject = [allCases objectAtIndex:selectedCaseInt];
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseDetailsEmailCell" forIndexPath:indexPath];
    UILabel *propertyDescrLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *answersLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *timeLabel = (UILabel *)[cell viewWithTag:3];
    UIImageView *iconImgView = (UILabel *)[cell viewWithTag:4];
    
    int sortedCaseItemCount = (int)[sortedCaseItems count];
    
    if(indexPath.row == sortedCaseItemCount)
    {
        //show a button to create a new caseItem instead
        
        propertyDescrLabel.text = @"Create a New Case Item";
        return cell;
        
    }
    
    PFObject *propAtIndex = [propsArray objectAtIndex:indexPath.row];
    NSString *propertyDescr = [propAtIndex objectForKey:@"propertyDescr"];
    
    propertyDescrLabel.text = propertyDescr;
    
    //check to see the type of property and assign different values to the "answersLabel" accordingly.
    
    PFObject *caseItemPicked = [sortedCaseItems objectAtIndex:indexPath.row];
    selectedItemForUpdate = indexPath.row;
    
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
                    [answersArray addObject:ansNum];
                    
                }
                ansStaticArray = [answersArray mutableCopy];
                
                //retrieve the property choices for this caseItemObject from Parse.
                
                NSString *optionsString = [propAtIndex objectForKey:@"options"];
                
                //NSLog(@"%@",optionsString);
                
                //need to convert options string to an array of objects with ; separators.
                NSString *finalAnsString = @"";
                
                optionsArray = [optionsString componentsSeparatedByString:@";"];
                int indexMatcher = 1;
                for(NSString *optString in optionsArray)
                {
                    NSString *numMatcher = [[NSNumber numberWithInt:indexMatcher] stringValue];
                    if([answersArray containsObject:numMatcher])
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    //if the selected row is greater than the count of caseItems, show the NewPropertyViewController
    
    if(indexPath.row==sortedCaseItems.count)
    {
        NSLog(@"create a new case");
        NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
        npvc.userName = self.itsMTLObject.objectId;
        npvc.delegate = self;
        
        [self.navigationController pushViewController:npvc animated:YES];
        
        return;
        
    }
    
    //popup a small window for editing the selection of this entry
    
    UIView *popupView = [[UIView alloc] initWithFrame:CGRectMake(20,50,280,400)];
    UIColor *lightYellowColor = [UIColor colorWithRed:252.0f/255.0f green:252.0f/255.0f blue:150.0f/255.0f alpha:1];
    popupView.backgroundColor = lightYellowColor;
    
    popupViewController *popVC = [self.storyboard instantiateViewControllerWithIdentifier:@"popupvc"];
    
    //set data for popupViewController
     NSNumber *selectedCaseItem = [NSNumber numberWithInteger:indexPath.row];
    
    popVC.popupitsMTLObject = self.itsMTLObject;
    popVC.selectedCase = self.selectedCaseIndex;
    popVC.selectedCaseItem = selectedCaseItem;
    popVC.selectedPropertyObject = [propsArray objectAtIndex:indexPath.row];
    popVC.UCIdelegate = self;
    
    
    //check the property type of the property at this selected index and set different modes on the popup accordingly.
    PFObject *selectedProperty = [propsArray objectAtIndex:indexPath.row];
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:indexPath.row];
    
    //check the property type and show different UI accordingly.
    NSString *propType = [popVC.selectedPropertyObject objectForKey:@"propertyType"];
    NSString *options = [selectedProperty objectForKey:@"options"];
    
    //If the property is type I, show an info Message
    //If the property is type N, do nothing.
    //If the property is type B, show the matches view controller
    if([propType  isEqual:@"I"])
    {
        //property is an info message
        //display a UI alert with the info in the info message
        NSString *infoMsg = [selectedProperty objectForKey:@"propertyDescr"];
        
        //for the caseItem of this index, take the params value
        NSString *params = [selectedCaseItemObject objectForKey:@"params"];
        
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
    }
    else if([options length]==0)
    {
        //show the popup in custom answer mode
       popVC.displayMode = @"custom";
        [self setPresentationStyleForSelfController:self presentingController:popVC];
        [self presentViewController:popVC animated:NO completion:nil];
    }
    else
    {
        //show the popup in the normal mode with the tableView
        popVC.displayMode = @"table";
        [self setPresentationStyleForSelfController:self presentingController:popVC];
        [self presentViewController:popVC animated:NO completion:nil];
        
    }
    
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

- (void)reloadData:(PFObject *) myObject
{
    
    self.itsMTLObject = myObject;
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *casesArray = [self.itsMTLObject objectForKey:@"cases"];
    PFObject *caseItemObject;
    
    int i = 0;
    int indexOfCase = 0;
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
    
    templateMode =0;
    
    caseItemObject = [casesArray objectAtIndex:indexOfCase];
    self.selectedCaseIndex = [NSNumber numberWithInt:indexOfCase];
    
    caseBeingUpdated = [caseItemObject objectForKey:@"caseId"];
  
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
    [propertsQuery orderByDescending:@"priority"];
    
    [propsArray removeAllObjects];
    int gj = 0;
    
    while ([propsArray count] != [sortedCaseItems count]) {
            propsArray = [[propertsQuery findObjects] mutableCopy];
        
            //check the propsArray and remove all objects if one of them doens't have a propertyDescr;
            for (PFObject *property in propsArray)
            {
                NSString *propDescr =[property objectForKey:@"propertyDescr"];
                if([propDescr length] ==0)
                {
                    [propsArray removeAllObjects];
                    break;
                    
                }
            }
        NSLog(@"doing the props query again");
        gj=gj+1;
        NSLog(@"%d",gj);
        
        }
    
    
    
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
    
    [self.caseDetailsEmailTableView reloadData];
    
    //remove the updating HUD
    [HUD hide:YES];
    
    //set the last timestamp value for cases where it's not the first template
   
        updateDate = self.itsMTLObject.updatedAt;
        
        for (PFObject *eachReturnedCase in casesArray)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] <=0)
            {
                NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                lastTimestamp = [f numberFromString:timeStampReturn];
                
            }
        }
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    
}
-(IBAction)doUpdate:(id)sender
{
    
    NSString *xmlForUpdate = [self createXMLTemplateModeFunction];
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];

    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Updating The Properties And Answers";
    [HUD show:YES];

    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"inboundZITSMTL"
                   withParameters:@{@"payload": xmlForUpdate}
                            block:^(NSString *responseString, NSError *error) {
                                
                                if (!error)
                                {
                                    
                                    NSString *responseText = responseString;
                                    NSLog(responseText);
                                    
                                    [HUD hide:NO];
                                    
                                    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
                                    PFObject *caseObject = [allCases objectAtIndex:[selectedCaseIndex integerValue]];
                                    caseBeingUpdated = [caseObject objectForKey:@"caseId"];
                                    
                                    NSString *timeStampReturn = [caseObject objectForKey:@"timestamp"];
                                    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                                    f.numberStyle = NSNumberFormatterDecimalStyle;
                                    lastTimestamp = [f numberFromString:timeStampReturn];
                                    
                                    [self pollForCaseRefresh];
                                    
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
    
    PFObject *returnedITSMTLObject = [query getObjectWithId:self.itsMTLObject.objectId];
    
    NSArray *returnedCases = [returnedITSMTLObject objectForKey:@"cases"];
    
    BOOL updateSuccess = 0;
    
    if(templateMode ==1)
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
        //check for a non template mode successful update
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
        [self reloadData:returnedITSMTLObject];
    
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
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    PFObject *caseObject = [allCases objectAtIndex:selectedCaseInt];
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:_userName];
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
    
    //Jan 18
    //updating to put ALL property tags first before caseItem tags
    int j = 0;
    
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        
        //do update
        
        PFObject *updatedProperty = [propsArray objectAtIndex:j];
        NSString *propertyNum = [eachCaseItem objectForKey:@"propertyNum"];
        NSString *propertyDescr = [updatedProperty objectForKey:@"propertyDescr"];
        
        //check to see if this caseItem is a brand new property
        
        if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:j]])
            
        {
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
            NSString *fullCharsString = [updatedProperty objectForKey:@"options"];
            
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
        
            //do update
            PFObject *updatedProperty = [propsArray objectAtIndex:h];
            NSString *propertyNum = [eachCaseItem objectForKey:@"propertyNum"];
            NSString *propertyDescr = [updatedProperty objectForKey:@"propertyDescr"];
        
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
            NSArray *answersDictionary = [eachCaseItem objectForKey:@"answers"];
        
            if([propertyType isEqualToString:@"I"] || [propertyType isEqualToString:@"N"] || [propertyType isEqualToString:@"B"])
            {
                //do nothing
            }
            else if([optionText length] == 0)
            {
                //write the answer as type Custom
                
                for (PFObject *ansObj in answersDictionary)
                {
                    NSString *ansString = [ansObj objectForKey:@"custom"];
                    [xmlWriter writeStartElement:@"ANSWER"];
                    
                    [xmlWriter writeStartElement:@"Custom"];
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
                
                for (PFObject *ansObj in answersDictionary)
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
                    [xmlWriter writeCharacters:semiColonDelimitedAAnswers];
                    [xmlWriter writeEndElement];
                    
                }
                
                [xmlWriter writeEndElement];
                
            }

    
            //close item element
            [xmlWriter writeEndElement];
        
        
        
    }
    if([locationRetrieved length]>0)
    {
        [xmlWriter writeStartElement:@"locationText"];
        [xmlWriter writeCharacters:locationRetrieved];
        [xmlWriter writeEndElement];
    }
    
    if([locationLatitude length]>0)
    {
        [xmlWriter writeStartElement:@"locationLatitude"];
        [xmlWriter writeCharacters:locationLatitude];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"locationLongitude"];
        [xmlWriter writeCharacters:locationLongitude];
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
    
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
    [self.caseDetailsEmailTableView reloadData];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
}
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
    
    
    NSMutableDictionary *caseItemObject = [[NSMutableDictionary alloc] init];
    [caseItemObject setObject:newCaseNum forKey:@"caseItem"];
    [caseItemObject setObject:Answers forKey:@"answers"];
    
    int g = (int)sortedCaseItems.count;
    
    [sortedCaseItems addObject:caseItemObject];
    [propsArray addObject:propertyObject];
    
    NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
    [newlyCreatedPropertiesIndex addObject:indexNum];
    [changedCaseItemsIndex addObject:indexNum];
    
    //[self.pickerView reloadAllComponents];
  //  [self.caseDetailsTableView reloadData];
    
    //Do something with data here
    NSLog(@"this fired");
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
    //reload data
    [self.caseDetailsEmailTableView reloadData];
    
    
    [self.navigationController popViewControllerAnimated:NO];
    
    
    
}

@end
