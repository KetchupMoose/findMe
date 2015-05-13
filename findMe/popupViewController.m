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
#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "UIViewController+ECSlidingViewController.h"
#import "CaseDetailsEmailViewController.h"


@interface popupViewController ()

@end

@implementation popupViewController
@synthesize testView;
@synthesize popupitsMTLObject;
@synthesize selectedCase;
@synthesize selectedCaseItem;
@synthesize selectedPropertyObject;
@synthesize displayMode;
@synthesize sortedCaseItems;
@synthesize locationLatitude;
@synthesize locationLongitude;
@synthesize locationRetrieved;
@synthesize popupOrSlideout;
@synthesize originalTemplateOptionsCounts;
@synthesize popupanswersDictionary;

NSMutableArray *popupOptionsArray;
NSMutableArray *answersArray;


NSArray *popupAnswersStatic;

NSNumber *lastTimestamp;
MBProgressHUD *HUD;
NSString *caseIDBeingUpdated;

BOOL templateMode = 0;
int originalAnswersCount;

int popUpTimerTicks =0;
UIView *bgDarkenView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    popupOptionsArray = [[NSMutableArray alloc] init];
    answersArray = [[NSMutableArray alloc] init];
    popupanswersDictionary = [[NSMutableArray alloc] init];
    
    //setup sliding view controller variables
     //[self.slidingViewController setAnchorRightRevealAmount:260.0f];
    [self.slidingViewController setAnchorLeftRevealAmount:190.0f];
    //[self.slidingViewController setAnchorRightRevealAmount:40.0f];
    //[self.slidingViewController setAnchorLeftPeekAmount:25.0f];
    
    self.answersTableView.delegate = self;
    self.answersTableView.dataSource = self;
    
    self.customAnswerTextField.delegate = self;
    
}

-(void) viewWillAppear:(BOOL)animated
{
   
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    //clear out all previous data.
    
    if([popupOptionsArray count] !=0)
    {
      [popupOptionsArray removeAllObjects];
    }
    
    // Add a shadow to the top view so it looks like it is on top of the others
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    
    self.answersTableView.delegate = self;
    self.answersTableView.dataSource = self;
    
    //load the options array
    NSString *options = [self.selectedPropertyObject objectForKey:@"options"];
    popupOptionsArray = [[options componentsSeparatedByString:@";"] mutableCopy];
    
    PFObject *selectedCaseObject;
    //load the answers array
    if([self.popupjsonDisplayMode isEqualToString:@"template"])
    {
        selectedCaseObject = self.popupjsonObject;
        self.updateButton.titleLabel.text = @"Select These Answers";
        templateMode = 1;
    }
    else if([self.popupjsonDisplayMode isEqualToString:@"singleCase"])
    {
        selectedCaseObject = self.popupjsonObject;
        templateMode = 0;
    }
    else
    {
        NSArray *cases = [self.popupitsMTLObject objectForKey:@"cases"];
        selectedCaseObject = [cases objectAtIndex:[selectedCase integerValue]];
        
        NSString *caseObjectID = [selectedCaseObject objectForKey:@"caseId"];
        
        int length = (int)[caseObjectID length];
        
        if(length==0)
        {
            self.updateButton.titleLabel.text = @"Select These Answers";
            templateMode = 1;
        }
    }
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:[selectedCaseItem integerValue]];
    
    NSArray *selectedCaseItemAnswersList = [selectedCaseItemObject objectForKey:@"answers"];
   
    [answersArray removeAllObjects];
    //[answersDictionary removeAllObjects];
    popupanswersDictionary = [selectedCaseItemAnswersList mutableCopy];
    
    if(popupanswersDictionary ==nil)
    {
        popupanswersDictionary = [[NSMutableArray alloc] init];
        
    }
    
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
    
    
    
    if ([self.popupjsonDisplayMode isEqualToString:@"template"])
    {
        NSInteger selectedCaseInteger = [selectedCaseItem integerValue];
        
        //get the value from the original optionCount
        if(selectedCaseInteger <= [self.originalTemplateOptionsCounts count]-1)
        {
            NSNumber *originalOptionCount = [self.originalTemplateOptionsCounts objectAtIndex:selectedCaseInteger];
            originalAnswersCount = [originalOptionCount intValue];
            
        }
    }
    else
    {
        originalAnswersCount = (int)[popupOptionsArray count];
    }
    
    
   }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated
{
    
}

