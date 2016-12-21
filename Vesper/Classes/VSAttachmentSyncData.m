//
//  VSAttachmentSyncData.m
//  Vesper
//
//  Created by Brent Simmons on 11/25/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAttachmentSyncData.h"
#import "QSDatabaseQueue.h"
#import "FMDatabase.h"
#import "NSString+QSDatabase.h"
#import "VSAttachmentDataController.h"


@interface VSAttachmentSyncData ()

@property (nonatomic) QSDatabaseQueue *databaseQueue;

@end


@implementation VSAttachmentSyncData


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_databaseQueue = [[QSDatabaseQueue alloc] initWithFilename:@"VesperAttachmentSyncData.sqlite3" excludeFromBackup:YES];

	static NSString *lastVacuumDateKey = @"VSAttachmentSyncDataLastVacuumDate";
	NSDate *lastVacuumDate = [[NSUserDefaults standardUserDefaults] objectForKey:lastVacuumDateKey];
	if (lastVacuumDate == nil) {
		lastVacuumDate = [NSDate distantPast];
	}
	NSDate *cutOffDate = [NSDate qs_dateWithNumberOfDaysInThePast:10];
	if ([cutOffDate earlierDate:lastVacuumDate]) {
		[self.databaseQueue vacuum];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:lastVacuumDateKey];
	}

	[_databaseQueue update:^(FMDatabase *database) {

		[database executeUpdate:@"CREATE TABLE if not exists attachments (uniqueID TEXT UNIQUE, existsOnServer BOOLEAN, createdLocally BOOLEAN, deletedFromServer BOOLEAN, shouldDelete BOOLEAN);"];

	}];

	[self ensureRowsForExistingAttachments];

	return self;
}


- (NSArray *)uniqueIDsWithResultSet:(FMResultSet *)rs {

	NSMutableArray *uniqueIDs = [NSMutableArray new];
	while ([rs next]) {
		NSString *oneUniqueID = [rs stringForColumn:@"uniqueID"];
		[uniqueIDs qs_safeAddObject:oneUniqueID];
	}

	return [uniqueIDs copy];
}


- (void)uniqueIDsOfAttachmentsNotOnServer:(QSFetchResultsBlock)fetchResultsBlock {

	[self.databaseQueue fetch:^(FMDatabase *database) {

		FMResultSet *rs = [database executeQuery:@"select uniqueID from attachments where existsOnServer=0 and deletedFromServer=0;"];
		NSArray *uniqueIDs = [self uniqueIDsWithResultSet:rs];

		dispatch_async(dispatch_get_main_queue(), ^{
			fetchResultsBlock(uniqueIDs);
		});
	}];
}


- (void)uniqueIDsOfAttachmentsOnServerOrDeletedFromServer:(QSFetchResultsBlock)fetchResultsBlock {

	[self.databaseQueue fetch:^(FMDatabase *database) {

		FMResultSet *rs = [database executeQuery:@"select uniqueID from attachments where existsOnServer=1 or deletedFromServer=1;"];
		NSArray *uniqueIDs = [self uniqueIDsWithResultSet:rs];

		dispatch_async(dispatch_get_main_queue(), ^{
			fetchResultsBlock([uniqueIDs copy]);
		});
	}];
}


//- (void)storeUniqueIDsOfAttachmentsStoredOnServer:(NSArray *)uniqueIDs {
//
//	if (QSIsEmpty(uniqueIDs)) {
//		return;
//	}
//
//	[self.databaseQueue update:^(FMDatabase *database) {
//
//		NSString *placeholders = [NSString qs_SQLValueListWithPlaceholders:[uniqueIDs count]];
//		NSString *sqlString = [NSString stringWithFormat:@"update attachments set existsOnServer=1 where uniqueID in %@;", placeholders];
//		[database executeUpdate:sqlString withArgumentsInArray:uniqueIDs];
//		
//		FMResultSet *rs = [database executeQuery:@"select uniqueID from attachments;"];
//		NSArray *existingUniqueIDs = [self uniqueIDsWithResultSet:rs];
//
//		NSMutableSet *attachmentsToInsert = [NSMutableSet setWithArray:uniqueIDs];
//		[attachmentsToInsert minusSet:[NSSet setWithArray:existingUniqueIDs]];
//
//		if (QSIsEmpty(attachmentsToInsert)) {
//			return;
//		}
//
//		for (NSString *oneUniqueID in attachmentsToInsert) {
//			[database executeUpdate:@"insert into attachments (uniqueID, existsOnServer) values (?, ?);", oneUniqueID, @YES];
//		}
//	}];
//}


