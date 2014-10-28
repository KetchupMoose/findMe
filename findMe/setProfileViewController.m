//
//  setProfileViewController.m
//  findme
//
//  Created by Brian Allen on 2014-10-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "setProfileViewController.h"
#import "Parse/Parse.h"
#import "MBProgressHUD.h"
#import "XMLWriter.h"
#import "UIView+Animation.h"

@interface setProfileViewController ()

@end

@implementation setProfileViewController

NSString *gender;
NSString *showName;
NSString *phoneNum;


MBProgressHUD *HUD;
NSArray *templatePickerChoices;
NSMutableArray *templatePickerParentChoices;
NSMutableArray *templatePickerActiveChoices;

NSString *selectedTemplate1;
NSString *selectedTemplate2;
PFObject *itsMTLObject;
int timerTicks =0;

UIImageView *phoneSearchersView;
int selectedPic;



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
    
    self.phoneTextField.delegate = self;
    self.nameTextField.delegate = self;
    
    // Do any additional setup after loading the view.
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    
    
    [self.view addGestureRecognizer:tap];
    
    
    //retrieve the five parent templatePickerChoices from Parse
    //templatePickerChoices =
    PFQuery *templateQuery = [PFQuery queryWithClassName:@"Templates"];
    
    [templateQuery whereKey:@"laiso" equalTo:@"EN"];
  
    
    templatePickerChoices = [templateQuery findObjects];
    templatePickerParentChoices = [[NSMutableArray alloc] init];
    
    for(PFObject *templateObject in templatePickerChoices)
    {
        if([templateObject objectForKey:@"parenttemplateid"]==nil)
        {
            [templatePickerParentChoices addObject:templateObject];
            
        }
    }
    
    self.templatePickerView.delegate = self;
    self.templatePickerView.dataSource = self;
  
    templatePickerActiveChoices = [[NSMutableArray alloc] init];
    
    self.childTemplateTableView.delegate = self;
    self.childTemplateTableView.dataSource = self;
    
    
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

-(IBAction)selectedMale:(id)sender
{
    gender = @"M";
    [self removeViewsShowTemplateChoices:nil];
    
   
    
    
}

