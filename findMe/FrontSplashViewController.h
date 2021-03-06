//
//  FrontSplashViewController.h
//  Pick Something
//
//  Created by Macbook on 2014-01-09.
//  Copyright (c) 2014 bricorp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InternetOfflineViewController.h"

@class FrontSplashViewController;

@protocol FrontSplashViewControllerDelegate <NSObject>

@required
-(void)makestuffvisible;
-(void)makestuffnotvisible;
-(void)gotologin;

@end


@interface FrontSplashViewController : UIViewController <internetOfflineViewControllerDelegate>


@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) IBOutlet UILabel *screenNumber;
@property (strong, nonatomic) id dataObject;

@property (strong,nonatomic) IBOutlet UILabel *screenText;
@property (strong,nonatomic) IBOutlet UILabel *titleText;

@property (strong,nonatomic) IBOutlet UIImageView *selection1Image;
@property (strong,nonatomic) IBOutlet UIImageView *selection2Image;
@property (strong,nonatomic) IBOutlet UIImageView *selection3Image;

@property (strong,nonatomic) IBOutlet UIImageView *screenshot;

@property (strong,nonatomic) IBOutlet UIButton *startPlayingButton;
-(IBAction) startPlayingClick:(id) sender;
@property (strong, nonatomic) UIPageControl *pageControl;

@property (nonatomic, strong) id <FrontSplashViewControllerDelegate> fsplashDelegate;


@end
