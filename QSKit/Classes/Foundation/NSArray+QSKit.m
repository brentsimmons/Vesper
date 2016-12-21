//
//  NSArray+QSKit.m
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/31/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "NSArray+QSKit.h"


@implementation NSArray (QSKit)


- (id)qs_safeObjectAtIndex:(NSUInteger)anIndex {
	if ([self count] < 1 || anIndex >= [self count])
	if (anIndex >= [self count])
		return nil;
	return [self objectAtIndex:anIndex];
}


- (id)qs_firstObjectWhereValueForKey:(NSString *)key equalsValue:(id)value {

	return [self qs_firstObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [[obj valueForKey:key] isEqual:value];
	}];
}


- (id)qs_firstObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {

	NSUInteger ix = [self indexOfObjectPassingTest:predicate];
	if (ix == NSNotFound) {
		return nil;
	}

	return self[ix];
}


- (NSArray *)qs_map:(QSMapBlock)mapBlock {

	NSMutableArray *mappedArray = [NSMutableArray new];

	for (id oneObject in self) {

		id objectToAdd = mapBlock(oneObject);
		if (objectToAdd) {
			[mappedArray addObject:objectToAdd];
		}
	}

	return [mappedArray copy];
}


- (NSArray *)qs_arrayWithCopyOfEachObject {

	return [self qs_map:^id(id obj) {
		return [obj copy];
	}];
}


- (NSDictionary *)qs_dictionaryUsingKey:(id)key {

	NSMutableDictionary *d = [NSMutableDictionary new];

	for (id oneObject in self) {

		id oneUniqueID = [oneObject valueForKey:key];
		d[oneUniqueID] = oneObject;
	}

	return [d copy];
}


@end
