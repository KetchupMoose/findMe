//
//  CaseDetailsViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "CaseDetailsViewController.h"
#import <Parse/Parse.h>
#import "XMLWriter.h"
#import "NewPropertyViewController.h"
#import "UIView+Animation.h"


@interface CaseDetailsViewController ()

@end

@implementation CaseDetailsViewController
@synthesize caseListData;
@synthesize selectedCaseIndex;
@synthesize pickerView;
@synthesize userName;
@synthesize customAnswerTextField;


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

//location manager variables
CLLocationManager *locationManager;
CLGeocoder *geocoder;
CLPlacemark *placemark;

//used for calcaulting swipe gestures
CGPoint startLocation;

int panningEnabled = 1;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.customAnswerTextField.delegate = self;
    
    
    //location manager instance variable allocs
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    
    
    // Do any additional setup after loading the view.
    int selectedCaseInt = (int)[selectedCaseIndex integerValue];
    //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    PFObject *caseItemObject = [caseListData objectAtIndex:selectedCaseInt];
    
    NSString *caseObjectID = [caseItemObject objectForKey:@"caseId"];
    
    int length = (int)[caseObjectID length];
    
    if(length==0)
    {
        self.submitAnswersButton.titleLabel.text = @"Create Case";
        
    }
    //get the LAST (latest) QuestionItem to display that information.
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    caseItems= [caseItemObject objectForKey:@"caseItems"];
    
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
    
    
    PFObject *firstSuggestedCaseToShow;
    if (suggestedCases.count >0)
    {
        firstSuggestedCaseToShow = [suggestedCases objectAtIndex:0];
        
        NSNumber *firstSuggestionIndex = [suggestedCaseIndex objectAtIndex:0];
        suggestedCaseDisplayedIndex = [firstSuggestionIndex intValue];
        
        selectedItemForUpdate = [firstSuggestionIndex integerValue];
        
        //NSString *lastQPropertyNum = [firstSuggestedCaseToShow objectForKey:@"propertyNum"];
        selectedCaseItemAnswersList = [firstSuggestedCaseToShow objectForKey:@"answers"];
        
        answersArray = [[NSMutableArray alloc] init];
        
        [answersArray removeAllObjects];
        
        for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
        {
            NSString *ansNum = [eachAnsObj valueForKey:@"a"];
            
            if (ansNum==nil)
            {
                NSString *ans = [eachAnsObj valueForKey:@"custom"];
                [answersArray addObject:ans];
                
            }
            else
            {
               [answersArray addObject:ansNum];
            }
         
        }
        
        ansStaticArray = [answersArray mutableCopy];
        
        //show the property's information for options
        
        PFObject *propertsObject = [suggestedProperties objectAtIndex:0];
        
        NSString *questionString = [propertsObject objectForKey:@"propertyDescr"];
        NSString *suggestedQString = @"Suggested Question: ";
        
        self.suggestedQuestion.text = [suggestedQString stringByAppendingString:questionString];
        
        NSString *optionsString = [propertsObject objectForKey:@"options"];
        
        //need to convert options string to an array of objects with ; separators.
        
        optionsArray = [optionsString componentsSeparatedByString:@";"];
        
        self.questionLabel.text = questionString;
        
        [self.caseDetailsTableView reloadData];
    }
    else
    {
        //show no suggested question popup and don't populate the answers tableview
        self.checkPreviousAnswersButton.titleLabel.text = @"Showing Previous Answers";
        self.pickerView.alpha =1;
        self.suggestedQuestion.alpha = 0;
        self.caseDetailsTableView.alpha =0;
        
        //check to see if the first priority case in case items is an answered question.  If so, display the list of options.
        
        if ([answeredPropertiesIndex containsObject:[NSNumber numberWithInt:0]])
        {
            //display the list of options & answers for this case on the first index
            
            firstSuggestedCaseToShow = [sortedCaseItems objectAtIndex:0];
            
            //selectedItemForUpdate = [firstSuggestionIndex integerValue];
            
            //NSString *lastQPropertyNum = [firstSuggestedCaseToShow objectForKey:@"propertyNum"];
            selectedCaseItemAnswersList = [firstSuggestedCaseToShow objectForKey:@"answers"];
            
            answersArray = [[NSMutableArray alloc] init];
            
            [answersArray removeAllObjects];
            
            for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
            {
                NSString *ansNum = [eachAnsObj valueForKey:@"a"];
                if (ansNum==nil)
                {
                    NSString *ans = [eachAnsObj valueForKey:@"custom"];
                    [answersArray addObject:ans];
                }
                else
                {
                    [answersArray addObject:ansNum];
                }
            }
            
            ansStaticArray = [answersArray mutableCopy];
            
            //show the property's information for options
            
            PFObject *propertsObject = [propsArray objectAtIndex:0];
            
            NSString *optionsString = [propertsObject objectForKey:@"options"];
            
            //need to convert options string to an array of objects with ; separators.
            
            optionsArray = [optionsString componentsSeparatedByString:@";"];
                        
            self.caseDetailsTableView.alpha = 1;
            
            [self.caseDetailsTableView reloadData];

            
        }
        
    }

    self.caseDetailsTableView.dataSource = self;
    self.caseDetailsTableView.delegate = self;
    
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    //add gesture recognizer for the suggestedQuestionBox
   
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
  
    UISwipeGestureRecognizer * swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
    
     UISwipeGestureRecognizer * swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
    swipeLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    //[self.suggestedQuestion addGestureRecognizer:swipeLeft];
   // [self.suggestedQuestion addGestureRecognizer:swipeRight];
    [self.suggestedQuestion setUserInteractionEnabled:YES];

    [self.suggestedQuestion addGestureRecognizer:panRecognizer];
    
    //the submit answers button should be disabled until the user actually makes a change
    
    self.submitAnswersButton.enabled = 0;
    self.submitAnswersButton.backgroundColor = [UIColor lightGrayColor];
    
    
}
- (void)swipeLeft:(UISwipeGestureRecognizer *)swipeRecognizer
{
    if (swipeRecognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = [swipeRecognizer locationInView:self.view];
    }
    else if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [swipeRecognizer locationInView:self.view];
        
        CGFloat dx = stopLocation.x - startLocation.x;
        CGFloat dy = stopLocation.y - startLocation.y;
        CGFloat distance = sqrt(dx*dx + dy*dy );
        NSLog(@"Distance: %f", distance);
        CGRect newLabelFrame =  CGRectMake(self.suggestedQuestion.frame.origin.x-dx,self.suggestedQuestion.frame.origin.y,self.suggestedQuestion.frame.size.width,self.suggestedQuestion.frame.size.height);
        
        self.suggestedQuestion.frame = newLabelFrame;
    }
    
}