//- (void)setUniqueID:(NSString *)uniqueID deletedFromServer:(BOOL)deletedFromServer {
//
//	[self.databaseQueue update:^(FMDatabase *database) {
//
//		[database executeUpdate:@"update attachments set deletedFromServer=? where uniqueID=?", @(deletedFromServer), uniqueID];
//	}];
//}


//- (void)insertOrUpdateAttachment:(NSString *)uniqueID createdLocally:(BOOL)createdLocally {
//
//	[self.databaseQueue update:^(FMDatabase *database) {
//
//		FMResultSet *rs = [database executeQuery:@"select 1 from attachments where uniqueID=?;"];
//		BOOL attachmentExists = NO;
//		while ([rs next]) {
//			attachmentExists = [rs boolForColumnIndex:0];
//		}
//
//		if (attachmentExists) {
//			[database executeUpdate:@"update attachments set createdLocally=? where uniqueID=?", @(createdLocally), uniqueID];
//		}
//		else {
//			[database executeUpdate:@"insert into attachments (uniqueID, createdLocally) values (?, ?);", uniqueID, @(createdLocally)];
//		}
//	}];
//}


- (void)logout {

	[self.databaseQueue update:^(FMDatabase *database) {

		[database executeUpdate:@"update attachments set existsOnServer=0;"];
		[database executeUpdate:@"update attachments set deletedFromServer=0;"];
		[database executeUpdate:@"update attachments set shouldDelete=0;"];
	}];
}


- (void)addUniqueIDOfAttachmentCreatedLocally:(NSString *)uniqueID {

	[self insertOrUpdateAttachment:uniqueID createdLocally:YES];
}


- (void)ensureUniqueIDsExist:(NSArray *)uniqueIDs {

	if (QSIsEmpty(uniqueIDs)) {
		return;
	}

	[self.databaseQueue update:^(FMDatabase *database) {

		FMResultSet *rs = [database executeQuery:@"select uniqueID from attachments;"];
		NSArray *existingUniqueIDs = [self uniqueIDsWithResultSet:rs];

		NSMutableSet *missingUniqueIDs = [[NSSet setWithArray:uniqueIDs] mutableCopy];
		[missingUniqueIDs minusSet:[NSSet setWithArray:existingUniqueIDs]];

		if (QSIsEmpty(missingUniqueIDs)) {
			return;
		}

		for (NSString *oneUniqueID in missingUniqueIDs) {
			[database executeUpdate:@"insert into attachments (uniqueID) values ?;", oneUniqueID];
		}
	}];
}


- (void)ensureRowsForExistingAttachments {

	VSAttachmentUniqueIDsOnDisk(^(NSArray *uniqueIDs) {

		[self ensureUniqueIDsExist:uniqueIDs];

	});
}


- (void)uniqueIDsOfAttachmentsToUpload:(QSFetchResultsBlock)fetchResultsBlock {

	/*If an attachment is:
	 1. Attached to a note,
	 2. On disk,
	 3. Not on the server (or deleted from server),
	 then it should be uploaded.*/

	[app_delegate.dataController allAttachmentIDs:^(NSArray *uniqueIDs) {

		if (QSIsEmpty(uniqueIDs)) {

			dispatch_async(dispatch_get_main_queue(), ^{
				fetchResultsBlock(nil);
				return;
			});
		}

		VSAttachmentUniqueIDsOnDisk(^(NSArray *diskUniquedIDs) {

			if (QSIsEmpty(diskUniquedIDs)) {

				dispatch_async(dispatch_get_main_queue(), ^{
					fetchResultsBlock(nil);
					return;
				});
			}

			NSMutableSet *remainingUniqueIDs = [NSMutableSet setWithArray:uniqueIDs];
			[remainingUniqueIDs intersectSet:[NSSet setWithArray:diskUniquedIDs]];

			if (QSIsEmpty(remainingUniqueIDs)) {

				dispatch_async(dispatch_get_main_queue(), ^{
					fetchResultsBlock(nil);
					return;
				});
			}

			[self uniqueIDsOfAttachmentsOnServerOrDeletedFromServer:^(NSArray *uniqueIDsOnServer) {

				[remainingUniqueIDs minusSet:[NSSet setWithArray:uniqueIDsOnServer]];

				dispatch_async(dispatch_get_main_queue(), ^{
					fetchResultsBlock([remainingUniqueIDs allObjects]);
					return;
				});
			}];
		});
	}];
}


@end
