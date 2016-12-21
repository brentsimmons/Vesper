//
//  VSBinaryCache.h
//  Vesper
//
//  Created by Brent Simmons on 7/18/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


/*The folder this manages must already exist.
 Doesn't do any locking or queueing -- caller is responsible.*/


@interface VSBinaryCache : NSObject


- (instancetype)initWithFolder:(NSString *)folder;

- (NSString *)filePathForKey:(NSString *)key;

- (BOOL)setBinaryData:(NSData *)data key:(NSString *)key error:(NSError **)error;

- (NSData *)binaryDataForKey:(NSString *)key error:(NSError **)error;

- (BOOL)removeBinaryDataForKey:(NSString *)key error:(NSError **)error;

- (BOOL)binaryForKeyExists:(NSString *)key;

- (UInt64)lengthOfBinaryDataForKey:(NSString *)key error:(NSError **)error;

- (NSArray *)allKeys:(NSError **)error;


extern NSString *VSBinaryKey;
extern NSString *VSBinaryLength;

- (NSArray *)allObjects:(NSError **)error; /*NSDictionary objects with VSBinaryKey and VSBinaryLength.*/


@end
