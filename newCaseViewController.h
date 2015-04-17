//
//  newCaseViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-11-07.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import "findMeBaseViewController.h"

@interface newCaseViewController : findMeBaseViewController <UICollectionViewDataSource,UICollectionViewDelegate,UITableViewDataSource, UITableViewDelegate,MBProgressHUDDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak,nonatomic) IBOutlet UICollectionView *CaseOptionsCollectionView;

@property (strong,nonatomic) UITableView *TemplateSecondLevelTableView;
@property (strong,nonatomic) NSString *manualLocationPropertyNum;

@property (strong,nonatomic) PFObject *itsMTLObject;

@end
