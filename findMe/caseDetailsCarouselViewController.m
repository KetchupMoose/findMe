//
//  caseDetailsCarouselViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-04-06.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//


#import "caseDetailsCarouselViewController.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import <QuartzCore/QuartzCore.h>
#import "XMLWriter.h"
#import "mapPinViewController.h"
#import "verticalPanGestureRecognizer.h"
#import "matchesViewController.h"
#import "CaseTitleSetViewController.h"
#import "conversationJSQViewController.h"
#import "conversationModelData.h"


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
NSMutableArray *priorCaseIDS;
NSMutableArray *templateOptionsCounts;
NSMutableArray *items;
NSMutableArray *customAnsweredCaseItems;


PFObject *returnedITSMTLObject;
//this variable stores the case being updated so it's clear which one to show when the json returns.  Used for a case where we're not in "template mode".
PFObject *caseObjectBeingUpdated;
BOOL templateMode;

int suggestedCaseDisplayedIndex;
int carouselCaseUpdateTicker = 0;
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

float manualLocationLatitude;
float manualLocationLongitude;
@synthesize manualLocationPropertyNum;
NSString *manualLocationCaseItemID;
BOOL useManualLocation = NO;
//used for calcaulting swipe gestures
CGPoint startLocation;

NSMutableArray *propertyTableOptionsArray;
UIView *bgDarkenView;

NSMutableArray *selectedCaseItemAnswersArray;
NSMutableArray *selectedCaseItemAnswersArrayOfDictionaries;
NSMutableArray *selectedCaseItemOriginalOptions;
NSInteger selectedCarouselIndex;
NSMutableArray *activeMatchesArray;
NSMutableArray *activeMatchCaseObjectsArray;
NSMutableArray *activeMatchesCaseItemObjectsArray;
NSMutableArray *activeMatchesCaseTypesArray;
NSMutableArray *activeMatchesCaseProfiles;
NSMutableArray *changedCaseItemsIndex;

UIColor *colorForButtons;

UIView *deleteBGView;
NSString *answerabilityFlag;
NSString *propertyBeingUpdated;
BOOL LoadedBOOL = NO;


-(NSMutableArray *)filterOutLocationProperty:(NSMutableArray *)incomingCaseItems
{
    int j = 0;
    int indexToRemove = -1;
    for(PFObject *caseItemObject in incomingCaseItems)
    {
        NSString *propNum = [caseItemObject objectForKey:@"propertyNum"];
        if([propNum isEqualToString:manualLocationPropertyNum])
            {
                indexToRemove = j;
                //get the longitude and latitude;
                NSArray *answersArray = [caseItemObject objectForKey:@"answers"];
                NSDictionary *customAns = [answersArray objectAtIndex:0];
                NSString *longitudeLatitudeString = [customAns objectForKey:@"custom"];
                
                NSArray *longitudeLatitudeArray = [longitudeLatitudeString componentsSeparatedByString:@"; "];
                NSNumber *latitudeNum = [longitudeLatitudeArray objectAtIndex:0];
                
                manualLocationLatitude = [latitudeNum floatValue];
                NSNumber *longitudeNum = [longitudeLatitudeArray objectAtIndex:1];
                
                manualLocationLongitude = [longitudeNum floatValue];
                
                manualLocationCaseItemID = [caseItemObject objectForKey:@"caseItem"];
                
                NSLog(@"filtering out location property");
                NSLog(@"%f",manualLocationLatitude);
                NSLog(@"%f",manualLocationLongitude);
            }
        j = j+1;
    }
    
    if(indexToRemove>-1)
    {
         [incomingCaseItems removeObjectAtIndex:indexToRemove];
    }
   
    
    return incomingCaseItems;
    
}
-(void)viewDidLoad
{
    colorForButtons = [UIColor colorWithRed:41/255.0f green:188.0f/255.0f blue:243.0f/255.0f alpha:1];
    
    items = [NSMutableArray array];
    for (int i = 0; i < 1000; i++)
    {
        [items addObject:@(i)];
    }
        
    self.carousel.type = iCarouselTypeCoverFlow2;
    self.carousel.bounces = YES;
    self.carousel.scrollToItemBoundary = YES;
    self.carousel.stopAtItemBoundary = YES;
    
    //set up delegates
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.customAnswerTextField.delegate = self;
    
    [self.carousel scrollToItemAtIndex:0 duration:0.0f];
    
    manualLocationLatitude = 0;
    manualLocationLongitude = 0;
    self.viewMatchesButton.alpha = 0;
    
    
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
    
    caseObjectBeingUpdated = caseObject;
    
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    int length = (int)[caseObjectID length];
    
    if(length==0)
    {
        //self.submitAnswersButton.titleLabel.text = @"Create Case";
        [self.submitAnswersButton setTitle:@"Create Case" forState:UIControlStateNormal];
        self.submitAnswersButton.titleLabel.textColor = [UIColor whiteColor];
        
        templateMode = 1;
        
    }
    else
    {
        templateMode= 0;
        self.carousel.animateSwipeUp = YES;
        
        
    }
    caseItems= [caseObject objectForKey:@"caseItems"];
    
    //sort the incoming caseItems by priority
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    sortedCaseItems = [self filterOutLocationProperty:sortedCaseItems];
    
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
    priorCaseIDS = [[NSMutableArray alloc] init];
    templateOptionsCounts = [[NSMutableArray alloc] init];
    propertyTableOptionsArray = [[NSMutableArray alloc] init];
    selectedCaseItemAnswersArray = [[NSMutableArray alloc] init];
    selectedCaseItemAnswersArrayOfDictionaries  = [[NSMutableArray alloc] init];
    selectedCaseItemOriginalOptions = [[NSMutableArray alloc] init];
    customAnsweredCaseItems = [[NSMutableArray alloc] init];
    changedCaseItemsIndex = [[NSMutableArray alloc] init];
    
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
    selectedCaseItemOriginalOptions = propertyTableOptionsArray;
     answerabilityFlag = [propertyObject objectForKey:@"answerability"];
    
    
    [self.carousel reloadData];
    
    self.propertiesTableView.delegate = self;
    self.propertiesTableView.dataSource = self;
    self.matchesTableView.delegate = self;
    self.matchesTableView.dataSource = self;
    
    [self.propertiesTableView reloadData];
    
    LoadedBOOL = YES;
    
    [self checkForSureMatch:propsArray];
    
    //check to see if we should fire bubble burst
    //only fire a bubble burst if there is at least one new flag
    BOOL fireBubbleBurst = NO;
    for(PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *stringVal = [eachCaseItem objectForKey:@"new"];
        
        if([stringVal isEqualToString:@"X"])
        {
            //found one
            fireBubbleBurst = YES;
        }
    }
    if(fireBubbleBurst ==YES)
    {
        [self sendBubbleBurst:caseObjectBeingUpdated];
        
    }
    
    [self carouselCurrentItemIndexDidChange:self.carousel];
    
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
    
    self.propertiesTableView.backgroundColor = [UIColor clearColor];
    self.propertiesTableView.layer.borderColor = (__bridge CGColorRef)([UIColor whiteColor]);
    self.propertiesTableView.layer.borderWidth = 3.0f;
    self.propertiesTableView.layer.masksToBounds = YES;
    
    self.navigationController.navigationBarHidden = NO;
    
   
    [self.addCaseItemButton.layer setCornerRadius:self.addCaseItemButton.bounds.size.width / 2.0];
    [self.addCaseItemButton.layer setMasksToBounds:YES];
    [self.addCaseItemButton setTitleEdgeInsets:UIEdgeInsetsMake(-10, 0, 0, 0)];
   
    
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
        caseObjectBeingUpdated = caseItemObject;
        
    }
    
    NSString *caseObjectID = [caseItemObject objectForKey:@"caseId"];
    
    int length = (int)[caseObjectID length];
    
    if(length==0)
    {
        //self.submitAnswersButton.titleLabel.text = @"Create Case";
        [self.submitAnswersButton setTitle:@"Create Case" forState:UIControlStateNormal];
        self.submitAnswersButton.titleLabel.textColor = [UIColor whiteColor];
        
        templateMode = 1;
    }
    else
    {
        templateMode= 0;
       
    }

}

//XML of bubble burst
/*
 <PAYLOAD>
 <USEROBJECTID>NoJW05Xwsq</USEROBJECTID>
 <LAISO>EN</LAISO>
 <CASEOBJECTID>2giurY8F9c</CASEOBJECTID>
 <CASENAME>I just saw you</CASENAME>
 <BUBBLEBURST>320</BUBBLEBURST>
 </PAYLOAD>
 */

-(void)sendBubbleBurst:(PFObject *) caseObject
{
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    
    if([self.externalCaseName length] >0)
    {
        caseName = self.externalCaseName;
        
    }
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    NSString *version = [caseObject objectForKey:@"version"];
    
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
    
    [xmlWriter writeStartElement:@"CASEOBJECTID"];
    [xmlWriter writeCharacters:caseObjID];
    [xmlWriter writeEndElement];
    
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

    
    [xmlWriter writeStartElement:@"BUBBLEBURST"];
    [xmlWriter writeCharacters:version];
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];

    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xml}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                    if (!error)
                                    {
                                        NSLog(@"bubble bursted successfully");
                                        
                                    }
                                    else
                                        
                                    {
                                        NSLog(@"error bursting bubble for case");
                                    }
                                }];
    
    
}


