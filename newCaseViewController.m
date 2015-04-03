//
//  newCaseViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-11-07.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "newCaseViewController.h"
#import <Parse/Parse.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "UIImageView+Scaling.h"
#import "UIView+Animation.h"
#import "XMLWriter.h"
#import "MBProgressHUD.h"
#import "CaseDetailsViewController.h"
#import "CaseDetailsEmailViewController.h"
#import "BaseCaseDetailsSlidingViewController.h"


@interface newCaseViewController ()

@end

@implementation newCaseViewController

NSArray *CaseOptionImages;
NSArray *templatePickerChoices;
NSMutableArray *templatePickerParentChoices;
NSMutableArray *templatePickerActiveChoices;
int pickedParentTemplateIndex;

NSString *selectedTemplate1;
NSString *selectedTemplate2;

NSNumber *previousTemplateTimestamp;
PFObject *queryReturnPFObject;

int timerTickCheck =0;

MBProgressHUD *HUD;

//location manager variables

CLGeocoder *geocoder;
CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;

@synthesize CaseOptionsCollectionView;
@synthesize TemplateSecondLevelTableView;
@synthesize itsMTLObject;
@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //location manager instance variable allocs
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
     locationManager.delegate = self;
    
    //populate the URL's of images from parse.
    [self queryForTemplates];
    
    CaseOptionsCollectionView.dataSource = self;
    CaseOptionsCollectionView.delegate = self;
    
    
    [CaseOptionsCollectionView reloadData];
    
    [self getLocation:self];
    
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

-(void) viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:NO];
    self.navigationController.navigationBarHidden = NO;
}

