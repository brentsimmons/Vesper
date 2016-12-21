//
//  VSSyncObject.h
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@interface VSSyncObject : NSObject


+ (NSArray *)syncObjectsWithManagedObjects:(NSArray *)managedObjects;
+ (NSArray *)syncObjectsWithJSONDictionaries:(NSArray *)JSONDictionaries;
+ (NSArray *)JSONDictionariesWithSyncObjects:(NSArray *)syncObjects;
+ (NSArray *)JSONDictionariesWithManagedObjects:(NSArray *)managedObjects;


/*Subclasses must override.*/

+ (instancetype)syncObjectWithManagedObject:(id)managedObject;
+ (instancetype)syncObjectWithJSONDictionary:(NSDictionary *)JSONDictionary;
- (NSDictionary *)JSONDictionary;


@end



@interface NSDictionary (VSSyncObject)


/*Returns nil is string is empty.*/

- (NSArray *)vs_JSONArrayForKey:(NSString *)key;

/*If date is nil or NSNull, returns [NSDate distantPast].*/

- (NSDate *)vs_JSONDateForKey:(NSString *)key;

///*Decodes an array or dictionary that was JSON + base64-encoded.*/
//
//- (id)vs_JSONObjectForKey:(NSString *)key;

@end


@interface NSMutableDictionary (VSSyncObject)


/*If array is nil or empty, sets @"".*/

- (void)vs_setJSONArray:(NSArray *)array forKey:(NSString *)key;


/*If d is nil, sets VSOldDate().*/

- (void)vs_setJSONDate:(NSDate *)d forKey:(NSString *)key;

///*Encodes an array or dictionary as JSON + base64-encoded.*/
//
//- (void)vs_setJSONObject:(id)obj forKey:(NSString *)key;


@end