#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    //return the total number of items in the carousel
    return [sortedCaseItems count]+1;
    
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    //NSLog(@"making view for index");
    //NSLog(@"%ld",(long)index);
    
    UILabel *carouselLabel = nil;
    UIView *borderView = nil;
    UIImageView *iconImgView = nil;
    UILabel *propertyClassLabel = nil;
    UIButton *deleteButton = nil;
    UIButton *createACaseItem = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        
        //view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
       
        // ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view = [[UIView alloc] initWithFrame:CGRectMake(0,0,120.0f,self.carousel.frame.size.height)];
        
        view.layer.borderColor = (__bridge CGColorRef)([UIColor blueColor]);
        //view.layer.borderWidth = 25.0f;
        [view.layer setBorderWidth:20];
        
        view.contentMode = UIViewContentModeCenter;
        
        //view.backgroundColor = [UIColor blueColor];
        
        UIView *borderView = [[UIView alloc] initWithFrame:view.bounds];
        borderView.layer.borderColor =[UIColor whiteColor].CGColor;
        borderView.layer.borderWidth = 2.0f;
        borderView.layer.cornerRadius = 10.0f;
        borderView.tag = 77;
        //borderView.backgroundColor = [UIColor redColor];
        
        [view addSubview:borderView];
        
        
        carouselLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,2,view.frame.size.width-10,60)];
        carouselLabel.backgroundColor = [UIColor clearColor];
        carouselLabel.textAlignment = NSTextAlignmentCenter;
        carouselLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:18];
        carouselLabel.numberOfLines = 2;
        
        carouselLabel.textColor = [UIColor whiteColor];
        
        carouselLabel.tag = 1;
        carouselLabel.numberOfLines = 2;
        
        
        iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(35,view.frame.size.height-60,50,50)];
        iconImgView.tag = 2;
        
        propertyClassLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,5,100,25)];
        propertyClassLabel.tag = 3;
        propertyClassLabel.text = @" Template Question ";
        propertyClassLabel.font = [UIFont boldSystemFontOfSize:12];
        
        propertyClassLabel.textColor = [UIColor blackColor];
        UIColor *defaultLabelColor = [UIColor colorWithRed:255/255 green:255/255 blue:204.0f/255.0f alpha:1];
        
        propertyClassLabel.backgroundColor = defaultLabelColor;
        propertyClassLabel.layer.cornerRadius = 5.0f;
        propertyClassLabel.layer.masksToBounds = YES;
        propertyClassLabel.layer.borderColor = [UIColor blueColor].CGColor;
        propertyClassLabel.layer.borderWidth = 1.0f;
        
        int deleteButtonWidth = 50;
        int deleteButtonHeight = 30;
        
        deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(view.frame.size.width-deleteButtonWidth-5,5,deleteButtonWidth,deleteButtonHeight)];
        
        [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [deleteButton setBackgroundColor:[UIColor redColor]];
        [deleteButton addTarget:self action:@selector(deleteCaseItem:) forControlEvents:UIControlEventTouchUpInside];
        [deleteButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
        deleteButton.tag = 100+index;
        deleteButton.alpha = 0;
        
        
        //create near the bottom
        int createButtonWidth = 180;
        int createButtonHeight = 75;
        createACaseItem = [[UIButton alloc] initWithFrame:CGRectMake(view.frame.size.width/2-createButtonWidth/2,view.frame.size.height-createButtonHeight-10,createButtonWidth,createButtonHeight)];
        [createACaseItem setTitle:@"Create A Question!" forState:UIControlStateNormal];
        
        [createACaseItem setBackgroundColor:colorForButtons];
        [createACaseItem.titleLabel setTextColor:[UIColor whiteColor]];
        createACaseItem.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        createACaseItem.layer.cornerRadius = 5.0f;
        [createACaseItem addTarget:self action:@selector(createCaseItem:) forControlEvents:UIControlEventTouchUpInside];
        createACaseItem.tag = 5;
        
         verticalPanGestureRecognizer *panRecognizer = [[verticalPanGestureRecognizer alloc] initWithTarget:self action:@selector(carouselViewPanDetected:)];
        panRecognizer.cancelsTouchesInView = NO;
       
        //[view addGestureRecognizer:panRecognizer];
        [view addSubview:carouselLabel];
        [view addSubview:iconImgView];
        //[view addSubview:propertyClassLabel];
        [view addSubview:deleteButton];
        //[view addSubview:createACaseItem];
        
    }
    else
    {
        //get a reference to the label in the recycled view
        
         carouselLabel = (UILabel *)[view viewWithTag:1];
        iconImgView = (UIImageView *)[view viewWithTag:2];
        propertyClassLabel = (UILabel *)[view viewWithTag:3];
        deleteButton = (UIButton *)[view viewWithTag:100+index];
        createACaseItem = (UIButton *) [view viewWithTag:5];
        
        borderView = (UIView *)[view viewWithTag:77];
        
         carouselLabel = (UILabel *)[view viewWithTag:1];
    }
    
       
    //iconImgView.tag = 2;
    //propertyClassLabel.tag = 3;
    deleteButton.tag = 100+index;
    //createACaseItem.tag = 5;
    
       
    if(index ==[sortedCaseItems count])
    {
        //display UI to create your own case item
        createACaseItem.alpha = 1;
        deleteButton.alpha = 0;
        carouselLabel.text = @"Create A Question";
        propertyClassLabel.text = @" Create Question ";
       UIColor *propertyCreateBGColor = [UIColor colorWithRed:0/255.0f green:204.0f/255.0f blue:102.0f/255.0f alpha:1];
        propertyClassLabel.backgroundColor = propertyCreateBGColor;
        propertyClassLabel.textColor = [UIColor whiteColor];
       
        //set the iconImageView
        [iconImgView setImage:nil];
        
        [propertyClassLabel sizeToFit];
        
        return view;
        
    }
    else
    {
        createACaseItem.alpha =0;
        deleteButton.alpha =0;
        
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
    //NSLog(@"writing property descr");
    
    //NSLog(propertyDescr);
    
    
    carouselLabel.text = propertyDescr;
   // NSLog(@"writing carousel label ended");
    
    NSString *imgURL = [propAtIndex objectForKey:@"v2iconImageURL"];
    
    if([imgURL length]==0)
    {
       imgURL = @"http://i.imgur.com/MnknKF8.png";
    }
    //set the iconImageView
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    [iconImgView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
   // iconImgView.image = [UIImage imageNamed:@"carselfie1.jpg"];
    
    //get property type and customize the label
    NSString *propType = [propAtIndex objectForKey:@"propertyType"];
   
    /*
    if([propType  isEqual:@"I"])
    {
        //property is an info message
        propertyClassLabel.text = @" Info Message ";
        propertyClassLabel.textColor = [UIColor blackColor];
        propertyClassLabel.backgroundColor = [UIColor whiteColor];
        
        
    }
    else if([propType isEqual:@"N"])
    {
        propertyClassLabel.text = @" New Suggestion ";
        propertyClassLabel.textColor = [UIColor whiteColor];
        propertyClassLabel.backgroundColor = [UIColor blueColor];
        
    }
    
    else if([propType isEqual:@"B"])
    {
        propertyClassLabel.text = @" View Matches! ";
        propertyClassLabel.textColor = [UIColor whiteColor];
        propertyClassLabel.backgroundColor = [UIColor redColor];
    }
    */
    
    NSString *newVal = [caseItemPicked objectForKey:@"new"];
    if([newVal isEqualToString:@"X"])
    {
        propertyClassLabel.text = @"NEW";
        propertyClassLabel.textColor = [UIColor whiteColor];
        propertyClassLabel.backgroundColor = [UIColor blueColor];
    }
    else
    {
        propertyClassLabel.text = @"";
        propertyClassLabel.backgroundColor = [UIColor clearColor];
        
    }
    [propertyClassLabel sizeToFit];
    
    
    //NSLog(@"prebug");
   // NSLog(@"%ld",carouselLabel.tag);
    
    
    //NSLog(@"postbug");
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


/*
-(void)carouselViewPanDetected:(UIPanGestureRecognizer *)sendingPan
{
    UIView *carouselView = (UIView *)sendingPan.view;
    NSInteger viewTag = carouselView.tag;
    NSLog([NSString stringWithFormat:@"%ld",(long)viewTag]);
    [self.carousel gestureRecognizerShouldBegin:sendingPan];
    
}
*/
- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
  
}

-(void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    NSInteger index = self.carousel.currentItemIndex;
    NSLog(@"carousel index fired");
    NSLog(@"%ld",index);
    
    selectedCarouselIndex = self.carousel.currentItemIndex;
    NSInteger carouselNumOfItems = self.carousel.numberOfItems;
    if(index ==carouselNumOfItems-1)
    {
        self.propertiesTableView.alpha = 0;
        self.matchesTableView.alpha = 0;
       
        self.viewMatchesButton.alpha = 0;
        self.customAnswerTextField.alpha = 0;
        self.customAnswerLabel.alpha = 0;
        self.customAnswerButton.alpha = 0;
        self.customAnswerLabel.text = @"";
        self.customAnswerCheckmark.alpha = 0;
        return;
    }
    else
    {
        
        PFObject *propertyObject = [propsArray objectAtIndex:index];
        
        NSString *propTypeString = [propertyObject objectForKey:@"propertyType"];
        
        if([propTypeString isEqualToString:@"B"])
        {
            
            
            self.matchesTableView.alpha = 1;
            self.propertiesTableView.alpha = 0;
            self.viewMatchesButton.alpha = 0;
            self.customAnswerTextField.alpha = 0;
            self.customAnswerLabel.alpha = 0;
            self.customAnswerButton.alpha = 0;
            self.customAnswerLabel.text = @"";
            self.customAnswerCheckmark.alpha = 0;
            
            //gather the full array of matches to display
            //loop through the itsMTLObject and gather all the user's matches
            activeMatchesArray = [[NSMutableArray alloc] init];
            activeMatchCaseObjectsArray = [[NSMutableArray alloc] init];
            activeMatchesCaseItemObjectsArray = [[NSMutableArray alloc] init];
            activeMatchesCaseTypesArray = [[NSMutableArray alloc] init];
           
            //get selectedCaseItemObject
            PFObject *caseItemObject = [sortedCaseItems objectAtIndex:index];
            
            //get selectedCase
            //class level variable caseObjectBeingUpdated;
            
            
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
                                [activeMatchesArray addObject:caseMatchID];
                                NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                                [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                                
                                [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                                [activeMatchesCaseTypesArray addObject:@"rejected"];
                                
                            }
                            
                        }
                        
                        if([matchesYesArray count] >0)
                        {
                            for(NSString *caseMatchID in matchesYesArray)
                            {
                                
                                //if(![activeMatchesArray containsObject:caseMatchID])
                                // {
                                [activeMatchesArray addObject:caseMatchID];
                                [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                                NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                                [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                                [activeMatchesCaseTypesArray addObject:@"yes"];
                                //  }
                                
                            }
                            
                        }
                        
                        if([matchesArray count] >0)
                        {
                            for(NSString *caseMatchID in matchesArray)
                            {
                                // if(![activeMatchesArray containsObject:caseMatchID])
                                //{
                                [activeMatchesArray addObject:caseMatchID];
                                [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                                NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                                
                                [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                                [activeMatchesCaseTypesArray addObject:@"match"];
                                // }
                            }
                            
                        }
                    }
            
            //query for caseProfiles
            PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
            [caseProfileQuery whereKey:@"caseID" containedIn:activeMatchesArray];
            [caseProfileQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
             {
                 activeMatchesCaseProfiles = [objects mutableCopy];
                  [self.matchesTableView reloadData];
             }];
            
                                                                
           
            
           
            
            
            return;
            
        }
        if([propTypeString isEqualToString:@"N"] || [propTypeString isEqualToString:@"I"])
        {
            self.matchesTableView.alpha = 0;
                       self.propertiesTableView.alpha = 0;
            self.viewMatchesButton.alpha = 0;
            self.customAnswerTextField.alpha = 0;
            self.customAnswerLabel.alpha = 0;
            self.customAnswerButton.alpha = 0;
             self.customAnswerCheckmark.alpha = 0;
            self.customAnswerLabel.text = @"";
            
            return;
        }
        
        //get choices
        NSString *propOptions = [propertyObject objectForKey:@"options"];
        propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
        
        answerabilityFlag = [propertyObject objectForKey:@"answerability"];
        
        selectedCaseItemOriginalOptions = propertyTableOptionsArray;
        
        //set the answers array
        PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:index];
        self.propertiesTableView.alpha =1;
        self.viewMatchesButton.alpha = 0;
        if([selectedCaseItemObject objectForKey:@"answers"] !=nil)
        {
            selectedCaseItemAnswersArrayOfDictionaries  = [[selectedCaseItemObject objectForKey:@"answers"] mutableCopy];
        }
        else
        {
            selectedCaseItemAnswersArrayOfDictionaries = [[NSMutableArray alloc] init];
            
        }
       
        //build the mutableArray of answers from the dictionary
        
        //check to see if this row is one of the custom answer types.  It is if option length is 0.
        if([propOptions length] ==0)
        {
            //display just one custom answer
            NSString *customAns;
            //check to see if the custom answer is there
            for (NSDictionary *eachAnsObj in  selectedCaseItemAnswersArrayOfDictionaries)
            {
                customAns = [eachAnsObj valueForKey:@"custom"];
            }
            
            //set a textbox value as that current answer, don't show the tableview
            //WORKINPROGRESS APR 13
            //answersLabel.text = customAns;
            self.matchesTableView.alpha = 0;
            
            self.propertiesTableView.alpha = 0;
             self.customAnswerCheckmark.alpha = 0;
            
            self.customAnswerTextField.text = customAns;
            
            self.customAnswerTextField.alpha = 1;
            self.customAnswerLabel.alpha = 1;
            self.customAnswerButton.alpha = 1;
            self.customAnswerLabel.text = @"Enter Your Custom Answer";
            self.customAnswerLabel.textColor = [UIColor whiteColor];
            
            //self.customAnswerLabel.text = customAns;
            
            
        }
        else
        {
            [selectedCaseItemAnswersArray removeAllObjects];
            
            for (PFObject *eachAnsObj in selectedCaseItemAnswersArrayOfDictionaries )
            {
                NSString *ansNum = [eachAnsObj valueForKey:@"a"];
                if([ansNum length] ==0)
                {
                    ansNum = [eachAnsObj valueForKey:@"custom"];
                }
                [selectedCaseItemAnswersArray addObject:ansNum];
                
            }
        self.propertiesTableView.alpha=1;
        self.matchesTableView.alpha = 0;
        self.customAnswerTextField.alpha = 0;
        self.customAnswerLabel.alpha = 0;
        self.customAnswerCheckmark.alpha = 0;
        self.customAnswerButton.alpha = 0;
        self.customAnswerLabel.text = @"";
        [self.propertiesTableView reloadData];
        }
        
    }
   
}

-(IBAction)viewMatches:(id)sender
{
    PFObject *caseItemPicked = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
    
    
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
}


-(void)showDeleteBGView
{
    //show a UIView to indicate that the delete is in progress
    if(deleteBGView !=nil)
    {
        return;
    }
    deleteBGView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,400)];
    
    deleteBGView.backgroundColor = [UIColor blackColor];
    
    deleteBGView.layer.cornerRadius = 10.0f;
    
    UILabel *deletionInProgress = [[UILabel alloc] initWithFrame:CGRectMake(0,200,self.view.bounds.size.width,100)];
    deletionInProgress.text = @"Deletion In Progress";
    deletionInProgress.textAlignment = NSTextAlignmentCenter;
    
    deletionInProgress.textColor = [UIColor whiteColor];
    
    [deleteBGView addSubview:deletionInProgress];
    
    [self.view addSubview:deleteBGView];
}

-(void)popDeleteBGView
{
    [deleteBGView removeFromSuperview];
    deleteBGView = nil;
    
}

- (void)removeDelegateDataAtIndex:(NSInteger) index
{
    if(templateMode==YES)
    {
        //do nothing
    }
    else
    {
        
    [self showDeleteChoiceView:index];
        
   
    
    }
    
    
    /*
    [sortedCaseItems removeObjectAtIndex:index];
    [propsArray removeObjectAtIndex:index];
    
    [self.carousel removeItemAtIndex:index animated:YES];
    
    [self.carousel reloadData];
    [self carouselCurrentItemIndexDidChange:self.carousel];
    
    [self.propertiesTableView reloadData];
    */
    
    //[self.carousel reloadData];
    
}

-(void)showDeleteChoiceView:(NSInteger) index
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Case Item"
                                                        message:@"Are You Sure You Want To Delete This Case Item?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Delete", nil];
    alertView.tag = index;
    [alertView show];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)//Cancel button pressed
    {
        //start delete process
        
        
    }
    else if(buttonIndex == 1)//Delete button pressed.
    {
         //start delete process
        [self showDeleteBGView];
        
        NSLog(@"deleting for this index");
        NSLog(@"%ld",alertView.tag);
        
        //start the XML for processing the delete
        PFObject *caseItemObjectAtIndex = [sortedCaseItems objectAtIndex:alertView.tag];
        [self deleteACaseItem:caseItemObjectAtIndex atIndex:alertView.tag];
    }
}

