//
//  HomePageViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-11-16.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "HomePageViewController.h"
#import "newCaseViewController.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "ViewCasesViewController.h"

@interface HomePageViewController ()


@end

@implementation HomePageViewController

NSString *HomePageuserName = @"exTJgfgotY";
MBProgressHUD *HUD;
@synthesize ViewMyCasesButton;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //add a progress HUD to show it is retrieving list of cases
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Retrieving Cases";
    [HUD show:YES];
    
    //needs to query for the user and pull some info
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query getObjectInBackgroundWithId:HomePageuserName block:^(PFObject *latestCaseList, NSError *error) {
        // Do something with the returned PFObject
        NSLog(@"%@", latestCaseList);
       
        [HUD hide:NO];
        
        //do some logic to sort through these cases and see how many have matches, how many are awaiting more info.
        NSArray *cases = [latestCaseList objectForKey:@"cases"];
        
        int caseCount = cases.count;
        
        UIView *bubbleIndicatorCases = [[UIView alloc] init];
        int bubbleWidth = 20;
        int bubbleHeight = 20;
        
        [bubbleIndicatorCases setFrame:CGRectMake(ViewMyCasesButton.frame.origin.x+ViewMyCasesButton.frame.size.width-bubbleWidth/2,ViewMyCasesButton.frame.origin.y-bubbleHeight/2,bubbleWidth,bubbleHeight)];
        
        bubbleIndicatorCases.backgroundColor = [UIColor redColor];
        
        UILabel *bubbleNumber = [[UILabel alloc] initWithFrame:bubbleIndicatorCases.bounds];
        
        bubbleNumber.text = [NSString stringWithFormat:@"%i",caseCount];
        
        [bubbleNumber setTextAlignment:NSTextAlignmentCenter];
        
        [bubbleIndicatorCases addSubview:bubbleNumber];
        
        bubbleIndicatorCases.layer.cornerRadius = 9.0;
        bubbleIndicatorCases.layer.masksToBounds = YES;
        
        [self.view addSubview:bubbleIndicatorCases];
        
        
    }];
    
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

- (IBAction)CreateNewCase:(id)sender {
    
    
    newCaseViewController *ncvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ncvc"];
    
    //UINavigationController *uinc = self.navigationController;
    
    [self.navigationController pushViewController:ncvc animated:YES];
    
}
- (IBAction)ViewMyCases:(id)sender {
    ViewCasesViewController *vcvc = [self.storyboard instantiateViewControllerWithIdentifier:@"vcvc"];
     [self.navigationController pushViewController:vcvc animated:YES];
    
}
- (IBAction)MyMatches:(id)sender {
    
}
- (IBAction)MyProfile:(id)sender {
    
}
@end
