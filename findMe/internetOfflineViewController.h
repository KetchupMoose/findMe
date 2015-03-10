//
//  internetOfflineViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-03-04.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class internetOfflineViewController;

@protocol internetOfflineViewControllerDelegate

- (void)dismissIOVC;

@end

@interface internetOfflineViewController : UIViewController

@property (weak,nonatomic) IBOutlet UIButton *internetRetryButton;
- (IBAction)retryConnection:(id)sender;
@property (weak,nonatomic) id<internetOfflineViewControllerDelegate> delegate;
@end
