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


@interface CaseDetailsViewController ()

@end

@implementation CaseDetailsViewController
@synthesize caseListData;
@synthesize selectedCaseIndex;
@synthesize pickerView;
@synthesize userName;

NSArray *questionItems;
NSArray *answersList;
NSArray *optionsArray;
NSArray *ansStaticArray;
NSArray *propsArray;
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
    int *selectedCaseInt = (NSInteger *)[selectedCaseIndex integerValue];
    //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    PFObject *caseItemObject = [caseListData objectAtIndex:selectedCaseInt];
    
    //get the LAST (latest) QuestionItem to display that information.
    
   questionItems= [caseItemObject objectForKey:@"caseItems"];
    
    propertyIDSArray = [[NSMutableArray alloc] init];
    for (PFObject *eachQuestion in questionItems)
    {
        NSString *propNum = [eachQuestion objectForKey:@"propertyNum"];
        [propertyIDSArray addObject:propNum];
        
    }
    
    PFQuery *propertsQuery = [PFQuery queryWithClassName:@"Properts"];
    [propertsQuery whereKey:@"objectId" containedIn:propertyIDSArray];
    
    propsArray = [propertsQuery findObjects];
    
    PFObject *lastQuestion = [questionItems objectAtIndex:(questionItems.count-1)];
    selectedItemForUpdate = questionItems.count-1;
    
    NSString *lastQPropertyNum = [lastQuestion objectForKey:@"propertyNum"];
    answersList = [lastQuestion objectForKey:@"answers"];
    
    answersArray = [[NSMutableArray alloc] init];
    
    [answersArray removeAllObjects];
    
    for (PFObject *eachAnsObj in answersList)
    {
        NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
        
        [answersArray addObject:ansNum];
    }
    
    ansStaticArray = [answersArray mutableCopy];
    
    //retrieve the property choices for this caseItemObject from Parse.
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving List of Properts";
    [HUD show:YES];
    
     PFQuery *query = [PFQuery queryWithClassName:@"Properts"];
    
    //hardcoded string with 3 answers
    //eI4q4TycPu
    [query getObjectInBackgroundWithId:lastQPropertyNum block:^(PFObject *PropertsObject, NSError *error) {
        
        NSString *questionString = [PropertsObject objectForKey:@"propertyDescr"];
        
        NSString *optionsString = [PropertsObject objectForKey:@"options"];
        
        //need to convert options string to an array of objects with ; separators.
        
        optionsArray = [optionsString componentsSeparatedByString:@";"];
        
        self.questionLabel.text = questionString;
        
        [self.caseDetailsTableView reloadData];
        
        [HUD hide:YES];
        
        
    }
     ];
    
    //here are the contents of each case item object
   answersList = [caseItemObject objectForKey:@"answers"];
    
    self.caseDetailsTableView.dataSource = self;
    self.caseDetailsTableView.delegate = self;
    
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    
    
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
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [optionsArray count] +1;
    
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
    //send an xml function with the updated answers and options.
    
    NSString *xmlString = @"<PAYLOAD><USEROBJECTID>exTJgfgotY</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>ZRfwJYgFYe</CASEOBJECTID><CASENAME>Sparks on my way to school yesterday</CASENAME><ITEM><CASEITEM>403</CASEITEM><PROPERTYNUM>GbietFwjDh</PROPERTYNUM><ANSWER><A>4</A></ANSWER></ITEM></PAYLOAD>";
        PFObject *itemObjectToUpdate = questionItems [selectedItemForUpdate];
  
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
    return questionItems.count +1;
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
    if(row==questionItems.count)
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
    
    PFObject *questionItemPicked = [questionItems objectAtIndex:row];
    selectedItemForUpdate = row;
    
    NSString *lastQPropertyNum = [questionItemPicked objectForKey:@"propertyNum"];
    answersList = [questionItemPicked objectForKey:@"answers"];
    //setting global var
    selectedPropertyQuestion = [questionItemPicked objectForKey:@"propertyNum"];
    
    answersArray = [[NSMutableArray alloc] init];
    
    [answersArray removeAllObjects];
    
    for (PFObject *eachAnsObj in answersList)
    {
        NSNumber *ansNum = [eachAnsObj valueForKey:@"a"];
  
        [answersArray addObject:ansNum];
        
    }
    ansStaticArray = [answersArray mutableCopy];

    //retrieve the property choices for this caseItemObject from Parse.
    
    PFQuery *query = [PFQuery queryWithClassName:@"Properts"];
    
    //hardcoded string with 3 answers
    //eI4q4TycPu
    [query getObjectInBackgroundWithId:lastQPropertyNum block:^(PFObject *PropertsObject, NSError *error) {
        
        NSString *questionString = [PropertsObject objectForKey:@"propertyDescr"];
        
        self.questionLabel.text = questionString;
        
        
        NSString *optionsString = [PropertsObject objectForKey:@"options"];
        
        //need to convert options string to an array of objects with ; separators.
        
        optionsArray = [optionsString componentsSeparatedByString:@";"];
        
        self.questionLabel.text = questionString;
        
        [self.caseDetailsTableView reloadData];

    }
     ];
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
    }
    
    //show a label to create a new property if it's the final questionItem
    if(row ==questionItems.count)
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
    PFObject *questionItem = questionItems[row];
        PFObject *propObject = propsArray[row];
        NSString *PropertyString = [propObject objectForKey:@"propertyDescr"];
        
    
    NSString *origin = [questionItem objectForKey:@"origin"];
    
    //If a system suggested case item, add to text.
    NSString *stringWithOrigin;
    if([origin isEqualToString:@"S"])
    {
        stringWithOrigin = [@"Suggested Property: " stringByAppendingString:PropertyString];
    }
    else
    {
        stringWithOrigin = PropertyString;
        
    }
    NSArray *answers = [questionItem objectForKey:@"answers"];
    
    NSString *answerCount = [NSString stringWithFormat:@"%i",answers.count];
    
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
    
    
    
    //Inefficient design here with lots of parse queries; need a better way to do an include query that includes all of the property titles.
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

@end
