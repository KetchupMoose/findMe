//
//  findMeBottomTab.h
//  findMe
//
//  Created by Brian Allen on 2015-08-05.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol findMeBottomTabDelegate

- (void)tabSelected:(NSInteger)selectedTab;

@end

@interface findMeBottomTab : UIView
@property NSNumber *selectedViewController;
@property (nonatomic, weak) id<findMeBottomTabDelegate> delegate;
@property UIImageView *tabBG;

@end
