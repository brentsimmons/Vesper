//
//  FMResultSet+RSExtras.m
//  Vesper
//
//  Created by Brent Simmons on 2/19/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "FMResultSet+RSExtras.h"


@implementation FMResultSet (RSExtras)


- (id)valueForKey:(NSString *)key {
	return [self objectForColumnName:key];
}


@end
