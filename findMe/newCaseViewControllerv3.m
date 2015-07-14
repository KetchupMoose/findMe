//
//  newCaseViewControllerv3.m
//  findMe
//
//  Created by Brian Allen on 2015-06-30.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "newCaseViewControllerv3.h"
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
#import "caseDetailsCarouselViewController.h"
#import "caseTitleSetViewController.h"

@interface newCaseViewControllerv3 ()

@end

@implementation newCaseViewControllerv3
@synthesize TemplateSecondLevelTableView;
@synthesize templatePickerActiveChoices;
@synthesize locationManager;
NSString *selectedTemplate1;
NSString *selectedTemplate2;
MBProgressHUD *HUD;

//location manager variables
CLGeocoder *geocoder;
CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   
    
    
    
    self.baseScrollView=[[UIScrollView alloc]initWithFrame:CGRectMake(0,0,320,self.view.bounds.size.height)];
   self.baseScrollView.showsVerticalScrollIndicator=YES;
    self.baseScrollView.scrollEnabled=YES;
    self.baseScrollView.userInteractionEnabled=YES;
    self.baseScrollView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.baseScrollView];
    self.baseScrollView.contentSize = CGSizeMake(320,1000);
    
    //bgview
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.baseScrollView.bounds];
    backgroundView.image = [UIImage imageNamed:@"papers.co-mk25-night-city-view-dark-bw-nautre-art-33-iphone6-wallpaper.jpg"];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.baseScrollView addSubview:backgroundView];
    
    //calculate the number of categories required
    [self queryForTemplates];

    int numberOfCategories = (int)self.totalSetsOfParentTemplates.count;
    
    //collection view height: 180
    //collection view cell: 145 width, 130 height
    //collection view image: 31 width, 8 height,82 width, 82height
    //collection view titleLabel 8 width, 95 height,129 width, 27 height
    
    int yMarginBetweenCollectionViews= 40;
    int cViewHeight = 180;
    for (int i = 0; i <= numberOfCategories-1; i++)
    {
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        UILabel *sectionTitleLabel;
        
        UICollectionView *categoryCollectionView;
        if(i==0)
        {
             categoryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,yMarginBetweenCollectionViews,320,cViewHeight) collectionViewLayout:layout];
            
            //add title label from category text
            NSArray *firstTemplatesArray = [self.totalSetsOfParentTemplates objectAtIndex:0];
            PFObject *templateObj = [firstTemplatesArray objectAtIndex:0];
            NSString *categoryText = [templateObj objectForKey:@"category"];
            
            //add a label
            sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,320,yMarginBetweenCollectionViews)];
            sectionTitleLabel.text = categoryText;
        }
        else
        {
            categoryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,(cViewHeight*i)+yMarginBetweenCollectionViews*i+yMarginBetweenCollectionViews,320,cViewHeight) collectionViewLayout:layout];
            
             sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,cViewHeight*i+yMarginBetweenCollectionViews,320,yMarginBetweenCollectionViews)];
            
            //add title label from category text
            NSArray *firstTemplatesArray = [self.totalSetsOfParentTemplates objectAtIndex:i];
            PFObject *templateObj = [firstTemplatesArray objectAtIndex:0];
            NSString *categoryText = [templateObj objectForKey:@"category"];
            if([categoryText isEqualToString:@""] || categoryText == nil)
            {
                categoryText = @"Null Category";
            }
            sectionTitleLabel.text = categoryText;
            
        }
        
        sectionTitleLabel.textAlignment = NSTextAlignmentCenter;
        sectionTitleLabel.textColor = [UIColor whiteColor];
        sectionTitleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:16];
        sectionTitleLabel.tag = i+1;
        
        [self.baseScrollView addSubview:sectionTitleLabel];
        
        categoryCollectionView.tag = i+1;
        categoryCollectionView.dataSource = self;
        categoryCollectionView.delegate = self;
        categoryCollectionView.backgroundColor = [UIColor whiteColor];
        
        [categoryCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"templateCell"];
        
        [self.baseScrollView addSubview:categoryCollectionView];
        
        [categoryCollectionView reloadData];
        
    }
}