-(void) queryForTemplates
{
    //retrieve the five parent templatePickerChoices from Parse
    //templatePickerChoices =
    PFQuery *templateQuery = [PFQuery queryWithClassName:@"Templates"];
    //[templateQuery selectKeys:@[@"parenttemplateid"]];
    
    
    [templateQuery whereKey:@"laiso" equalTo:@"EN"];
    
    templatePickerChoices = [templateQuery findObjects];
    
    templatePickerParentChoices = [[NSMutableArray alloc] init];
    templatePickerActiveChoices = [[NSMutableArray alloc] init];
    
    for(PFObject *templateObject in templatePickerChoices)
    {
        NSLog(@"numberofKeys");
        NSLog(@"%i",templateObject.allKeys.count);
    
        
     
       PFObject *theParentObj = [templateObject objectForKey:@"parenttemplateid"];
        
        /*
        NSString *objID = [templateObject valueForKey:@"parentemplateid"];
        
       if(objID==Nil)
       {
          objID = @"no";
           
       }
        else
        {
            objID = @"yes";
            
        }
        */
        
        if([theParentObj isEqual:[NSNull null]])
        {
            [templatePickerParentChoices addObject:templateObject];
            
            
        }
    }

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

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return templatePickerParentChoices.count;
    
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"caseOptionCell";
    
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *caseImageView= (UIImageView *)[cell viewWithTag:100];
    
    //check to see if a button is already created, if not, create a button overlayed on top of the UIImageView.  This button when tapped will activate the next step for the index of its displayed template.
    
    UIButton *templateChooseButton = (UIButton *)[cell viewWithTag:indexPath.row+1];
    
    if(templateChooseButton ==nil)
    {
        UIButton *templateChooseButton = [[UIButton alloc] initWithFrame:caseImageView.bounds];
        
        templateChooseButton.tag = indexPath.row+1;
        
        [templateChooseButton addTarget:self action:@selector(parentTemplatePicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell addSubview:templateChooseButton];
        
        
    }
    
    PFObject *templateObject = [templatePickerParentChoices objectAtIndex:indexPath.row];
    
    NSString *imgURL = [templateObject objectForKey:@"imageURL"];
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    
    [caseImageView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    UILabel *descrLabel = (UILabel *) [cell viewWithTag:101];
    
    descrLabel.text = [templateObject objectForKey:@"description"];
    
    descrLabel.font = [UIFont systemFontOfSize:10];
    
    
    //caseImageView.image = [UIImage imageNamed:[recipeImages objectAtIndex:indexPath.row]];
    
    return cell;
}

-(void) parentTemplatePicked:(UIButton *)sender
{
    int btnTag = sender.tag;
    
    //select the next template display based on this button.

    NSLog(@"%i",btnTag);
    
    pickedParentTemplateIndex = btnTag -1;
    
    
    
    //remove all the templatePicker Parent Views With An Interesting Animation
    [self removeTemplatePickerParentViews];
    
    //remove everything from the previous active choices
    [templatePickerActiveChoices removeAllObjects];
    
    //get the selected parent template object
    PFObject *selectedParentTemplateObj = [templatePickerParentChoices objectAtIndex:btnTag-1];
    selectedTemplate1 = selectedParentTemplateObj.objectId;
    
    
    //loop through and add to the active templates in the 2nd table/wheel only the ones that match that selected parent template.
    for (PFObject *templateObj in templatePickerChoices)
    {
        PFObject *pointerObj = [templateObj objectForKey:@"parenttemplateid"];
            if ([pointerObj isEqual:[NSNull null]])
                {
                 
                }
                else
                {
                if([pointerObj.objectId isEqualToString:selectedParentTemplateObj.objectId])
                {
                    [templatePickerActiveChoices addObject:templateObj];
            
                }
             }
    }
    if(templatePickerActiveChoices.count ==0)
    {
        //show alert view saying theres no choices for this parent template yet
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Choices Yet", nil) message:NSLocalizedString(@"There are no child templates for this parent template yet", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
   
    TemplateSecondLevelTableView = [[UITableView alloc] initWithFrame:CGRectMake(0,150,320,400)];
    TemplateSecondLevelTableView.dataSource = self;
    TemplateSecondLevelTableView.delegate = self;
    
    [TemplateSecondLevelTableView reloadData];
    
    [self.view BounceAddTheView:TemplateSecondLevelTableView];
    
    
    //[self.childTemplateTableView reloadData];
    
}

-(void) removeTemplatePickerParentViews
{
    int j=-0;
    for (UICollectionViewCell *templateCell in [CaseOptionsCollectionView visibleCells])
    {
        j=j+1;
        
        if(j==[[CaseOptionsCollectionView visibleCells] count])
        {
            [templateCell BounceViewThenFadeAlpha:templateCell shouldRemoveParentView:@"yes"];
        }
        else
        {
           [templateCell BounceViewThenFadeAlpha:templateCell shouldRemoveParentView:@"no"];
        }
    }
    
   
    //[self showSecondTierTemplateOptions];
    
}

//create 2nd tier template option views
-(void) showSecondTierTemplateOptions
{
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
    
    /*
    NSArray *templateMakerCases = [tmpMaker objectForKey:@"cases"];
    PFFile *templateMakerImage = [tmpMaker objectForKey:@"templateMakerImage"];
    UIImage *tmpMakerImage = [UIImage imageWithData:templateMakerImage];
    */
    
    int numOptions = 3;
    
    //loop through creating UI for the options to show
    for (int i = 0; i<numOptions;i++)
    {
        
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(startxMargin-bgHorizMargin,startyMargin-10,imgWidth+textWidth+buttonWidth+textimgxmargin+textbuttonxmargin+bgHorizMargin*2,imgHeight+bgVertMargin*2)];
        
        bgView.backgroundColor = [UIColor colorWithRed:0.902 green:0.98 blue:1 alpha:1] /*#e6faff*/;
        
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
  
    static NSString *CellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    
    UILabel *templateDescLabel = (UILabel *)[cell viewWithTag:51];
    
    if(templateDescLabel ==nil)
    {
        templateDescLabel = [[UILabel alloc] init];
        templateDescLabel.tag = 51;
        [cell addSubview:templateDescLabel];
        
    }
    
    UIImageView *choice1ImageView = (UIImageView *)[cell viewWithTag:52];
    
    if(choice1ImageView ==nil)
    {
        choice1ImageView = [[UIImageView alloc] init];
        choice1ImageView.tag = 52;
        [cell addSubview:choice1ImageView];
        
    }
    
    UIButton *createCaseButton = (UIButton *)[cell viewWithTag:60+indexPath.row];
    
    if(createCaseButton ==nil)
    {
        createCaseButton = [[UIButton alloc] init];
        createCaseButton.tag = 60+indexPath.row;
        [createCaseButton addTarget:self action:@selector(secondTemplatePicked:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell addSubview:createCaseButton];
        
    }
    
    [createCaseButton setBackgroundColor:[UIColor blueColor]];
    
    [createCaseButton setTitle:@"Create Case" forState:UIControlStateNormal];
    
    int startyMargin = 20;
    int startxMargin = 20;
    
    int imgWidth = 90;
    int imgHeight = 90;
    
    int textimgxmargin=10;
    
    int textWidth = 90;
    int textHeight = 90;
    
    int textbuttonxmargin=10;
    
    int buttonWidth = 80;
    int buttonHeight = 80;
    
    int verticalMargin = 0;
    
    int bgVertMargin = 10;
    int bgHorizMargin = 10;
    
    
    choice1ImageView.frame = CGRectMake(startxMargin,startyMargin,imgWidth,imgHeight);
     int imgMidPoint = choice1ImageView.frame.origin.y+choice1ImageView.frame.size.height/2;
    
    templateDescLabel.frame = CGRectMake(textimgxmargin+choice1ImageView.frame.origin.x+choice1ImageView.frame.size.width,imgMidPoint-textHeight/2,textWidth,textHeight);
    templateDescLabel.font = [UIFont systemFontOfSize:10];
    templateDescLabel.numberOfLines = 5;
    
    PFObject *selectedTemplateObject = [templatePickerActiveChoices objectAtIndex:indexPath.row];
    templateDescLabel.text = (NSString *)[selectedTemplateObject objectForKey:@"description"];
    
    
    createCaseButton.frame = CGRectMake(templateDescLabel.frame.origin.x+templateDescLabel.frame.size.width+textbuttonxmargin,imgMidPoint-buttonHeight/2,buttonWidth,buttonHeight);
    
    //createCaseButton.titleLabel.numberOfLines = 2;
    UILabel *buttonTitleLabel = createCaseButton.titleLabel;
    buttonTitleLabel.numberOfLines = 2;
    buttonTitleLabel.font = [UIFont systemFontOfSize:12];
    
    
    //set rounded corners on UIViews
    createCaseButton.layer.cornerRadius = 9.0;
    createCaseButton.layer.masksToBounds = YES;
    
    //bgView.layer.cornerRadius = 9.0;
    //bgView.layer.masksToBounds = YES;
    
    choice1ImageView.layer.cornerRadius = 4.0;
    choice1ImageView.layer.masksToBounds = YES;
    
    choice1ImageView.image = [UIImage imageNamed:@"thinkingaboutyou.jpg"];
    
    //templateDescLabel.text = [[templatePickerActiveChoices objectAtIndex:indexPath.row] objectForKey:@"description"];
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //PFObject *selectedTemplateObject = [templatePickerActiveChoices objectAtIndex:indexPath.row];
    
    
   // selectedTemplate2=selectedTemplateObject.objectId;
    
    
}

-(void)secondTemplatePicked:(UIButton *) sendingButton
{
    //create a new case with the two templates.
    
    int indexOfButton = sendingButton.tag-60;
    
    //second level template
    PFObject *secondTemplate = [templatePickerActiveChoices objectAtIndex:indexOfButton];
    selectedTemplate2 = secondTemplate.objectId;
    
    /*
    //create parse objects and create the new case for the template
    PFUser *currentUser = [PFUser currentUser];
    
    //create new case with this user.
    itsMTLObject = [PFObject objectWithClassName:@"ItsMTL"];
    [itsMTLObject setObject:currentUser forKey:@"ParseUser"];
    [itsMTLObject setObject:@"newtemptest" forKey:@"showName"];
    
    // Set the access control list to current user for security purposes
    PFACL *itsMTLACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [itsMTLACL setPublicReadAccess:YES];
    [itsMTLACL setPublicWriteAccess:YES];
    
    itsMTLObject.ACL = itsMTLACL;
    
    [itsMTLObject save];
    
    //set user properties to parse true user account
    [currentUser setObject:@"newtemptest" forKey:@"showName"];
    [currentUser setObject:@"4" forKey:@"cellNumber"];
    [currentUser setObject:@"F" forKey:@"gender"];
    [currentUser save];
    */
    
    //return the current itsMTLObject for the currentParseUser
    
    //get the ID and run the XML with the case info.
    NSString *itsMTLObjectID = itsMTLObject.objectId;
    
    //add a progress HUD to show it is sending the XML with the case info
    
    NSString *hardcodedXMLString = @"<PAYLOAD><USEROBJECTID>4OvTmAzGE7</USEROBJECTID><LAISO>EN</LAISO><PREFERENCES><SHOWNAME>Rose</SHOWNAME><COUNTRY>CA</COUNTRY><GENDER>F</GENDER><TEMPLATEID1>01VURH6zGz</TEMPLATEID1><TEMPLATEID2>9XXwNvkFTI</TEMPLATEID2></PREFERENCES></PAYLOAD>";
    
    NSString *xmlGeneratedString = [self createTemplateXMLFunction:itsMTLObjectID];
    
    //show progress HUD
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Creating Parse Case";
    [HUD show:YES];

    //use parse cloud code function to update with appropriate XML
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xmlGeneratedString}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        NSString *responseText = responseString;
                                        NSString *responseTextWithoutHeader = [responseText
                                                                         stringByReplacingOccurrencesOfString:@"[00] " withString:@""];
                                        NSError *jsonError;
                                        NSData *objectData = [responseTextWithoutHeader dataUsingEncoding:NSUTF8StringEncoding];
                                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                                                             options:NSJSONReadingMutableContainers
                                                                                               error:&jsonError];
                                        
                                        NSMutableDictionary *jsonObjectChange = [json mutableCopy];
                                        
                                        [jsonObjectChange setObject:@"" forKey:@"caseId"];
                                        
                                        
                                        NSLog(responseText);
                                        [HUD hide:NO];
                                        
                                        [self showCaseDetailsWithTemplateJSON:jsonObjectChange];
                                        
                                        
                                       // NSLog(@"starting to poll for template maker update");
                                        //[self pollForTemplateMaker];
                                        
                                    }
                                    else
                                    {
                                        NSLog(error.localizedDescription);
                                         [HUD hide:NO];
                                        
                                    }
                                }];
}


