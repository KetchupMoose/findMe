//
//  UIView+CALayerControls.m
//  findMe
//
//  Created by Brian Allen on 2015-06-05.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "UIView+CALayerControls.h"

@implementation UIView (CALayerControls)
@dynamic borderColor,borderWidth,cornerRadius;

-(void)setBorderColor:(UIColor *)borderColor{
    if(borderColor !=nil)
    {
       [self.layer setBorderColor:borderColor.CGColor];
    }
    
}

-(void)setBorderWidth:(NSInteger)borderWidth{
    
    if(borderWidth >0)
    {
         [self.layer setBorderWidth:borderWidth];
    }
   
}

-(void)setCornerRadius:(NSInteger)cornerRadius{
    if(cornerRadius >0)
    {
        [self.layer setCornerRadius:cornerRadius];
    }
  
}
@end
