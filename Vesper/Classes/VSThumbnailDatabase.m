//
//  VSThumbnailDatabase.h
//  Vesper
//
//  Created by Brent Simmons on 3/15/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSThumbnailDatabase.h"
#import "VSThumbnail.h"
#import "FMDatabase.h"
#import "QSDatabaseQueue.h"
#import "NSString+QSDatabase.h"
#import "FMDatabase+QSKit.h"


@interface VSThumbnailDatabase ()

@property (nonatomic, strong) QSDatabaseQueue *databaseQueue;

@end


@implementation VSThumbnailDatabase


#pragma mark - Class Methods

+ (instancetype)sharedDatabase {
	
	static id gMyInstance = nil;
	
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		gMyInstance = [[self alloc] init];
	});
	
	return gMyInstance;
}


#pragma mark Init

- (instancetype)init {
	
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_databaseQueue = [[QSDatabaseQueue alloc] initWithFilename:@"Thumbnails007.sqlite3" excludeFromBackup:YES];
	[_databaseQueue update:^(FMDatabase *database) {
		
		[database executeUpdate:@"CREATE TABLE if not exists thumbnails (uniqueID TEXT UNIQUE, binaryData BLOB, scale INTEGER);"];
	}];
	
	NSString *lastVacuumDateKey = @"thumbnailsLastVacuumDate";
	NSDate *lastVacuumDate = [[NSUserDefaults standardUserDefaults] objectForKey:lastVacuumDateKey];
	if (lastVacuumDate == nil) {
		lastVacuumDate = [NSDate distantPast];
	}
	NSDate *oneWeekAgo = [NSDate qs_dateWithNumberOfDaysInThePast:7];
	
	if ([oneWeekAgo earlierDate:lastVacuumDate] == lastVacuumDate) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:lastVacuumDateKey];
		[_databaseQueue vacuum];
	}
	
	return self;
}


#pragma mark - API

- (void)saveThumbnails:(NSArray *)thumbnails {
	
	for (VSThumbnail *oneThumbnail in thumbnails) {
		[self saveThumbnail:oneThumbnail];
	}
}


- (void)saveThumbnail:(VSThumbnail *)thumbnail {
	
	NSParameterAssert(thumbnail.image != nil);
	NSParameterAssert(thumbnail.uniqueID != nil);
	NSParameterAssert(thumbnail.scale > 0.9f);
	
	NSString *uniqueID = thumbnail.uniqueID;
	NSUInteger scale = thumbnail.scale;
	QS_IMAGE *image = thumbnail.image;
	
	[self.databaseQueue update:^(FMDatabase *database) {
		
#if TARGET_OS_IPHONE
		NSData *binaryData = UIImagePNGRepresentation(image);
#else
		NSData *binaryData = [image TIFFRepresentation];
#endif
		
		if (binaryData == nil) {
			NSLog(@"Error creating PNG representation while saving thumbnail.");
			return;
		}
		
		[database qs_insertRowWithDictionary:@{VSThumbnailUniqueIDKey : uniqueID, VSThumbnailBinaryDataKey : binaryData, VSThumbnailScaleKey : @(scale)} insertType:QSDatabaseInsertOrIgnore tableName:VSThumbnailsTableName];
	}];
}


- (void)fetchThumbnails:(NSArray *)attachmentIDs callback:(QSFetchResultsBlock)callback {
	
	assert(!QSIsEmpty(attachmentIDs));
	
#if TARGET_OS_IPHONE
	CGFloat currentScale = [UIScreen mainScreen].scale;
#else
	//	CGFloat currentScale = 1.0f; /*TODO: scale and Mac images*/
#endif
	
	[self fetchThumbnailDataWithAttachmentIDs:attachmentIDs fetchResultsBlock:^(NSArray *fetchedObjects) {
		
		NSMutableArray *thumbnails = [NSMutableArray new];
		
		for (VSThumbnail *oneThumbnail in fetchedObjects) {
#if TARGET_OS_IPHONE
			if (oneThumbnail.scale != currentScale || oneThumbnail.image == nil)
				continue;
#else
			if (oneThumbnail.image == nil) {
				continue;
			}
#endif
			[thumbnails addObject:oneThumbnail];
		}
		
		QSCallBlockWithParameter(callback, thumbnails);
	}];
}


