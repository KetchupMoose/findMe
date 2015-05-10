//
//  FindMeLoginViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-05-10.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <Parse/Parse.h>
#import "FrontSplashViewController.h"

@interface FindMeLoginViewController : PFLogInViewController
<UIPageViewControllerDataSource,UITextFieldDelegate,FrontSplashViewControllerDelegate,UIPageViewControllerDelegate,UIGestureRecognizerDelegate>


{
    UIPageViewController *pageController;
    UIPageControl *pageControl;
    NSArray *pageContent;
}

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSArray *pageContent;

-(void) makestuffvisible;
-(void) makestuffnotvisible;
-(void) gotologin;
@end
