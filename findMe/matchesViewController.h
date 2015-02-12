//
//  matchesViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-02-11.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface matchesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong,nonatomic) IBOutlet UITableView *matchesTableView;

@end
