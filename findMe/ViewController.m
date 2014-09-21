//
//  ViewController.m
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    PFQuery *query = [PFQuery queryWithClassName:@"ItsMTL"];
    [query getObjectInBackgroundWithId:@"exTJgfgotY" block:^(PFObject *latestCase, NSError *error) {
        // Do something with the returned PFObject in the gameScore variable.
        NSLog(@"%@", latestCase);
        NSArray *jsonBlobArray = [latestCase objectForKey:@"cases"];
        NSString *jsonBlob1 = [jsonBlobArray objectAtIndex:0];
        
        NSLog(jsonBlob1);
        
        
    }];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
