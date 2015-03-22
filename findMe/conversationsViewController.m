//
//  conversationsViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-02-27.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "conversationsViewController.h"
#import "MBProgressHUD.h"

@interface conversationsViewController ()

@end

@implementation conversationsViewController

NSArray *conversationMessagesArray;
MBProgressHUD* HUD;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.chatTableView.delegate = self;
    self.chatTableView.dataSource = self;
    
    self.chatTextField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
    
    //query for updated messages
    [self.chatTableView removeConstraints:self.chatTableView.constraints];
    
    PFQuery *query = [PFQuery queryWithClassName:@"conversationMessages"];
    [query whereKey:@"Conversation" equalTo:self.conversationObject];
    [query orderByDescending:@"updatedAt"];
    
    conversationMessagesArray = [query findObjects];
    
    [self.chatTableView reloadData];
   
    

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[conversationMessagesArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
    
    UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
    
    if([conversationMessagesArray count] ==0)
    {
        messageLabel.text = @"Chat With Your Match Here";
    }
    else
    {
        PFObject *messageObject = [conversationMessagesArray objectAtIndex:indexPath.row];
        
        messageLabel.text = [messageObject objectForKey:@"MessageString"];
        
    }
    
    //if odd, show on right side, if even, show on left side.
    NSInteger modulusResult = (indexPath.row % 2);
    
    if(modulusResult ==1)
    {
        [messageLabel setFrame:CGRectMake(10,messageLabel.frame.origin.y,messageLabel.frame.size.width,messageLabel.frame.size.height)];
   
    }
    else
    {
        [messageLabel setFrame:CGRectMake(90,messageLabel.frame.origin.y,messageLabel.frame.size.width,messageLabel.frame.size.height)];
    }
    
    CALayer *messageLabelLayer = [messageLabel layer];
    messageLabelLayer.cornerRadius = 5.0f;
    
    return cell;
}

- (IBAction)sendChat:(id)sender
{
    [self.chatTextField resignFirstResponder];
    
    //create a messages object with the text
    
    NSString *chatMessage = self.chatTextField.text;
    PFObject *messageObject;
    
    if([chatMessage length] >0)
    {
         messageObject = [PFObject objectWithClassName:@"conversationMessages"];
        [messageObject setObject:self.conversationObject forKey:@"Conversation"];
        [messageObject setObject:chatMessage forKey:@"MessageString"];
        [messageObject setObject:self.conversationCaseUserID forKey:@"messageCaseUserID"];
        [messageObject save];
    }
    
    NSMutableArray *messagesMutableArray = [[NSMutableArray alloc] init];
    [messagesMutableArray addObjectsFromArray:conversationMessagesArray];
    [messagesMutableArray addObject:messageObject];
    
    conversationMessagesArray = [messagesMutableArray copy];
    
    [self.chatTableView reloadData];
    
}

//textfield delegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    [self animateTextField:textField up:YES];
    
    self.sendButton.enabled = 1;
    
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


@end
