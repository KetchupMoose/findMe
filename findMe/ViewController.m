//
//  ViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import "CaseBuilder.h"
#import "CaseDetailsViewController.h"


@interface ViewController ()

@end

@implementation ViewController
NSArray *caseListJSON;
@synthesize casesTableView;
NSString *userName = @"exTJgfgotY";
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [casesTableView setDataSource:self];
    [casesTableView setDelegate:self];
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query getObjectInBackgroundWithId:userName block:^(PFObject *latestCaseList, NSError *error) {
        // Do something with the returned PFObject
        NSLog(@"%@", latestCaseList);
       caseListJSON = [latestCaseList objectForKey:@"cases"];
        //this represents the overall list of cases
        
    /*
        for (PFObject *caseObject in caseListJSON)
        {
            NSArray *caseItems = [caseObject objectForKey:@"caseItems"];
            
            PFObject *caseItemObject = [caseItems objectAtIndex:0];
            
            //here are the contents of each case item object
            NSArray *answerList = [caseItemObject objectForKey:@"answers"];
            NSString *caseItem = [caseItemObject objectForKey:@"caseItem"];
            NSString *priority =[caseItemObject objectForKey:@"priority"];
            NSString *propertyNum = [caseItemObject objectForKey:@"propertyNum"];

            
            
        }
       */
        
        [casesTableView reloadData];
        
        
       // NSArray *myCases = [CaseBuilder casesFromJSON:[latestCase objectForKey:@"cases"] error:nil];
        
       // NSLog(@"%i",myCases.count);
        
        //NSString *jsonBlob1 = [jsonBlobArray objectAtIndex:0];
        
        
       // NSLog(jsonBlob1);
        
        
    }];
    
   
    
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDelegateMethods
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [caseListJSON count];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"caseCell" forIndexPath:indexPath];
    
    UILabel *caseNameLabel = (UILabel *)[cell viewWithTag:2];
    UILabel *caseIDLabel = (UILabel *)[cell viewWithTag:3];
    PFObject *caseObject = [caseListJSON objectAtIndex:indexPath.row];
    
    NSString *caseName = [caseObject objectForKey:@"caseName"];
    caseNameLabel.text = caseName;
    
    NSString *caseId = [caseObject objectForKey:@"caseId"];
    caseIDLabel.text = caseId;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 
    //bring up the case details view controller
    
    NSNumber *selectedIndex = [NSNumber numberWithInteger:indexPath.row];
    
    
    CaseDetailsViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"cdvc"];
    
    cdvc.selectedCaseIndex=selectedIndex;
    cdvc.caseListData = caseListJSON;
    cdvc.userName = userName;
    
    
    [self.navigationController pushViewController:cdvc animated:YES];
    
    
}


@end
