//
//  setProfileViewController2.m
//  findMe
//
//  Created by Brian Allen on 2015-08-10.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "setProfileViewController2.h"
#import "Parse/Parse.h"
#import "MBProgressHUD.h"
#import "XMLWriter.h"
#import "UIView+Animation.h"
#import <DigitsKit/DigitsKit.h>
#import "mapPinViewController.h"
#import "ErrorHandlingClass.h"

@interface setProfileViewController2 ()

@end

@implementation setProfileViewController2

MBProgressHUD *HUD;
int timerTicks2 =0;
UIImageView *phoneSearchersView;
int selectedPic2 = 1;
 CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationText;
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

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
        
        NSString *userShowName =  [currentUser objectForKey:@"showName"];
        NSString *userPhoneNum = [currentUser objectForKey:@"cellNumber"];
        NSString *userGender = [currentUser objectForKey:@"gender"];
        NSString *userEmail = [currentUser objectForKey:@"email"];
        NSString *firstName = [currentUser objectForKey:@"firstName"];
        NSString *lastName = [currentUser objectForKey:@"lastName"];
        
        self.usernameTextField.text = userShowName;
        self.gender = userGender;
        self.emailAddress = userEmail;
        self.phoneNumber = userPhoneNum;
        self.firstName = firstName;
        self.lastName = lastName;
        
        [self.genderSelectBtn setTitle:userGender forState:UIControlStateNormal];
        
    }
    else
    {
        NSString *userShowName = [currentUser objectForKey:@"username"];
        self.usernameTextField.text = userShowName;

    }
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardDidHideNotification object:nil];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    
    // unregister for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    /*
     UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Test This", nil) message:NSLocalizedString(@"Test", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] ;
    errorAlert.tag = 101;
    [errorAlert show];
    */
    
    self.phoneTextField.delegate = self;
    self.usernameTextField.delegate = self;
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    
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

-(void)viewDidLayoutSubviews
{
    
    /*
    CGRect scrollViewBounds = self.scrollView.bounds;
    CGRect containerViewBounds = self.contentView.bounds;
    
    UIEdgeInsets scrollViewInsets = UIEdgeInsetsZero;
    scrollViewInsets.top = scrollViewBounds.size.height/2.0;
    scrollViewInsets.top -= self.contentView.bounds.size.height/2.0;
    scrollViewInsets.top = 0;
    
    scrollViewInsets.bottom = scrollViewBounds.size.height/2.0;
    scrollViewInsets.bottom -= self.contentView.bounds.size.height/2.0;
    scrollViewInsets.bottom += 1;
    
    //scrollViewInsets.bottom = 245;
    //self.scrollView.bounces = NO;
    
    self.scrollView.contentInset = scrollViewInsets;
    */
}

