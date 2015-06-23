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


MBProgressHUD *HUD;
PFObject *itsMTLObject;
int timerTicks =0;
UIImageView *phoneSearchersView;
int selectedPic = 1;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    
    self.navigationController.navigationBarHidden = NO;
    
    //if it's being opened from the home screen, it should query for the latest profile information for this user.
    
    PFUser *currentUser = [PFUser currentUser];
    if([self.openingMode isEqualToString:@"HomeScreen"])
    {
        
       NSString *userShowName =  [currentUser objectForKey:@"username"];
       NSString *userPhoneNum = [currentUser objectForKey:@"cellNumber"];
       NSString *userGender = [currentUser objectForKey:@"gender"];
        NSString *userEmail = [currentUser objectForKey:@"email"];
    
        self.usernameTextField.text = userShowName;
        self.phoneTextField.text = userPhoneNum;
        self.emailTextField.text = userEmail;
        self.gender = userGender;
        self.emailAddress = userEmail;
        
        [self.genderSelectBtn setTitle:userGender forState:UIControlStateNormal];
        
    }
    else
    {
        NSString *userShowName = [currentUser objectForKey:@"username"];
        self.usernameTextField.text = userShowName;
         NSString *userEmail = [currentUser objectForKey:@"email"];
        self.emailTextField.text = userEmail;
    }
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.phoneTextField.delegate = self;
    self.usernameTextField.delegate = self;
    
    self.navigationItem.title = @"Edit Profile";
    
    UIBarButtonItem *SaveItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:nil];
    [SaveItem setAction:@selector(saveProfilePress:)];
    
    NSArray *actionButtonItems = @[SaveItem];
    self.navigationItem.rightBarButtonItems = actionButtonItems;
    
    if([self.openingMode isEqualToString:@"HomeScreen"])
    {
        
    }
    else
    {
        [self.navigationItem setHidesBackButton:YES];
    }
    
    
    // Do any additional setup after loading the view.
    
    //brian feb 5
    //commenting out template information as it's no longer relevant
    /*
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
    
    //self.childTemplateTableView.delegate = self;
    //self.childTemplateTableView.dataSource = self;
    */
    
}

-(void)saveProfilePress:(id)sender
{
    if(self.usernameTextField.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Name", nil) message:NSLocalizedString(@"Please enter a name before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
    
    if(self.phoneTextField.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Phone Number", nil) message:NSLocalizedString(@"Please enter a valid phone number before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
        
    }
    
    if(self.gender.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Gender", nil) message:NSLocalizedString(@"Please select a gender before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }

    //passed validation, run xml to create new user
    
    self.username = self.usernameTextField.text;
    self.phoneNumber = self.phoneTextField.text;
    
    if(self.emailTextField.text.length !=0)
    {
        self.emailAddress = self.emailTextField.text;
        
    }
    
    PFUser *currentUser = [PFUser currentUser];
    
    /*
    NSString *userShowName =  [currentUser objectForKey:@"username"];
    NSString *userPhoneNum = [currentUser objectForKey:@"cellNumber"];
    NSString *userGender = [currentUser objectForKey:@"gender"];
    NSString *userEmail = [currentUser objectForKey:@"email"];
    */
    
    //set user properties to parse true user account
    [currentUser setObject:self.username forKey:@"username"];
    [currentUser setObject:self.phoneNumber forKey:@"cellNumber"];
    [currentUser setObject:self.gender forKey:@"gender"];
    [currentUser setObject:self.emailAddress forKey:@"email"];
    [currentUser save];
    
    //create new case with this user.
    if(![self.openingMode isEqualToString:@"HomeScreen"])
    {
        
        
        itsMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
        [itsMTLObject setObject:currentUser forKey:@"ParseUser"];
        
        // Set the access control list to current user for security purposes
        PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [itsMTLACL setPublicReadAccess:YES];
        [itsMTLACL setPublicWriteAccess:YES];
        
        itsMTLObject.ACL = itsMTLACL;
        
        [itsMTLObject save];
        
        // Associate the device with a user
        PFInstallation *installation = [PFInstallation currentInstallation];
        installation[@"user"] = [PFUser currentUser];
        installation[@"itsMTL"] = itsMTLObject.objectId;
        [installation saveInBackground];
    }

   
    
    //get the ID and run the XML with the case info.
    NSString *itsMTLObjectID = itsMTLObject.objectId;
    
    if([itsMTLObjectID length] ==0)
    {
        itsMTLObjectID = self.homeScreenMTLObjectID;
    }
    
    NSString *hardcodedXMLString = @"<PAYLOAD><USEROBJECTID>4OvTmAzGE7</USEROBJECTID><LAISO>EN</LAISO><PREFERENCES><SHOWNAME>Rose</SHOWNAME><COUNTRY>CA</COUNTRY><GENDER>F</GENDER><TEMPLATEID1>01VURH6zGz</TEMPLATEID1><TEMPLATEID2>9XXwNvkFTI</TEMPLATEID2></PREFERENCES></PAYLOAD>";
    
    NSString *xmlGeneratedString = [self createTemplateXMLFunction:itsMTLObjectID];
    
    //add a layer here to show pictures of beautiful people while the user is getting information
    phoneSearchersView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+40,self.view.bounds.size.width, self.view.bounds.size.height-40)];
    phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman1.jpg"];
    
    [self.view addSubviewWithFadeAnimation:phoneSearchersView duration:2 option:UIViewAnimationOptionCurveEaseIn];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0
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
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xmlGeneratedString}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        //NSString *responseText = responseString;
                                        //NSLog(responseText);
                                        [HUD hide:NO];
                                        
                                        NSString *itsMTLObjectID = itsMTLObject.objectId;
                                        
                                        if([itsMTLObjectID length] ==0)
                                        {
                                            itsMTLObjectID = self.homeScreenMTLObjectID;
                                        }
                                        [self.delegate setNewProfile:itsMTLObject];
                                        
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

