//
//  CaseDetailsViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-23.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "CaseDetailsViewController.h"
#import <Parse/Parse.h>

@interface CaseDetailsViewController ()

@end

@implementation CaseDetailsViewController
@synthesize caseListData;
@synthesize selectedCaseIndex;
NSArray *answersList;

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
    int *selectedCaseInt = (NSInteger *)[selectedCaseIndex integerValue];
    NSUInteger *selectedCase = (NSUInteger *)selectedCaseInt;
    
    PFObject *caseItemObject = [caseListData objectAtIndex:1];
    
    //get the LAST QuestionItem to display that information.
    
    NSArray *questionItems = [caseItemObject objectForKey:@"caseItems"];
    
    PFObject *lastQuestion = [questionItems objectAtIndex:(questionItems.count-1)];
    
    NSString *lastQPropertyNum = [lastQuestion objectForKey:@"propertyNum"];
    
    
    
    //retrieve the property choices for this caseItemObject from Parse.
    
     PFQuery *query = [PFQuery queryWithClassName:@"propert"];
    
    [query getObjectInBackgroundWithId:lastQPropertyNum block:^(PFObject *latestCaseList, NSError *error) {
        
        
        
        
    }
     ];
    
    
    
    
    //here are the contents of each case item object
   answersList = [caseItemObject objectForKey:@"answers"];
    
    self.caseDetailsTableView.dataSource = self;
    self.caseDetailsTableView.delegate = self;
    
    
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

#pragma mark UITableViewDelegateMethods
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [answersList count];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseDetailsCell" forIndexPath:indexPath];
    
    UILabel *AnswerNameLabel = (UILabel *)[cell viewWithTag:2];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
}


@end
