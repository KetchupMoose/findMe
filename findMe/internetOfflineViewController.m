//
//  internetOfflineViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-03-04.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "internetOfflineViewController.h"
#import "reachabilitySingleton.h"
#import "Reachability.h"
#import "MBProgressHUD.h"


@interface internetOfflineViewController ()

@end

@implementation internetOfflineViewController
NSTimer *checkInternetTimer;
int checkInternetTimerTicks;
@synthesize delegate;
MBProgressHUD *internetProgressHUD;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)retryConnection:(id)sender
{
    Reachability *singletonReach = [[reachabilitySingleton sharedReachability] reacher];
    
    NetworkStatus *status = [singletonReach currentReachabilityStatus];
    
    
    
    if (status !=NotReachable)
    {
        NSLog(@"reached it!");
        //[self.view removeFromSuperview];
        [self.delegate dismissIOVC];
        
    }
    else
    {
        NSLog(@"no connection");
        internetProgressHUD = [[MBProgressHUD alloc] init];
        
        internetProgressHUD.labelText = @"Polling For Internet";
        [internetProgressHUD show:YES];
        //start a timer to refresh and try again
        if(checkInternetTimer ==nil)
        {
            
       checkInternetTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(internetCheck:)
                                       userInfo:nil
                                                            repeats:YES];
        }
    }
}

-(void)internetCheck:(id)sender
{
    Reachability *singletonReach = [[reachabilitySingleton sharedReachability] reacher];
    
    NetworkStatus *status = [singletonReach currentReachabilityStatus];
    
    if(status != NotReachable)
    {
        NSLog(@"reached it!");
        [checkInternetTimer invalidate];
        checkInternetTimerTicks = 0;
        [internetProgressHUD hide:NO];
        
        //[self.view removeFromSuperview];
        
        //[self.delegate dismissIOVC];
        [self.delegate dismissIOVC];
    }
    else
    {
        checkInternetTimerTicks = checkInternetTimerTicks+1;
        
        if(checkInternetTimerTicks ==10)
        {
            [checkInternetTimer invalidate];
             [internetProgressHUD hide:NO];
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Internet Detected", nil) message:@"No Connection Detected.  Hit Retry to Try Again" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            
        }
    }
}



@end
