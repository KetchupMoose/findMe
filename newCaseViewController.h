//
//  newCaseViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-11-07.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface newCaseViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate,UITableViewDataSource, UITableViewDelegate,MBProgressHUDDelegate>


@property (weak,nonatomic) IBOutlet UICollectionView *CaseOptionsCollectionView;

@property (strong,nonatomic) UITableView *TemplateSecondLevelTableView;



@end
