//
//  NSDictionary+QSKit.h
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 11/1/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import Foundation;


@interface NSDictionary (QSKit)

/*Keys that aren't strings are ignored. No coercion.*/

- (id)qs_objectForCaseInsensitiveKey:(NSString *)key;

- (BOOL)qs_boolForKey:(NSString *)key; /*NO if doesn't exist.*/


@end