- (void)swipeRight:(UISwipeGestureRecognizer *)swipeRecognizer
{
    if (swipeRecognizer.state == UIGestureRecognizerStateBegan) {
        startLocation = [swipeRecognizer locationInView:self.view];
    }
    else if (swipeRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [swipeRecognizer locationInView:self.view];
        
        CGFloat dx = stopLocation.x - startLocation.x;
        CGFloat dy = stopLocation.y - startLocation.y;
        CGFloat distance = sqrt(dx*dx + dy*dy );
        NSLog(@"Distance: %f", distance);
        CGRect newLabelFrame =  CGRectMake(self.suggestedQuestion.frame.origin.x+dx,self.suggestedQuestion.frame.origin.y,self.suggestedQuestion.frame.size.width,self.suggestedQuestion.frame.size.height);
        
        self.suggestedQuestion.frame = newLabelFrame;
    }
    
}


- (void)panDetected:(UIPanGestureRecognizer *)panRecognizer
{
    if(panningEnabled==0)
    {
        NSLog(@"panning not enabled");
        
        return;
        
    }
    
    CGPoint translation = [panRecognizer translationInView:self.view];
    //CGPoint labelViewPosition = self.suggestedQuestion.center;
    
    CGPoint originalOrigin= self.suggestedQuestion.frame.origin;
     CGRect originalQuestionFrame = self.suggestedQuestion.frame;
    
    CGRect newLabelFrame =  CGRectMake(self.suggestedQuestion.frame.origin.x +translation.x,self.suggestedQuestion.frame.origin.y,self.suggestedQuestion.frame.size.width,self.suggestedQuestion.frame.size.height);
    
    self.suggestedQuestion.frame = newLabelFrame;
    
    [panRecognizer setTranslation:CGPointZero inView:self.view];
    
    //if the difference is less than 50 pixels from the original x position of the view, play an animation to "snap it back" to its original position.
    
    if(translation.x<=25)
    {
        [self.suggestedQuestion moveTo:originalOrigin duration:0.2 option:UIViewAnimationOptionCurveEaseInOut];
        
        
    }
    else
    {
        NSLog(@"Starting process of removing the suggestedQuestion Label");
        
        //setting this variable to 0 to restrict the panning from doing anything until the timer goes off to re-enable that UI
        panningEnabled = 0;
        
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.3
                                                 target:self
                                               selector:@selector(PanningEnabled:)
                                               userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
       
        
        //animate the questionLabel being removed
        [self.suggestedQuestion removeWithZoomOutAnimation:0.2 option:UIViewAnimationOptionCurveEaseInOut];
        
        //remove the suggestedCase from relevant arrays
        
        //brian jan 7 turning swipe case delete off for now
        //PFObject *caseToRemove = [suggestedCases objectAtIndex:0];
        [suggestedCases removeObjectAtIndex:0];
        [suggestedCaseIndex removeObjectAtIndex:0];
        
        [suggestedProperties removeObjectAtIndex:0];
     
        
        //remove this case from the overall arrays also
         //brian jan 7 turning swipe case delete off for now
        //[sortedCaseItems removeObjectAtIndex:indexInt];
        //[propsArray removeObjectAtIndex:indexInt];
        
        //remove the selected data for this suggestion from the tableView, make Tableview invisible
        self.caseDetailsTableView.alpha = 0;
        
        //reload the pickerview data to reflect this exiting the array
        [self.pickerView reloadAllComponents];
        
        
        //send to the backend to delete this suggestion from the case
        //only do this if the caseObjectID is not nil (it's not just a returned template)
        int selectedCaseInt = (int)[selectedCaseIndex integerValue];
        //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
        
        PFObject *caseObject = [caseListData objectAtIndex:selectedCaseInt];
        NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
        
        int length = (int)[caseObjectID length];
        
        if(length==0)
        {
            NSLog(@"caseObject Nil");
            //dont do any backend removal, just ensure it's removed from the information that will be sent to create the new case.
            
        }
        else
        {
          //brian jan 7 turning swipe case delete off for now
          // [self deleteACaseItem:caseToRemove];
        }
        
        //check to see if there is another object still in the suggestedCases
        //update the options in the tableview below to reflect the suggested cases information
        
        int suggestedCaseArrayCount = (int)[suggestedCases count];
        
        if(suggestedCaseArrayCount >0)
            
            {
            //create and animate in another suggestedQuestionLabel
            //change the color so it's clear it's new.
            self.suggestedQuestion = [[UILabel alloc] init];
                UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
            [self.suggestedQuestion setUserInteractionEnabled:YES];
            [self.suggestedQuestion addGestureRecognizer:panRecognizer];
                
            self.suggestedQuestion.backgroundColor = [UIColor whiteColor];
            self.suggestedQuestion.alpha = 0.8;
            self.suggestedQuestion.textAlignment = NSTextAlignmentCenter;
            self.suggestedQuestion.frame = originalQuestionFrame;
            self.suggestedQuestion.numberOfLines = 5;
            self.suggestedQuestion.lineBreakMode = NSLineBreakByWordWrapping;
                
            
            [self.view SlideFromLeft:self.suggestedQuestion duration:0.2 option:UIViewAnimationOptionCurveEaseInOut];
            
        //update options based on this new suggestedQuestion
            
            PFObject *newSuggestedCaseToShow = [suggestedCases objectAtIndex:0];
                
            //get the index in terms of overall cases;
            NSNumber *nextCaseIndex = [suggestedCaseIndex objectAtIndex:0];
            suggestedCaseDisplayedIndex = [nextCaseIndex intValue];
            
            selectedCaseItemAnswersList = [newSuggestedCaseToShow objectForKey:@"answers"];
            
            answersArray = [[NSMutableArray alloc] init];
            
            [answersArray removeAllObjects];
            
                for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
                {
                    NSString *ansNum = [eachAnsObj valueForKey:@"a"];
                    if (ansNum==nil)
                    {
                        NSString *ans = [eachAnsObj valueForKey:@"custom"];
                        [answersArray addObject:ans];
                    }
                    else
                    {
                        [answersArray addObject:ansNum];
                    }
                }

            
            ansStaticArray = [answersArray mutableCopy];
            
            //show the property's information for options
            
            PFObject *propertsObject = [suggestedProperties objectAtIndex:0];
            
            NSString *questionString = [propertsObject objectForKey:@"propertyDescr"];
            NSString *suggestedQString = @"Suggested Question: ";
            
            self.suggestedQuestion.text = [suggestedQString stringByAppendingString:questionString];
            
            NSString *optionsString = [propertsObject objectForKey:@"options"];
            
            //need to convert options string to an array of objects with ; separators.
            
            optionsArray = [optionsString componentsSeparatedByString:@";"];
            
            self.questionLabel.text = questionString;
            
            [self.caseDetailsTableView reloadData];
            
            }
        else
        {
            //no more suggestions to show
            NSLog(@"setting pickerview alpha to 1");
            self.pickerView.alpha = 1;
            suggestedCaseDisplayedIndex = -1;
            
            
            //show the answers/options for the first case item in the list
         
            [self.pickerView selectRow:0 inComponent:0 animated:YES];
            // The delegate method isn't called if the row is selected programmatically
            [self pickerView:self.pickerView didSelectRow:0 inComponent:0];
           
           //this code block not necessary, can just pick the first row of pickerview programatically
            /*
            PFObject *firstCaseItem = [sortedCaseItems objectAtIndex:0];
            
            selectedCaseItemAnswersList = [firstCaseItem objectForKey:@"answers"];
            
            answersArray = [[NSMutableArray alloc] init];
            
            [answersArray removeAllObjects];
            
            for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
            {
                NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
                
                [answersArray addObject:ansNum];
            }
            
            ansStaticArray = [answersArray mutableCopy];
            
            NSString *optionsString = [firstCaseItem objectForKey:@"options"];
            
            //need to convert options string to an array of objects with ; separators.
            
            optionsArray = [optionsString componentsSeparatedByString:@";"];
           
            if(answersArray.count >0)
            {
                self.caseDetailsTableView.alpha = 1;
                
                [self.caseDetailsTableView reloadData];
            }
        */
        }
     
        
    }
}