-(IBAction)selectedMale:(id)sender
{
    
}

-(IBAction)selectedFemale:(id)sender
{
   
}
-(IBAction)submitProfile:(id)sender
{
    
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
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];// this will do the trick
    
}


-(void) changeSearchPicture:(NSTimer *) timer
{
    
    if(selectedPic ==1)
    {
        //change to pic 2
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotoguy1.jpg"];
        selectedPic = 2;
        
    }
    else if(selectedPic==2)
    
    {
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman1.jpg"];
        selectedPic = 3;
    }
    else if(selectedPic==3)
    {
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman2.jpg"];
        selectedPic=1;
        
    }
        
}

- (void)timerFired:(NSTimer *)timer {
    
    NSLog(@"timer fired");
//check the parse object to see if it is updated
  
    [itsMTLObject fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //do stuff with object.
        PFObject *templateMakerObj = [object objectForKey:@"templateMaker"];
        
        //note November 1
        //look at timestamp at time of sending request for profile maker, then poll every few seconds until the updatedTimestamp for the itsMTLObject is changed
        //Make sure the updated timestamp for templateMakerObject is
        
        if(templateMakerObj != nil)
        {
            //stop the timer
            [timer invalidate];
            timerTicks = 0;
            NSString *tempMakerID = templateMakerObj.objectId;
            
            NSLog(@"got a template maker with this ID: %@", tempMakerID);
            [HUD hide:YES];
          
            //show button after this step
             [phoneSearchersView removeWithSinkAnimation:3];
            UIAlertView *templateSuccess =  [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Profile Info Set", nil) message:@"Profile Set" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [templateSuccess show];
            
            [self.delegate setNewProfile:object];
            
            return;
            
            
           // [self removeViewsShowTemplateChoices:(templateMakerObj)];
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

/*
-(void)removeViewsShowTemplateChoices:(PFObject *) tmpMaker
{
    //remove views with animation
    [self.femaleButton removeWithSinkAnimation:2];
    [self.maleButton removeWithSinkAnimation:2];
    [self.nameTextField removeWithSinkAnimation:2];
    [self.phoneTextField removeWithSinkAnimation:2];
    [self.nameTextField removeWithSinkAnimation:3];
     [self.setProfileLabel removeWithSinkAnimation:3];
     [self.chooseGenderLabel removeWithSinkAnimation:3];
     [self.phoneLabel removeWithSinkAnimation:3];
     [self.nameLabel removeWithSinkAnimation:3];
    [self.submitProfileButton removeWithSinkAnimation:3];
    [phoneSearchersView removeWithSinkAnimation:3];
    
    UILabel *templatePicker = [[UILabel alloc] initWithFrame:CGRectMake(0,60,320,60)];
    templatePicker.font = [UIFont systemFontOfSize:20];
    templatePicker.text = @"Pick One Of These Pre-Set Templates For Your Case";
    templatePicker.textAlignment = NSTextAlignmentCenter;
    
    templatePicker.numberOfLines=3;
    
    [self.view BounceAddTheView:templatePicker];
    
    
    //add a UIImageView, Button, and Text section based on the selected case.
    int startyMargin = 140;
    int startxMargin = 20;
    
    int imgWidth = 90;
    int imgHeight = 90;
    
    int textimgxmargin=10;
    
    int textWidth = 60;
    int textHeight = 50;
    
    int textbuttonxmargin=10;
    
    int buttonWidth = 100;
    int buttonHeight = 50;
    
    int verticalMargin = 0;
    
    int bgVertMargin = 10;
    int bgHorizMargin = 10;
    
    
    //get number of options to show based on the template maker cases
    
    NSArray *templateMakerCases = [tmpMaker objectForKey:@"cases"];
    PFFile *templateMakerImage = [tmpMaker objectForKey:@"templateMakerImage"];
    UIImage *tmpMakerImage = [UIImage imageWithData:templateMakerImage];
    
    
    int numOptions = [templateMakerCases count];
    
    //loop through creating UI for the options to show
    for (int i = 0; i<numOptions;i++)
    {
        
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(startxMargin-bgHorizMargin,startyMargin-10,imgWidth+textWidth+buttonWidth+textimgxmargin+textbuttonxmargin+bgHorizMargin*2,imgHeight+bgVertMargin*2)];
        
        bgView.backgroundColor = [UIColor colorWithRed:0.902 green:0.98 blue:1 alpha:1]
        
        
        
        UIImageView *choice1ImageView = [[UIImageView alloc] initWithFrame:CGRectMake(startxMargin,startyMargin,imgWidth,imgHeight)];
        
        choice1ImageView.image = [UIImage imageNamed:@"sawyousubway.jpg"];
        
        int imgMidPoint = choice1ImageView.frame.origin.y+choice1ImageView.frame.size.height/2;
        
        
        UILabel *choiceLabel = [[UILabel alloc] initWithFrame:CGRectMake(textimgxmargin+choice1ImageView.frame.origin.x+choice1ImageView.frame.size.width,imgMidPoint-textHeight/2,textWidth,textHeight)];
        
        if (i==0)
        {
              choiceLabel.text = @"I just saw you";
               choice1ImageView.image = [UIImage imageNamed:@"sawyousubway.jpg"];
        }
        else
        if(i==1)
        {
            choiceLabel.text = @"I just saw 2";
               choice1ImageView.image = [UIImage imageNamed:@"thinkingaboutyou.jpg"];
        }
        else
        if(i==2)
        {
            choiceLabel.text = @"I still love you, do you love me?";
            choice1ImageView.image = [UIImage imageNamed:@"alwaysloveyou.png"];
        }
      
        choiceLabel.font = [UIFont systemFontOfSize:12];
        
        choiceLabel.numberOfLines = 2;
        
        
        UIButton *createCaseButton = [[UIButton alloc] initWithFrame:CGRectMake(choiceLabel.frame.origin.x+choiceLabel.frame.size.width+textbuttonxmargin,imgMidPoint-buttonHeight/2,buttonWidth,buttonHeight)];
        
        [createCaseButton setBackgroundColor:[UIColor blueColor]];
        
        [createCaseButton setTitle:@"Create Case" forState:UIControlStateNormal];
        
        createCaseButton.layer.cornerRadius = 9.0;
        createCaseButton.layer.masksToBounds = YES;
        
        bgView.layer.cornerRadius = 9.0;
        bgView.layer.masksToBounds = YES;
        
        choice1ImageView.layer.cornerRadius = 4.0;
        choice1ImageView.layer.masksToBounds = YES;
        
        
        [self.view BounceAddTheView:bgView];
        [self.view BounceAddTheView:choice1ImageView];
        [self.view BounceAddTheView:choiceLabel];
        [self.view BounceAddTheView:createCaseButton];
        
        startyMargin = choice1ImageView.frame.origin.y+choice1ImageView.frame.size.height + verticalMargin;
    }
    
}
*/

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
    [xmlWriter writeCharacters:self.gender];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"SHOWNAME"];
    [xmlWriter writeCharacters:self.username];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CELLNUMBER"];
    [xmlWriter writeCharacters:self.phoneNumber];
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
    
    NSInteger textFieldTag = textField.tag;
    
    switch (textFieldTag)
    {
        case 1:
        {
            //username
            self.username = textField.text;
        }
        case 2:
        {
            //phone
            self.phoneNumber = textField.text;
            
        }
        case 3:
        {
            //email
            self.emailAddress = textField.text;
        }
        case 4:
        {
            //first
            self.firstName = textField.text;
            
        }
        case 5:
        {
            //last
            self.lastName = textField.text;
            
        }
    }
    
    [textField resignFirstResponder];
    
    return YES;
}

-(IBAction)selectGender:(id)sender
{
    if(self.genderPicker ==nil)
    {
      self.genderPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(10,270,300,200)];
        self.genderPicker.alpha = 1;
        
    }
    if(self.genderPickerBGView ==nil)
    {
        self.genderPickerBGView = [[UIView alloc] initWithFrame:CGRectMake(0,230,320,500)];
        self.genderPickerBGView.backgroundColor = [UIColor blackColor];
        self.genderPickerBGView.alpha = 1;
        [self.view addSubview:self.genderPickerBGView];
        
        self.confirmGenderBTN = [[UIButton alloc] initWithFrame:CGRectMake(250,240,50,50)];
        //[self.confirmGenderBTN setTitle:@"Confirm" forState:UIControlStateNormal];
        [self.confirmGenderBTN setBackgroundColor:[UIColor clearColor]];
        [self.confirmGenderBTN addTarget:self action:@selector(confirmGender:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *acceptBtnImage = [UIImage imageNamed:@"Accept_circular_button_outline_256"];
        [self.confirmGenderBTN setBackgroundImage:acceptBtnImage forState:UIControlStateNormal];
        
        
    }
    else
    {
        [self.view addSubview:self.genderPickerBGView];
        
    }
    
    
    self.genderPicker.delegate = self;
    self.genderPicker.dataSource = self;
    
    [self.view addSubview:self.genderPicker];
    [self.view addSubview:self.confirmGenderBTN];
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
    return 4;
}

/*
 - (NSString *)pickerView:(UIPickerView *)pickerView
 titleForRow:(NSInteger)row
 forComponent:(NSInteger)component
 {
 
 
 
 return stringToReturn;
 }
 */

-(void)confirmGender:(id)sender
{
    //confirm the gender selected
    
    [self.genderPicker removeFromSuperview];
    [self.genderPickerBGView removeFromSuperview];
    [self.confirmGenderBTN removeFromSuperview];
    
}

#pragma mark -
#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    //if they pick the very last row on the wheel, they are selecting to create a new question.
    if(row ==0)
    {
        self.gender = @"Male";
        [self.genderSelectBtn setTitle:@"Male" forState:UIControlStateNormal];
        
    }
    if(row==1)
    {
        self.gender = @"Female";
        [self.genderSelectBtn setTitle:@"Female" forState:UIControlStateNormal];
        
    }
    if(row==2)
    {
        self.gender = @"Other";
        [self.genderSelectBtn setTitle:@"Other" forState:UIControlStateNormal];
        
    }
    if(row==3)
    {
        self.gender = @"Prefer Not To Say";
        [self.genderSelectBtn setTitle:@"Prefer Not To Say" forState:UIControlStateNormal];
        
    }
    
    
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
        
        tView.backgroundColor = [UIColor whiteColor];
        
        // Setup label properties - frame, font, colors etc
        tView.frame = view.bounds;
        tView.textAlignment = NSTextAlignmentCenter;
        
        tView.font = [UIFont systemFontOfSize:12];
        
        tView.alpha =1;
        
        //tView.alpha = 0.95;
        
        if(row==0)
        {
            tView.text = @"Male";
        }
        if(row==1)
        {
            tView.text = @"Female";
        }
        if(row==2)
        {
            tView.text = @"Other";
            
        }
        if(row==3)
        {
            tView.text = @"Prefer Not To Say";
        }
    }
    
    return tView;
    
}


-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}