- (void)deleteThumbnails:(NSArray *)attachmentIDs {
	
	if (attachmentIDs.count < 1) {
		return;
	}
	
	[self.databaseQueue update:^(FMDatabase *database) {
		
		[database qs_deleteRowsWhereKey:QSUniqueIDKey inValues:attachmentIDs tableName:VSThumbnailsTableName];
	}];
}


- (void)deleteUnreferencedThumbnails:(NSArray *)referencedAttachmentIDs {
	
	if ([referencedAttachmentIDs count] < 1) {
		return; /*Would end up deleting all thumbnails, which is probably an error.*/
	}
	
	[self allThumbnailIDs:^(NSArray *fetchedObjects) {
		
		if ([fetchedObjects count] < 1) {
			return;
		}
		
		NSMutableSet *thumbnailIDsToDelete = [NSMutableSet setWithArray:fetchedObjects];
		[thumbnailIDsToDelete minusSet:[NSSet setWithArray:referencedAttachmentIDs]];
		
		[self deleteThumbnails:[thumbnailIDsToDelete allObjects]];
	}];
}

#pragma mark - Utilities


static NSString *VSThumbnailUniqueIDKey = @"uniqueID";
static NSString *VSThumbnailScaleKey = @"scale";
static NSString *VSThumbnailBinaryDataKey = @"binaryData";

- (VSThumbnail *)thumbnailWithResultSet:(FMResultSet *)resultSet {
	
	NSParameterAssert(resultSet != nil);
	NSAssert(![NSThread isMainThread], nil);
	
	VSThumbnail *thumbnail = [VSThumbnail new];
	
	thumbnail.uniqueID = [resultSet stringForColumn:VSThumbnailUniqueIDKey];
	NSAssert(!QSStringIsEmpty(thumbnail.uniqueID), nil);
	
	thumbnail.scale = (NSUInteger)[resultSet intForColumn:VSThumbnailScaleKey];
	NSAssert(thumbnail.scale > 0.9f, nil);
	
	@autoreleasepool {
		NSData *binaryData = [resultSet dataForColumn:VSThumbnailBinaryDataKey];
		NSAssert(binaryData != nil, nil);
		if (binaryData != nil) {
#if TARGET_OS_IPHONE
			thumbnail.image = [UIImage imageWithData:binaryData scale:(CGFloat)(thumbnail.scale)];
#else
			thumbnail.image = [[NSImage alloc] initWithData:binaryData];
#endif
		}
	}
	
	return thumbnail;
}


- (NSArray *)thumbnailsWithResultSet:(FMResultSet *)resultSet {
	
	NSAssert(![NSThread isMainThread], nil);
	
	NSMutableArray *thumbnails = [NSMutableArray new];
	
	while ([resultSet next]) {
		
		VSThumbnail *oneThumbnail = [self thumbnailWithResultSet:resultSet];
		if (oneThumbnail != nil) {
			[thumbnails addObject:oneThumbnail];
		}
	}
	
	return [thumbnails copy];
}


static NSString *VSThumbnailsTableName = @"thumbnails";

- (void)fetchThumbnailDataWithAttachmentIDs:(NSArray *)attachmentIDs fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {
	
	NSParameterAssert(!QSIsEmpty(attachmentIDs));
	if (attachmentIDs.count < 1) {
		return;
	}
	
	[self.databaseQueue fetch:^(FMDatabase *database) {
		
		FMResultSet *rs = [database qs_selectRowsWhereKey:QSUniqueIDKey inValues:attachmentIDs tableName:VSThumbnailsTableName];
		NSArray *thumbnails = [self thumbnailsWithResultSet:rs];
		fetchResultsBlock(thumbnails);
	}];
}


- (void)allThumbnailIDs:(QSFetchResultsBlock)fetchResultsBlock {
	
	[self.databaseQueue fetch:^(FMDatabase *database) {
		
		FMResultSet *rs = [database qs_selectColumnWithKey:VSThumbnailUniqueIDKey tableName:VSThumbnailsTableName];
		NSArray *uniqueIDs = [rs qs_arrayForSingleColumnResultSet];
		
		QSCallFetchResultsBlock(fetchResultsBlock, uniqueIDs);
	}];
}


@end
