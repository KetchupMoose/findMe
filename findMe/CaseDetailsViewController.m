//
//  CaseDetailsViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "CaseDetailsViewController.h"
#import <Parse/Parse.h>

@interface CaseDetailsViewController ()

@end

@implementation CaseDetailsViewController
@synthesize caseListData;
@synthesize selectedCaseIndex;
NSArray *answersList;
NSArray *optionsArray;
NSArray *ansStaticArray;
NSMutableArray *answersArray;


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
    
    NSArray *questionItems = [caseItemObject objectForKey:@"caseItems"];
    
    PFObject *lastQuestion = [questionItems objectAtIndex:(questionItems.count-7)];
    
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
        
        
    }
     ];
    
    
    
    
    //here are the contents of each case item object
   answersList = [caseItemObject objectForKey:@"answers"];
    
    self.caseDetailsTableView.dataSource = self;
    self.caseDetailsTableView.delegate = self;
    
    
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
    
    
    UILabel *OptionNameLabel = (UILabel *)[cell viewWithTag:3];
    
    //show a radio checkmark button to toggle on and off.
    
  if([optionsArray count]<=0)
  {
      return cell;
  }
    
    //check to see if the answer should be highlighted
    
   for (NSNumber *eachAns in answersArray)
   {
       int ansInt = [eachAns integerValue];
       if(ansInt==indexPath.row)
       {
           //highlight this cell in the table as one of the selected answers
           cell.backgroundColor = [UIColor greenColor];
           
       }
   }
    
    //for the last cell, make it show text saying "Tap Here to Add"
    if(indexPath.row==[optionsArray count])
    {
        OptionNameLabel.text = @"";
        [cell addSubview:textEnter];
        textEnter.delegate = self;
        
        textEnter.text = @"Tap Here To Add An Option";
        textEnter.alpha=1;
        
        textEnter.tag = indexPath.row+100;
        
    }
    else
    {
        OptionNameLabel.text = [optionsArray objectAtIndex:indexPath.row];
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
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:textField.tag-100 inSection:0];
    
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
    
    
}


@end
