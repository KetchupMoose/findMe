//
//  popupViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface popupViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *testView;
@property (weak, nonatomic) IBOutlet UITableView *answersTableView;

@property (weak,nonatomic) IBOutlet UIButton *updateButton;

-(IBAction)closePopup:(id)sender;

@end
