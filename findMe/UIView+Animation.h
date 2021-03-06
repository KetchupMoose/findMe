//
//  UIView+Animation.h
//  funnyBusiness
//
//  Created by Macbook on 2013-10-22.
//  Copyright (c) 2013 bricorp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Animation)

- (void) moveTo:(CGPoint)destination duration:(float)secs option:(UIViewAnimationOptions)option;

- (void) downUnder:(float)secs option:(UIViewAnimationOptions)option;

- (void) addSubviewWithZoomInAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option;
- (void) removeWithZoomOutAnimation:(float)secs option:(UIViewAnimationOptions)option;

- (void) addSubviewWithFadeAnimation:(UIView*)view duration:(float)secs option:(UIViewAnimationOptions)option;
- (void) removeWithSinkAnimation:(int)steps;
- (void) removeWithSinkAnimationRotateTimer:(NSTimer*) timer;
- (void) AddWithMoveTo:(UIView *) addview duration:(float) secs option:(UIViewAnimationOptions)option;
- (void) AddFromTop:(UIView *) addview duration:(float) secs option:(UIViewAnimationOptions)option;
-(void) BounceAView:(UIView *) view;
-(void) PopButtonForBounce:(UIView *) view;
-(void) BounceAddTheView:(UIView *) view;
- (void) SlideFromLeft:(UIView *) addview duration:(float) secs option:(UIViewAnimationOptions)option;
- (void) SlideFromRight:(UIView *) addview containerView:(UIView *) container duration:(float) secs option:(UIViewAnimationOptions)option;
- (void) SlideFromRightWithBounceBack:(UIView *) addview containerView:(UIView *) container duration:(float) secs option:(UIViewAnimationOptions)option;

-(void) PopButtonWithBounce:(UIButton *) view;
-(void) BounceViewThenFadeAlpha:(UIView *) view shouldRemoveParentView:(NSString *) removeOrNot;
-(void) addHeartThenSpin:(UIView *) view withCellView:(UIView *) cv;
-(void) SpinAView:(UIView *) view;
-(void) SpinThenAdd:(UIView *) view withHeartView:(UIView *) heartView;
-(void) GrowAView:(UIView *) view WithNewOrigin:(CGPoint ) newpoint;
-(void)fadeAView:(UIView *) view WithNewImage:(UIImage *) newImage;
-(void) SlideOffRight:(UIView *) view duration:(float) secs;
-(void) SlideOffLeft:(UIView *) view duration:(float) secs;
-(void)BounceSmallVertical:(UIView *)view duration:(float)secs;
-(void)BounceSmallerVertical:(UIView *)view duration:(float)secs;
-(void)SlideOffLeft:(UIView *)view thenGrowNewView:(UIView *)secondView duration:(float)secs;
-(void)slideUpView:(UIView *)view duration:(float)secs pixels:(int)pixels;
-(void)growViewAfterDelayAndDuration:(UIView *)view duration:(float)secs delay:(float)delaysecs;
-(void)bounceUpAndDown:(UIView *)view duration:(float)secs bounce:(int)bounceHeight;
@end
