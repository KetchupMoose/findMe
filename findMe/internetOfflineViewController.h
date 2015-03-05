//
//  internetOfflineViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-03-04.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface internetOfflineViewController : UIViewController

@property (weak,nonatomic) IBOutlet UIButton *internetRetryButton;
- (IBAction)retryConnection:(id)sender;
@end