-(void) viewWillDisappear:(BOOL)animated
{
    CaseDetailsEmailViewController *cdevc = (CaseDetailsEmailViewController *)self.slidingViewController.topViewController;
    cdevc.slideoutDisplayed = @"no";
    
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
    if([popupOrSlideout isEqualToString:@"slideout"])
       {
           //[self.slidingViewController anchorTopViewToLeftAnimated:YES];
           //[self.slidingViewController setAnchorLeftRevealAmount:0];
           //[self.slidingViewController anchorTopViewToRightAnimated:YES];
           [self.slidingViewController resetTopViewAnimated:YES];
           
       }
       else
       
       {
            [self dismissViewControllerAnimated:NO completion:nil];
       }
  
    
}

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int caseItemsCount = (int)[popupOptionsArray count];
    
    return caseItemsCount +1;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"popupCell" forIndexPath:indexPath];
    UILabel *optionLabel = (UILabel *)[cell viewWithTag:1];
    
    if(indexPath.row == popupOptionsArray.count)
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
        optionLabel.text = [popupOptionsArray objectAtIndex:indexPath.row];
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
   
    //for the last cell, show a keyboard to type a new option
    if(indexPath.row==popupOptionsArray.count)
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
    
    
}

- (void)closeNewAnswerView:(id)sender
{
    UIButton *sendingButton = (UIButton *)sender;
    UIView *NewAnswerView = sendingButton.superview;
    
    [NewAnswerView removeFromSuperview];
    [bgDarkenView removeFromSuperview];
    
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
                [answersArray addObject:@"newAnsString"];
                NSMutableDictionary *newAnsCustom = [[NSMutableDictionary alloc] init];
                [newAnsCustom setObject:newAnsString forKey:@"custom"];
                [popupanswersDictionary addObject:newAnsCustom];
                [popupOptionsArray addObject:newAnsString];
            }
        }
        
    }
    [NewAnswerView removeFromSuperview];
    [bgDarkenView removeFromSuperview];
    
    
    //NSIndexPath *path = [NSIndexPath indexPathForRow:[optionsArray count]-1 inSection:0];
    //[self.answersTableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionBottom];
    
    [self updateAnswers:(self)];
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    [self animateTextField:textField up:YES];
    
    self.updateButton.enabled = 1;
    [self.updateButton.titleLabel setTextColor:[UIColor blueColor]];
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
    
    [textField resignFirstResponder];

    return YES;
    
}

-(IBAction)updateAnswers:(id)sender
{
   if([displayMode isEqualToString:@"custom"])
   {
    [popupanswersDictionary removeAllObjects];
    
    NSMutableDictionary *AnsObj = [[NSMutableDictionary alloc] init];
    [AnsObj setValue:self.customAnswerTextField.text forKey:@"custom"];
    [popupanswersDictionary addObject:AnsObj];
   }

    PFObject *selectedCaseObject;
    if([self.popupjsonDisplayMode isEqualToString:@"template"] || ([self.popupjsonDisplayMode isEqualToString:@"singleCase"]))
    {
        selectedCaseObject = self.popupjsonObject;
    }
    else
    {
    NSArray *cases = [self.popupitsMTLObject objectForKey:@"cases"];
    selectedCaseObject = [cases objectAtIndex:[selectedCase integerValue]];
   }
   
    PFObject *selectedCaseItemObject = [sortedCaseItems objectAtIndex:[selectedCaseItem integerValue]];
    
    if(templateMode ==1)
    {
        //update the data for sortedCaseItems and propsArray to prepare for updating on the CaseDetailsEmailViewController
        
        caseIDBeingUpdated = [selectedCaseItemObject objectForKey:@"caseItem"];
        
        [self.UCIdelegate updateCaseItem:caseIDBeingUpdated AcceptableAnswersList:popupanswersDictionary];
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
            if([caseString length] >0)
            {
                if([caseIDBeingUpdated isEqualToString:caseString])
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
        
        [self.UCIdelegate reloadData:returnedITSMTLObject reloadMode:@"polledForMTL"];
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
    
    if([locationRetrieved length]>0)
    {
        [xmlWriter writeStartElement:@"LOCATIONTEXT"];
        [xmlWriter writeCharacters:locationRetrieved];
        [xmlWriter writeEndElement];
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
    
    int h = 0;
    
    
    NSString *propertyNum = [caseItemObject objectForKey:@"propertyNum"];
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
                
                for (PFObject *ansObj in popupanswersDictionary)
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
                
                for (PFObject *ansObj in popupanswersDictionary)
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

-(NSString *)createXMLFunctionSingleJSONCase
{
    PFObject *caseObject = self.popupjsonObject;
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
    [xmlWriter writeCharacters:self.popupUserName];
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
        [xmlWriter writeStartElement:@"LOCATIONTEXT"];
        [xmlWriter writeCharacters:locationRetrieved];
        [xmlWriter writeEndElement];
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
    int h = 0;
    
    NSString *propertyNum = [caseItemObject objectForKey:@"propertyNum"];
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
        
        for (PFObject *ansObj in popupanswersDictionary)
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
        
        for (PFObject *ansObj in popupanswersDictionary)
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

@end
