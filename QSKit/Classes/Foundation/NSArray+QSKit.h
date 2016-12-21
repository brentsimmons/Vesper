//
//  NSArray+QSKit.h
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/31/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import Foundation;


@interface NSArray (QSKit)


/*Returns nil if out of bounds instead of throwing an exception.*/

- (id)qs_safeObjectAtIndex:(NSUInteger)anIndex;

/*Does valueForKey:key. When value isEqual, returns YES.*/

- (id)qs_firstObjectWhereValueForKey:(NSString *)key equalsValue:(id)value;

/*Gets the index from indexOfObjectPassingTest: and returns the object.
 Returns nil if not found.*/

- (id)qs_firstObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;


typedef id (^QSMapBlock)(id obj);

- (NSArray *)qs_map:(QSMapBlock)mapBlock;


- (NSArray *)qs_arrayWithCopyOfEachObject;


/*Does [valueForKey:key] on each object and uses that as the key in the dictionary.*/

- (NSDictionary *)qs_dictionaryUsingKey:(id)key;


@end
