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
    PFObject *itsMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
    
    [itsMTLObject setObject:currentUser forKey:@"ParseUser"];
    
    [itsMTLObject save];
    
    //get the ID and run the XML with the case info.
    NSString *itsMTLObjectID = itsMTLObject.objectId;
    
    //add a progress HUD to show it is sending the XML with the case info
    
    NSString *hardcodedXMLString = @"<PAYLOAD><USEROBJECTID>4OvTmAzGE7</USEROBJECTID><LAISO>EN</LAISO><PREFERENCES><SHOWNAME>Rose</SHOWNAME><COUNTRY>CA</COUNTRY><GENDER>F</GENDER><TEMPLATEID1>01VURH6zGz</TEMPLATEID1><TEMPLATEID2>9XXwNvkFTI</TEMPLATEID2></PREFERENCES></PAYLOAD>";
    
    NSString *xmlGeneratedString = [self createTemplateXMLFunction:itsMTLObjectID];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Updating The Properties And Answers";
    [HUD show:YES];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"inboundZITSMTL"
                       withParameters:@{@"payload": xmlGeneratedString}
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