-(void)pollForTemplateMaker
{
    //set the previous timestamp of the template to the current value.  If there is no data at all yet, set it to 0.
    //set the last timestamp value for cases where it's not the first template
    
    NSArray *casesArray = [self.itsMTLObject objectForKey:@"cases"];
    //set the previous timestamp so it knows what to compare against.
    
    if([casesArray count] >0)
    {
        
    
    
        for (PFObject *eachReturnedCase in casesArray)
        {
            NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
            if([caseString length] <=0)
            {
                NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                previousTemplateTimestamp = [f numberFromString:timeStampReturn];
                
            }
        }
        
    }
    else
        
    {
        previousTemplateTimestamp = [NSNumber numberWithInt:0];
        
        
    }
    
    
    //run a timer in the background to look for the moment the case is updated with a template maker
   
    //show progress HUD
  
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Polling for New Case";
    [HUD show:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(timerFired:)
                                   userInfo:nil
                                    repeats:YES];
    
}

- (void)timerFired:(NSTimer *)timer {
    
    NSLog(@"timer fired");
    //check the parse object to see if it is updated
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query includeKey:@"cases"];
    
    queryReturnPFObject = [query getObjectWithId:self.itsMTLObject.objectId];
    
    self.itsMTLObject = queryReturnPFObject;
    
        //do stuff with object.
        NSArray *caseList = [queryReturnPFObject objectForKey:@"cases"];
        
         if(caseList != nil)
    {
        
        if(caseList.count ==0)
        {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Templates", nil) message:NSLocalizedString(@"There are currently no templates for this case type", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            //stop the timer
            [timer invalidate];
            timerTickCheck = 0;
            [HUD hide:YES];
        }
        else
        {
            //check to see if the new case has been created yet, look for a case ID where case is = nil.
        
            //check to see if the timestamp returned on the template case is newer than the previous timestamp.
            int i = 0;
            for (PFObject *eachReturnedCase in caseList)
            {
                NSString *caseString = [eachReturnedCase objectForKey:@"caseId"];
                if([caseString length] <=0)
                {
                    //check the timestamp, see if newer than prior timestamp
                    NSString *timeStampReturn = [eachReturnedCase objectForKey:@"timestamp"];
                    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                    f.numberStyle = NSNumberFormatterDecimalStyle;
                    
                    NSNumber *timestamp = [f numberFromString:timeStampReturn];
                    
                    if([timestamp doubleValue] > [previousTemplateTimestamp doubleValue])
                    {
                        NSLog(@"newer timestamp found");
                       
                        //stop the timer
                        [timer invalidate];
                        timerTickCheck = 0;
                        NSLog(@"got the blank caseID, showing the case details page");
                        [HUD hide:YES];
                        [self ShowCaseDetails:caseList LastCreatedCaseIndex:i];
                        break;
                    }
                    else
                    {
                        NSLog(@"timestamp not greater");
                        
                    }
                }
                   i = i+1;
            }
        }
    }
    
    timerTickCheck=timerTickCheck+1;
    if(timerTickCheck==15)
    {
        [timer invalidate];
        NSLog(@"ran into maximum time");
        [HUD hide:YES];
    }
    
}