-(IBAction)selectedFemale:(id)sender
{
    gender =@"F";
    
}
-(IBAction)submitProfile:(id)sender
{
    //check if info is complete, if not, show an alert.
    
      if(self.nameTextField.text.length == 0)
      {
          [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Name", nil) message:NSLocalizedString(@"Please enter a name before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
      }
    
    if(self.phoneTextField.text.length == 0)
    {
         [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Phone Number", nil) message:NSLocalizedString(@"Please enter a valid phone number before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    if(gender.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Gender", nil) message:NSLocalizedString(@"Please select a gender before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    if(selectedTemplate1.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Parent Template", nil) message:NSLocalizedString(@"Please select a parent template before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    if(selectedTemplate2.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Second Template", nil) message:NSLocalizedString(@"Please select a second template before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    //passed validation, run xml to create new user
    
    showName = self.nameTextField.text;
    phoneNum = self.phoneTextField.text;
    
    
    PFUser *currentUser = [PFUser currentUser];
    
    //create new case with this user.
    itsMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
    [itsMTLObject setObject:currentUser forKey:@"ParseUser"];
    [itsMTLObject setObject:showName forKey:@"showName"];
    
    // Set the access control list to current user for security purposes
    PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [itsMTLACL setPublicReadAccess:YES];
    [itsMTLACL setPublicWriteAccess:YES];
    
    itsMTLObject.ACL = itsMTLACL;
    
    [itsMTLObject save];
    
    //set user properties to parse true user account
    [currentUser setObject:showName forKey:@"showName"];
    [currentUser setObject:phoneNum forKey:@"cellNumber"];
    [currentUser setObject:gender forKey:@"gender"];
    [currentUser save];
    
    
    //get the ID and run the XML with the case info.
    NSString *itsMTLObjectID = itsMTLObject.objectId;
    
    //add a progress HUD to show it is sending the XML with the case info
    
    NSString *hardcodedXMLString = @"<PAYLOAD><USEROBJECTID>4OvTmAzGE7</USEROBJECTID><LAISO>EN</LAISO><PREFERENCES><SHOWNAME>Rose</SHOWNAME><COUNTRY>CA</COUNTRY><GENDER>F</GENDER><TEMPLATEID1>01VURH6zGz</TEMPLATEID1><TEMPLATEID2>9XXwNvkFTI</TEMPLATEID2></PREFERENCES></PAYLOAD>";
    
    NSString *xmlGeneratedString = [self createTemplateXMLFunction:itsMTLObjectID];
    
    //add a layer here to show pictures of beautiful people while the user is getting information
    phoneSearchersView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+40,self.view.bounds.size.width, self.view.bounds.size.height-40)];
    phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman1.jpg"];
    
    [self.view addSubviewWithFadeAnimation:phoneSearchersView duration:2 option:UIViewAnimationOptionCurveEaseIn];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(changeSearchPicture:)
                                   userInfo:nil
                                    repeats:YES];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [phoneSearchersView addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Sending XML to Generate New User";
    [HUD show:YES];
    
    //use parse cloud code function to update with appropriate XML
    [PFCloud callFunctionInBackground:@"inboundZITSMTL"
                       withParameters:@{@"payload": xmlGeneratedString}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                    NSString *responseText = responseString;
                                    NSLog(responseText);
                                        
                                    [HUD hide:NO];
                                    if([responseText isEqualToString:@"ok"])
                                    {
                                           
                                        NSLog(@"starting to poll for template maker update");
                                        [self pollForTemplateMaker];
                                        
                                    }
                                        
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                        [HUD hide:YES];
                                        
                                    }
                                }];
    
   
    
    
}

-(void)pollForTemplateMaker
{
    //run a timer in the background to look for the moment the case is updated with a template maker
    
    //show progress HUD
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Polling Parse For Update";
    [HUD show:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(timerFired:)
                                   userInfo:nil
                                    repeats:YES];
    
}

-(void) changeSearchPicture:(NSTimer *) timer
{
    
    
    if(selectedPic ==1)
    {
        //change to pic 2
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotoguy1.jpg"];
        selectedPic = 2;
        
    }
    else
    {
         phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman1.jpg"];
        selectedPic = 1;
    }
        
}

- (void)timerFired:(NSTimer *)timer {
    
    NSLog(@"timer fired");
//check the parse object to see if it is updated
  
    [itsMTLObject fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //do stuff with object.
        PFObject *templateMakerObj = [object objectForKey:@"templateMaker"];
        
        if(templateMakerObj != nil)
        {
            //stop the timer
            [timer invalidate];
            timerTicks = 0;
            
            NSLog(@"got a template maker with this ID: ", templateMakerObj.objectId);
            [HUD hide:YES];
          
            
            [self removeViewsShowTemplateChoices:(templateMakerObj)];
        }
    }];
     
     timerTicks=timerTicks+1;
    if(timerTicks==6)
     {
         [timer invalidate];
         NSLog(@"ran into maximum time");
          [HUD hide:YES];
     }
    
}

-(void)removeViewsShowTemplateChoices:(PFObject *) tmpMaker
{
    //remove views with animation
    [self.femaleButton removeWithSinkAnimation:2];
    [self.maleButton removeWithSinkAnimation:2];
    [self.nameTextField removeWithSinkAnimation:2];
    [self.phoneTextField removeWithSinkAnimation:2];
    [self.childTemplateTableView removeWithSinkAnimation:3];
    [self.templatePickerView removeWithSinkAnimation:3];
    [self.nameTextField removeWithSinkAnimation:3];
     [self.setProfileLabel removeWithSinkAnimation:3];
     [self.chooseGenderLabel removeWithSinkAnimation:3];
     [self.phoneLabel removeWithSinkAnimation:3];
     [self.nameLabel removeWithSinkAnimation:3];
    [self.submitProfileButton removeWithSinkAnimation:3];
    
    
    
    UILabel *templatePicker = [[UILabel alloc] initWithFrame:CGRectMake(0,60,320,60)];
    templatePicker.font = [UIFont systemFontOfSize:20];
    templatePicker.text = @"Pick One Of These Pre-Set Templates For Your Case";
    templatePicker.textAlignment = NSTextAlignmentCenter;
    
    templatePicker.numberOfLines=2;
    
    
    [self.view BounceAddTheView:templatePicker];
    
  
}

-(NSString *)createTemplateXMLFunction:(NSString *)userName
{
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
    
    [xmlWriter writeStartElement:@"PREFERENCES"];
    
    [xmlWriter writeStartElement:@"COUNTRY"];
    [xmlWriter writeCharacters:@"CA"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"GENDER"];
    [xmlWriter writeCharacters:gender];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"SHOWNAME"];
    [xmlWriter writeCharacters:showName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CELLNUMBER"];
    [xmlWriter writeCharacters:phoneNum];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"TEMPLATEID1"];
    [xmlWriter writeCharacters:selectedTemplate1];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"TEMPLATEID2"];
    [xmlWriter writeCharacters:selectedTemplate2];
    [xmlWriter writeEndElement];
   
    
    //close preferences element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
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
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
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
   return templatePickerParentChoices.count;
}

#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    
    //remove everything from the 2nd table/wheel
    [templatePickerActiveChoices removeAllObjects];
    
    //get the selected parent template object
    PFObject *selectedParentTemplateObj = [templatePickerParentChoices objectAtIndex:row];
    
    //loop through and add to the active templates in the 2nd table/wheel only the ones that match that selected parent template.
    for (PFObject *templateObj in templatePickerChoices)
    {
        PFObject *pointerObj = [templateObj objectForKey:@"parenttemplateid"];
        if([pointerObj.objectId isEqualToString:selectedParentTemplateObj.objectId])
        {
            [templatePickerActiveChoices addObject:templateObj];
            
        }
    }
    if(templatePickerActiveChoices.count ==0)
    {
        //show alert view saying theres no choices for this parent template yet
          [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Choices Yet", nil) message:NSLocalizedString(@"There are no child templates for this parent template yet", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    [self.childTemplateTableView reloadData];
    
    selectedTemplate1 = selectedParentTemplateObj.objectId;
    
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
        
        
        // Setup label properties - frame, font, colors etc
        tView.frame = view.bounds;
        tView.textAlignment = NSTextAlignmentCenter;
        tView.numberOfLines = 2;
        
        
        tView.font = [UIFont systemFontOfSize:12];
    }

    PFObject *templateObject = [templatePickerParentChoices objectAtIndex:row];
    NSString *stringToReturn = [templateObject objectForKey:@"description"];
    
    tView.text = stringToReturn;
    
    return tView;
}

#pragma mark UITableViewDelegateMethods
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return templatePickerActiveChoices.count;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"childTemplateCaseCell" forIndexPath:indexPath];


    UILabel *templateDescLabel = (UILabel *)[cell viewWithTag:1];
    
    templateDescLabel.text = [[templatePickerActiveChoices objectAtIndex:indexPath.row] objectForKey:@"description"];
    
    return cell;
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *selectedTemplateObject = [templatePickerActiveChoices objectAtIndex:indexPath.row];
    
    
    selectedTemplate2=selectedTemplateObject.objectId;
    
    
}

@end