-(void)PanningEnabled:(id)sender
{
   panningEnabled = 1;
}

-(void)deleteCaseItemLocally
{
    
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
    
    PFObject *caseObject = [caseListData objectAtIndex:selectedCaseInt];
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
    [xmlWriter writeCharacters:userName];
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
    [PFCloud callFunctionInBackground:@"inboundZITSMTL"
                       withParameters:@{@"payload": xml}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                        [HUD hide:YES];
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                        
                                    }
                                }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int optsCount = (int)[optionsArray count];
    
    return optsCount +1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseDetailsCell" forIndexPath:indexPath];
    UITextField *textEnter = (UITextField *)[cell viewWithTag:99];
    textEnter.frame = cell.bounds;
    
    if(textEnter==nil)
    {
        NSLog(@"warning it's nil!!");
        
    }
    
    UILabel *OptionNameLabel = (UILabel *)[cell viewWithTag:3];
    
    //show a radio checkmark button to toggle on and off.
    
  if([optionsArray count]<=0)
  {
      return cell;
  }
    
    //check to see if the answer should be highlighted
    cell.backgroundColor = [UIColor clearColor];

    //change this logic to check if the index path is present in the answers array, then color it green color.
    NSString *rowNumber = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
    
    if([answersArray containsObject:rowNumber])
    {
        cell.backgroundColor = [UIColor greenColor];
        
    }
   
    NSInteger myIndexRow = indexPath.row;
    NSInteger optionsCount = [optionsArray count];
    
    //for the last cell, make it show text saying "Tap Here to Add"
    if(myIndexRow == optionsCount)
    {
        OptionNameLabel.text = @"";
        
        textEnter.delegate = self;
        
        textEnter.text = @"Tap Here To Add An Option";
        textEnter.alpha=1;
        
        newTextFieldIndex  = indexPath.row;
        
    }
    else
    {
        OptionNameLabel.text = [optionsArray objectAtIndex:indexPath.row];
        textEnter.alpha = 0;
        textEnter.text = @"";
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //for the last cell, show a keyboard to type a new option
    if(indexPath.row==optionsArray.count)
    {
        
    }
    
    UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.backgroundColor==[UIColor greenColor])
    {
      
        //remove this answer from the list.
        int i = 0;
        int indexToRemove = 0;
        for (NSNumber *eachAns in answersArray)
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
        
    }
    else
            
        {
            NSString *newAns = [[NSNumber numberWithInteger:indexPath.row+1] stringValue];
            [answersArray addObject:newAns];
            cell.backgroundColor = [UIColor greenColor];
            
        }
    
    //get the selectedCaseItem from the selected row of the pickerView OR get the index of the displayed suggested caseItem if there's currently a displayed suggestion
    
    NSInteger sortedCaseItemsIndexToDisplay;
    
    if(suggestedCaseDisplayedIndex>-1)
    {
        //there's a suggested case being displayed, show it now

        sortedCaseItemsIndexToDisplay = suggestedCaseDisplayedIndex;
    }
    else
    {
        sortedCaseItemsIndexToDisplay = [self.pickerView selectedRowInComponent:0];
        
    }
    
     PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:sortedCaseItemsIndexToDisplay];
 
        //set the answers for this case to an array of a-value NSDicts
        
        NSMutableArray *newAnsArray = [[NSMutableArray alloc] init];
        
        for(NSNumber *eachAns in answersArray)
        {
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:eachAns forKey:@"a"];
            [newAnsArray addObject:AnsObj];
            
        }
    
    [selectedCaseItem setObject:[newAnsArray copy] forKey:@"answers"];
    
    [self.pickerView reloadAllComponents];
    
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
   textField.text = @"";
    
    [self animateTextField:textField up:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
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
    
    if(textField.tag ==99)
    {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:newTextFieldIndex inSection:0];
        
        UIView *cell = [self.caseDetailsTableView cellForRowAtIndexPath:cellIndexPath];
        
        UILabel *label = (UILabel *)[cell viewWithTag:3];
        
        label.text = textField.text;
        
        //add field to options array
        NSMutableArray *curarray = [optionsArray mutableCopy];
        [curarray addObject:textField.text];
        optionsArray = [curarray copy];
        
        //add the field to the answersArray.  Add 1 to it.
        newTextFieldIndex=newTextFieldIndex+1;
        NSNumber *newAnsNumber = [[NSNumber alloc] initWithInteger:newTextFieldIndex];
        
        [answersArray addObject:newAnsNumber];
        
        
        
        
        //update the options in the property area and update the answers in the caseItem answers section for the internal arrays of data.
        PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:[self.pickerView selectedRowInComponent:0]];
        //change object to be an NSMutableArray with keyValues a
        //bugfixhere
        NSMutableArray *newAnsArray = [[NSMutableArray alloc] init];
        
        for(NSString *eachAns in answersArray)
        {
            NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
            [AnsObj setValue:eachAns forKey:@"a"];
            [newAnsArray addObject:AnsObj];
            
        }
        
       
        
        [selectedCaseItem setObject:[newAnsArray copy] forKey:@"answers"];
        
        
        PFObject *propertyObject = [propsArray objectAtIndex:[self.pickerView selectedRowInComponent:0]];
        NSString *options = [propertyObject objectForKey:@"options"];
        NSString *updatedOptions = [[options stringByAppendingString:textField.text] stringByAppendingString:@";"];
        [propertyObject setObject:updatedOptions forKey:@"options"];
        
        
        //remove the text field from the table view
        textField.alpha =0;
        [self.caseDetailsTableView reloadData];
    }
    else if(textField.tag ==72)
    {
       //add answer to json array of cases with a custom tag.
        
        //get the currently selected index of the pickerview to establish which caseItem is being edited.
        
        PFObject *selectedCaseItem = [sortedCaseItems objectAtIndex:[self.pickerView selectedRowInComponent:0]];
        
        //edit the answers key of the selectedCaseItem
        
        NSArray *answersList = [selectedCaseItem objectForKey:@"answers"];
        NSMutableArray *answersListMutable = [answersList mutableCopy];
        
        if(answersListMutable.count ==0)
        {
            NSMutableDictionary *ansKey = [NSMutableDictionary alloc];
            [ansKey setObject:textField.text forKey:@"custom"];
            
            [answersListMutable addObject:ansKey];
            
            answersList = [answersListMutable copy];
            [selectedCaseItem setObject:answersList forKey:@"answers"];
            
        }
        else
        {
            PFObject *customAns = [answersList objectAtIndex:0];
            [customAns setObject:textField.text forKey:@"custom"];
            [answersListMutable removeAllObjects];
            [answersListMutable addObject:customAns];
            answersList = [answersListMutable copy];
            [selectedCaseItem setObject:answersList forKey:@"answers"];
            
        }
    }
     [textField resignFirstResponder];
    
     self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
     return YES;
   }

