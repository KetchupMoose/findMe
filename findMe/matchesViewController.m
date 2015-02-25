//
//  matchesViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-02-11.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "matchesViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "XMLWriter.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface matchesViewController ()

@end

@implementation matchesViewController

MBProgressHUD *HUD;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.matchesTableView.delegate = self;
    self.matchesTableView.dataSource = self;
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.matchesTableView reloadData];
    
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

#pragma mark UITableViewDelegateMethods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.matchesArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"matchCell" forIndexPath:indexPath];
    
    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    UILabel *matchNameLabel = (UILabel *)[cell viewWithTag:2];
    UIImageView *matchImage = (UIImageView *)[cell viewWithTag:1];
    
    matchImage.image = [UIImage imageNamed:@"femalesilhouette.jpeg"];
    
    NSString *matchNameString = [self.matchesArray objectAtIndex:indexPath.row];
    
    matchNameLabel.text = matchNameString;
    
    return cell;
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.0f green:0.78f blue:0.0f alpha:1.0]
                                                title:@"Yes"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                               title:@"No"];
     
     /*
                                                icon:[UIImage imageNamed:@"check.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:1.0f blue:0.35f alpha:1.0]
                                                icon:[UIImage imageNamed:@"clock.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
                                                icon:[UIImage imageNamed:@"cross.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.55f green:0.27f blue:0.07f alpha:1.0]
                                                icon:[UIImage imageNamed:@"list.png"]];
      */
    
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark swipableTableViewCellsDelegateMethods

// click event on left utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    NSLog(@"No button was pressed");
    [self doSwipe:index swipeMode:@"NO"];
}

// click event on right utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
      NSLog(@"Yes button was pressed");
    [self doSwipe:index swipeMode:@"YES"];
    
    
}

// utility button open/close event
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    
}

// prevent multiple cells from showing utilty buttons simultaneously
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    
    return YES;
}

// prevent cell(s) from displaying left/right utility buttons
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state
{
    return YES;
    
}

-(void)doSwipe:(NSInteger) index swipeMode:(NSString *)yesOrNo
{

    NSString *xmlToSwipe = [self createSwipeXML:index withMode:yesOrNo];
    
    //add a progress HUD to show it is retrieving list of properts
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Sending Swipe to Backend";
    [HUD show:YES];
    
    //use parse cloud code function
    [PFCloud callFunctionInBackground:@"submitXML"
                       withParameters:@{@"payload": xmlToSwipe}
                                block:^(NSString *responseString, NSError *error) {
                                    if (!error) {
                                        
                                        NSString *responseText = responseString;
                                        NSLog(responseText);
                                        
                                        [HUD hide:NO];
                                        
                                    }
                                    else
                                    {
                                        NSString *errorString = error.localizedDescription;
                                        NSLog(errorString);
                                        [HUD hide:NO];
                                        
                                    }
                                }];
}

-(NSString *)createSwipeXML:(NSInteger) index withMode:(NSString *)YesOrNo;
{
    //hardcoded XML for sending a swipe
    /*
    <PAYLOAD><USEROBJECTID>NoJW05Xwsq</USEROBJECTID><LAISO>EN</LAISO><CASEOBJECTID>77rmIIxX9z</CASEOBJECTID><CASENAME>I just saw you</CASENAME><BUBBLEBURST>22</BUBBLEBURST><ITEM><CASEITEM>18</CASEITEM><PROPERTYNUM>8ZKsAhHzak</PROPERTYNUM><SWIPE><YES>OKXDu5YEJF</YES></SWIPE></ITEM></PAYLOAD>
    */
    
    
    NSString *selectedMatch = [self.matchesArray objectAtIndex:index];
    PFObject *caseObject = [self.matchesCaseObjectArrays objectAtIndex:index];
    NSString *caseItem = [self.matchesCaseItemArrays objectAtIndex:index];
    
    NSArray *caseObjectCaseItems = [caseObject objectForKey:@"caseItems"];
    NSString *propertyNum;
    NSString *caseName;
    NSString *caseObjectID = [caseObject objectForKey:@"caseId"];
    
    
    caseName = [caseObject objectForKey:@"caseName"];
    
    for(PFObject *caseItemObject in caseObjectCaseItems)
    {
        NSString *caseItemString = [caseItemObject objectForKey:@"caseItem"];
        if([caseItemString isEqualToString:caseItem])
        {
            propertyNum = [caseItemObject objectForKey:@"propertyNum"];
        }
    }

        // allocate serializer
        XMLWriter *xmlWriter = [[XMLWriter alloc] init];
        
        // add root element
        [xmlWriter writeStartElement:@"PAYLOAD"];
        
        // add element with an attribute and some some text
        [xmlWriter writeStartElement:@"USEROBJECTID"];
        [xmlWriter writeCharacters:self.matchesUserName];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"LAISO"];
        [xmlWriter writeCharacters:@"EN"];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"CASEOBJECTID"];
        [xmlWriter writeCharacters:caseObjectID];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"CASENAME"];
        [xmlWriter writeCharacters:caseName];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"ITEM"];
        
        [xmlWriter writeStartElement:@"CASEITEM"];
        [xmlWriter writeCharacters:caseItem];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"PROPERTYNUM"];
        [xmlWriter writeCharacters:propertyNum];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"SWIPE"];
    
            [xmlWriter writeStartElement:YesOrNo];
            [xmlWriter writeCharacters:selectedMatch];
            [xmlWriter writeEndElement];
    
        //close swipe element
        [xmlWriter writeEndElement];
        
        // close ITEM element
        [xmlWriter writeEndElement];
        
        // close payload element
        [xmlWriter writeEndElement];
        
        // end document
        [xmlWriter writeEndDocument];
        
        NSString* xml = [xmlWriter toString];
        
    return xml;
    
}


@end
