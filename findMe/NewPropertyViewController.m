//
//  NewPropertyViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-10-11.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "NewPropertyViewController.h"

@interface NewPropertyViewController ()

@end

@implementation NewPropertyViewController
@synthesize userName;
@synthesize answersListTableView;

NSMutableArray *answersListArray;
NSMutableArray *acceptableAnswers;
NSString *questionText;

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
    self.answersListTableView.delegate = self;
    self.answersListTableView.dataSource = self;
    
    answersListArray = [[NSMutableArray alloc] init];
    acceptableAnswers = [[NSMutableArray alloc] init];
    
    self.answerTextField.delegate = self;
    self.questionTextField.delegate = self;
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
     tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
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

-(IBAction)addAnswerToList:(id)sender
{
   
    
    NSString *newAnswer = self.answerTextField.text;
    
    [answersListArray addObject:newAnswer];
    
    if(self.checkMark2.alpha==0)
    {
        self.checkMark2.alpha =1;
        
    }
    
    [self.answersListTableView reloadData];
    
}
-(IBAction)addNewProperty:(id)sender
{
    
}

#pragma mark UITableViewDelegateMethods
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [answersListArray count];
    
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"answerCell" forIndexPath:indexPath];
    
    UILabel *answerLabel = (UILabel *)[cell viewWithTag:1];
    answerLabel.text = [answersListArray objectAtIndex:indexPath.row];
    
    //check to see if the answer should be highlighted
    cell.backgroundColor = [UIColor clearColor];
    
    for (NSNumber *eachAns in acceptableAnswers)
    {
        int ansInt = [eachAns integerValue];
        if(ansInt==indexPath.row)
        {
            //highlight this cell in the table as one of the selected answers
            cell.backgroundColor = [UIColor greenColor];
            
        }
        
    }

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    // Add your Colour.
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setTintColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.backgroundColor==[UIColor greenColor])
    {
        //remove this answer from the list.
        for (NSNumber *eachAns in acceptableAnswers)
        {
            int ansInt = [eachAns integerValue];
            if(ansInt==indexPath.row)
            {
                [acceptableAnswers removeObject:eachAns];
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    }
    else
        
    {
        NSNumber *newAns = [NSNumber numberWithInteger:indexPath.row];
        [acceptableAnswers addObject:newAns];
        cell.backgroundColor = [UIColor greenColor];
        
        
        if(self.checkMark2.alpha==0)
        {
            self.checkMark2.alpha =1;
            self.addNewPropertyButton.enabled = true;
            
        }

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
    if(textField.tag ==44)
    {
        //set the question text.
        questionText = textField.text;
        self.checkMark1.alpha = 1;
        
    }
    
    if(textField.tag==45)
    {
        
    }
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}


@end
