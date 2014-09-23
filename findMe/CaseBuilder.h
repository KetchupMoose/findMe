//
//  CaseBuilder.h
//  findMe
//
//  Created by Brian Allen on 2014-09-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CaseBuilder : NSObject
+ (NSArray *)casesFromJSON:(NSData *)objectNotation error:(NSError **)error;
@end