-(void)deleteCaseItem:(id)sender
{
    if(templateMode==1)
    {
        return;
    }
    
    UIButton *sendingButton = (UIButton *)sender;
    UIView *carouselItemView = sendingButton.superview;
    NSInteger *index = [self.carousel indexOfItemView:carouselItemView];
    //NSInteger index = sendingButton.tag -100;
    
    NSLog(@"deleting for this index");
    NSLog(@"%ld",index);
    
    //do delete actions for this index
    
    //if no data remains, do not delete
    if(sortedCaseItems.count ==1)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Delete", nil) message:@"Case must retain at least one question" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    [self showDeleteBGView];
    
    //start the XML for processing the delete
    PFObject *caseItemObjectAtIndex = [sortedCaseItems objectAtIndex:index];
    [self deleteACaseItem:caseItemObjectAtIndex atIndex:index];
   
}

-(void)createCaseItem:(id)sender
{
   /*
    //code to spoof a new carousel item
    NSMutableDictionary *newCaseItem = [[NSMutableDictionary alloc] init];
    NSMutableArray *myArray = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 4; i++)
    {
        NSMutableDictionary *newAns = [[NSMutableDictionary alloc] init];
        NSString *ansString = [[NSString alloc] initWithFormat:@"%d",i];
        
        [newAns setObject:ansString forKey:@"a"];
        
        [myArray addObject:newAns];
    }
    [newCaseItem setObject:myArray forKey:@"answers"];
    NSMutableDictionary *propObject = [[NSMutableDictionary alloc] init];
    [propObject setObject:@"blah, blah2, blah3, blah4" forKey:@"options"];
    [propObject setObject:@"testprop" forKey:@"propertyDescr"];
     NSString *ansString = [[NSString alloc] initWithFormat:@"%d",444];
    [propObject setObject:ansString forKey:@"propertyNum"];
    NSString *newNum =[[NSString alloc] initWithFormat:@"%d",9444];
    [newCaseItem setObject:newNum forKey:@"caseItem"];
    [newCaseItem setObject:ansString forKey:@"propertyNum"];
    
    [sortedCaseItems addObject:newCaseItem];
    [propsArray addObject:propObject];
    
    int g = (int)sortedCaseItems.count-1;
    
    NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
    [newlyCreatedPropertiesIndex addObject:indexNum];
   
    [self.carousel reloadData];
*/
    
    //do stuff with button
    NSLog(@"create a new case");
    NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
    npvc.userName = self.userName;
    npvc.delegate = self;
    
    [self.navigationController pushViewController:npvc animated:YES];
    
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
   // NSLog(@"didUpdateToLocation: %@", newLocation);
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
        //NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
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
if(tableView.tag ==8999)
{
    
    int caseItemsCount = (int)[propertyTableOptionsArray count];
    
    //check to see answerability of the currently selected case item.  If it is not one that supports custom answers, then do not show the Add Another Answer option.
    NSInteger index = selectedCarouselIndex;
    
    PFObject *propertyObject = [propsArray objectAtIndex:index];
    
    NSString *answerability = [propertyObject objectForKey:@"answerability"];
    NSString *propType = [propertyObject objectForKey:@"propertyType"];
    if([propType  isEqual:@"I"] || [propType isEqual:@"B"] || [propType isEqual:@"N"])
    {
        return caseItemsCount;
    }
    
    if([answerability length] ==0 || [answerability containsString:@"+"])
    {
         return caseItemsCount +1;
    }
    else
    {
        return caseItemsCount;
        
    }
}
    else
    {
        return activeMatchesArray.count;
        
    }
   
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSInteger tableViewTag = tableView.tag;
 
if(tableViewTag ==8999)
    {
        
       UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"propertyCell" forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:
                    UITableViewCellStyleDefault reuseIdentifier:@"propertyCell"];
        }
        
    UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
    NSString *optionTxt;
    
    if(indexPath.row == propertyTableOptionsArray.count)
    {
        //show a button
        optionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        optionLabel.textColor = colorForButtons;
        optionLabel.shadowColor = [UIColor whiteColor];
        optionLabel.shadowOffset = CGSizeMake(0,1);
        
        optionLabel.text = @"Add Another Answer";
        
        NSNumber *indexNum = [NSNumber numberWithInteger:selectedCarouselIndex];
        if([customAnsweredCaseItems containsObject:indexNum])
        {
            //change the label to gray color
            
            optionLabel.textColor = [UIColor whiteColor];
            optionLabel.text = @"Add More Answers After Submitting Case";
            
        }
    }
    else
    {
        optionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
        optionLabel.textColor = [UIColor whiteColor];
        optionLabel.text = [propertyTableOptionsArray objectAtIndex:indexPath.row];
        optionTxt =[propertyTableOptionsArray objectAtIndex:indexPath.row];
    }
    
    NSString *rowNumber = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
    
    if([selectedCaseItemAnswersArray containsObject:rowNumber])
    {
        cell.backgroundColor = colorForButtons;
        
        
    }
    else
    {
        cell.backgroundColor = [UIColor clearColor];
        
    }
   
    if ([selectedCaseItemAnswersArray  containsObject:optionTxt])
    {
        cell.backgroundColor = colorForButtons;
        
    }
    
    return cell;
 }
