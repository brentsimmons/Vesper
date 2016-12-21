//
//  VSSQLDataController.m
//  Vesper
//
//  Created by Brent Simmons on 2/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSQLDataController.h"
#import "QSDatabaseQueue.h"
#import "FMDatabase.h"
#import "NSString+QSDatabase.h"


@interface VSSQLDataController ()

@property (nonatomic) QSDatabaseQueue *queue;

@end


@implementation VSSQLDataController


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_queue = [[QSDatabaseQueue alloc] initWithFilename:@"VesperSQLData.sqlite3" excludeFromBackup:NO];

	[_queue update:^(FMDatabase *database) {

		[database executeUpdate:@"CREATE TABLE if not exists deletedNotes (clientID INTEGER UNIQUE NOT NULL);"];
	}];
	[_queue vacuum];

	return self;
}


#pragma mark - API

- (void)deletedNoteIDs:(QSFetchResultsBlock)fetchResultsBlock {

	/*Fetch results is array of clientIDs.*/

	[self.queue fetch:^(FMDatabase *database) {

		FMResultSet *rs = [database executeQuery:@"select clientID from deletedNotes;"];
		NSArray *deletedNoteIDs = [self clientIDsWithResultSet:rs];

		dispatch_async(dispatch_get_main_queue(), ^{
			fetchResultsBlock(deletedNoteIDs);
		});
	}];
}


- (void)addDeletedNoteClientIDs:(NSArray *)clientIDs {

	[self.queue update:^(FMDatabase *database) {

		for (NSNumber *oneClientID in clientIDs) {
			[database executeUpdate:@"insert or replace into deletedNotes (clientID) values (?);", oneClientID];
		}
	}];
}


- (void)removeDeletedNoteClientIDs:(NSArray *)clientIDs {

	if (QSIsEmpty(clientIDs)) {
		return;
	}

	[self.queue update:^(FMDatabase *database) {

		NSString *placeholder = [NSString qs_SQLValueListWithPlaceholders:[clientIDs count]];
		NSString *sqlString = [NSString stringWithFormat:@"delete from deletedNotes where id in %@;", placeholder];
		[database executeUpdate:sqlString withArgumentsInArray:clientIDs];
	}];
}


@end
