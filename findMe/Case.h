//
//  Case.h
//  findMe
//
//  Created by Brian Allen on 2014-09-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Case : NSObject

@property (strong, nonatomic) NSString *caseID;
@property (strong, nonatomic) NSString *caseName;
@property (strong, nonatomic) NSArray *caseItems;

@end
