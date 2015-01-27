//
//  CaseDetailsEmailViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "CaseDetailsEmailViewController.h"
#import "popupViewController.h"

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
int EmailtimerTickCaseDetails =0;
int EmailsecondaryTimerTicks = 0;

//location manager variables
CLLocationManager *locationManager;
CLGeocoder *geocoder;
CLPlacemark *placemark;

//used for calcaulting swipe gestures
CGPoint startLocation;



NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;
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
        
    }
    
    [self.caseDetailsEmailTableView reloadData];
    

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
                
                NSLog(@"%@",optionsString);
                
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
    //popup a small window for editing the selection of this entry
    
    UIView *popupView = [[UIView alloc] initWithFrame:CGRectMake(20,50,280,400)];
    UIColor *lightYellowColor = [UIColor colorWithRed:252.0f/255.0f green:252.0f/255.0f blue:150.0f/255.0f alpha:1];
    popupView.backgroundColor = lightYellowColor;
    
    UIViewController *popVC = [self.storyboard instantiateViewControllerWithIdentifier:@"popupvc"];

    
    [self setPresentationStyleForSelfController:self presentingController:popVC];
    
    [self presentViewController:popVC animated:NO completion:nil];
    
    
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


@end
