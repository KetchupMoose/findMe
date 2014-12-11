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
    
    
    //get all the property ID's from each item in the selected case.
    int j = 0;
    for (PFObject *eachCaseItem in sortedCaseItems)
    {
        NSString *propNum = [eachCaseItem objectForKey:@"propertyNum"];
        [propertyIDSArray addObject:propNum];
        
        //show the case in the suggested Question box if there are no answers
        
        NSArray *answerList = [eachCaseItem objectForKey:@"answers"];
        
        if(answerList.count == 0)
        {
            //do nothing, further down we determine whether it's an info message or a suggested question
           
            
        }
        
        else
        {
            NSNumber *indexNum = [[NSNumber alloc] initWithInt:j];
            //array for keeping track of the properties with answers.  Some of these may be info messages so that is dealt with further down.  It is assumed info messages can not have answers.
            [answeredPropertiesIndex addObject:indexNum];
            
        }
     j = j+1;
    }
    
    //get all the property information for the list of properties to consider
    PFQuery *propertsQuery = [PFQuery queryWithClassName:@"Properts"];
    [propertsQuery whereKey:@"objectId" containedIn:propertyIDSArray];
    [propertsQuery orderByDescending:@"priority"];
    
    propsArray = [[propertsQuery findObjects] mutableCopy];
    
    //sort the properties into three categories based on their type: info messages, answeredQuestions, and new suggestions
    int g = 0;
    for (PFObject *property in propsArray)
    {
         NSString *propType = [property objectForKey:@"propertyType"];
        
        if([propType  isEqual:@"I"])
            {
                //property is an info message
                [infoMessageProperties addObject:property];
                [infoCases addObject:sortedCaseItems[g]];
            }
        else if ([answeredPropertiesIndex containsObject:[NSNumber numberWithInt:g]])
        
            {
                //add the property to the list of answeredProperties
                [answeredProperties addObject:property];
                [answeredCases addObject:sortedCaseItems[g]];
                
            }
        else if([propType isEqual:@"N"])
        {
            [NoAnswerProperties addObject:property];
            [NoAnswerCases addObject:sortedCaseItems[g]];
        }
        
        else
            {
                [suggestedProperties addObject:property];
                [suggestedCases addObject:sortedCaseItems[g]];
                NSNumber *caseIndex = [NSNumber numberWithInt:g];
                [suggestedCaseIndex addObject:caseIndex];
                
            }
        
        
        
        g=g+1;
    }
    
    
    PFObject *firstSuggestedCaseToShow;
    if (suggestedCases.count >0)
    {
        firstSuggestedCaseToShow = [suggestedCases objectAtIndex:0];
        
        NSNumber *firstSuggestionIndex = [suggestedCaseIndex objectAtIndex:0];
        
        selectedItemForUpdate = [firstSuggestionIndex integerValue];
        
        //NSString *lastQPropertyNum = [firstSuggestedCaseToShow objectForKey:@"propertyNum"];
        selectedCaseItemAnswersList = [firstSuggestedCaseToShow objectForKey:@"answers"];
        
        answersArray = [[NSMutableArray alloc] init];
        
        [answersArray removeAllObjects];
        
        for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
        {
            NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
            
            [answersArray addObject:ansNum];
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
        PFObject *caseToRemove = [suggestedCases objectAtIndex:0];
        [suggestedCases removeObjectAtIndex:0];
        [suggestedProperties removeObjectAtIndex:0];
        NSNumber *indexNum = suggestedCaseIndex[0];
        NSInteger indexInt = [indexNum integerValue];
        
        //remove this case from the overall arrays also
        [sortedCaseItems removeObjectAtIndex:indexInt];
        [propsArray removeObjectAtIndex:indexInt];
        
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
           [self deleteACaseItem:caseToRemove];
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
                
            self.suggestedQuestion.backgroundColor = [UIColor blueColor];
            self.suggestedQuestion.alpha = 0.8;
            self.suggestedQuestion.textAlignment = NSTextAlignmentCenter;
            self.suggestedQuestion.frame = originalQuestionFrame;
            self.suggestedQuestion.numberOfLines = 5;
            self.suggestedQuestion.lineBreakMode = NSLineBreakByWordWrapping;
                
            
            [self.view SlideFromLeft:self.suggestedQuestion duration:0.2 option:UIViewAnimationOptionCurveEaseInOut];
            
        //update options based on this new suggestedQuestion
            
            PFObject *newSuggestedCaseToShow = [suggestedCases objectAtIndex:0];
            
            selectedCaseItemAnswersList = [newSuggestedCaseToShow objectForKey:@"answers"];
            
            answersArray = [[NSMutableArray alloc] init];
            
            [answersArray removeAllObjects];
            
            for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
            {
                NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
                
                [answersArray addObject:ansNum];
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
    UITextField *textEnter = (UITextField *)[cell viewWithTag:4];
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

   for (NSNumber *eachAns in answersArray)
   {
       int ansInt = [eachAns integerValue];
       //adjusting index down 1 since George's values start at 1
       ansInt = ansInt-1;
       
       if(ansInt==indexPath.row)
       {
           //highlight this cell in the table as one of the selected answers
           cell.backgroundColor = [UIColor greenColor];
           
       }
      
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
            int ansInt = [eachAns integerValue];
            
           
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
            NSNumber *newAns = [NSNumber numberWithInteger:indexPath.row+1];
            [answersArray addObject:newAns];
            cell.backgroundColor = [UIColor greenColor];
            
        }
    
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
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:newTextFieldIndex inSection:0];
    
    UIView *cell = [self.caseDetailsTableView cellForRowAtIndexPath:cellIndexPath];
    
    UILabel *label = (UILabel *)[cell viewWithTag:3];
    
    label.text = textField.text;
    
    //add field to options array
    NSMutableArray *curarray = [optionsArray mutableCopy];
    [curarray addObject:textField.text];
    optionsArray = [curarray copy];
    
    //remove the text field from the table view
    
    [textField resignFirstResponder];
    
    textField.alpha =0;
    
    
    [self.caseDetailsTableView reloadData];
    
    return YES;
}

-(IBAction)doUpdate:(id)sender
{
    if(selectedItemForUpdate ==-1)
    {
        //you must select an item to update first.
        
    }
    
    //send an xml function with the updated answers and options.
    
    NSString *xmlString = @"<PAYLOAD><USEROBJECTID>exTJgfgotY</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>ZRfwJYgFYe</CASEOBJECTID><CASENAME>Sparks on my way to school yesterday</CASENAME><ITEM><CASEITEM>403</CASEITEM><PROPERTYNUM>GbietFwjDh</PROPERTYNUM><ANSWER><A>4</A></ANSWER></ITEM></PAYLOAD>";
        PFObject *itemObjectToUpdate = sortedCaseItems [selectedItemForUpdate];
  
    NSString *generatedXMLString = [self createXMLFunction:itemObjectToUpdate CreatingNewProperty:NO];
    
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
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                        
                                    }
                                }];
    
    
    //XML needs to take in the new case information and new
    
    
    
    
}