-(IBAction)doUpdate:(id)sender
{
    //if in setting answers mode, just update the internal arrays of answers for caseItems
    
    
    //send an xml function with the updated answers and options.
    //hardcoded XML example
    /*
    NSString *xmlString = @"<PAYLOAD><USEROBJECTID>exTJgfgotY</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>ZRfwJYgFYe</CASEOBJECTID><CASENAME>Sparks on my way to school yesterday</CASENAME><ITEM><CASEITEM>403</CASEITEM><PROPERTYNUM>GbietFwjDh</PROPERTYNUM><ANSWER><A>4</A></ANSWER></ITEM></PAYLOAD>";
     */
    
    //brian dec 14--change this to update all objects instead
  
    NSString *generatedXMLString = [self createXMLFunction];
    
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
                       withParameters:@{@"payload": generatedXMLString}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                        [HUD hide:YES];
                                        
                                        //need to poll for a response to the case
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                        
                                    }
                                }];
}

-(NSString *)createXMLFunction
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    
    NSInteger selectedCaseInt = [selectedCaseIndex integerValue];
    //the case object includes the list of all caseItems and the caseId
    PFObject *caseObject = [caseListData objectAtIndex:selectedCaseInt];
    
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];

    //get the selected property from the chooser element.
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
    int h = 0;
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        PFObject *updatedProperty = [propsArray objectAtIndex:h];
        NSString *propertyNum = [eachCaseItem objectForKey:@"propertyNum"];
        NSString *propertyDescr = [updatedProperty objectForKey:@"propertyDescr"];
        
        //check to see if this caseItem is a brand new property
        
        if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:h]])
            
        {
            //add the XML for a new or updated property here
            [xmlWriter writeStartElement:@"PROPERTY"];
            
            [xmlWriter writeStartElement:@"PROPERTYNUM"];
            [xmlWriter writeCharacters:@"1"];
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
    }
    
    
    //build strings for adding properties
    //Nov 24 2014
    //changing logic so that it only creates a new property portion if the user really chose to create a new one.
    //Dec 14 2014
    //changing logic to iterate through all properties and case items in the array and update with their contents.  New properties will need to be added to these arrays.
    
    int g = 0;
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        PFObject *updatedProperty = [propsArray objectAtIndex:g];
        NSString *propertyNum = [eachCaseItem objectForKey:@"propertyNum"];
        NSString *propertyDescr = [updatedProperty objectForKey:@"propertyDescr"];
        
        //check to see if this caseItem is a brand new property
        //Jan 18, commenting this part out since properties are created further above now
        /*
         if ([newlyCreatedPropertiesIndex containsObject:[NSNumber numberWithInt:g]])
        
         {
             //add the XML for a new or updated property here
             [xmlWriter writeStartElement:@"PROPERTY"];
            
             [xmlWriter writeStartElement:@"PROPERTYNUM"];
             [xmlWriter writeCharacters:@"1"];
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
        */
        //write logic for updating the caseItem
        //build strings for building item
        [xmlWriter writeStartElement:@"ITEM"];
        
        //check to see if this caseItem has a number.  Otherwise give it a number of 9000 to indicate it is a brand new caseItem.
        NSString *myCaseItem = [eachCaseItem objectForKey:@"caseItem"];
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
        
        if(propertyNum==nil)
        {
            propertyNum =@"1";
            
        }
        [xmlWriter writeStartElement:@"PROPERTYNUM"];
        [xmlWriter writeCharacters:propertyNum];
        [xmlWriter writeEndElement];
        
        //write out the answers value of this case Item
        
        //need to check if the case type is custom answers
        
        //if case type is I or N, don't update anything for answers
         NSString *propertyType = [updatedProperty objectForKey:@"propertyType"];
        NSString *optionText = [updatedProperty objectForKey:@"options"];
        
        if([propertyType isEqualToString:@"I"] || [propertyType isEqualToString:@"N"] || [propertyType isEqualToString:@"B"])
        {
            //do nothing
        }
        else if([optionText length] == 0)
        {
            //write the answer as type Custom
            NSArray *caseAnswers = [eachCaseItem objectForKey:@"answers"];
            for (PFObject *ansObj in caseAnswers)
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
           NSArray *caseAnswers = [eachCaseItem objectForKey:@"answers"];
            for (PFObject *ansObj in caseAnswers)
            {
                NSString *ansString = [ansObj objectForKey:@"a"];
                [xmlWriter writeStartElement:@"ANSWER"];
                
                [xmlWriter writeStartElement:@"A"];
                [xmlWriter writeCharacters:ansString];
                [xmlWriter writeEndElement];
                
                [xmlWriter writeEndElement];
                
            }

        }
        
        //close item element
        [xmlWriter writeEndElement];

        //iterate to the next item in the sortedCasesArray
        g =g+1;
        
        
    }
    
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
    
}

