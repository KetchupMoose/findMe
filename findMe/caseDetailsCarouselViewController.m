//
//  caseDetailsCarouselViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-04-06.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "caseDetailsCarouselViewController.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@implementation caseDetailsCarouselViewController

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



//location manager variables

CLGeocoder *geocoder;
CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;

//used for calcaulting swipe gestures
CGPoint startLocation;

NSMutableArray *propertyTableOptionsArray;
UIView *bgDarkenView;

-(void)viewDidLoad
{
   
    
   self.carousel.type = iCarouselTypeCoverFlow2;
    
    //set up delegates
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    
    self.propertiesTableView.delegate = self;
    self.propertiesTableView.dataSource = self;
    
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
    propertyTableOptionsArray = [[NSMutableArray alloc] init];
    
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
    
    //decide the selected index of the carousel and load that data
    //for now just default to 0 selected index
    PFObject *propertyObject = [propsArray objectAtIndex:0];
    
    //get choices
    NSString *propOptions = [propertyObject objectForKey:@"options"];
    propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
    
    [self.carousel reloadData];
     [self.propertiesTableView reloadData];
    
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
#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [sortedCaseItems count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    UIImageView *iconImgView = nil;
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        
        //view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
       // ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view = [[UIView alloc] initWithFrame:CGRectMake(0,50,200.0f,150.0f)];
        view.layer.borderColor = (__bridge CGColorRef)([UIColor blueColor]);
        view.layer.borderWidth = 3.0f;
        
        view.contentMode = UIViewContentModeCenter;
        
        view.backgroundColor = [UIColor blueColor];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0,100,200,50)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:16];
        label.tag = 1;
        
        iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(60,10,80,80)];
        iconImgView.tag = 2;
        
        [view addSubview:label];
        [view addSubview:iconImgView];
        
     
        
    
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
        iconImgView = (UIImageView *)[view viewWithTag:2];
        
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    
    PFObject *propAtIndex;
    PFObject *caseItemPicked = [sortedCaseItems objectAtIndex:index];
    selectedItemForUpdate = index;
    
    NSString *caseItemPickedPropertyNum = [caseItemPicked objectForKey:@"propertyNum"];
    
    //check to see if the object is a new property--new properties are set as NSDictionaries and cannot be accessed by .objectId
    if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:(int)index]])
    {
        propAtIndex = [propsArray objectAtIndex:index];
        
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
    label.text = propertyDescr;
    
    
    NSString *imgURL = [propAtIndex objectForKey:@"iconImageURL"];
    
    //set the iconImageView
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    [iconImgView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
   // iconImgView.image = [UIImage imageNamed:@"carselfie1.jpg"];
    
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    if (option == iCarouselOptionSpacing)
    {
        return value * 1.1;
    }
    return value;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
   /*
    PFObject *propertyObject = [propsArray objectAtIndex:index];
    
    //get choices
    NSString *propOptions = [propertyObject objectForKey:@"options"];
    propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
    [self.propertiesTableView reloadData];
    */
    
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
    NSInteger index = self.carousel.currentItemIndex;
    PFObject *propertyObject = [propsArray objectAtIndex:index];
    
    //get choices
    NSString *propOptions = [propertyObject objectForKey:@"options"];
    propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
    [self.propertiesTableView reloadData];

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
    NSLog(@"didUpdateToLocation: %@", newLocation);
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
        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
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
#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int caseItemsCount = (int)[propertyTableOptionsArray count];
    
    return caseItemsCount +1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"propertyCell" forIndexPath:indexPath];
    UILabel *optionLabel = (UILabel *)[cell viewWithTag:4];
    
    if(indexPath.row == propertyTableOptionsArray.count)
    {
        //show a button
        optionLabel.font = [UIFont systemFontOfSize:17];
        optionLabel.textColor = [UIColor blueColor];
        optionLabel.text = @"Add Another Answer";
    }
    else
    {
        optionLabel.font = [UIFont systemFontOfSize:17];
        optionLabel.textColor = [UIColor blackColor];
        optionLabel.text = [propertyTableOptionsArray objectAtIndex:indexPath.row];
    }
    
    NSString *rowNumber = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
    
    if([answersArray containsObject:rowNumber])
    {
        cell.backgroundColor = [UIColor greenColor];
        
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
        
    }
    NSString *optionTxt = optionLabel.text;
    
    if ([answersArray containsObject:optionTxt])
    {
        cell.backgroundColor = [UIColor greenColor];
        
    }
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    //for the last cell, show a keyboard to type a new option
    if(indexPath.row==propertyTableOptionsArray.count)
    {
        bgDarkenView = [[UIView alloc] initWithFrame:self.view.bounds];
        bgDarkenView.backgroundColor = [UIColor blackColor];
        bgDarkenView.alpha = 0.2;
        [self.view addSubview:bgDarkenView];
        
        UIView *newOptionView = [[UIView alloc] initWithFrame:CGRectMake(27,150,266,210)];
        newOptionView.backgroundColor = [UIColor whiteColor];
        newOptionView.layer.cornerRadius = 5.0f;
        [newOptionView.layer masksToBounds];
        
        UITextField *newAnsTextField = [[UITextField alloc] initWithFrame:CGRectMake(25,60,200,50)];
        [[newAnsTextField layer] setBorderColor:[[UIColor colorWithRed:171.0/255.0
                                                                 green:171.0/255.0
                                                                  blue:171.0/255.0
                                                                 alpha:1.0] CGColor]];
        newAnsTextField.layer.borderWidth = 1;
        newAnsTextField.layer.cornerRadius = 5;
        newAnsTextField.layer.masksToBounds = YES;
        newAnsTextField.tag = 88;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(newOptionView.frame.size.width-60,4,55,40)];
        [closeButton setTitle:@"Close" forState:UIControlStateNormal];
        [closeButton addTarget:self
                        action:@selector(closeNewAnswerView:)
              forControlEvents:UIControlEventTouchUpInside];
        
        
        UILabel *btnLabel = closeButton.titleLabel;
        btnLabel.font = [UIFont systemFontOfSize:12];
        closeButton.backgroundColor = [UIColor redColor];
        
        
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(110,125,50,50)];
        [addButton setTitle:@"Add" forState:UIControlStateNormal];
        UILabel *addBtnLabel = addButton.titleLabel;
        addBtnLabel.font = [UIFont systemFontOfSize:12];
        addButton.backgroundColor = [UIColor blueColor];
        [addButton addTarget:self
                      action:@selector(addNewAnswerView:)
            forControlEvents:UIControlEventTouchUpInside];
        
        [newOptionView addSubview:closeButton];
        [newOptionView addSubview:addButton];
        [newOptionView addSubview:newAnsTextField];
        [self.view addSubview:newOptionView];
        
        return;
        
    }
    
    UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.backgroundColor==[UIColor greenColor])
    {
        
        //remove this answer from the list.
        int i = 0;
        int indexToRemove = 0;
        
        //check to see if the answersArray includes the string label
        UILabel *optionLabel = (UILabel *)[cell viewWithTag:1];
        NSString *optionTxt = optionLabel.text;
        if ([answersArray containsObject:optionTxt])
        {
            NSInteger indexOfObject = [answersArray indexOfObject:optionTxt];
            
            [answersArray removeObject:optionTxt];
            [popupanswersDictionary removeObjectAtIndex:indexOfObject];
            
            
        }
        
        for (NSString *eachAns in answersArray)
        {
            int ansInt = (int)[eachAns integerValue];
            
            
            //making sure to compare to a number +1 since the answersArray has a 1 higher index
            if(ansInt==indexPath.row+1)
            {
                indexToRemove = i;
                cell.backgroundColor = [UIColor whiteColor];
                
            }
            i = i+1;
        }
        [answersArray removeObjectAtIndex:indexToRemove];
        [popupanswersDictionary removeObjectAtIndex:indexToRemove];
    }
    else
        
        //add the answer to the answers array and answersDictionary.
    {
        
        //check to see if the answer is an answer for one of the original properties on this caseItem or a new custom property
        if(indexPath.row +1 <=originalAnswersCount)
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [answersArray addObject:newAns];
            cell.backgroundColor = [UIColor greenColor];
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"a"];
            NSDictionary *myAnsDict = [AnsObj copy];
            
            [popupanswersDictionary addObject:myAnsDict];
        }
        else
        {
            UILabel *optionLabel = (UILabel *)[cell viewWithTag:1];
            NSString *newAns = optionLabel.text;
            [answersArray addObject:newAns];
            cell.backgroundColor = [UIColor greenColor];
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"custom"];
            NSDictionary *myAnsDict = [AnsObj copy];
            [popupanswersDictionary addObject:myAnsDict];
        }
        
    }
    
    self.updateButton.enabled = 1;
    [self.updateButton.titleLabel setTextColor:[UIColor blueColor]];
    
    */
}

@end