-(NSString *)createXMLFunction:(PFObject *)itemObject CreatingNewProperty:(BOOL) NewProp
{
    int *selectedCaseInt = (NSInteger *)[selectedCaseIndex integerValue];
    PFObject *caseObject = [caseListData objectAtIndex:selectedCaseInt];
    
    
NSString *caseName = [caseObject objectForKey:@"caseName"];
NSString *caseObjID = [caseObject objectForKey:@"caseId"];
NSString *propertyNum = [itemObject objectForKey:@"propertyNum"];
NSString *propertyDesc = self.questionLabel.text;
    
    
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
    
    if(caseObjID != nil)
    {
        
    
        [xmlWriter writeStartElement:@"CASEOBJECTID"];
        [xmlWriter writeCharacters:caseObjID];
        [xmlWriter writeEndElement];
    }
    
        [xmlWriter writeStartElement:@"CASENAME"];
        [xmlWriter writeCharacters:caseName];
        [xmlWriter writeEndElement];
    
    
    //build strings for adding properties
    //Nov 24 2014
    //changing logic so that it only creates a new property portion if the user really chose to create a new one.
    if(NewProp ==TRUE)
    {
        
        [xmlWriter writeStartElement:@"PROPERTY"];
    
    
            [xmlWriter writeStartElement:@"PROPERTYNUM"];
            [xmlWriter writeCharacters:propertyNum];
            [xmlWriter writeEndElement];
    
            [xmlWriter writeStartElement:@"PROPERTYDESCR"];
            [xmlWriter writeCharacters:propertyDesc];
            [xmlWriter writeEndElement];
    
        //go through the list of options for the selected case.

            [xmlWriter writeStartElement:@"OPTIONS"];
    
        //generate list of strings from options
        int i = 0;
        NSString *fullCharsString = @"";
        for(NSString *optionString in optionsArray)
        {
            i = i+1;
     
            fullCharsString = [fullCharsString stringByAppendingString:optionString];
        
            if  (i!= [optionsArray count])
            {
            fullCharsString = [fullCharsString stringByAppendingString:@";"];
            }
        
        }
            [xmlWriter writeCharacters:fullCharsString];
            [xmlWriter writeEndElement];
    
        [xmlWriter writeEndElement];
        
    }
    
    //build strings for building item
    [xmlWriter writeStartElement:@"ITEM"];
    
        [xmlWriter writeStartElement:@"CASEITEM"];
        [xmlWriter writeCharacters:@"9000"];
        [xmlWriter writeEndElement];
    
        [xmlWriter writeStartElement:@"PROPERTYNUM"];
        [xmlWriter writeCharacters:propertyNum];
        [xmlWriter writeEndElement];
    
    
    //write all the possible answers
    //Nov-01-2014--this will be changing in the future to show CUSTOM instead of A and show the actual strings instead of the answer index.
    
    for (NSNumber *ansNumber in answersArray)
    {
        //build a new answer element
        NSInteger myInt = [ansNumber integerValue];
        
        myInt = myInt;
        
        NSString *ansString = [NSString stringWithFormat:@"%i",myInt];
        
        [xmlWriter writeStartElement:@"ANSWER"];
        
        [xmlWriter writeStartElement:@"A"];
        [xmlWriter writeCharacters:ansString];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeEndElement];
        
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
        
    if([propertyType isEqualToString:@"I"])
    {
        //display an info message, hide the options view
        self.caseDetailsTableView.alpha = 0;
        
        NSString *infoMsg = [selectedProperty objectForKey:@"propertyDescr"];
        
         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info Message", nil) message:NSLocalizedString(infoMsg, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        
    }
    else
        if([propertyType isEqualToString:@"N"])
    {
        //do nothing, hide the options view
        self.caseDetailsTableView.alpha = 0;
        
    }
    else
    {
        self.caseDetailsTableView.alpha = 1;
        
    
    
    answersArray = [[NSMutableArray alloc] init];
    
    [answersArray removeAllObjects];
    
    for (PFObject *eachAnsObj in selectedCaseItemAnswersList)
    {
        NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
  
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

@end
