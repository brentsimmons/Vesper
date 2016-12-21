//
//  VSSyncUtilities.m
//  Vesper
//
//  Created by Brent Simmons on 11/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "VSSyncUtilities.h"
#import "QSDateParser.h"


static BOOL isNilOrNull(id obj) {

	return !obj || (id)obj == [NSNull null];
}



BOOL VSSyncObjectHasLaterDate(NSDate *syncObjectDate, NSDate *existingObjectDate) {

	if (isNilOrNull(syncObjectDate) && isNilOrNull(existingObjectDate)) {
		return NO;
	}

	if (isNilOrNull(syncObjectDate) && !isNilOrNull(existingObjectDate)) {
		return NO;
	}

	if (!isNilOrNull(syncObjectDate) && isNilOrNull(existingObjectDate)) {
		return YES;
	}

	if ([syncObjectDate isEqualToDate:existingObjectDate]) {
		return NO;
	}

	/*The same date may not be exactly the same -- the local date may have greater precision.
	 So do a floor and compare.*/

	NSTimeInterval syncTimeInterval = floor([syncObjectDate timeIntervalSince1970]);
	NSTimeInterval existingTimeInterval = floor([existingObjectDate timeIntervalSince1970]);

	if (syncTimeInterval == existingTimeInterval) {
		return NO;
	}

	if (syncTimeInterval > existingTimeInterval) {
		return YES;
	}

	return NO;
}


BOOL VSSyncProperty(id existingObject, id syncObject, NSString *propertyName) {

	@autoreleasepool {

		static OSSpinLock dateNameCacheLock = OS_SPINLOCK_INIT;

		static NSMutableDictionary *dateNameCache = nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			dateNameCache = [NSMutableDictionary new];
		});

		OSSpinLockLock(&dateNameCacheLock);
		NSString *datePropertyName = dateNameCache[propertyName];
		if (QSStringIsEmpty(datePropertyName)) {
			datePropertyName = [NSString stringWithFormat:@"%@ModificationDate", propertyName];
			dateNameCache[propertyName] = datePropertyName;
		}
		OSSpinLockUnlock(&dateNameCacheLock);

		NSDate *existingObjectDate = [existingObject valueForKey:datePropertyName];
		id syncObjectDate = [syncObject valueForKey:datePropertyName];
		if ([syncObjectDate isKindOfClass:[NSString class]]) { /*JSON date string > date*/
			syncObjectDate = QSDateWithString(syncObjectDate);
		}

		BOOL didUpdateExistingObject = NO;

		if (VSSyncObjectHasLaterDate(syncObjectDate, existingObjectDate)) {

			didUpdateExistingObject = YES;

			id syncValue = [syncObject valueForKey:propertyName];
			if (syncValue == [NSNull null]) {
				syncValue = nil;
			}
			
			id existingValue = [existingObject valueForKey:propertyName];

			if (![existingValue isEqual:syncValue]) {
				[existingObject setValue:syncValue forKey:propertyName];
			}

			[existingObject setValue:syncObjectDate forKey:datePropertyName];
		}

		return didUpdateExistingObject;
	}
}