else
{
    
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"matchCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SWTableViewCell alloc]initWithStyle:
                UITableViewCellStyleDefault reuseIdentifier:@"matchCell"];
    }

    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;

    
    //customize the cell
    UIImageView *matchImageView = (UIImageView *)[cell viewWithTag:201];
    UILabel *caseTitleLabel = (UILabel *)[cell viewWithTag:202];
    UILabel *caseNameLabel = (UILabel *)[cell viewWithTag:203];
    
    NSString *matchCaseID = [activeMatchesArray objectAtIndex:indexPath.row];
    
    //matchNameLabel.text = matchNameString;
    
    //check to see if there is a caseProfile for this caseID
    NSString *caseimgURL;
    for (PFObject *caseProfileObj in activeMatchesCaseProfiles)
    {
        NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
        if([matchCaseID isEqualToString:caseProfileCaseID])
        {
            //display case information
            caseNameLabel.text = [caseProfileObj objectForKey:@"externalCaseName"];
            PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
            caseimgURL = imgFile.url;
        }
    }
    UIActivityIndicatorViewStyle *activityStyle = UIActivityIndicatorViewStyleGray;
    
    if([caseimgURL length] ==0)
    {
        NSString *defaultMatchImgFileName = [[NSBundle mainBundle] pathForResource:@"femalesilhouette" ofType:@"jpeg"];
        matchImageView.image = [UIImage imageWithContentsOfFile:defaultMatchImgFileName];
        
    }
    else
    {
        [matchImageView setImageWithURL:[NSURL URLWithString:caseimgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    }
    
    NSString *matchType = [activeMatchesCaseTypesArray objectAtIndex:indexPath.row];
    if([matchType isEqualToString:@"yes"])
    {
        caseNameLabel.textColor = [UIColor greenColor];
        
    }
    else if([matchType isEqualToString:@"rejected"])
    {
        caseNameLabel.textColor = [UIColor grayColor];
        
    }

     return cell;
}
   
    

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
    int tableViewTag = tableView.tag;
    
if(tableViewTag ==8999)
{
    
    //add to changedCaseItemsIndex if this index isn't already represented
    NSNumber *changedCaseItemIndexNum = [NSNumber numberWithInteger:selectedCarouselIndex];
    
    if(![changedCaseItemsIndex containsObject:changedCaseItemIndexNum])
    {
        [changedCaseItemsIndex addObject:changedCaseItemIndexNum];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    //for the last cell, show a keyboard to type a new option
    if(indexPath.row==propertyTableOptionsArray.count)
    {
        NSNumber *indexNum = [NSNumber numberWithInteger:selectedCarouselIndex];
        if([customAnsweredCaseItems containsObject:indexNum])
        {
            //don't respond when this is selected
            
            return;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        //cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
   
     UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    //implement answerability logic:
    //- Property error: Answerability 0..1 violated
    //- Property error: Answerability 1 violated
    //Property error: Answerability 0..n violated
    //- Property error: Answerability 1..n violated
    //- Property error: Answerability 0..n+ violated
    //- Property error: Answerability 1..n+ violated
    
    //if answerability 0..1, answer must be 0 answer or 1.
    //if answerability 1, answer must have exactly one answer
    //if answerability 0..n, answer must have 0 or multiple answers, but no custom answer
    //if answerability 1..n, answer must have at least 1 answer, can support multiple answers, but have no custom answers
    //if answerability 0..n+, answer can have multiple answers,custom answers, and a blank answer
    //if answerability 1..n+, answer must have at least one answer, can have multiple answers, can have custom answer
    
    PFObject *propertyObject = [propsArray objectAtIndex:selectedCarouselIndex];
    NSString *answerability = [propertyObject objectForKey:@"answerability"];
    
    //if the property is user created, use a different method for removing it from the list since it's defined as numeric
    NSString *propType = [propertyObject objectForKey:@"propertyType"];
    if([propType isEqualToString:@"U"])
       {
           //handling removing and re-adding answers for custom answer type
           [self HandleCustomAnswerChange:indexPath UITableViewCell:cell];
           return;
       }
    
    if([answerability length] ==0)
    {
        [self HandleAnswer0NPlus:indexPath UITableViewCell:cell];
        
    }
    else
    {
        NSArray *items = @[@"1", @"0..n", @"0..1",@"1..n",@"0..n+",@"1..n+"];
        int item = [items indexOfObject:answerability];
        switch (item) {
            case 0:
                [self HandleAnswer1:indexPath UITableViewCell:cell];
            break;
            case 1:
                [self HandleAnswer0NPlus:indexPath UITableViewCell:cell];
            break;
            case 2:
                [self HandleAnswer01:indexPath UITableViewCell:cell];
            break;
            case 3:
                [self HandleAnswer1NPlus:indexPath UITableViewCell:cell];
            break;
            case 4:
                [self HandleAnswer0NPlus:indexPath UITableViewCell:cell];
            break;
            case 5:
                [self HandleAnswer1NPlus:indexPath UITableViewCell:cell];
            break;
            default:
            break;
    }

    }
 
    //APR13
    //these two class level variables are already filled each time the user selects a new property with the carousel.
    //the mutable dictionary will be the object that is populated and sent eventually to the JSON when updates are being done.
    //NSMutableArray *selectedCaseItemAnswersArray;
    //NSMutableDictionary *selectedCaseItemAnswersArrayOfDictionaries ;
    //this code will have an error if users enter values with numeric strings (ie; they enter "2" and then it goes to remove 2 twice later
    
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
    NSString *caseItemObjectID = [selectedCaseItemObject objectForKey:@"caseItem"];
    
    [self updateCaseItem:caseItemObjectID AcceptableAnswersList:selectedCaseItemAnswersArrayOfDictionaries ForNewAnswer:NO];
    
    self.submitAnswersButton.enabled = 1;
    UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
    
    [self.submitAnswersButton.titleLabel setBackgroundColor:submitAnswersColor];
    
  
    
}
    else
{
        
   [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    //create a conversation PFObject between the two usernames or look up the conversation object
    PFQuery *query = [PFQuery queryWithClassName:@"Conversations"];
    
    NSString *matchID = [activeMatchesArray objectAtIndex:indexPath.row];
    NSMutableArray *twoMatches = [[NSMutableArray alloc] init];
    
    [twoMatches addObject:matchID];
    PFObject *caseObjAtIndex = [activeMatchCaseObjectsArray objectAtIndex:indexPath.row];
    
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

}
}

-(void)HandleCustomAnswerChange:(NSIndexPath *) indexPath UITableViewCell:(UITableViewCell *)cell
{
    
    NSString *indexPathString = [NSString stringWithFormat:@"%ld",(long)indexPath.row+1];
     UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
    if(cell.backgroundColor == colorForButtons)
    {
        int i = 0;
        int indexToRemove = -1;
        for (NSString *eachAns in selectedCaseItemAnswersArray)
        {
            int ansInt = (int)[eachAns integerValue];
            
            //making sure to compare to a number +1 since the answersArray has a 1 higher index
            if(ansInt==indexPath.row+1)
            {
                indexToRemove = i;
                
                
            }
            i = i+1;
        }
        if(indexToRemove>-1)
        {
            [selectedCaseItemAnswersArray removeObjectAtIndex:indexToRemove];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexToRemove];
            
            //update the answers on the caseItem itself
            PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
            [selectedCaseItem setObject:selectedCaseItemAnswersArrayOfDictionaries forKey:@"answers"];
            cell.backgroundColor = [UIColor clearColor];
        }
        
    }
    else
    {
        NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
        [selectedCaseItemAnswersArray addObject:newAns];
        cell.backgroundColor = colorForButtons;
        
        NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
        [AnsObj setValue:newAns forKey:@"a"];
        NSDictionary *myAnsDict = [AnsObj copy];
        
        [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        
        //update the answers on the caseItem itself
        PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
        [selectedCaseItem setObject:selectedCaseItemAnswersArrayOfDictionaries forKey:@"answers"];
        
    }
}

-(void)HandleAnswer1:(NSIndexPath *) indexPath UITableViewCell:(UITableViewCell *)cell
{
    
    //01 Answer Updates,
    //Answer can have no custom values, must have either 0 answers or 1 answer
    if(cell.backgroundColor==colorForButtons)
    {
        
        //show an alert explaining this property must have at least one answer
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Remove Answer" message:@"This Case Item Requires At Least One Answer, Select Another To Change" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];

        
    }
    else
        //add the answer to the answers array and answersDictionary.
    {
        if([selectedCaseItemAnswersArray count]>=1)
        {
            [selectedCaseItemAnswersArray removeAllObjects];
            [selectedCaseItemAnswersArrayOfDictionaries removeAllObjects];
            
            //clear all the previous green colored cells
            for (UIView *view in self.propertiesTableView.subviews){
                for (id subview in view.subviews){
                    if ([subview isKindOfClass:[UITableViewCell class]]){
                        UITableViewCell *cell = subview;
                        cell.backgroundColor = [UIColor clearColor];
                        
                    }
                }
            }

        }
        
        //check to see if the answer is an answer for one of the original properties on this caseItem or a new custom property
        if(indexPath.row +1 <=[selectedCaseItemOriginalOptions count])
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"a"];
            NSDictionary *myAnsDict = [AnsObj copy];
            
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        else
        {
            UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
            NSString *newAns = optionLabel.text;
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"custom"];
            NSDictionary *myAnsDict = [AnsObj copy];
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        
    }
    
}


-(void)HandleAnswer01:(NSIndexPath *) indexPath UITableViewCell:(UITableViewCell *)cell
{
    
    //01 Answer Updates,
    //Answer can have no custom values, must have either 0 answers or 1 answer
    if(cell.backgroundColor==colorForButtons)
    {
        //remove this answer from the list.
        int i = 0;
        int indexToRemove = -1;
        
        //check to see if the answersArray includes the string label
        UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
        NSString *optionTxt = optionLabel.text;
        if ([selectedCaseItemAnswersArray containsObject:optionTxt])
        {
            NSInteger indexOfObject = [selectedCaseItemAnswersArray indexOfObject:optionTxt];
            [selectedCaseItemAnswersArray removeObject:optionTxt];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexOfObject];
        }
        
        for (NSString *eachAns in selectedCaseItemAnswersArray)
        {
            int ansInt = (int)[eachAns integerValue];
            
            //making sure to compare to a number +1 since the answersArray has a 1 higher index
            if(ansInt==indexPath.row+1)
            {
                indexToRemove = i;
                cell.backgroundColor = [UIColor clearColor];
                
            }
            i = i+1;
        }
        if(indexToRemove>-1)
        {
            [selectedCaseItemAnswersArray removeObjectAtIndex:indexToRemove];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexToRemove];
        }
        
    }
    else
        //add the answer to the answers array and answersDictionary.
    {
        
        [selectedCaseItemAnswersArray removeAllObjects];
        [selectedCaseItemAnswersArrayOfDictionaries removeAllObjects];
        
        //clear all the previous green colored cells
        for (UIView *view in self.propertiesTableView.subviews){
            for (id subview in view.subviews){
                if ([subview isKindOfClass:[UITableViewCell class]]){
                    UITableViewCell *cell = subview;
                    cell.backgroundColor = [UIColor clearColor];
                    
                }
            }
        }
        //check to see if the answer is an answer for one of the original properties on this caseItem or a new custom property
        if(indexPath.row +1 <=[selectedCaseItemOriginalOptions count])
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"a"];
            NSDictionary *myAnsDict = [AnsObj copy];
            
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        else
        {
            UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
            NSString *newAns = optionLabel.text;
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"custom"];
            NSDictionary *myAnsDict = [AnsObj copy];
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        
    }
    
    
}


-(void)HandleAnswer0NPlus:(NSIndexPath *) indexPath UITableViewCell:(UITableViewCell *)cell
{
   
    //0NPLUS Answer Updates,
    //Answer can have custom values, multiple values or 0 values
    if(cell.backgroundColor==colorForButtons)
    {
        //remove this answer from the list.
        int i = 0;
        int indexToRemove = -1;
        
        //check to see if the answersArray includes the string label
        UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
        NSString *optionTxt = optionLabel.text;
        if ([selectedCaseItemAnswersArray containsObject:optionTxt])
        {
            NSInteger indexOfObject = [selectedCaseItemAnswersArray indexOfObject:optionTxt];
            [selectedCaseItemAnswersArray removeObject:optionTxt];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexOfObject];
        }
        
        for (NSString *eachAns in selectedCaseItemAnswersArray)
        {
            int ansInt = (int)[eachAns integerValue];
            
            //making sure to compare to a number +1 since the answersArray has a 1 higher index
            if(ansInt==indexPath.row+1)
            {
                indexToRemove = i;
                cell.backgroundColor = [UIColor clearColor];
                
            }
            i = i+1;
        }
        if(indexToRemove>-1)
        {
            [selectedCaseItemAnswersArray removeObjectAtIndex:indexToRemove];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexToRemove];
        }
        
    }
    else
        //add the answer to the answers array and answersDictionary.
    {
        
        //check to see if the answer is an answer for one of the original properties on this caseItem or a new custom property
        if(indexPath.row +1 <=[selectedCaseItemOriginalOptions count])
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"a"];
            NSDictionary *myAnsDict = [AnsObj copy];
            
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        else
        {
            UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
            NSString *newAns = optionLabel.text;
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"custom"];
            NSDictionary *myAnsDict = [AnsObj copy];
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        
    }

}

-(void)HandleAnswer1NPlus:(NSIndexPath *) indexPath UITableViewCell:(UITableViewCell *)cell
{
    
    //0NPLUS Answer Updates,
    //Answer can have custom values, multiple values or 0 values
    if(cell.backgroundColor==colorForButtons)
    {
        //check to see if there is only one answer in selectedCaseItemAnswersArray, if so do not remove
        if([selectedCaseItemAnswersArray count] <=1)
        {
            //show an alert explaining this property must have at least one answer
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Remove Answer" message:@"This Case Item Requires At Least One Answer" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
        }
        
        //remove this answer from the list.
        int i = 0;
        int indexToRemove = -1;
        
        //check to see if the answersArray includes the string label
        UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
        NSString *optionTxt = optionLabel.text;
        if ([selectedCaseItemAnswersArray containsObject:optionTxt])
        {
            NSInteger indexOfObject = [selectedCaseItemAnswersArray indexOfObject:optionTxt];
            [selectedCaseItemAnswersArray removeObject:optionTxt];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexOfObject];
        }
        
        for (NSString *eachAns in selectedCaseItemAnswersArray)
        {
            int ansInt = (int)[eachAns integerValue];
            
            //making sure to compare to a number +1 since the answersArray has a 1 higher index
            if(ansInt==indexPath.row+1)
            {
                indexToRemove = i;
                cell.backgroundColor = [UIColor clearColor];
                
            }
            i = i+1;
        }
        if(indexToRemove>-1)
        {
            [selectedCaseItemAnswersArray removeObjectAtIndex:indexToRemove];
            [selectedCaseItemAnswersArrayOfDictionaries removeObjectAtIndex:indexToRemove];
        }
        
    }
    else
        //add the answer to the answers array and answersDictionary.
    {
        
        //check to see if the answer is an answer for one of the original properties on this caseItem or a new custom property
        if(indexPath.row +1 <=[selectedCaseItemOriginalOptions count])
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"a"];
            NSDictionary *myAnsDict = [AnsObj copy];
            
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        else
        {
            UILabel *optionLabel = (UILabel *)[cell viewWithTag:44];
            NSString *newAns = optionLabel.text;
            [selectedCaseItemAnswersArray addObject:newAns];
            cell.backgroundColor = colorForButtons;
            
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:newAns forKey:@"custom"];
            NSDictionary *myAnsDict = [AnsObj copy];
            [selectedCaseItemAnswersArrayOfDictionaries addObject:myAnsDict];
        }
        
    }
    
}



