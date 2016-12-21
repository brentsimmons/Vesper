//
//  NSString+QSDatabase.h
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

@import Foundation;


@interface NSString (QSDatabase)


/*Returns @"(?, ?, ?)" -- where number of ? spots is specified by numberOfValues.
 numberOfValues should be greater than 0. Triggers an NSParameterAssert if not.*/

+ (NSString *)qs_SQLValueListWithPlaceholders:(NSUInteger)numberOfValues;


/*Returns @"(someColumn, anotherColumm, thirdColumn)" -- using passed-in keys.
 It's essential that you trust keys. They must not be user input.
 Triggers an NSParameterAssert if keys are empty.*/

+ (NSString *)qs_SQLKeysListWithArray:(NSArray *)keys;


/*Returns @"key1=?, key2=?" using passed-in keys. Keys must be trusted.*/

+ (NSString *)qs_SQLKeyPlaceholderPairsWithKeys:(NSArray *)keys;


@end