-(void) queryForTemplates
{
    //retrieve the five parent templatePickerChoices from Parse
    //templatePickerChoices =
    PFQuery *templateQuery = [PFQuery queryWithClassName:@"Templates"];
    //[templateQuery selectKeys:@[@"parenttemplateid"]];
    
    [templateQuery whereKey:@"laiso" equalTo:@"EN"];
    [templateQuery orderByDescending:@"category"];
    
    NSMutableArray *templateParentChoices = [[NSMutableArray alloc] init];
    
    self.totalSetsOfParentTemplates = [[NSMutableArray alloc] init];
    
    self.templatePickerActiveChoices = [[NSMutableArray alloc] init];
    self.parentTemplateCategories = [[NSMutableArray alloc] init];
    
    self.allTemplates = (NSMutableArray *)[templateQuery findObjects];
    for(PFObject *templateObject in self.allTemplates)
    {
        NSLog(@"numberofKeys");
        NSLog(@"%lu",(unsigned long)templateObject.allKeys.count);
        
        PFObject *theParentObj = [templateObject objectForKey:@"parenttemplateid"];
        
        if([theParentObj isEqual:[NSNull null]])
        {
            //check the designation
            [templateParentChoices addObject:templateObject];
            [self.parentTemplateCategories addObject:templateObject];
            
        }
    }
    
    //filter parent choices into different categories
    NSString *previousCategory = @"";
    NSMutableArray *templateArray;
    int lastObject = (int)templateParentChoices.count;
    int j = 1;
    
    for (PFObject *parentTemplateObject in templateParentChoices)
    {
        NSString *category = [parentTemplateObject objectForKey:@"category"];
        if(category ==nil)
        {
            category = @"";
            
        }
        //handle very first case
        if(j==1)
        {
            //create a new templatearray and add it to total sets of templates
            templateArray = [[NSMutableArray alloc] init];
            [templateArray addObject:parentTemplateObject];
            previousCategory = category;
            
            if(j == lastObject)
            {
                [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                
            }
        }
        else if([previousCategory isEqualToString:category])
        {
            [templateArray addObject:parentTemplateObject];
            if(j == lastObject)
            {
                [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                
            }
        }
        else
        {
            //if there are already some objects, add this one and finish the array
            if(templateArray.count >=1)
            {
                [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                [templateArray removeAllObjects];
                templateArray = [[NSMutableArray alloc] init];
                [templateArray addObject:parentTemplateObject];
                previousCategory = category;
                if(previousCategory ==nil)
                {
                    previousCategory = @"";
                }
                if(j == lastObject)
                {
                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                    
                }
            }
            else //if not already some objects, start a new templateArray
            {
                [templateArray removeAllObjects];
                templateArray = [[NSMutableArray alloc] init];
                [templateArray addObject:parentTemplateObject];
                previousCategory = category;
                if(previousCategory ==nil)
                {
                    previousCategory = @"";
                }
                if(j == lastObject)
                {
                    [self.totalSetsOfParentTemplates addObject:[templateArray copy]];
                    
                }
            }
        }
        
        j = j+1;
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
    
    NSArray *templatePicksForTag = [self.totalSetsOfParentTemplates objectAtIndex:collectionView.tag-1];
    
    return templatePicksForTag.count;
    
}
//collection view cell: 145 width, 130 height
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(145, 130);
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"templateCell";
    NSArray *sourceArray;
    
    sourceArray = [self.totalSetsOfParentTemplates objectAtIndex:collectionView.tag-1];
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *caseImageView = nil;
    UILabel *descrLabel = nil;
    
    caseImageView= (UIImageView *)[cell viewWithTag:1];
    descrLabel = (UILabel *) [cell viewWithTag:2];
    
    //collection view image: 31 width, 8 height,82 width, 82height
    //collection view titleLabel 8 width, 95 height,129 width, 27 height
    if(caseImageView ==nil)
    {
        caseImageView = [[UIImageView alloc] initWithFrame:CGRectMake(31,8,82,82)];
        descrLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,95,129,27)];
        caseImageView.tag = 1;
        descrLabel.tag = 2;
        
        [cell addSubview:caseImageView];
        [cell addSubview:descrLabel];
        
    }
    
    //check to see if a button is already created, if not, create a button overlayed on top of the UIImageView.  This button when tapped will activate the next step for the index of its displayed template.
    
    PFObject *templateObject = [sourceArray objectAtIndex:indexPath.row];
    
    NSString *imgURL = [templateObject objectForKey:@"imageURL"];
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    [caseImageView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    descrLabel.text = [templateObject objectForKey:@"description"];
    
    descrLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
    
    descrLabel.textAlignment = NSTextAlignmentCenter;
    
    
    //caseImageView.image = [UIImage imageNamed:[recipeImages objectAtIndex:indexPath.row]];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //load next wave of templates from selection
    
    //calculate the index based on # of collectionviews shown, this collectionview tag, and the sub contents of each array.
    NSInteger indexOfThisCollectionView = collectionView.tag;
    NSInteger objCountTotal = 0;
    for(int i = 0; i <indexOfThisCollectionView-1; i++)
    {
        //sum up the counts of
        NSArray *contentsOfCollectionViewAtIndex = [self.totalSetsOfParentTemplates objectAtIndex:i];
        NSInteger objCount = contentsOfCollectionViewAtIndex.count;
        objCountTotal += objCount;
        
    }
    
    NSInteger indexForAllParentTemplates = objCountTotal + indexPath.row;
    
    [self parentTemplatePicked:indexForAllParentTemplates];
    
    UICollectionViewCell *selectedCell = [collectionView cellForItemAtIndexPath:indexPath];
    
    //create new UIImage & DescriptionLabel to animate onto screen with that
    UIImageView *replicaOfCellImageView = (UIImageView *)[selectedCell viewWithTag:1];
    UILabel *cellDescriptionLabel = (UILabel *)[selectedCell viewWithTag:2];
    cellDescriptionLabel.textColor = [UIColor whiteColor];
    
    //dismiss tableview by animating left
    UIView *selectedFirstTemplateView = [[UIView alloc] initWithFrame:CGRectMake(5,5,310,140)];
    
    selectedFirstTemplateView.layer.borderColor = [UIColor whiteColor].CGColor;
    selectedFirstTemplateView.layer.cornerRadius = 5.0f;
    selectedFirstTemplateView.layer.masksToBounds = YES;
    selectedFirstTemplateView.layer.borderWidth = 3.0f;
 
    //add imageview for selected case as subcomponent
    CGRect cellFrame = replicaOfCellImageView.frame;
    cellFrame.origin.y = cellFrame.origin.y+20;
    cellFrame.origin.x -=10;
    
    replicaOfCellImageView.frame = cellFrame;
    
    UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(100,0,200,40)];
    categoryLabel.text = @"Selected Category:";
    categoryLabel.textColor = [UIColor whiteColor];
    
    CGRect labelFrame = cellDescriptionLabel.frame;
    labelFrame.origin.x +=90;
    labelFrame.origin.y -=75;
    labelFrame.size.width = 190;
    labelFrame.size.height = 90;
    
    
    
    cellDescriptionLabel.frame = labelFrame;
    cellDescriptionLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
    cellDescriptionLabel.numberOfLines = 2;
    
    [selectedFirstTemplateView addSubview:cellDescriptionLabel];
    
    [selectedFirstTemplateView addSubview:replicaOfCellImageView];
    //[selectedFirstTemplateView addSubview:categoryLabel];
    
    [self.view SlideOffLeft:self.baseScrollView thenGrowNewView:selectedFirstTemplateView duration:0.5f];
    
    //setup the second tableview if it doesn't exist already
    int SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    int SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    
    TemplateSecondLevelTableView.frame = CGRectMake(0,160,320,SCREEN_HEIGHT-200);
    
    TemplateSecondLevelTableView.dataSource = self;
    TemplateSecondLevelTableView.delegate = self;
    
    [TemplateSecondLevelTableView reloadData];
    
    TemplateSecondLevelTableView.layer.cornerRadius = 0;
    TemplateSecondLevelTableView.layer.masksToBounds = YES;
    TemplateSecondLevelTableView.alpha = 1;
    TemplateSecondLevelTableView.backgroundColor = [UIColor clearColor];
    
    
    [self.view growViewAfterDelayAndDuration:TemplateSecondLevelTableView duration:0.4f delay:0.5f];
    

}

-(void) parentTemplatePicked:(NSInteger) tag;
{
    int btnTag = tag;
    
    //select the next template display based on this button.
    
    NSLog(@"%i",btnTag);
    
    //remove everything from the previous active choices
    [templatePickerActiveChoices removeAllObjects];
    
    //get the selected parent template object
    PFObject *selectedParentTemplateObj = [self.parentTemplateCategories objectAtIndex:btnTag];
    selectedTemplate1 = selectedParentTemplateObj.objectId;
    
    
    //loop through and add to the active templates in the 2nd table/wheel only the ones that match that selected parent template.
    for (PFObject *templateObj in self.allTemplates)
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
    
    int SCREEN_WIDTH = [[UIScreen mainScreen] bounds].size.width;
    int SCREEN_HEIGHT = [[UIScreen mainScreen] bounds].size.height;
    TemplateSecondLevelTableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,SCREEN_WIDTH,SCREEN_HEIGHT-60)];
    TemplateSecondLevelTableView.dataSource = self;
    TemplateSecondLevelTableView.delegate = self;
    
    [TemplateSecondLevelTableView reloadData];
    
    TemplateSecondLevelTableView.layer.cornerRadius = 0;
    TemplateSecondLevelTableView.layer.masksToBounds = YES;
    TemplateSecondLevelTableView.alpha = 1;
    TemplateSecondLevelTableView.backgroundColor = [UIColor clearColor];
    
    [self.view BounceAddTheView:TemplateSecondLevelTableView];
    
    //[self.childTemplateTableView reloadData];
    
}