-(void)saveProfilePress:(id)sender
{
    if(self.usernameTextField.text.length == 0)
    {
      [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing User Name", nil) message:NSLocalizedString(@"Please enter a user name before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
                                    
        return;
        
    }
    
    /*
     if(self.phoneTextField.text.length == 0)
     {
     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Phone Number", nil) message:NSLocalizedString(@"Please enter a valid phone number before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
     return;
     
     }
     */
    
    if(self.gender.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Gender", nil) message:NSLocalizedString(@"Please select a gender before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    //passed validation, run xml to create new user
    
    self.username = self.usernameTextField.text;
    self.firstName = self.firstNameTextField.text;
    self.lastName = self.lastNameTextField.text;
    
    
    if([self.phoneNumber length] <=0)
    {
        self.phoneNumber = @"None Entered";
        
    }
    
    PFUser *currentUser = [PFUser currentUser];
    
    /*
     NSString *userShowName =  [currentUser objectForKey:@"username"];
     NSString *userPhoneNum = [currentUser objectForKey:@"cellNumber"];
     NSString *userGender = [currentUser objectForKey:@"gender"];
     NSString *userEmail = [currentUser objectForKey:@"email"];
     */
    
    //set user properties to parse true user account
    
    if([self.countryName length]<1)
    {
        self.countryName = @"CA";
    }
    if([self.firstName length]<1)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing First Name", nil) message:NSLocalizedString(@"Please enter a first name before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    if([self.lastName length]<1)
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Last Name", nil) message:NSLocalizedString(@"Please enter a last name before submitting", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    
    [currentUser setObject:self.username forKey:@"showName"];
    [currentUser setObject:self.gender forKey:@"gender"];
    [currentUser setObject:self.firstName forKey:@"firstName"];
    [currentUser setObject:self.lastName forKey:@"lastName"];
    [currentUser setObject:self.countryName forKey:@"country"];
    
    //save profile picture for current user
    if(self.selectedProfileImageView.image != NULL)
    {
        NSData *data = UIImageJPEGRepresentation(self.selectedProfileImageView.image, 0.8f);
        
        PFFile *imageFile = [PFFile fileWithName:@"profileImage.jpg" data:data];
        [currentUser setObject:imageFile forKey:@"profileImage"];

    }
    
    BOOL saveSuccess= [currentUser save];
    if(saveSuccess==NO)
    {
        
        BOOL errorCheck = [self displayErrorsBoolean:@"p1"];
        
        return;
    }
    //create new case with this user.
    if(![self.openingMode isEqualToString:@"HomeScreen"])
    {
        self.itsMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
        
        // Set the access control list to current user for security purposes
        PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [itsMTLACL setPublicReadAccess:YES];
        [itsMTLACL setPublicWriteAccess:YES];
        
        self.itsMTLObject.ACL = itsMTLACL;
        
        BOOL saveSuccess = [self.itsMTLObject save];
        if(saveSuccess ==NO)
        {
             BOOL errorCheck = [self displayErrorsBoolean:@"p2"];
            
                                           
        }
        
        // Associate the device with a user
        PFInstallation *installation = [PFInstallation currentInstallation];
        installation[@"user"] = [PFUser currentUser];
        installation[@"itsMTL"] = self.itsMTLObject.objectId;
        BOOL installSaveSuccess = [installation saveInBackground];
        if(installSaveSuccess==NO)
        {
            {
                 BOOL errorCheck = [self displayErrorsBoolean:@"p3"];
                
            
            }
 
        }
    }
    
    //get the ID and run the XML with the case info.
    NSString *itsMTLObjectID = self.itsMTLObject.objectId;
    
    if([itsMTLObjectID length] ==0)
    {
        itsMTLObjectID = self.homeScreenMTLObjectID;
    }
    
    //NSString *hardcodedXMLString = @"<PAYLOAD><USEROBJECTID>4OvTmAzGE7</USEROBJECTID><LAISO>EN</LAISO><PREFERENCES><SHOWNAME>Rose</SHOWNAME><COUNTRY>CA</COUNTRY><GENDER>F</GENDER><TEMPLATEID1>01VURH6zGz</TEMPLATEID1><TEMPLATEID2>9XXwNvkFTI</TEMPLATEID2></PREFERENCES></PAYLOAD>";
    
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
                                  
                                    BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"p4" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:self.itsMTLObject];
                                    
                                    if(errorCheck)
                                    {
                                        NSLog(@"got to point of saving parse user to MTL");

                                        [HUD hide:NO];
                                        
                                        [self.itsMTLObject setObject:currentUser forKey:@"ParseUser"];
                                       BOOL saveSuccess = [self.itsMTLObject save];
                                        
                                        if(saveSuccess==FALSE)
                                        {
                                            
                                             BOOL errorCheck = [self displayErrorsBoolean:@"p5"];
                                            
                                            return;
                                        }
                                        else
                                        {
                                            NSLog(@"calling delegate to dismiss the set profile controller");
                                             [self.delegate setNewProfile2:self.itsMTLObject];
                                        }
                                  
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
    self.gender = @"Male";
    [self.maleButton setImage:[UIImage imageNamed:@"ico_male-selected@3x.png"] forState:UIControlStateNormal];
    [self.femaleButton setImage:[UIImage imageNamed:@"ico_female@3x.png"] forState:UIControlStateNormal];
    
}

-(IBAction)selectedFemale:(id)sender
{
    self.gender = @"Female";
    [self.femaleButton setImage:[UIImage imageNamed:@"ico_female-selected@3x.png"] forState:UIControlStateNormal];
    [self.maleButton setImage:[UIImage imageNamed:@"ico_male@3x.png"] forState:UIControlStateNormal];
}
-(IBAction)submitProfile:(id)sender
{
    [self saveProfilePress:self];
    
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
    
    if(selectedPic2 ==1)
    {
        //change to pic 2
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotoguy1.jpg"];
        selectedPic2 = 2;
        
    }
    else if(selectedPic2==2)
        
    {
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman1.jpg"];
        selectedPic2 = 3;
    }
    else if(selectedPic2==3)
    {
        phoneSearchersView.image = [UIImage imageNamed:@"stockphotowoman2.jpg"];
        selectedPic2=1;
        
    }
    
}

- (void)timerFired:(NSTimer *)timer {
    
    NSLog(@"timer fired");
    //check the parse object to see if it is updated
    
    [self.itsMTLObject fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //do stuff with object.
        
        //brian sep6
        NSString *responseString = @"";
        BOOL errorCheck = [ErrorHandlingClass checkForErrors:responseString errorCode:@"p101" returnedError:error ParseUser:[PFUser currentUser] MTLOBJ:self.itsMTLObject];
        
        if(errorCheck)
        {
        
        PFObject *templateMakerObj = [object objectForKey:@"templateMaker"];
        
        //note November 1
        //look at timestamp at time of sending request for profile maker, then poll every few seconds until the updatedTimestamp for the itsMTLObject is changed
        //Make sure the updated timestamp for templateMakerObject is
        
        if(templateMakerObj != nil)
        {
            //stop the timer
            [timer invalidate];
            timerTicks2 = 0;
            NSString *tempMakerID = templateMakerObj.objectId;
            
            NSLog(@"got a template maker with this ID: %@", tempMakerID);
            [HUD hide:YES];
            
            //show button after this step
            [phoneSearchersView removeWithSinkAnimation:3];
            UIAlertView *templateSuccess =  [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Profile Info Set", nil) message:@"Profile Set" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [templateSuccess show];
            
            [self.delegate setNewProfile2:object];
            
            return;
            
            
            // [self removeViewsShowTemplateChoices:(templateMakerObj)];
        }
            }
    }];
    
    timerTicks2=timerTicks2+1;
    if(timerTicks2==6)
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
    [xmlWriter writeCharacters:self.username];
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
    [xmlWriter writeCharacters:@"blank"];
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
    // save the text view that is being edited
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // release the selected text view as we don't need it anymore
    self.activeTextField = nil;
}

- (void)keyboardWasShown:(NSNotification *)aNotification
{
    // keyboard frame is in window coordinates
    NSDictionary *userInfo = [aNotification userInfo];
    CGRect keyboardInfoFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // get the height of the keyboard by taking into account the orientation of the device too
    CGRect windowFrame = [self.view.window convertRect:self.view.frame fromView:self.view];
    CGRect keyboardFrame = CGRectIntersection (windowFrame, keyboardInfoFrame);
    CGRect coveredFrame = [self.view.window convertRect:keyboardFrame toView:self.view];
    
    // add the keyboard height to the content insets so that the scrollview can be scrolled
    UIEdgeInsets contentInsets = UIEdgeInsetsMake (0.0, 0.0, coveredFrame.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // make sure the scrollview content size width and height are greater than 0
    [self.scrollView setContentSize:CGSizeMake (self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    
    // scroll to the text view
  
  [self.scrollView setContentOffset:CGPointMake(0, 200) animated:NO];
    
}

// Called when the UIKeyboardWillHideNotification is received
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    // scroll back..
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //put the string of the text field onto a label now in the same cell
    //put -100 so it doesn't interfere with the uilabel tag of 3 in every cell
    
    [textField resignFirstResponder];
    
    [self dismissKeyboard];
    
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
    
    
    [self.selectProfileImgButton setImage:image forState:UIControlStateNormal];
    self.selectProfileImgButton.layer.cornerRadius = 45.0f;
    self.selectProfileImgButton.layer.masksToBounds = YES;
    
    self.selectedProfileImageView.image = image;
    self.selectedProfileImageView.alpha = 0.3;
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

-(IBAction)confirmPhone:(id)sender
{
    [[Digits sharedInstance] authenticateWithCompletion:^
     (DGTSession* session, NSError *error) {
         if (session) {
             // Inspect session/error objects
             self.phoneNumber = session.phoneNumber;
             
         }
     }];
}

-(IBAction)locationPicker
{
    self.locationPermissionPopup = [[UIView alloc] initWithFrame:CGRectMake(20,100,280,200)];
    self.locationPermissionPopup.backgroundColor = [UIColor whiteColor];
    self.locationPermissionPopup.layer.cornerRadius = 5.0f;
    
    NSString *locationPermissionText = @"To improve your matching with other users and show you more relevant content, the app requires a default location which can be changed at any time in the future.";
    
    UILabel *locationPermissionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,20,280,40)];
    locationPermissionLabel.numberOfLines = 4;
    locationPermissionLabel.text = locationPermissionText;
    [self.locationPermissionPopup addSubview:locationPermissionLabel];
    
    UIButton *setLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(40,100,100,40)];
    [setLocationButton setTitle:@"Set Location" forState:UIControlStateNormal];
    [setLocationButton setBackgroundColor:[UIColor greenColor]];
    
    UIButton *rejectLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(150,100,100,40)];
    rejectLocationButton.backgroundColor = [UIColor redColor];
    [rejectLocationButton setTitle:@"Reject Location" forState:UIControlStateNormal];
    [rejectLocationButton addTarget:self action:@selector(rejectLocationPress:) forControlEvents:UIControlEventTouchUpInside];
    
    [setLocationButton addTarget:self action:@selector(setLocationBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.locationPermissionPopup addSubview:setLocationButton];
    [self.locationPermissionPopup addSubview:rejectLocationButton];
    
    [self.view addSubview:self.locationPermissionPopup];
    
}

-(void)setLocationBtnPress:(id)sender
{
    if (self.locationManager==nil) {
        self.locationManager = [[CLLocationManager alloc]init];
    }
    self.locationManager.delegate = self;
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) {
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {
            NSString *title;
            title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
            NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Settings", nil];
            [alertView setTag:1001];
            [alertView show];
        }
        else{
            NSString *titles;
            titles = @"Title";
            NSString *msg = @"Location services are off. To use location services you must turn on 'Always' in the Location Services Settings from Click on 'Settings' > 'Privacy' > 'Location Services'. Enable the 'Location Services' ('ON')";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titles
                                                                message:msg
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        }
        
        
    }
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        {
            [self.locationManager requestWhenInUseAuthorization];
            
        }
        else if (status==kCLAuthorizationStatusAuthorizedWhenInUse)
        {
            [self.locationManager startUpdatingLocation];
            UIButton *sendingButton = (UIButton *)sender;
            [sendingButton.superview removeFromSuperview];
            
            //show a popup with a map picker
            mapPinViewController *mpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mpvc"];
            mpvc.delegate = self;
            
            [self.navigationController pushViewController:mpvc animated:YES];

        }
        
    }
    
    
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    //show the popup with mappicker
    if(status ==kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager startUpdatingLocation];
        
        //show a popup with a map picker
        mapPinViewController *mpvc = [self.storyboard instantiateViewControllerWithIdentifier:@"mpvc"];
        mpvc.delegate = self;
        
        [self.navigationController pushViewController:mpvc animated:YES];

    }
}

