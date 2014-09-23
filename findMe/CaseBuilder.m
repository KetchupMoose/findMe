//
//  CaseBuilder.m
//  findMe
//
//  Created by Brian Allen on 2014-09-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "CaseBuilder.h"
#import "Case.h"

@implementation CaseBuilder

+ (NSArray *)casesFromJSON:(NSData *)objectNotation error:(NSError **)error
{
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:objectNotation options:0 error:&localError];
    
    if (localError != nil) {
        *error = localError;
        return nil;
    }
    
    NSMutableArray *cases = [[NSMutableArray alloc] init];
    
    NSArray *results = [parsedObject valueForKey:@"cases"];
    NSLog(@"Count %d", results.count);
    
    for (NSDictionary *caseDic in results) {
        Case *matchCase = [[Case alloc] init];
        
        for (NSString *key in caseDic) {
            if ([matchCase respondsToSelector:NSSelectorFromString(key)]) {
                [matchCase setValue:[caseDic valueForKey:key] forKey:key];
            }
        }
        
        [cases addObject:matchCase];
    }
    
    return cases;
}

@end
