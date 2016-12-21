//
//  VSTagSuggester.h
//  Vesper
//
//  Created by Brent Simmons on 3/30/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@interface VSTagSuggester : NSObject


+ (NSArray *)tags:(NSArray *)tags matchingSearchString:(NSString *)searchString;


@end
