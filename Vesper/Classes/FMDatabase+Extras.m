/*
	FMDatabase+Extras.m
	NetNewsWire

	Created by Brent Simmons on 5/30/06.
	Copyright 2006 Ranchero Software. All rights reserved.
*/


#import "FMDatabase+Extras.h"


@implementation FMDatabase (Extras)


+ (FMDatabase *)openDatabaseWithPath:(NSString *)f {
	FMDatabase *fmdb = [self databaseWithPath:f];
	if (!fmdb || ![fmdb open])
		return nil;
	return fmdb;
	}
	

@end