#pragma mark DataDelegateMethods
- (void)recieveData:(NSString *)OptionsList AcceptableAnswersList:(NSMutableArray *)Answers QuestionText:(NSString *) question {
    
    carouselCaseUpdateTicker = carouselCaseUpdateTicker  +1;
    int newCaseNumber = 9000 +carouselCaseUpdateTicker ;
    
    NSString *newPropNum = [NSString stringWithFormat:@"%d",carouselCaseUpdateTicker ];
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
    //[self.caseDetailsTableView reloadData];
    
    //Do something with data here
    NSLog(@"this fired");
    self.submitAnswersButton.enabled = 1;
     UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
    self.submitAnswersButton.backgroundColor = submitAnswersColor;
    
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
        
        [self.carousel reloadData];
        [self.carousel scrollToItemAtIndex:self.carousel.numberOfItems-2 duration:0.0f];
        
        [self.propertiesTableView reloadData];
        self.propertiesTableView.alpha = 1;
        
    }
    
}

-(void)updateNewCaseItem:(NSDictionary *)propertyObject CaseItemObject:(NSDictionary *)caseItemObject
{
    NSString *xmlForUpdate;

   xmlForUpdate = [self createXMLFunctionSingleCaseItem:propertyObject CaseItemObject:caseItemObject];
    
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
                                        NSLog(responseText);
                                        
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
                                        //update here may 26 to dismiss
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    //free up memory by releasing subviews
    self.carousel = nil;
    self.carousel.delegate = nil;
    self.carousel.dataSource = nil;
    sortedCaseItems = nil;
    propertyTableOptionsArray = nil;
    self.propertiesTableView = nil;
    self.propertiesTableView.delegate = nil;
    self.propertiesTableView.dataSource = nil;
}

- (void) viewWillDisappear:(BOOL)animated
{
    //self.carousel = nil;
    [self.carousel scrollToItemAtIndex:0 animated:0];
    //self.carousel = nil;
    //self.carousel.delegate = nil;
    //self.carousel.dataSource = nil;
    
}

- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    self.carousel.currentItemIndex = 0;
    self.carousel = nil;
    self.carousel.delegate = nil;
    self.carousel.dataSource = nil;
    sortedCaseItems = nil;
     propsArray = nil;
    propertyTableOptionsArray = nil;
    self.propertiesTableView = nil;
    self.propertiesTableView.delegate = nil;
    self.propertiesTableView.dataSource = nil;
    
    LoadedBOOL = NO;
}

- (void)reloadData:(PFObject *) myObject reloadMode:(NSString *)reloadModeString
{
    //code for old refresh/poll mode where the entire itsMTLobject is returned on the refresh
    NSArray *casesArray;
    int indexOfCase = 0;
    PFObject *caseItemObject;
    
    NSString *selectedPropNumAtUpdateTime;
    if([reloadModeString isEqualToString:@"fromMatchSwipe"])
    {
       //reload the data normally but scroll right after to the carousel index with the matches
        
        //assumes we are not in template mode since they have a match
        
        //set propertyNum with current carousel index
        PFObject *CaseObj = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
        propertyBeingUpdated = [CaseObj objectForKey:@"propertyNum"];
    
     
    }
   
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
                NSString *caseBeingUpdatedString = [caseObjectBeingUpdated objectForKey:@"caseId"];
                
                if([caseBeingUpdatedString isEqualToString:caseString])
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
    caseObjectBeingUpdated = (PFObject *)caseItemObject;
    
    if(templateMode==1)
        
    {
        //get the new caseID
        NSString *caseString = [caseItemObject objectForKey:@"caseId"];
        
        //if the caseProfile has info, then save it.  otherwise skip this step.
        
        if([self.externalCaseName length] >0)
            {
                //create the case profile
                [self submitCaseProfileInfo:caseString];
            }
        
    }
   
    templateMode =0;
    self.carousel.animateSwipeUp = YES;

    //define sort descriptors for sorting caseItems by priority
    NSArray *sortDescriptors;
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    caseItems= [caseItemObject objectForKey:@"caseItems"];
    sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    sortedCaseItems = [self filterOutLocationProperty:sortedCaseItems];
    //loop through sortedCaseItems and remove the pinDrop Property
    
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
    //[propertyTableOptionsArray removeAllObjects];
    //[selectedCaseItemAnswersArray removeAllObjects];
    //[selectedCaseItemAnswersArrayOfDictionaries removeAllObjects];
    //[selectedCaseItemOriginalOptions removeAllObjects];
    
    //get all the property ID's from each item in the selected case.
    
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *propNum = [eachCaseItem objectForKey:@"propertyNum"];
        [propertyIDSArray addObject:propNum];
    }
    
    //get all the property information for the list of properties to consider
    PFQuery *propertsQuery = [PFQuery queryWithClassName:@"Properts"];
    [propertsQuery whereKey:@"objectId" containedIn:propertyIDSArray];
    //loop through properties
    //check designation == "the match"
    //play popup
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
    
    //loop through the sortedCaseItems to get the new index after reload for where the user just left off.
    int loop =0;
    int indexForCarouselReload = 0;
    
    for(PFObject *caseItemObject in sortedCaseItems)
    {
        NSString *propNum = [caseItemObject objectForKey:@"propertyNum"];
        if([propNum isEqualToString:propertyBeingUpdated])
            {
                indexForCarouselReload = loop;
            }
        
        loop = loop+1;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        PFObject *propertyObject = [propsArray objectAtIndex:indexForCarouselReload];
        
        //get choices
        NSString *propOptions = [propertyObject objectForKey:@"options"];
        propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
        
        [self.carousel scrollToItemAtIndex:indexForCarouselReload duration:0.0f];
        [self.carousel reloadData];
        [self.propertiesTableView reloadData];
        
        //remove the updating HUD
        [HUD hide:YES];
    });
    
    
    //set the last timestamp for the case if there needs to be polling.
    NSString *timeStampReturn = [caseItemObject objectForKey:@"timestamp"];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    lastTimestamp = [f numberFromString:timeStampReturn];
    
    
    //change to only dismiss if this is triggered from the update
    //may26
    if([reloadModeString isEqualToString:@"fromSingleNewProperty"])
    {
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    
     [self.submitAnswersButton setTitle:@"Update Answers" forState:UIControlStateNormal];
    
    //check to see if we should fire bubble burst
    //only fire a bubble burst if there is at least one new flag
    BOOL fireBubbleBurst = NO;
    for(PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *stringVal = [eachCaseItem objectForKey:@"new"];
        
        if([stringVal isEqualToString:@"X"])
        {
            //found one
            fireBubbleBurst = YES;
        }
    }
    if(fireBubbleBurst ==YES)
    {
        [self sendBubbleBurst:caseObjectBeingUpdated];
        
    }
    
     if([reloadModeString isEqualToString:@"fromMatchSwipe"])
     {
         [self.matchesTableView reloadData];
         
     }

}

//changed this function to work for updating single case items when not in template mode
//two modes of calling this function.  In one, propertyObject and caseItemObjForXML are set to nil.  This is for updating existing items.
//2nd Mode these values are passed, this is for updating brand new case items
-(NSString *)createXMLFunctionSingleCaseItem:(NSDictionary *) propertyObject CaseItemObject:(NSDictionary *)caseItemObjForXML
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    PFObject *caseObject = caseObjectBeingUpdated;
    
    PFObject *caseItemObject;
    
    if(caseItemObjForXML ==nil)
    {
          caseItemObject = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
    }
    else
    {
        caseItemObject = (PFObject *)caseItemObjForXML;
    }
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    
    if([self.externalCaseName length] >0)
    {
       caseName = self.externalCaseName;
        
    }

    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
    PFObject *selectedPropertyObject;
    
    if(propertyObject ==nil)
    {
       selectedPropertyObject = [propsArray objectAtIndex:selectedCarouselIndex];
    }
    else
    {
        selectedPropertyObject = (PFObject *)propertyObject;
    }
    
    NSString *propertyNum = [caseItemObject objectForKey:@"propertyNum"];
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
    
    if(propertyObject ==nil)
    {
        //don't write property information
    }
    else
    {
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
    }
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

