//
//  findMeBaseViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-03-24.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface findMeBaseViewController : UIViewController

@property (strong,nonatomic) NSString *BaseViewControllerUserName;
-(void) setUserValueFromSingleton;
-(void) loadBaseViewControllerElements;
@end
