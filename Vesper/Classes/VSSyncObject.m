//
//  VSSyncObject.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "VSSyncObject.h"
#import "RSDateParser.h"


@implementation VSSyncObject


+ (NSArray *)syncObjectsWithManagedObjects:(NSArray *)managedObjects {

	NSMutableArray *syncObjects = [NSMutableArray new];

	for (NSManagedObject *oneManagedObject in managedObjects) {
		[syncObjects addObject:[self syncObjectWithManagedObject:oneManagedObject]];
	}

	return [syncObjects copy];
}


+ (instancetype)syncObjectWithManagedObject:(NSManagedObject *)managedObject {

	NSAssert(NO, @"syncObjectWithManagedObject must be overriden.");
	return nil;
}


+ (NSArray *)syncObjectsWithJSONDictionaries:(NSArray *)JSONDictionaries {

	NSMutableArray *syncObjects = [NSMutableArray new];

	for (NSDictionary *oneJSONDictionary in JSONDictionaries) {
		[syncObjects addObject:[self syncObjectWithJSONDictionary:oneJSONDictionary]];
	}

	return [syncObjects copy];
}


+ (instancetype)syncObjectWithJSONDictionary:(NSDictionary *)JSONDictionary {

	NSAssert(NO, @"syncObjectWithJSONDictionary must be overriden.");
	return nil;
}



+ (NSArray *)JSONDictionariesWithSyncObjects:(NSArray *)syncObjects {

	NSMutableArray *JSONDictionaries = [NSMutableArray new];

	for (VSSyncObject *oneSyncObject in syncObjects) {
		[JSONDictionaries addObject:[oneSyncObject JSONDictionary]];
	}

	return [JSONDictionaries copy];
}


+ (NSArray *)JSONDictionariesWithManagedObjects:(NSArray *)managedObjects {

	NSMutableArray *JSONDictionaries = [NSMutableArray new];

	for (NSManagedObject *oneManagedObject in managedObjects) {
		@autoreleasepool {
			VSSyncObject *oneSyncObject = [self syncObjectWithManagedObject:oneManagedObject];
			[JSONDictionaries addObject:[oneSyncObject JSONDictionary]];
		}
	}

	return [JSONDictionaries copy];
}


- (NSDictionary *)JSONDictionary {

	NSAssert(NO, @"JSONDictionary must be overriden.");
	return nil;
}


@end


@implementation NSDictionary (VSSyncObject)


- (NSArray *)vs_JSONArrayForKey:(NSString *)key {

	NSString *s = self[key];
	if (QSStringIsEmpty(s)) {
		return nil;
	}

	return [s componentsSeparatedByString:VSJSONArraySeparator];
}


- (NSDate *)vs_JSONDateForKey:(NSString *)key {

	NSString *s = self[key];
	if (QSStringIsEmpty(s)) {
		return VSOldDate();
	}

	return RSDateWithString(s);
}


//- (id)vs_JSONObjectForKey:(NSString *)key {
//
//	/*The value is raw JSON that's been base64-encoded. Decode then parse.*/
//
//	NSString *value = self[key];
//	if (QSIsEmpty(value)) {
//		return nil;
//	}
//
//	NSData *d = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
//	NSAssert(!QSIsEmpty(d), nil);
//	if (QSIsEmpty(d)) {
//		return nil;
//	}
//
//	NSError *error = nil;
//	id obj = [NSJSONSerialization JSONObjectWithData:d options:0 error:&error];
//	NSAssert(error == nil, nil);
//
//	return obj;
//}


@end


@implementation NSMutableDictionary (VSSyncObject)

- (void)vs_setJSONArray:(NSArray *)array forKey:(NSString *)key {

	if (QSIsEmpty(array)) {
		self[key] = @"";
		return;
	}


	NSString *s = [array componentsJoinedByString:VSJSONArraySeparator];
	self[key] = s;
}



- (void)vs_setJSONDate:(NSDate *)d forKey:(NSString *)key {

	if (d == nil) {
		d = VSOldDate();
	}

	self[key] = [d qs_iso8601DateString];
}


//- (void)vs_setJSONObject:(id)obj forKey:(NSString *)key {
//
//	/*Serialized as JSON and then base64-encoded.*/
//
//	if (obj == nil) {
//		return;
//	}
//
//	NSError *error = nil;
//	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
//	NSAssert(error == nil, nil);
//	NSAssert(!QSIsEmpty(JSONData), nil);
//
//	if (QSIsEmpty(JSONData)) {
//		return;
//	}
//
//	NSString *base64EncodedString = [JSONData base64EncodedStringWithOptions:0];
//	NSAssert(!QSStringIsEmpty(base64EncodedString), nil);
//
//	self[key] = base64EncodedString;
//}


@end
