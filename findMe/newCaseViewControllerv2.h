//
//  newCaseViewControllerv2.h
//  findMe
//
//  Created by Brian Allen on 2015-06-29.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "findMeBaseViewController.h"
#import <MediaPlayer/MediaPlayer.h>


@interface newCaseViewControllerv2 : UIViewController<UICollectionViewDataSource,UICollectionViewDelegate,MBProgressHUDDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak,nonatomic) IBOutlet UICollectionView *CaseOptionsCollectionView;
@property (weak,nonatomic) IBOutlet UICollectionView *secondCaseOptionsCollectionView;

@property (strong,nonatomic) UITableView *TemplateSecondLevelTableView;
@property (strong,nonatomic) NSString *manualLocationPropertyNum;

@property (strong,nonatomic) PFObject *itsMTLObject;

@property (strong,nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;

@end