-(void)rejectLocationPress:(id)sender
{
    UIButton *sendingButton = (UIButton *)sender;
    [sendingButton.superview removeFromSuperview];

    //show a country selector instead
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Here we will need ability to select country"
                                                        message:@"Future coding needed, select country"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    
}

- (void)setUserLocation:(float) latitude withLongitude:(float)longitude andLatitudeSpan:(float) latSpan andLongitudeSpan:(float) longSpan
{
    //interpret user location data
    NSString *locationString = [self getAddressFromLatLon:latitude withLongitude:longitude];
    
}

-(NSString *)getAddressFromLatLon:(double)pdblLatitude withLongitude:(double)pdblLongitude
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    CLLocation *myLocation = [[CLLocation alloc] initWithLatitude:pdblLatitude longitude:pdblLongitude];
   
    
    [geocoder reverseGeocodeLocation:myLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        // NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
            locationText =[NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                           placemark.subThoroughfare, placemark.thoroughfare,
                           placemark.postalCode, placemark.locality,
                           placemark.administrativeArea,
                           placemark.country];
            locationRetrieved = placemark.locality;
            
            NSLog(locationText);
            NSString *cityText = placemark.locality;
            NSString *stateText = placemark.administrativeArea;
            NSString *countryText = placemark.country;
            
            self.locationLabel.text = [[cityText stringByAppendingString:@", "] stringByAppendingString:stateText];
            
            self.cityName = cityText;
            self.stateName = stateText;
            self.countryName = countryText;
            
            [self.navigationController popViewControllerAnimated:NO];
            //[HUD hide:YES];
        }
        else {
            NSLog(@"%@", error.debugDescription);
            {
                [self displayErrorsBoolean:@"p102"];
                return;
            }

            [self.navigationController popViewControllerAnimated:NO];
            //[HUD hide:YES];
        }
    } ];
    
    [self.locationPermissionPopup removeFromSuperview];
    
 return locationText;
 
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==101)
    {
        strcpy(0, "bla");
    }
}

/*
//brian Sep5
-(BOOL) checkForErrors:(NSString *) returnedString errorCode:(NSString *)customErrorCode returnedError:(NSError *)error;
{
    [HUD hide:NO];
    
    if(error)
    {
        NSString *errorString = error.localizedDescription;
        NSLog(errorString);
        
        NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
        
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        errorView.tag = 101;
        [errorView show];
        
        return NO;
    }
    if([returnedString containsString:@"BROADCAST"])
    {
        //show a ui alertview with the response text
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Broadcast Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
    }
    
    if([returnedString containsString:@"ERROR"])
    {
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for Sync Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
        
        
    }
    else
    {
        return YES;
    }
    
}
*/
//brian Sep5
-(BOOL) displayErrorsBoolean:(NSString *)customErrorCode;
{
    [HUD hide:NO];
    
    NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
        
    UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    errorView.tag = 101;
    [errorView show];
        
    return NO;
}


@end