#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
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
    cell.backgroundColor = [UIColor clearColor];
    
    
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
        createCaseButton.alpha = 0;
        
        [cell addSubview:createCaseButton];
        
        
    }
    
    [createCaseButton setBackgroundColor:[UIColor blueColor]];
    
    [createCaseButton setTitle:@"Create Case" forState:UIControlStateNormal];
    
    int startyMargin = 20;
    int startxMargin = 10;
    
    int imgWidth = 90;
    int imgHeight = 90;
    
    int textimgxmargin=10;
    
    int textWidth = 200;
    int textHeight = 90;
    
    int textbuttonxmargin=10;
    
    int buttonWidth = 80;
    int buttonHeight = 80;
    
    choice1ImageView.frame = CGRectMake(startxMargin,startyMargin,imgWidth,imgHeight);
    int imgMidPoint = choice1ImageView.frame.origin.y+choice1ImageView.frame.size.height/2;
    
    templateDescLabel.frame = CGRectMake(textimgxmargin+choice1ImageView.frame.origin.x+choice1ImageView.frame.size.width,imgMidPoint-textHeight/2,textWidth,textHeight);
    
    templateDescLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    //[templateDescLabel setShadowColor:shadow.shadowColor];
    //[templateDescLabel setShadowOffset:shadow.shadowOffset];
    
    templateDescLabel.textColor = [UIColor whiteColor];
    
    templateDescLabel.numberOfLines = 5;
    templateDescLabel.textAlignment = NSTextAlignmentCenter;
    
    PFObject *selectedTemplateObject = [templatePickerActiveChoices objectAtIndex:indexPath.row];
    templateDescLabel.text = (NSString *)[selectedTemplateObject objectForKey:@"description"];
    
    createCaseButton.frame = CGRectMake(templateDescLabel.frame.origin.x+templateDescLabel.frame.size.width+textbuttonxmargin,imgMidPoint-buttonHeight/2,buttonWidth,buttonHeight);
    
    //createCaseButton.titleLabel.numberOfLines = 2;
    UILabel *buttonTitleLabel = createCaseButton.titleLabel;
    buttonTitleLabel.numberOfLines = 2;
    buttonTitleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    //June 4 font
    
    
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    // selectedTemplate2=selectedTemplateObject.objectId;
    
    //second level template
    PFObject *secondTemplate = [templatePickerActiveChoices objectAtIndex:indexPath.row];
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
    NSString *itsMTLObjectID = self.itsMTLObject.objectId;
    
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
                                        
                                        //[self showCaseDetailsWithTemplateJSON:jsonObjectChange];
                                        [self showCaseDetailsCarouselWithTemplateJSON:jsonObjectChange];
                                        
                                        
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
        //[xmlWriter writeStartElement:@"LOCATIONTEXT"];
        //[xmlWriter writeCharacters:locationRetrieved];
        //[xmlWriter writeEndElement];
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
    //NSLog(@"didUpdateToLocation: %@", newLocation);
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
        // NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
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

-(void) showCaseDetailsCarouselWithTemplateJSON:(NSMutableDictionary *)templateJSON
{
    //get storyboard from main bundle instead
    UIStoryboard *storyboard = self.navigationController.storyboard;
    
    caseDetailsCarouselViewController *cdcvc = [storyboard instantiateViewControllerWithIdentifier:@"cdcvc2"];
    
    cdcvc.jsonObject = templateJSON;
    cdcvc.jsonDisplayMode = @"template";
    cdcvc.userName = self.itsMTLObject.objectId;
    cdcvc.itsMTLObject = self.itsMTLObject;
    cdcvc.manualLocationPropertyNum = self.manualLocationPropertyNum;
    
    [self.navigationController pushViewController:cdcvc animated:NO];
    //[self.navigationController pushViewController:ctsvc animated:NO];
    
}


@end