-(NSString *)createXMLCaseUpdate;
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    //**update**June 1, now only updating for items in NSMutableArray *changedCaseItemsIndex;
    
    PFObject *caseObject = caseObjectBeingUpdated;
    
    PFObject *caseItemObject;
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    if([self.externalCaseName length] >0)
    {
        caseName = self.externalCaseName;
        
    }
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
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
    
    NSInteger h = 0;
    //**update**June 1, only focusing on items in changedCaseItemsIndex
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        
        NSNumber *caseUpdatingIndex = [NSNumber numberWithInteger:h];
        
         h = h+1;
    if([changedCaseItemsIndex containsObject:caseUpdatingIndex])
{
    
        NSString *caseItemPickedPropertyNum = [eachCaseItem objectForKey:@"propertyNum"];
        PFObject *propAtIndex;
        
            for(PFObject *propObject in propsArray)
            {
                if([propObject.objectId isEqualToString:caseItemPickedPropertyNum])
                {
                    propAtIndex = propObject;
                    break;
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
       
        propNumString = propertyNum;
    
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
    }

    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
}


-(IBAction)doUpdate:(id)sender
{
    NSString *xmlForUpdate;
    if(templateMode ==YES)
    {
        xmlForUpdate = [self createXMLTemplateModeFunction];
    }
    else
    {
        
        //generate XML for updating a single caseItem
        //xmlForUpdate = [self createXMLFunctionSingleCaseItem:nil CaseItemObject:nil];
        xmlForUpdate = [self createXMLCaseUpdate];
    }
    
    if([xmlForUpdate isEqualToString:@"no"])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Update", nil) message:@"New Case Must Include At Least One Answered Question" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
    
    //store a local value of the property (or last property for template mode) being updated based on the current carousel index and sortedCaseItems
    
    PFObject *caseItemBeingUpdated = sortedCaseItems[selectedCarouselIndex];
    propertyBeingUpdated = [caseItemBeingUpdated objectForKey:@"propertyNum"];
    
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
    if([self.externalCaseName length] >0)
    {
        caseName = self.externalCaseName;
        
    }
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

//need to modify this function to show the acceptable answers list

- (void)updateCaseItem:(NSString *)caseItemID AcceptableAnswersList:(NSArray *)Answers ForNewAnswer:(BOOL) NewAns
{
    
    NSLog(@"got this");
    
    //update the data and modify the sortedCaseItems and propsArray to take on the new data coming back
    
    //loop through the caseItems and select the one with this caseItemID
    
    if([Answers count]==0)
    {
        self.submitAnswersButton.enabled = 1;
         UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
        self.submitAnswersButton.backgroundColor = submitAnswersColor;
      
        
        [self.propertiesTableView reloadData];
        return;
        
    }
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
    NSString *options;
    if([ansCustomVal length] >0)
    {
        //loop through the propsArray to get the matching property and add to it only if this answer hasn't already been added.
        for (PFObject *propObject in propsArray)
        {
            if([propObject.objectId isEqualToString:propNum])
            {
               options = [propObject objectForKey:@"options"];
                
                //loop through op
                
                options = [[options stringByAppendingString:@";"] stringByAppendingString:ansCustomVal];
                [propObject setObject:options forKey:@"options"];
                
            }
        }
        
        
    }
    self.submitAnswersButton.enabled = 1;
     UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
    self.submitAnswersButton.backgroundColor = submitAnswersColor;
    
    if(NewAns ==TRUE)
    {
        NSString *propOptions = options;
        propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
        
        //add answer array to selectedCaseItem
        [selectedCaseItem setObject:Answers forKey:@"answers"];
        
    }
  
    [self.propertiesTableView reloadData];
    
}



-(void)updateAnswersCarousel:(NSInteger)caseIndex
{
    /*
    //should comment out this part
    [popupanswersDictionary removeAllObjects];
        
    NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
    [AnsObj setValue:self.customAnswerTextField.text forKey:@"custom"];
    [popupanswersDictionary addObject:AnsObj];
 
    
    PFObject *selectedCaseObject;
    
    NSArray *cases = [self.itsMTLObject objectForKey:@"cases"];
    selectedCaseObject = [cases objectAtIndex:[selectedCaseIndex integerValue]];
    
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:caseIndex];
    NSString *caseIDBeingUpdated;
    
    if(templateMode ==1)
    {
        //update the data for sortedCaseItems and propsArray to prepare for updating on the CaseDetailsEmailViewController
        
        caseIDBeingUpdated = [selectedCaseItemObject objectForKey:@"caseItem"];
        
        [self updateCaseItem:caseIDBeingUpdated AcceptableAnswersList:popupanswersDictionary];
        return;
    }
    
    NSString *generatedXMLString;
    if([self.popupjsonDisplayMode isEqualToString:@"singleCase"])
    {
        generatedXMLString = [self createXMLFunctionSingleJSONCase];
    }
    else
    {
        generatedXMLString = [self createXMLFunction];
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
                       withParameters:@{@"payload": generatedXMLString}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                    if (!error)
                                    {
                                        
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                        [HUD hide:NO];
                                        
                                        caseIDBeingUpdated = [selectedCaseObject objectForKey:@"caseId"];
                                        
                                        NSString *timeStampReturn = [selectedCaseObject  objectForKey:@"timestamp"];
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
                                        
                                        [self.UCIdelegate reloadData:jsonCaseChange reloadMode:@"json"];
                                        
                                        //[self pollForCaseRefresh];
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                    }
                                }];
     */
}


-(IBAction)showLocationPicker:(id)sender
{
    mapPinViewController *mpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mpvc"];
    mpvc.delegate = self;
    
    if(fabsf(manualLocationLatitude) >0)
    {
        NSLog(@"show location picker");
        NSNumber *priorLatitudeNum = [NSNumber numberWithFloat:manualLocationLatitude];
        
        mpvc.priorLatitude = priorLatitudeNum;
        NSNumber *priorLongitudeNum = [NSNumber numberWithFloat:manualLocationLongitude];
        
        mpvc.priorLongitude = priorLongitudeNum;
        mpvc.myRegion = self.setRegion;
        
        NSLog(@"%@",mpvc.priorLatitude);
        NSLog(@"%@",mpvc.priorLongitude);
       
    }
    [self.navigationController pushViewController:mpvc animated:YES];
    
}

- (void)setUserLocation:(float) latitude withLongitude:(float)longitude andRegion:(MKCoordinateRegion)region
{
    //set manual location variables which will take priority over automatic variables when present
    manualLocationLatitude = latitude;
    
    manualLocationLongitude = longitude;
    self.setRegion = region;
    
    useManualLocation = YES;
    
    if(templateMode)
    {
        //save this data for later when the user submits the case
         [self.navigationController popViewControllerAnimated:NO];
    }
    else
    {
        //submit the manual location override right away when receiving this delegate function
        [self submitLocationXMLUpdate];
    }
    
    
    //when there is a manual location latitude/longitude set, this will insert on each XML update the insertion of the location property
    //format below
    /*
    <ITEM>
    <CASEITEM>848</CASEITEM>
    <PROPERTYNUM>7M7BcXdi3G</PROPERTYNUM>
    <ANSWER>
    <CUSTOM>33.242211; -122.11232</CUSTOM>
    </ANSWER>
    </ITEM>
     */
    
}

-(void)submitLocationXMLUpdate
{
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    
    NSArray *allCases = [self.itsMTLObject objectForKey:@"cases"];
    
    
    PFObject *caseObject = [allCases objectAtIndex:selectedCaseInt];
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    if([self.externalCaseName length] >0)
    {
        caseName = self.externalCaseName;
        
    }
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
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
    
    [xmlWriter writeStartElement:@"ITEM"];
    
    [xmlWriter writeStartElement:@"CASEITEM"];
    if([manualLocationCaseItemID length]>0)
    {
      [xmlWriter writeCharacters:manualLocationCaseItemID];
    }
    else
    {
      [xmlWriter writeCharacters:@"900"];
    }
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"PROPERTYNUM"];
    [xmlWriter writeCharacters:manualLocationPropertyNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"ANSWER"];
    
    [xmlWriter writeStartElement:@"CUSTOM"];
    NSString *latitudeString = [NSString stringWithFormat:@"%f",manualLocationLatitude];
    NSString *longitudeString = [NSString stringWithFormat:@"%f",manualLocationLongitude];
    
    NSString *locationForUpdate = [[latitudeString stringByAppendingString:@"; "] stringByAppendingString:longitudeString];
    
    [xmlWriter writeCharacters:locationForUpdate];
    
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    //close item element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
   //send this via submit XML
    
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xml}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
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
                                        
                                        //pop the mapViewController
                                        [self.navigationController popViewControllerAnimated:NO];
                                        
                                        
                                    }
                                    else
                                    {
                                        NSString *errorString = error.localizedDescription;
                                        NSLog(errorString);
                                        
                                        //pop the mapViewController
                                        [self.navigationController popViewControllerAnimated:NO];
                                    }
                                }];

    

}

- (void)addNewAnswerView:(id)sender
{
    UIButton *sendingButton = (UIButton *)sender;
    UIView *NewAnswerView = sendingButton.superview;
    
    for (UIView *theView in NewAnswerView.subviews)
    {
        if(theView.tag ==88)
        {
            UITextField *newAnsTextField = (UITextField *) theView;
            //add the answer from this text field.
            
            if([newAnsTextField.text length] >0)
            {
                NSString *newAnsString = newAnsTextField.text;
                
                //add the new answer to the local storage of answers for the carousel's selected CaseItem
                
                PFObject *propObject = [propsArray objectAtIndex:selectedCarouselIndex];
                NSString *propString = [propObject objectForKey:@"propertyType"];
                NSString *options = [propObject objectForKey:@"options"];
                
                //check to see if we are in template mode

                if(templateMode ==YES)
                {
                   
                    
                    if([propString isEqualToString:@"U"])
                    {
                        //can add unlimited custom answers
                        //custom answers should be added to both the property in text form and the answers array in numeric form
                        
                    //may12
                    NSString *updatedPropertyOptions = [[options stringByAppendingString:@";" ]stringByAppendingString:newAnsString];
                    
                    [propObject setObject:updatedPropertyOptions forKey:@"options"];
                    
                    //get count of options
                        NSArray *optionsArray = [[updatedPropertyOptions componentsSeparatedByString:@";"] mutableCopy];
                        int optionCount = [optionsArray count];
                        
                    //add index of answer as option count
                        NSString *optionCountString = [NSString stringWithFormat:@"%d",optionCount];
                        
                        [selectedCaseItemAnswersArray addObject:optionCountString];
                        NSMutableDictionary *newAnsCustom =[[NSMutableDictionary alloc] init];
                        [newAnsCustom setObject:optionCountString forKey:@"a"];
                        [selectedCaseItemAnswersArrayOfDictionaries addObject:newAnsCustom];
                        
                        propertyTableOptionsArray = [optionsArray mutableCopy];
                        
                        
                    }
                    
                    //template mode logic for adding custom answers to non user created answers:
                    //only allow adding 1 answer, add it with custom flag
                    //add the option to the property options for display purposes but do NOT update the property when updating the template, just update the answer with custom flag
                    //add the property index to an index of customAnsweredCaseItems so the tableview knows not to display another "add your answer" field
                    else
                    {
                        NSString *updatedPropertyOptions = [[options stringByAppendingString:@";" ]stringByAppendingString:newAnsString];
                         NSArray *optionsArray = [[updatedPropertyOptions componentsSeparatedByString:@";"] mutableCopy];
                        [propObject setObject:updatedPropertyOptions forKey:@"options"];
                        
                        [selectedCaseItemAnswersArray addObject:newAnsString];
                        NSMutableDictionary *newAnsCustom = [[NSMutableDictionary alloc] init];
                        [newAnsCustom setObject:newAnsString forKey:@"custom"];
                        [selectedCaseItemAnswersArrayOfDictionaries addObject:newAnsCustom];
                        
                         propertyTableOptionsArray = [optionsArray mutableCopy];
                        NSNumber *customAnswerIndex = [NSNumber numberWithInteger:selectedCarouselIndex];
                        
                        [customAnsweredCaseItems addObject:customAnswerIndex];
                        
                    }
                }
                else
                //update this with XML right away since out of template mode
                {
                 
                    //update caseItem with custom tagged answer
                    [selectedCaseItemAnswersArray addObject:newAnsString];
                    NSMutableDictionary *newAnsCustom = [[NSMutableDictionary alloc] init];
                    [newAnsCustom setObject:newAnsString forKey:@"custom"];
                    [selectedCaseItemAnswersArrayOfDictionaries addObject:newAnsCustom];
                    
                    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
                    [selectedCaseItemObject setObject:selectedCaseItemAnswersArrayOfDictionaries forKey:@"answers"];
                    
                    //update XML
                    NSDictionary *propObjectForUpdate = (NSDictionary *)propObject;
                    NSDictionary *selectedCaseObjectDict = (NSDictionary *)selectedCaseItemObject;
                    
                    NSString *xmlForUpdate = [self createXMLFunctionSingleCaseItem:nil CaseItemObject:selectedCaseObjectDict];
                    
                    //add code to do the actual update
                    
                    //add a progress HUD to show it is retrieving list of properts
                    HUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:HUD];
                    
                    // Set determinate mode
                    HUD.mode = MBProgressHUDModeDeterminate;
                    HUD.delegate = self;
                    HUD.labelText = @"Updating With The New Case Item";
                    [HUD show:YES];
                    //may13
                    //use parse cloud code function
                    [PFCloud callFunctionInBackground:@"submitXML"
                                       withParameters:@{@"payload": xmlForUpdate}
                                                block:^(NSString *responseString, NSError *error) {
                                                    
                        if (!error)
                        {
                                                        
                        NSString *responseText = responseString;
                        NSLog(responseText);
                                                        
                                                        
                        //convert to NSDictionaryHere
            
                        NSString *responseTextWithoutHeader = [responseText
                                                                                               stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                        NSError *jsonError;
                        NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
                                                        
                        NSMutableDictionary *jsonCaseChange = [json mutableCopy];
                        dispatch_async(dispatch_get_main_queue(), ^{
                        [self reloadData:jsonCaseChange reloadMode:@"singleAnswer"];
                                                        });
                                                        
                        }
                    else
                        {
                       NSLog(error.localizedDescription);
                       [HUD hide:YES];
                       }
                     }];

                }
                
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Empty Message"message:@"Must enter text for custom message" delegate:self
                                                         cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
                
            }
        }
        
    }
    [NewAnswerView removeFromSuperview];
    [bgDarkenView removeFromSuperview];
    
    [self.propertiesTableView reloadData];
    
    /*
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
    NSString *caseItemObjectID = [selectedCaseItemObject objectForKey:@"caseItem"];
    
    [self updateCaseItem:caseItemObjectID AcceptableAnswersList:selectedCaseItemAnswersArrayOfDictionaries ForNewAnswer:YES];
    */
}