#pragma mark -
#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return propsArray.count +1;
}

/*
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    
    
    
    return stringToReturn;
}
*/

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
 
    //if they pick the very last row on the wheel, they are selecting to create a new question.
    if(row==propsArray.count)
    {
        //show a dialogue asking if they want to create a new question
        // Customize Alert View
        UIAlertView *alertView = [UIAlertView new];
        alertView.title = @"Create New Question?";
        
        
        // Adding Your Buttons
        [alertView addButtonWithTitle:@"Create New"];
        [alertView addButtonWithTitle:@"Cancel"];
        
        alertView.delegate = self;
        
        
        [alertView show];
        
        return;
        
    }
    
    //else, query for the answers based on that already created property
    else
    
    {
    //query for a new set of selected answers based on this property num.
    
   
    PFObject *questionItemPicked = [sortedCaseItems objectAtIndex:row];
    selectedItemForUpdate = row;
    
    selectedCaseItemAnswersList = [questionItemPicked objectForKey:@"answers"];
    //setting global var
    
    PFObject *selectedProperty = [propsArray objectAtIndex:row];
    
    NSString *propertyType = [selectedProperty objectForKey:@"propertyType"];
    NSString *options = [selectedProperty objectForKey:@"options"];
        
        
    if([propertyType isEqualToString:@"I"])
    {
        //display an info message, hide the options view
        self.caseDetailsTableView.alpha = 0;
        
        NSString *infoMsg = [selectedProperty objectForKey:@"propertyDescr"];
        
        //for the caseItem of this index, take the params value
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
        
    }
    else
        if([propertyType isEqualToString:@"N"])
    {
        //do nothing, hide the options view
        self.caseDetailsTableView.alpha = 0;
        
    }
    else if([propertyType isEqualToString:@"B"])
        {
            //do nothing for now.  in the future, query for match information based on shown fields.
            self.caseDetailsTableView.alpha =0;
            
        }
    else
    {
    //check to see if this row is one of the custom answer types.  It is if option length is 0.
    
        if([options length] ==0)
        {
        //display just one custom answer
        self.customAnswerTextField.alpha = 1;
        self.caseDetailsTableView.alpha =0;
        NSString *customAns;
        //check to see if the custom answer is there
            for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
                {
                    customAns = [eachAnsObj valueForKey:@"custom"];
                }
        self.customAnswerTextField.text = customAns;
        
        }
        
    else
        {
            self.caseDetailsTableView.alpha = 1;
            answersArray = [[NSMutableArray alloc] init];
        
            [answersArray removeAllObjects];
        
            for (NSString *eachAnsObj in selectedCaseItemAnswersList)
            {
            NSString *ansNum = [eachAnsObj valueForKey:@"a"];
            [answersArray addObject:ansNum];
            
            }
            ansStaticArray = [answersArray mutableCopy];
            
            //retrieve the property choices for this caseItemObject from Parse.
        
            NSString *questionString = [selectedProperty objectForKey:@"propertyDescr"];
        
            self.questionLabel.text = questionString;
        
        
            NSString *optionsString = [selectedProperty objectForKey:@"options"];
        
            NSLog(@"%@",optionsString);
        
            //need to convert options string to an array of objects with ; separators.
        
            optionsArray = [optionsString componentsSeparatedByString:@";"];
        
            self.questionLabel.text = questionString;
        
            [self.caseDetailsTableView reloadData];
        }
   
      
    }
        
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
       
        
        // Setup label properties - frame, font, colors etc
        tView.frame = view.bounds;
        tView.textAlignment = NSTextAlignmentCenter;
        
        tView.font = [UIFont systemFontOfSize:12];
        
        tView.backgroundColor = [UIColor whiteColor];
        tView.alpha =1;
        
        //tView.alpha = 0.95;
        
    }
    
    //show a label to create a new property if it's the final questionItem
    if(row ==sortedCaseItems.count)
    {
        //show a button
        tView.text = @"Create New Question";
        tView.font = [UIFont boldSystemFontOfSize:12];
        tView.textColor = [UIColor blueColor];
        
        return tView;
        
    }
    
    else
    {
    // Fill the label text here
    PFObject *caseItem = sortedCaseItems[row];
    PFObject *propObject = propsArray[row];
    NSString *PropertyString = [propObject objectForKey:@"propertyDescr"];
    NSString *propertyType = [propObject objectForKey:@"propertyType"];
    
    NSString *origin = [caseItem objectForKey:@"origin"];
    
    //If a system suggested case item, add to text.
    NSString *stringWithOrigin;
    if([origin isEqualToString:@"S"])
    {
        stringWithOrigin = [@"Suggested Property: " stringByAppendingString:PropertyString];
        //tView.font = [UIFont boldSystemFontOfSize:12];
        
    }
    else
    {
        stringWithOrigin = PropertyString;
        
    }
        
        NSString *new = [caseItem objectForKey:@"new"];
        if([new isEqualToString:@"X"])
        {
            tView.textColor = [UIColor blueColor];
            
        }
    
        if([propertyType isEqualToString:@"I"])
        {
            stringWithOrigin = @"Info Message--Click To View";
            tView.textColor = [UIColor redColor];
            
        }
        
        if ([propertyType isEqualToString:@"N"])
        {
            tView.textColor = [UIColor lightGrayColor];
            
        }
        
        if ([propertyType isEqualToString:@"B"])
        {
            tView.textColor = [UIColor purpleColor];
            
        }
        
    NSArray *answers = [caseItem objectForKey:@"answers"];
    NSInteger ansCount = answers.count;
        
    NSString *answerCount = [NSString stringWithFormat:@"%i",(int)ansCount];
    
    NSString *stringToReturn;
    
    //If Case is answered, show # answers
    if(answers.count>0)
    {
        stringToReturn = [[[[stringWithOrigin stringByAppendingString:@" ("] stringByAppendingString:answerCount]  stringByAppendingString:@" Answers"]stringByAppendingString: @")"];
        
    }
    else
    {
        stringToReturn = stringWithOrigin;
        
    }
  
    tView.text = stringToReturn;
    
    return tView;
        
        }
}

