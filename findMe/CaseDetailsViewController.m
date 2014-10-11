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
NSMutableArray *answersArray;
//need to set selectedPropertyQuestion from the question picked by the pickerView
NSString *selectedPropertyQuestion;
NSInteger newTextFieldIndex;
NSInteger selectedItemForUpdate;
MBProgressHUD *HUD;



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
    // Do any additional setup after loading the view.
    int *selectedCaseInt = (NSInteger *)[selectedCaseIndex integerValue];
    //NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    PFObject *caseItemObject = [caseListData objectAtIndex:selectedCaseInt];
    
    //get the LAST (latest) QuestionItem to display that information.
    
   questionItems= [caseItemObject objectForKey:@"caseItems"];
    
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
        for (NSNumber *eachAns in answersArray)
        {
            int ansInt = [eachAns integerValue];
            if(ansInt==indexPath.row)
            {
                [answersArray removeObject:eachAns];
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    }
    else
            
        {
            NSNumber *newAns = [NSNumber numberWithInteger:indexPath.row];
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
  
    NSString *generatedXMLString = [self createXMLFunction:itemObjectToUpdate];
    
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

-(NSString *)createXMLFunction:(PFObject *)itemObject
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
    
        [xmlWriter writeStartElement:@"CASEOBJECTID"];
        [xmlWriter writeCharacters:caseObjID];
        [xmlWriter writeEndElement];
    
        [xmlWriter writeStartElement:@"CASENAME"];
        [xmlWriter writeCharacters:caseName];
        [xmlWriter writeEndElement];
    
    
    //build strings for adding properties
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
        
        if(i!= [optionsArray count])
        {
            fullCharsString = [fullCharsString stringByAppendingString:@";"];
        }
        
    }
            [xmlWriter writeCharacters:fullCharsString];
            [xmlWriter writeEndElement];
    
        [xmlWriter writeEndElement];
    
    //build strings for building item
    [xmlWriter writeStartElement:@"ITEM"];
    
        [xmlWriter writeStartElement:@"CASEITEM"];
        [xmlWriter writeCharacters:@"9000"];
        [xmlWriter writeEndElement];
    
        [xmlWriter writeStartElement:@"PROPERTYNUM"];
        [xmlWriter writeCharacters:propertyNum];
        [xmlWriter writeEndElement];
    
    
    //write all the possible answers
    
    for (NSNumber *ansNumber in answersArray)
    {
        //build a new answer element
        NSInteger myInt = [ansNumber integerValue];
        
        myInt = myInt+1;
        
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
    return questionItems.count;
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

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
       
        
        // Setup label properties - frame, font, colors etc
        tView.frame = view.bounds;
        tView.textAlignment = NSTextAlignmentCenter;
        
        tView.font = [UIFont systemFontOfSize:12];
    }
    // Fill the label text here
    PFObject *questionItem = questionItems[row];
    NSString *questionPropertyNum = [questionItem objectForKey:@"propertyNum"];
    
    NSString *origin = [questionItem objectForKey:@"origin"];
    
    //If a system suggested case item, add to text.
    NSString *stringWithOrigin;
    if([origin isEqualToString:@"S"])
    {
        stringWithOrigin = [@"Suggested Property: " stringByAppendingString:questionPropertyNum];
    }
    else
    {
        stringWithOrigin = questionPropertyNum;
        
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

-(IBAction)NewProperty:(id)sender
{
   NewPropertyViewController *npvc = [self.storyboard instantiateViewControllerWithIdentifier:@"npvc"];
    
   npvc.userName = userName;
    
    
    [self.navigationController pushViewController:npvc animated:YES];
}


@end
