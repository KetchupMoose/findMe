//
//  newCaseViewControllerv3.h
//  findMe
//
//  Created by Brian Allen on 2015-06-30.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "findMeBaseViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface newCaseViewControllerv3 : findMeBaseViewController<UICollectionViewDataSource,UICollectionViewDelegate,MBProgressHUDDelegate,CLLocationManagerDelegate,UITableViewDataSource, UITableViewDelegate,UIAlertViewDelegate>

@property (strong,nonatomic) UIScrollView *baseScrollView;
@property (strong,nonatomic) NSMutableArray *totalSetsOfParentTemplates;
@property (strong,nonatomic) NSMutableArray *parentTemplateCategories;
@property (strong,nonatomic) NSArray *allTemplates;
@property (strong,nonatomic) NSMutableArray *templatePickerActiveChoices;
@property (strong,nonatomic) PFObject *itsMTLObject;
@property (strong,nonatomic) UITableView *TemplateSecondLevelTableView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong,nonatomic) NSString *manualLocationPropertyNum;
@property (strong,nonatomic) NSArray *designationProperties;

@end