- (void)deleteACaseItem:(PFObject *)itemObject atIndex:(NSInteger) index
{
    NSLog(@"delete starting");
    
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
    
   
    //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    
    
    //PFObject *caseObject = [allCases objectAtIndex:selectedCaseInt];
    NSString *caseObjectID = [caseObjectBeingUpdated objectForKey:@"caseId"];
    NSString *caseName = [caseObjectBeingUpdated objectForKey:@"caseName"];
    if([self.externalCaseName length] >0)
    {
        caseName = self.externalCaseName;
        
    }
    
    NSString *caseItem = [itemObject objectForKey:@"caseItem"];
    NSString *propertyNum = [itemObject objectForKey:@"propertyNum"];
   
    
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
   /*
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Deleting the CaseItem";
    [HUD show:YES];
    */
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
                                        
                                        //[self removeItemAtIndex:panindex animated:YES];
                                        [self processDeletion:jsonCaseChange WithIndex:index];
                                        
                                        //[self reloadData:jsonCaseChange reloadMode:@"fromJSON"];
                                        
                                        //remove deleteBGView
                                        [self popDeleteBGView];
                                        
                                        //[HUD hide:NO];
                                    }
                                    else
                                    {
                                        NSString *errorString = error.localizedDescription;
                                        NSLog(errorString);
                                      //  [HUD hide:NO];
                                        [self popDeleteBGView];
                                        
                                    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Cannot Be Deleted"message:@"This Case Item Cannot Be Deleted." delegate:self
                                                                             cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                        
                                    [alertView show];
                                        
                                    }
                                }];
    
}

-(void)processDeletion:(PFObject *)jsonChange WithIndex:(NSInteger) caseIndex
{
    //check to see if the returned JSON from the delete function has 1 less entry than current sortedCaseItems array
    NSArray *caseItems = [jsonChange objectForKey:@"caseItems"];
    
    //go ahead with removing the data
    NSLog(@"delete succeed");
    
    self.carousel.userInteractionEnabled = FALSE;
    
    //code for old refresh/poll mode where the entire itsMTLobject is returned on the refresh
    NSArray *casesArray;
    int indexOfCase = 0;
    
    PFObject *caseItemObject;
            caseItemObject = jsonChange;
    self.jsonDisplayMode = @"singleCase";
    self.jsonObject = (PFObject *)caseItemObject;
    caseObjectBeingUpdated = caseItemObject;
    templateMode =0;
    
    //define sort descriptors for sorting caseItems by priority
    NSArray *sortDescriptors;
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    caseItems= [caseItemObject objectForKey:@"caseItems"];
    sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    sortedCaseItems = [self filterOutLocationProperty:sortedCaseItems];
    //loop through sortedCaseItems and remove the pinDrop Property
    
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
    //[propertyTableOptionsArray removeAllObjects];
    //[selectedCaseItemAnswersArray removeAllObjects];
    //[selectedCaseItemAnswersArrayOfDictionaries removeAllObjects];
    //[selectedCaseItemOriginalOptions removeAllObjects];
    
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
        
        //decide the selected index of the carousel and load that data
        //for now just default to 0 selected index
        PFObject *propertyObject = [propsArray objectAtIndex:0];
        
        //get choices
        NSString *propOptions = [propertyObject objectForKey:@"options"];
        propertyTableOptionsArray = [[propOptions componentsSeparatedByString:@";"] mutableCopy];
        
        //[self.carousel removeItemAtIndex:caseIndex animated:NO];
       [self.carousel scrollToItemAtIndex:0 duration:0.0f];
        [self.carousel reloadData];
        [self.propertiesTableView reloadData];
    
        self.carousel.userInteractionEnabled = TRUE;
    
        //remove the updating HUD
         [HUD hide:YES];
    });
    
    //set the last timestamp for the case if there needs to be polling.
    NSString *timeStampReturn = [caseItemObject objectForKey:@"timestamp"];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    lastTimestamp = [f numberFromString:timeStampReturn];
    
    
    if([self.popupVC.popupOrSlideout isEqualToString:@"slideout"])
    {
        //[self.slidingViewController resetTopViewAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
    [self.submitAnswersButton setTitle:@"Update Answers" forState:UIControlStateNormal];
    
    NSLog(@"deletion processed");
    
}

-(void)checkForSureMatch:(NSArray *)propObjectsArray
{
    //loop through the property objects and check their designation after sortedCaseItems and propsArray have been populated on reloading/loading functions
    
    //if designation is equal to "TheMatch" or "SureMatches" then check the sortedCaseItem at that index to see if it is flagged new.
    
    //if it is flagged new, show a new popup view the user can click to go straight to their match or close to continue editing their case.
    
    int indexIterator = 0;
    for(PFObject *propObject in propObjectsArray)
    {
        NSString *designation = [propObject objectForKey:@"designation"];
        BOOL sureMatchFound = FALSE;
        
        if([designation containsString:@"TheMatch"])
        {
            sureMatchFound =TRUE;
        }
        /*
        if([designation containsString:@"SureMatches"])
        {
            sureMatchFound =TRUE;
        }
        */
        if(sureMatchFound==TRUE)
        {
            //get the caseObject for this property and check if it is flagged NEW
            PFObject *caseItemObject = [sortedCaseItems objectAtIndex:indexIterator];
            NSString *stringVal = [caseItemObject objectForKey:@"new"];
            
            
                //found one
               
                //get the image from the caseProfileObject matching this
                
                //get the ID of the match
                
                //gather the full array of matches to display
                //loop through the itsMTLObject and gather all the user's matches
                activeMatchesArray = [[NSMutableArray alloc] init];
                activeMatchCaseObjectsArray = [[NSMutableArray alloc] init];
                activeMatchesCaseItemObjectsArray = [[NSMutableArray alloc] init];
                activeMatchesCaseTypesArray = [[NSMutableArray alloc] init];
                
                //selectedCaseItem defined above as caseItemObject based on index in sortedCaseItems
                
                //class level variable caseObjectBeingUpdated;
                
                
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
                            [activeMatchesArray addObject:caseMatchID];
                            NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                            [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                            
                            [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                            [activeMatchesCaseTypesArray addObject:@"rejected"];
                            
                        }
                        
                    }
                    
                    if([matchesYesArray count] >0)
                    {
                        for(NSString *caseMatchID in matchesYesArray)
                        {
                            
                            //if(![activeMatchesArray containsObject:caseMatchID])
                            // {
                            [activeMatchesArray addObject:caseMatchID];
                            [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                            NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                            [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                            [activeMatchesCaseTypesArray addObject:@"yes"];
                            //  }
                            
                        }
                        
                    }
                    
                    if([matchesArray count] >0)
                    {
                        for(NSString *caseMatchID in matchesArray)
                        {
                            // if(![activeMatchesArray containsObject:caseMatchID])
                            //{
                            [activeMatchesArray addObject:caseMatchID];
                            [activeMatchCaseObjectsArray addObject:caseObjectBeingUpdated];
                            NSString *caseItemObjectString = [caseItemObject objectForKey:@"caseItem"];
                            
                            [activeMatchesCaseItemObjectsArray addObject:caseItemObjectString];
                            [activeMatchesCaseTypesArray addObject:@"match"];
                            // }
                        }
                        
                    }
                
                
                //should be only one match, take the first index in "activeMatchesArray"
                NSString *theMatch = [activeMatchesArray objectAtIndex:0];
                
                //query for caseProfiles
                PFQuery *caseProfileQuery = [PFQuery queryWithClassName:@"CaseProfile"];
                [caseProfileQuery whereKey:@"caseID" equalTo:theMatch];
                NSArray *returnedCaseProfiles = [caseProfileQuery findObjects];
                activeMatchesCaseProfiles = [returnedCaseProfiles mutableCopy];
                
                //later if they choose to hit the button we create on the "YourSureMatch UIView, it should open up JSQMessagesViewController with data based on the  first index from these arrays.
                
                //show the sureMatch View
                
                UIView *sureMatchView = [[UIView alloc] initWithFrame:CGRectMake(20,70,self.view.frame.size.width-40,450)];
                sureMatchView.backgroundColor = [UIColor whiteColor];
                    CALayer *sureMatchLayer = sureMatchView.layer;
                    sureMatchLayer.cornerRadius = 8.0f;
                    
                    
                UILabel *sureMatchTitle = [[UILabel alloc] initWithFrame:CGRectMake(20,20,sureMatchView.frame.size.width-40,40)];
                sureMatchTitle.text = @"You Have A SURE Match!";
                sureMatchTitle.font = [UIFont fontWithName:@"Futura-Medium" size:30];
                sureMatchTitle.textAlignment = NSTextAlignmentCenter;
                
                [sureMatchView addSubview:sureMatchTitle];
                
                
                UILabel *sureMatchCaseNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,70,300,50)];
                sureMatchCaseNameLabel.font =[UIFont fontWithName:@"Futura-Medium" size:25];
                
                UIImageView *sureMatchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10,120,150,150)];
                
                //check to see if there is a caseProfile for this caseID
                
                NSString *caseimgURL;
            for (PFObject *caseProfileObj in activeMatchesCaseProfiles)
                {
                    NSString *caseProfileCaseID = [caseProfileObj objectForKey:@"caseID"];
                    if([theMatch isEqualToString:caseProfileCaseID])
                    {
                        //display case information
                        sureMatchCaseNameLabel.text = [caseProfileObj objectForKey:@"externalCaseName"];
                        PFFile *imgFile = [caseProfileObj objectForKey:@"caseImage"];
                        caseimgURL = imgFile.url;
                    }
                }
                UIActivityIndicatorViewStyle *activityStyle = UIActivityIndicatorViewStyleGray;
                
                if([caseimgURL length] ==0)
                {
                    NSString *defaultMatchImgFileName = [[NSBundle mainBundle] pathForResource:@"femalesilhouette" ofType:@"jpeg"];
                    sureMatchImageView.image = [UIImage imageWithContentsOfFile:defaultMatchImgFileName];
                    
                }
                else
                {
                    [sureMatchImageView setImageWithURL:[NSURL URLWithString:caseimgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
                }
                
                NSString *matchType = [activeMatchesCaseTypesArray objectAtIndex:0];
                if([matchType isEqualToString:@"yes"])
                {
                    sureMatchCaseNameLabel.textColor = [UIColor greenColor];
                    
                }
                else if([matchType isEqualToString:@"rejected"])
                {
                    sureMatchCaseNameLabel.textColor = [UIColor grayColor];
                    
                }
                
                [sureMatchView addSubview:sureMatchCaseNameLabel];
                [sureMatchView addSubview:sureMatchImageView];
                    
                //add two buttons for "Not Who I Wanted" and "Start a Conversation"
                UIButton *notWhoIWantedButton = [[UIButton alloc] initWithFrame:CGRectMake(10,300,sureMatchView.frame.size.width-20,50)];
                notWhoIWantedButton.backgroundColor = [UIColor redColor];
                notWhoIWantedButton.titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
                notWhoIWantedButton.titleLabel.textColor = [UIColor whiteColor];
                notWhoIWantedButton.titleLabel.text = @"Not Who I Wanted";
                    [notWhoIWantedButton setTitle:@"Not Who I Wanted" forState:UIControlStateNormal];
                    
                [notWhoIWantedButton addTarget:self action:@selector(notWhoIWantedButton:) forControlEvents:UIControlEventTouchUpInside];
                
                    UIButton *startConversationButton = [[UIButton alloc] initWithFrame:CGRectMake(10,360,sureMatchView.frame.size.width-20,50)];
                    
                     UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
                    startConversationButton.backgroundColor = submitAnswersColor;
                    
                    startConversationButton.titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
                    startConversationButton.titleLabel.textColor = [UIColor whiteColor];
                       startConversationButton.titleLabel.text = @"Start Conversation";
                    [startConversationButton setTitle:@"Start Conversation" forState:UIControlStateNormal];
                    
                    [startConversationButton addTarget:self action:@selector(startConversationButton:) forControlEvents:UIControlEventTouchUpInside];
                    [sureMatchView addSubview:notWhoIWantedButton];
                    [sureMatchView addSubview:startConversationButton];
                
                    bgDarkenView = [[UIView alloc] initWithFrame:self.view.bounds];
                    bgDarkenView.backgroundColor = [UIColor blackColor];
                    bgDarkenView.alpha = 0.7;
                    [self.view addSubview:bgDarkenView];
                    [self.view addSubview:sureMatchView];
                
                    
                    
            }

        }
        
        indexIterator = indexIterator +1;
        
        
    }
    

    
    
}

