//
//  popupViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "popupViewController.h"
#import "XMLWriter.h"
#import "MBProgressHUD.h"



@interface popupViewController ()

@end

@implementation popupViewController
@synthesize testView;
@synthesize popupitsMTLObject;
@synthesize selectedCase;
@synthesize selectedCaseItem;
@synthesize selectedPropertyObject;
@synthesize displayMode;

NSMutableArray *optionsArray;
NSMutableArray *answersArray;
NSMutableArray *answersDictionary;
NSArray *sortedCaseItems;
NSNumber *lastTimestamp;
MBProgressHUD *HUD;

int popUpTimerTicks =0;


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.answersTableView.delegate = self;
    self.answersTableView.dataSource = self;
    
    //load the options array
    NSString *options = [self.selectedPropertyObject objectForKey:@"options"];
    optionsArray = [[options componentsSeparatedByString:@";"] mutableCopy];
   
    //load the answers array
    NSArray *cases = [self.popupitsMTLObject objectForKey:@"cases"];
    PFObject *selectedCaseObject = [cases objectAtIndex:[selectedCase integerValue]];
    NSArray *caseItems = [selectedCaseObject objectForKey:@"caseItems"];
    
    //sort caseItems by priority
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
   NSArray *sortedCaseItems = [[caseItems sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:[selectedCaseItem integerValue]];
    
    NSArray *selectedCaseItemAnswersList = [selectedCaseItemObject objectForKey:@"answers"];
    answersArray = [[NSMutableArray alloc] init];
    answersDictionary = [[NSMutableArray alloc] init];
    
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
    
    if([self.displayMode isEqualToString:@"custom"])
    {
        self.answersTableView.alpha = 0;
        self.customAnswerTextField.alpha =1;
        
        if([answersArray count]>0)
        {
            self.customAnswerTextField.text = [answersArray objectAtIndex:0];
            
        }
    }
    else
    {
        self.answersTableView.alpha = 1;
        self.customAnswerTextField.alpha =0;
        [self.answersTableView reloadData];
    }
   
    //set the update button to disabled by default until a change is made:
    self.updateButton.enabled = 0;
    [self.updateButton.titleLabel setTextColor:[UIColor lightGrayColor]];
    
    
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

-(IBAction)closePopup:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
}

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int caseItemsCount = (int)[optionsArray count];
    
    return caseItemsCount +1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"popupCell" forIndexPath:indexPath];
    UILabel *optionLabel = (UILabel *)[cell viewWithTag:1];
    
    if(indexPath.row == optionsArray.count)
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
        optionLabel.text = [optionsArray objectAtIndex:indexPath.row];
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
    
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    //for the last cell, show a keyboard to type a new option
    if(indexPath.row==optionsArray.count)
    {
        //add keyboard for adding a new option
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
    
    //set the answers for this case to an array of a-value NSDicts
    
    [answersDictionary removeAllObjects];
    
    
    for(NSNumber *eachAns in answersArray)
    {
        NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
        [AnsObj setValue:eachAns forKey:@"a"];
        [answersDictionary addObject:AnsObj];
        
    }
    
    self.updateButton.enabled = 1;
   [self.updateButton.titleLabel setTextColor:[UIColor blueColor]];
    
    
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
    
    [answersDictionary removeAllObjects];
    
    NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
    [AnsObj setValue:textField.text forKey:@"custom"];
    [answersDictionary addObject:AnsObj];
    
    self.updateButton.enabled = 1;
    [self.updateButton.titleLabel setTextColor:[UIColor blueColor]];
    
    return YES;
    
    
}

-(IBAction)updateAnswers:(id)sender
{
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
                                        
                                        [HUD hide:NO];
                                        
                                        //set update date to this exact moment
                                        //updateDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
                                        
                                        //loop through the cases to find the previously submitted timestamp
                                        NSArray *allCases = [self.popupitsMTLObject objectForKey:@"cases"];
                                        
                                        for (PFObject *eachReturnedCase in allCases)
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
    
    NSLog(@"timer fired tick %i", popUpTimerTicks);
    
    //check the parse object to see if it is updated
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query includeKey:@"cases"];
    
    PFObject *returnedITSMTLObject = [query getObjectWithId:self.popupitsMTLObject.objectId];
    
    NSArray *returnedCases = [returnedITSMTLObject objectForKey:@"cases"];
    
    BOOL updateSuccess = 0;
    
    
        for (PFObject *eachReturnedCase in returnedCases)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] <=0)
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
                else
                {
                //continue
                }
        }
    
    if(updateSuccess ==1)
    {
        NSLog(@"update successful");
        
        //stop the timer
        [timer invalidate];
        popUpTimerTicks = 0;
        
        //clear the progress hud
        [HUD hide:NO];
        
        //trigger caseDetailsEmailViewController to reload its data
        [self.cdevc reloadData:returnedITSMTLObject];
        
    }
    
    else
    {
        NSLog(@"running the loop again to query again");
        
    }
    
    popUpTimerTicks=popUpTimerTicks+1;
    if(popUpTimerTicks==40)
    {
        [timer invalidate];
        NSLog(@"ran into maximum time");
        [HUD hide:YES];
    }
    
}


-(NSString *)createXMLFunction
{
    //iterate through all items still in the caseitems and property arrays and send XML to update all of these (either with their original contents or the modifications/new entries)
    
    NSInteger selectedCaseInt = [selectedCase integerValue];
    //the case object includes the list of all caseItems and the caseId
    NSArray *allcases = [self.popupitsMTLObject objectForKey:@"cases"];
    
    PFObject *caseObject = [allcases objectAtIndex:selectedCaseInt];
    PFObject *caseItemObject = [sortedCaseItems objectAtIndex:[selectedCaseItem integerValue]];
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    NSString *caseObjID = [caseObject objectForKey:@"caseId"];
    
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:self.popupitsMTLObject.objectId];
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
    
    int h = 0;
    
    NSString *propertyNum = self.selectedPropertyObject.objectId;
    NSString *propertyDescr = [self.selectedPropertyObject objectForKey:@"propertyDescr"];
    
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
            NSString *propertyType = [self.selectedPropertyObject objectForKey:@"propertyType"];
            NSString *optionText = [self.selectedPropertyObject objectForKey:@"options"];
            
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
               
                for (PFObject *ansObj in answersDictionary)
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
    
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
    
}




@end
