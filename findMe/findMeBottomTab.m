//
//  findMeBottomTab.m
//  findMe
//
//  Created by Brian Allen on 2015-08-05.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "findMeBottomTab.h"

@implementation findMeBottomTab

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        
        
        [self setUpBottomTabViews];
        
    }
   
    return self;
    
}

-(void)setUpBottomTabViews
{
    
    //setup bottom tab views
    self.tabBG = [[UIImageView alloc] initWithFrame:self.bounds];
    
    UIImage *bgImg = [UIImage imageNamed:@"bg_menu@3x.png"];
    self.tabBG.image = bgImg;
    
    self.tabBG.userInteractionEnabled = YES;
    [self addSubview:self.tabBG];
    
    int numOfTabs = 4;
    
    float tabWidth = self.frame.size.width/4;
    float tabHeight = 50;
    
    int selectedViewTag = self.selectedViewController.intValue;
    
    for (int i=0;i<numOfTabs;i++)
    {
        
        UIImageView *standardTabView = [[UIImageView alloc] initWithFrame:CGRectMake(tabWidth*i,0,tabWidth,tabHeight)];
        standardTabView.userInteractionEnabled = YES;
        
        CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *tcolor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
        
        //only highlight the selected image
       if(selectedViewTag ==i)
       {
           standardTabView.image = [UIImage imageNamed:@"bg_menu-active@3x.png"];
       }
        
        UIButton *tabTextButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,tabWidth,tabHeight)];
        tabTextButton.tag = i;
        [tabTextButton addTarget:self action:@selector(tabPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        //btnImgView dimensions depends on the tab
        UIImageView *btnImageView;
        UILabel *btnTextLabel;
        btnTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,tabWidth,20)];
        if(i==0)
        {
            //pixel dimensions 42x42
            btnImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,14,14)];
            btnImageView.image = [UIImage imageNamed:@"ico_home@3x.png"];
            btnImageView.center = CGPointMake(tabTextButton.center.x,tabTextButton.center.y-7);
            //change frame to go 5 pixels up
            btnTextLabel.text = @"HOME";
            }
        
        if(i==1)
        {
            //pixel dimensions 48 × 48 pixels
            btnImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,24/1.5,24/1.5)];
            btnImageView.image = [UIImage imageNamed:@"ico_progress@3x.png"];
            btnImageView.center = CGPointMake(tabTextButton.center.x,tabTextButton.center.y-7);
            btnTextLabel.text = @"PROGRESS";
           
        }
        if(i==2)
        {
            //pixel dimensions 48 × 48 pixels
            btnImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,24/1.5,24/1.5)];
            btnImageView.image = [UIImage imageNamed:@"ico_matches@3x.png"];
            btnImageView.center = CGPointMake(tabTextButton.center.x,tabTextButton.center.y-7);
            btnTextLabel.text = @"MATCHES";
        }
        if(i==3)
        {
            //pixel dimensions 33 × 48 pixels
            btnImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,16.5/1.5,24/1.5)];
            btnImageView.image = [UIImage imageNamed:@"ico_profile@3x.png"];
            btnImageView.center = CGPointMake(tabTextButton.center.x,tabTextButton.center.y-7);
            btnTextLabel.text = @"PROFILE";
        }
        
        btnTextLabel.textColor = [UIColor whiteColor];
        btnTextLabel.center = CGPointMake(tabTextButton.center.x,tabTextButton.center.y+14);
        btnTextLabel.textAlignment = NSTextAlignmentCenter;
        btnTextLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:12];
        
        [tabTextButton addSubview:btnTextLabel];
        
        [tabTextButton addSubview:btnImageView];
        
        
        [standardTabView addSubview:tabTextButton];
        [self.tabBG addSubview:standardTabView];
        
        
    }
}

-(void)tabPressed:(id)sender
{
    UIButton *sendingButton = (UIButton *)sender;
    NSInteger sendingTag = sendingButton.tag;
    [self.delegate tabSelected:sendingTag];
    
}
    


@end