-(void)notWhoIWantedButton:(id)sender
{
    //close the sending view and send a swipe no to this match
    UIButton *notWhoIWantedBtn = (UIButton *)sender;
    UIView *btnHolderView = notWhoIWantedBtn.superview;
    
    //send swipe
    NSString *swipeNoXML = [self createSwipeXML:0 withMode:@"NO"];
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Removing the Match";
    [HUD show:YES];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": swipeNoXML}
                                block:^(NSString *responseString, NSError *error) {
                                    
                                    //remove the view
                                    [bgDarkenView removeFromSuperview];
                                    [btnHolderView removeFromSuperview];
                                    
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

-(void)startConversationButton:(id)sender
{
    //start a conversation with the match at index 0
    
    //create a conversation PFObject between the two usernames or look up the conversation object
    PFQuery *query = [PFQuery queryWithClassName:@"Conversations"];
    
    NSString *matchID = [activeMatchesArray objectAtIndex:0];
    NSMutableArray *twoMatches = [[NSMutableArray alloc] init];
    
    [twoMatches addObject:matchID];
    PFObject *caseObjAtIndex = [activeMatchCaseObjectsArray objectAtIndex:0];
    
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
    
    //remove the UIView sending this
    UIButton *sendingBtn = (UIButton *)sender;
    UIView *sendingBtnHolderView = sendingBtn.superview;
    [sendingBtnHolderView removeFromSuperview];
    
    [self.navigationController pushViewController:cJSQvc animated:YES];

}

-(NSString *)createSwipeXML:(NSInteger) index withMode:(NSString *)YesOrNo;
{
    //hardcoded XML for sending a swipe
    /*
     <PAYLOAD><USEROBJECTID>NoJW05Xwsq</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>77rmIIxX9z</CASEOBJECTID><CASENAME>I just saw you</CASENAME><BUBBLEBURST>22</BUBBLEBURST><ITEM><CASEITEM>18</CASEITEM><PROPERTYNUM>8ZKsAhHzak</PROPERTYNUM><SWIPE><YES>OKXDu5YEJF</YES></SWIPE></ITEM></PAYLOAD>
     */
    
    
    NSString *selectedMatch = [activeMatchesArray objectAtIndex:index];
    PFObject *caseObject = [activeMatchCaseObjectsArray objectAtIndex:index];
    NSString *caseItem = [activeMatchesCaseItemObjectsArray objectAtIndex:index];
    
    NSArray *caseObjectCaseItems = [caseObject objectForKey:@"caseItems"];
    NSString *propertyNum;
    NSString *caseName;
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    caseName = [caseObject objectForKey:@"caseName"];
    if([self.externalCaseName length] >0)
    {
       caseName = self.externalCaseName;
        
    }

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
    [xmlWriter writeCharacters:self.userName];
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


-(void)closeNewAnswerView:(id)sender
{
    UIView *closeButton = (UIView *)sender;
    UIView *newAnswerContainerView= closeButton.superview;
    [newAnswerContainerView removeFromSuperview];
    [bgDarkenView removeFromSuperview];
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
   // textField.text = @"";
    
    [self animateTextField:textField up:YES];
}




- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
    if(textField.tag ==77)
    {
        //set the question text.
        NSString *customText;
        customText = textField.text;
        //self.checkMark1.alpha = 1;
        
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
}

-(void)updateCustomAnswer:(NSString *)customAnsString
{
    //if template mode, just save it locally.
    //if not template mode, fire off the update in background
    
    //dismiss the text entry portion
    
    if(templateMode ==1)
    {
        PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
        NSMutableDictionary *AnsDict = [[NSMutableDictionary alloc] init];
        [AnsDict setObject:customAnsString forKey:@"custom"];
        NSMutableArray *newAnswersArray = [[NSMutableArray alloc] init];
        [newAnswersArray addObject:AnsDict];
        
        [selectedCaseItem setObject:newAnswersArray forKey:@"answers"];
        
    }
    else
    {
        //fire off XML for update
        PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:selectedCarouselIndex];
        NSMutableDictionary *AnsDict = [[NSMutableDictionary alloc] init];
        [AnsDict setObject:customAnsString forKey:@"custom"];
        NSMutableArray *answersArray = [[NSMutableArray alloc] init];
        [answersArray addObject:AnsDict];
        
        [selectedCaseItem setObject:answersArray forKey:@"answers"];
        
        [self doUpdate:self];
        
    }
    
}

-(IBAction)customAnswerSet:(id)sender
{
   
    
    //if template mode, just save it locally.
    //if not template mode, fire off the update in background
    [self.view endEditing:YES];
    if([self.customAnswerTextField.text length] >0)
    {
        NSNumber *changedCaseItemIndexNum = [NSNumber numberWithInteger:selectedCarouselIndex];
        
        if(![changedCaseItemsIndex containsObject:changedCaseItemIndexNum])
        {
            [changedCaseItemsIndex addObject:changedCaseItemIndexNum];
        }
        
        self.customAnswerCheckmark.alpha = 1;
        self.submitAnswersButton.enabled = TRUE;
         UIColor *submitAnswersColor = [UIColor colorWithRed:41/255.0f green:188/255.0f blue:243/255.0f alpha:1];
        self.submitAnswersButton.backgroundColor = submitAnswersColor;
      
        self.submitAnswersButton.titleLabel.textColor = [UIColor whiteColor];
        
        if(templateMode ==YES)
        {
              [self.submitAnswersButton setTitle:@"Create Case" forState:UIControlStateNormal];
        }
    }
    else
    {
        self.customAnswerCheckmark.alpha = 0;
        
        return;
    }
    
    [self updateCustomAnswer:self.customAnswerTextField.text];
    
    
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
    
    [self dismissKeyboard];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}

#pragma mark caseTitleSetDelegate Methods

-(void)dismissCaseTitleSetViewController:(NSString *)internalCaseName withExt:(NSString *)externalCaseName withImg:(UIImage *)caseImage
{
    self.internalCaseName = internalCaseName;
    self.externalCaseName = externalCaseName;
    self.caseImage = caseImage;
    
    if(templateMode==YES)
    {
        //no caseID, don't update yet until it's created
        
    }
    else
    {
        NSString *caseID = [caseObjectBeingUpdated objectForKey:@"caseId"];
        [self submitCaseProfileInfo:caseID];
        
    }
    
    [self.navigationController popViewControllerAnimated:NO];
}

-(void)pressingBack
{
    //[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
    
}


-(void)submitCaseProfileInfo:(NSString *)caseID;
{
    PFQuery *queryForCaseProfile = [PFQuery queryWithClassName:@"CaseProfile"];
    [queryForCaseProfile whereKey:@"caseID" equalTo:caseID];
    PFObject *caseProfileObject = [queryForCaseProfile getFirstObject];
    if(caseProfileObject ==nil)
    {
    caseProfileObject = [PFObject objectWithClassName:@"CaseProfile"];

    }
    
    [caseProfileObject setObject:caseID forKey:@"caseID"];
    
    [caseProfileObject setObject:self.internalCaseName forKey:@"internalCaseName"];
    [caseProfileObject setObject:self.externalCaseName forKey:@"externalCaseName"];
    
    //UIImage *imgForParse = self.caseImage;
    
    // Convert to JPEG with 50% quality
    
    if(self.caseImage !=nil)
    {
        NSData *data = UIImageJPEGRepresentation(self.caseImage, 0.8f);
        
        PFFile *imageFile = [PFFile fileWithName:@"caseImage.jpg" data:data];
        [caseProfileObject setObject:imageFile forKey:@"caseImage"];
    }
  
    [caseProfileObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error)
        {
            NSLog(@"ParseError: %@", error.localizedDescription);
        }
        NSLog(@"case profile information saved");
        
    }];
    
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
                                        
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                        [HUD hide:NO];
                                        
                                        NSString *responseTextWithoutHeader = [responseText
                                                                               stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                                        NSError *jsonError;
                                        NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                             options:NSJSONReadingMutableContainers
                                                                                               error:&jsonError];
                                        
                                        NSMutableDictionary *jsonCaseChange = [json mutableCopy];
                                        
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self reloadData:jsonCaseChange reloadMode:@"fromMatchSwipe"];
                                        });

                                    }
                                    else
                                    {
                                        NSString *errorString = error.localizedDescription;
                                        NSLog(errorString);
                                        [HUD hide:NO];
                                        
                                    }
                                }];
}

-(void)updateCaseProfile
{
    CaseTitleSetViewController *ctsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ctsvc"];
    ctsvc.delegate = self;
    
    if([self.externalCaseName length] ==0)
    {
        //set the external case name as the caseName from XML
        NSString *caseName = [caseObjectBeingUpdated objectForKey:@"caseName"];
        self.externalCaseName = caseName;
        
    }
    
    if([self.externalCaseName length] >0)
    {
        ctsvc.externalCaseName = self.externalCaseName;
    }
    if(self.caseImage !=nil)
    {
        ctsvc.caseImage = self.caseImage;
        
    }
    
    [self.navigationController pushViewController:ctsvc animated:YES];
    
}

-(IBAction)addCaseItem:(id)sender
{
    NSLog(@"create a new case");
    NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
    npvc.userName = self.userName;
    npvc.delegate = self;
    
    [self.navigationController pushViewController:npvc animated:YES];
}


- (void)carouselDidEndDragging:(iCarousel *)carousel willDecelerate:(BOOL)decelerate
{
    NSLog(@"carousel end dragging");
    if(decelerate ==TRUE)
    {
        NSLog(@"carousel will decelerate");
    }
    
    
}

-(void) carouselWillBeginDecelerating:(iCarousel *)carousel
{
    NSLog(@"carousel begin decelerating");
    //[self.carousel setUserInteractionEnabled:FALSE];
    
}
-(void) carouselWillBeginScrollingAnimation:(iCarousel *)carousel
{
    NSLog(@"carousel will begin scrolling animation");
    
    //[self.carousel setUserInteractionEnabled:FALSE];
}
-(void) carouselDidEndDecelerating:(iCarousel *)carousel
{
    //[self.carousel setUserInteractionEnabled:TRUE];
    NSLog(@"carousel will begin scrolling animation");
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
    NSLog(@"Carousel did end scrolling");
    [self.carousel setUserInteractionEnabled:TRUE];
    
}
- (void) carouselDidScroll:(iCarousel *)carousel
{
    //[self.carousel setUserInteractionEnabled:TRUE];
    
}

@end