-(IBAction)NewProperty:(id)sender
{
   NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
    
   npvc.userName = userName;
    npvc.delegate = self;
    
    
    [self.navigationController pushViewController:npvc animated:YES];
}

#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex ==0)
    {
        //said Ok, create the view controller for adding a new property
        NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
        
        npvc.userName = userName;
        npvc.delegate = self;
        
        
        [self.navigationController pushViewController:npvc animated:YES];
    }
    if (buttonIndex==1)
    {
        //cancel, dismiss alertview
        [alertView dismissWithClickedButtonIndex:1 animated:YES];
        
    }
}

-(IBAction)getLocation:(id)sender
{
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
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
    }
    
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
            _questionLabel.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                 placemark.subThoroughfare, placemark.thoroughfare,
                                 placemark.postalCode, placemark.locality,
                                 placemark.administrativeArea,
                                 placemark.country];
            
            
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
}

-(IBAction)getPreviousAnswers:(id)sender
{
    self.suggestedQuestion.alpha = 0;
    self.pickerView.alpha = 1;
    
    
}

#pragma mark DataDelegateMethods
- (void)recieveData:(NSString *)OptionsList AcceptableAnswersList:(NSArray *)Answers QuestionText:(NSString *) question {
    
    //add the data to the list sortedCaseList and propertiesArray
    
    NSMutableDictionary *propertyObject = [[NSMutableDictionary alloc] init];
    [propertyObject setObject:OptionsList forKey:@"options"];
    [propertyObject setObject:question forKey:@"propertyDescr"];
    [propertyObject setObject:@"9000" forKey:@"propertyNum"];
    [propertyObject setObject:@"U" forKey:@"propertyType"];
    
    
    NSMutableDictionary *caseItemObject = [[NSMutableDictionary alloc] init];
    [caseItemObject setObject:@"9000" forKey:@"caseItem"];
    [caseItemObject setObject:Answers forKey:@"answers"];
    
    int g = (int)sortedCaseItems.count;
    
    [sortedCaseItems addObject:caseItemObject];
    [propsArray addObject:propertyObject];
    
        
    NSNumber *indexNum = [[NSNumber alloc] initWithInt:g];
    [newlyCreatedPropertiesIndex addObject:indexNum];
    
    [self.pickerView reloadAllComponents];
    [self.caseDetailsTableView reloadData];
    
    
    //Do something with data here
    NSLog(@"this fired");
    self.submitAnswersButton.enabled = 1;
    self.submitAnswersButton.backgroundColor = [UIColor blueColor];
    
   [self.navigationController popViewControllerAnimated:NO];
    
}

@end