-(void) ShowCaseDetails:(NSArray *) itsMTLCases LastCreatedCaseIndex:(int) lastCaseInt
{
    //send the latest case information to
    NSNumber *selectedIndex = [NSNumber numberWithInt:lastCaseInt];
    
    //CaseDetailsViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdvc"];
    BaseCaseDetailsSlidingViewController *bcdsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"bcdsvc"];
    
   
    CaseDetailsEmailViewController *cdevc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdevc"];
    
    cdevc.selectedCaseIndex=selectedIndex;

    cdevc.userName = itsMTLObject.objectId;
    cdevc.itsMTLObject = queryReturnPFObject;
    
     [bcdsvc setTopViewController:cdevc];
    
    [self.navigationController pushViewController:bcdsvc animated:YES];
}

-(void) showCaseDetailsWithTemplateJSON:(NSMutableDictionary *)templateJSON
{
    BaseCaseDetailsSlidingViewController *bcdsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"bcdsvc"];
    
    
    CaseDetailsEmailViewController *cdevc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdevc"];
    
    cdevc.jsonObject = templateJSON;
    cdevc.jsonDisplayMode = @"template";
    cdevc.userName = self.itsMTLObject.objectId;
    cdevc.itsMTLObject = self.itsMTLObject;
    
    
    [bcdsvc setTopViewController:cdevc];
    
    [self.navigationController pushViewController:bcdsvc animated:YES];
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
    
    [xmlWriter writeStartElement:@"PREFERENCES"];
    
    [xmlWriter writeStartElement:@"COUNTRY"];
    [xmlWriter writeCharacters:@"CA"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"GENDER"];
    [xmlWriter writeCharacters:@"F"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"SHOWNAME"];
    [xmlWriter writeCharacters:@"newTest"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CELLNUMBER"];
    [xmlWriter writeCharacters:@"5"];
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

-(void)getLocation:(id)sender
{
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //show progress HUD
    /*
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Location Data";
    [HUD show:YES];
    */
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
   
    
    [locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        //longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        //latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        
        locationLongitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        locationLatitude =[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
           
            NSString *locationText =[NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                     placemark.subThoroughfare, placemark.thoroughfare,
                                     placemark.postalCode, placemark.locality,
                                     placemark.administrativeArea,
                                     placemark.country];
            locationRetrieved = placemark.locality;
            
            //[HUD hide:YES];
        } else {
            NSLog(@"%@", error.debugDescription);
            
            //[HUD hide:YES];
        }
    } ];
    
}




@end
