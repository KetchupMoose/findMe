//
//  secondViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-02-12.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "secondViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ECSlidingViewController.h"
#import "UIViewController+ECSlidingViewController.h"
@interface secondViewController ()

@end

@implementation secondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self.slidingViewController setAnchorRightRevealAmount:280.0f];
  // self.slidingViewController.underLeftWidthLayout = ECFullWidth;
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

@end