//commenting out the pickerview and tableview delegate methods.  They are no longer needed as the app will not need to set the profile with templates anymore.
/*
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
*/


-(IBAction) setImage:(id)sender
{
        self.imagePicker = [[GKImagePicker alloc] init];
        self.imagePicker.cropSize = CGSizeMake(300, 300);
        
        [self.imagePicker.imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        self.imagePicker.delegate = self;
        
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];

}

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
    //UIImage *scaledImage = [self imageWithImage:image scaledToSize:CGSizeMake(150, 150)];
    self.profileImage1.image = image;
    
    
    //NSLog(@"view %f %f, image %f %f", self.currentCardView.cardImage.frame.size.width, self.currentCardView.cardImage.frame.size.height, image.size.width, image.size.height);
    
    /*[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
     animations:^{
     imageUploadView.alpha = 0;
     }
     completion:^(BOOL completed){
     [imageUploadView removeFromSuperview];
     }];
     */
    
    //[self.imageView setImage:image];
    //[self dismissViewControllerAnimated:YES completion:nil];
    [imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) locationToggle:(id)sender
{
    if(self.locationPermission ==TRUE)
    {
        self.locationPermission = FALSE;
        self.locationPermissionLabel.text = @"Enable location tracking to help find matches.";
    }
    else
    {
        self.locationPermission = TRUE;
       
         self.locationPermissionLabel.text = @"Your location will be used to help find matches.";
    }
}


@end
