//
//  VSDataController.m
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

@import Security;
#import "VSDataController.h"
#import "VSTutorialDataImporter.h"
#import "VSV1DataExtracter.h"
#import "VSV1Importer.h"
#import "QSDatabaseQueue.h"
#import "FMDatabase.h"
#import "QSDataModel.h"
#import "FMDatabase+QSKit.h"
#import "NSString+QSDatabase.h"
#import "QSTable.h"
#import "QSLookupTable.h"
#import "QSFetchRequest.h"
#import "VSThumbnailDatabase.h"
#import "VSTimelineNote.h"
#import "VSAttachmentStorage.h"
#import "VSDateManager.h"


@interface VSDataController () <QSDatabaseQueueDelegate>

@property (nonatomic) QSDataModel *dataModel;
@property (nonatomic) NSMutableSet *noteIDs;
@property (nonatomic, readonly) NSMutableDictionary *tags;
@property (nonatomic, readonly) NSMutableDictionary *notes;
@property (nonatomic, readonly) QSTable *tagsTable;
@property (nonatomic, readonly) QSTable *notesTable;
@property (nonatomic, readonly) QSTable *timelineNotesTable;
@property (nonatomic, readonly) QSTable *attachmentsTable;
@property (nonatomic, readonly) QSLookupTable *attachmentsLookupTable;
@property (nonatomic) QSFetchRequest *sidebarTagsFetchRequest;
@property (nonatomic) QSFetchRequest *tagsWithAnyNotesFetchRequest;
@property (nonatomic, readwrite) NSArray *tagsWithAtLeastOneNote;

@end


@implementation VSDataController


#pragma mark - Class Methods

+ (instancetype)sharedController {
	
	static id gMyInstance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMyInstance = [self new];
	});
	
	return gMyInstance;
}

#pragma mark - Init

- (instancetype)init {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_tags = [NSMutableDictionary new];
	_notes = [NSMutableDictionary new];
	
	NSString *databaseFilePath = QSDataFile(nil, @"Vesper2-Notes.sqlite3");
#if TARGET_IPHONE_SIMULATOR || DEBUG
	NSLog(@"databaseFilePath: %@", databaseFilePath);
#endif
	
	_queue = [[QSDatabaseQueue alloc] initWithFilepath:databaseFilePath excludeFromBackup:NO];
	_queue.delegate = self;
	
	NSString *dataModelPath = [[NSBundle mainBundle] pathForResource:@"DataModel2" ofType:@"plist"];
	NSDictionary *dataModelDictionary = [NSDictionary dictionaryWithContentsOfFile:dataModelPath];
	NSAssert(dataModelDictionary != nil, nil);
	
	NSString *createStatementsPath = [[NSBundle mainBundle] pathForResource:@"CreateStatements2" ofType:@"sql"];
	NSError *error = nil;
	NSString *createStatements = [NSString stringWithContentsOfFile:createStatementsPath encoding:NSUTF8StringEncoding error:&error];
	NSAssert(error == nil, nil);
	
	_dataModel = [[QSDataModel alloc] initWithDictionary:dataModelDictionary createStatements:createStatements databaseFilePath:databaseFilePath queue:_queue];
	
	_tagsTable = [_dataModel objectTableForClass:[VSTag class]];
	_notesTable = [_dataModel objectTableForClass:[VSNote class]];
	_timelineNotesTable = [_dataModel objectTableForClass:[VSTimelineNote class]];
	_attachmentsTable = [_dataModel objectTableForClass:[VSAttachment class]];
	QSObjectModel *notesObjectModel = [_dataModel objectModelForClassName:NSStringFromClass([VSNote class])];
	_attachmentsLookupTable = [notesObjectModel lookupTableForRelationship:@"attachments"];
	
	NSString *lastVacuumDateKey = @"lastVacuumDate";
	NSDate *lastVacuumDate = [[NSUserDefaults standardUserDefaults] objectForKey:lastVacuumDateKey];
	if (!lastVacuumDate) {
		lastVacuumDate = [NSDate distantPast];
	}
	NSDate *cutOffDate = [NSDate qs_dateWithNumberOfDaysInThePast:6];
	if ([cutOffDate earlierDate:lastVacuumDate] == lastVacuumDate) {
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:lastVacuumDateKey];
		[self.queue vacuum];
	}
	
	[_queue fetchSync:^(FMDatabase *database) {
		
		NSArray *tags = [_tagsTable fetchAllObjects:database];
		[self cacheTags:tags];
	}];
	
	_noteIDs = [NSMutableSet new];
	
	[self.notesTable allUniqueIDs:^(NSArray *noteIDs) {
		[self cacheNoteIDs:noteIDs];
	}];
	
	[self performSelectorOnMainThread:@selector(loadTutorialDataOrMigrateDataIfNeeded) withObject:nil waitUntilDone:NO];
	
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarTagsDidChange:) name:VSSidebarTagsDidChangeNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)note {
	
	[self.notes removeAllObjects];
}


- (void)sidebarTagsDidChange:(NSNotification *)note {
	
	NSArray *tags = [note userInfo][VSTagsKey];
	self.tagsWithAtLeastOneNote = tags;
}


#pragma mark - Tags

- (NSArray *)allTags {
	return [self.tags allValues];
}


- (void)cacheTags:(NSArray *)tags {
	
	for (VSTag *oneTag in tags) {
		
		NSString *oneUniqueID = oneTag.uniqueID;
		if (!self.tags[oneUniqueID]) {
			self.tags[oneUniqueID] = oneTag;
		}
	}
}


- (void)fetchAndCacheTags {
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		[self.queue fetchSync:^(FMDatabase *database) {
			
			NSArray *tags = [self.tagsTable fetchAllObjects:database];
			[self cacheTags:tags];
		}];
	});
}


- (NSUInteger)numberOfTags {
	
	return [self.tags count];
}


- (VSTag *)existingTagWithName:(NSString *)name {
	
	NSParameterAssert(!QSStringIsEmpty(name));
	
	NSString *uniqueID = [VSTag uniqueIDForTagName:name];
	
	VSTag *tag = self.tags[uniqueID];
	return tag;
}


- (VSTag *)tagWithName:(NSString *)name {
	
	NSParameterAssert(!QSStringIsEmpty(name));
	if (QSStringIsEmpty(name)) {
		return nil;
	}
	
	VSTag *tag = [self existingTagWithName:name];
	
	if (!tag) {
		tag = [[VSTag alloc] initWithName:name];
		
		[self saveTags:@[tag]];
	}
	
	return tag;
}


- (void)saveTags:(NSArray *)tags {
	
	[self cacheTags:tags];
	[self.tagsTable saveObjects:tags];
}


- (void)tagsForSidebar:(QSFetchResultsBlock)fetchResultsBlock {
	
	if (!self.sidebarTagsFetchRequest) {
		
		self.sidebarTagsFetchRequest = [[QSFetchRequest alloc] initWithTable:self.tagsTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
			
			FMResultSet *rs = [database executeQuery:@"select * from tags where uniqueID in (select distinct tagID from tagsNotesLookup, notes where tagsNotesLookup.noteID = notes.uniqueID and notes.archived = 0);"];
			return rs;
		}];
	}
	[self.sidebarTagsFetchRequest performFetch:fetchResultsBlock];
}


#pragma mark - Notes

- (void)hasAtLeastOneUntaggedNote:(QSBoolResultBlock)resultBlock {
	
	[self.queue fetch:^(FMDatabase *database) {
		
		BOOL hasAtLeastOneUntaggedNote = NO;
		
		FMResultSet *rs = [database executeQuery:@"select 1 from notes where archived=0 and uniqueID not in (select distinct noteID from tagsNotesLookup) limit 1;"];
		while ([rs next]) {
			hasAtLeastOneUntaggedNote = [rs boolForColumnIndex:0];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			resultBlock(hasAtLeastOneUntaggedNote);
		});
	}];
}


- (void)hasAtLeastOneArchivedNote:(QSBoolResultBlock)resultBlock {
	
	[self.queue fetch:^(FMDatabase *database) {
		
		BOOL hasAtLeastOneArchivedNote = NO;
		
		FMResultSet *rs = [database executeQuery:@"select 1 from notes where archived=1 limit 1;"];
		while ([rs next]) {
			hasAtLeastOneArchivedNote = [rs boolForColumnIndex:0];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			resultBlock(hasAtLeastOneArchivedNote);
		});
	}];
}


NSString *VSNotesDidSaveNotification = @"VSNotesDidSaveNotification";

- (void)saveNotes:(NSArray *)notes {
	
	if ([notes count] < 1) {
		return;
	}
	
	[self cacheNoteIDs:[notes valueForKeyPath:@"uniqueID"]];
	[self cacheNotes:notes];
	[self.notesTable saveObjects:notes];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNotesDidSaveNotification object:self userInfo:@{VSUniqueIDsKey : [notes valueForKeyPath:QSUniqueIDKey], VSNotesKey: notes}];
}


NSString *VSAttachmentsForNoteDidSaveNotification = @"VSAttachmentsForNoteDidSaveNotification";

- (void)saveAttachmentsForNote:(VSNote *)note {
	
	[self cacheNote:note];
	[self.attachmentsTable saveObjects:note.attachments];
	[self.notesTable updateLookupTableForObject:note relationship:@"attachments"];
	
	NSArray *uniqueIDs = @[@(note.uniqueID)];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSAttachmentsForNoteDidSaveNotification object:self userInfo:@{VSUniqueIDsKey : uniqueIDs, VSNotesKey: @[note]}];
}


NSString *VSTagsForNoteDidSaveNotification = @"VSTagsForNoteDidSaveNotification";

- (void)saveTagsForNote:(VSNote *)note {
	
	/*Tags should already be saved via tagWithName:.
	 Caching is probably redundant, but it's done anyway because it's cheap.
	 The main thing is to update lookup table.*/
	
	[self cacheNote:note];
	[self cacheTags:note.tags];
	[self.notesTable updateLookupTableForObject:note relationship:@"tags"];
	
	NSArray *uniqueIDs = @[@(note.uniqueID)];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSTagsForNoteDidSaveNotification object:self userInfo:@{VSUniqueIDsKey : uniqueIDs, VSNotesKey: @[note]}];
}


- (void)saveNotesIncludingTagsAndAttachments:(NSArray *)notes {
	
	[self saveNotes:notes];
	for (VSNote *oneNote in notes) {
		
		[self saveTagsForNote:oneNote];
		[self saveAttachmentsForNote:oneNote];
	}
}


NSString *VSNotesDeletedNotification = @"VSNotesDeletedNotification";
NSString *VSUserDidDeleteKey = @"userDidDelete";

- (void)deleteNotes:(NSArray *)uniqueIDs userDidDelete:(BOOL)userDidDelete {
	
	[self.notesTable deleteObjectsWithUniqueIDs:uniqueIDs];
	
	if (userDidDelete) {
		[self addUniqueIDsToDeletedNotesTable:uniqueIDs];
		[VSNote sendUserDidEditNoteNotification];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNotesDeletedNotification object:self userInfo:@{VSUniqueIDsKey : uniqueIDs, VSUserDidDeleteKey : @(userDidDelete)}];
}


- (void)cacheNoteIDForNote:(VSNote *)note {
	
	[self cacheNoteIDs:@[@(note.uniqueID)]];
}


- (void)cacheNoteIDs:(NSArray *)noteIDs {
	
	[self.noteIDs addObjectsFromArray:noteIDs];
}


- (void)JSONNotesModifiedSinceDate:(NSDate *)d fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {
	
	[self.notesTable JSONObjects:^FMResultSet *(FMDatabase *database) {
		
		if (!d) {
			return [database executeQuery:@"select * from notes where uniqueID > ?;", @(VSTutorialNoteMaxID)];
		}
		return [database executeQuery:@"select * from notes where (modificationDate > ?) and (uniqueID > ?) ", d, @(VSTutorialNoteMaxID)];
		
	} fetchResultsBlock:fetchResultsBlock];
}


- (void)cacheNote:(VSNote *)note {
	
	if (!note) {
		return;
	}
	
	id uniqueID = @(note.uniqueID);
	if (!self.notes[uniqueID]) {
		self.notes[uniqueID] = note;
	}
}


- (void)cacheNotes:(NSArray *)notes {
	
	for (VSNote *oneNote in notes) {
		[self cacheNote:oneNote];
	}
}


- (VSNote *)cachedNote:(int64_t)uniqueID {
	
	return self.notes[@(uniqueID)];
}


- (NSArray *)cachedNotesWithUniqueIDs:(NSArray *)uniqueIDs {
	
	NSMutableArray *notes = [NSMutableArray new];
	for (id oneUniqueID in uniqueIDs) {
		VSNote *oneCachedNote = [self cachedNote:[oneUniqueID longLongValue]];
		[notes qs_safeAddObject:oneCachedNote];
	}
	
	return [notes copy];
}


- (VSNote *)noteWithUniqueID:(int64_t)uniqueID {
	
	VSNote *cachedNote = [self cachedNote:uniqueID];
	if (cachedNote) {
		return cachedNote;
	}
	
	__block VSNote *note = nil;
	
	[self.queue fetchSync:^(FMDatabase *database) {
		
		note = [self.notesTable fetchObjectWithUniqueID:@(uniqueID) database:database];
	}];
	
	[self cacheNote:note];
	
	return note;
}


- (void)noteWithUniqueID:(int64_t)uniqueID objectResultBlock:(QSObjectResultBlock)objectResultBlock {
	
	VSNote *cachedNote = [self cachedNote:uniqueID];
	if (cachedNote) {
		QSCallBlockWithParameter(objectResultBlock, cachedNote);
		return;
	}
	
	[self.queue fetch:^(FMDatabase *database) {
		
		VSNote *note = [self.notesTable fetchObjectWithUniqueID:@(uniqueID) database:database];
		QSCallBlockWithParameter(objectResultBlock, note);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[self cacheNote:note];
		});
	}];
}


- (NSArray *)notesWithUniqueIDs:(NSArray *)uniqueIDs {
	
	NSArray *cachedNotes = [self cachedNotesWithUniqueIDs:uniqueIDs];
	if ([cachedNotes count] == [uniqueIDs count]) {
		return cachedNotes;
	}
	
	__block NSArray *notes = nil;
	
	[self.queue fetchSync:^(FMDatabase *database) {
		
		notes = [self.notesTable fetchObjectsWithUniqueIDs:uniqueIDs database:database];
	}];
	
	[self cacheNotes:notes];
	
	return notes;
}


- (void)notesWithUniqueIDs:(NSArray *)uniqueIDs fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {
	
	NSArray *cachedNotes = [self cachedNotesWithUniqueIDs:uniqueIDs];
	if ([cachedNotes count] == [uniqueIDs count]) {
		QSCallFetchResultsBlock(fetchResultsBlock, cachedNotes);
		return;
	}
	
	[self.notesTable objectsWithUniqueIDs:uniqueIDs fetchResultsBlock:fetchResultsBlock];
}


- (void)activeNotes:(QSFetchResultsBlock)fetchResultsBlock {
	
	QSFetchRequest *request = [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select * from notes where archived=0;"];
	}];
	
	[request performFetch:fetchResultsBlock];
}

- (void)archivedNotes:(QSFetchResultsBlock)fetchResultsBlock {
	
	QSFetchRequest *request = [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select * from notes where archived=1;"];
	}];
	
	[request performFetch:fetchResultsBlock];
}

- (void)updateSortDate:(NSDate *)sortDate uniqueID:(int64_t)uniqueID {
	
	/*Update in database. Set sortDate, sortModificationDate to now, and modificationDate.*/
	
	NSDate *now = [[VSDateManager sharedManager] currentDate];
	NSDictionary *d = @{@"sortDate" : sortDate, @"sortDateModificationDate" : now, @"modificationDate" : now};
	[self.notesTable updateObjectWithUniqueID:@(uniqueID) dictionary:d];
	
	VSNote *note = [self noteWithUniqueID:uniqueID];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNotesDidSaveNotification object:self userInfo:@{VSUniqueIDsKey: @[@(uniqueID)], VSNotesKey: @[note]}];
	[VSNote sendUserDidEditNoteNotification];
}


- (void)updateArchived:(BOOL)archived uniqueID:(int64_t)uniqueID {
	
	NSDate *now = [[VSDateManager sharedManager] currentDate];
	
	/*Sorts to top upon being archived/unarchived.*/
	NSDictionary *d = @{@"archived" : @(archived), @"archivedModificationDate" : now, @"modificationDate" : now, @"sortDate" : now, @"sortDateModificationDate" : now};
	
	[self.notesTable updateObjectWithUniqueID:@(uniqueID) dictionary:d];
	
	VSNote *note = [self noteWithUniqueID:uniqueID];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNotesDidSaveNotification object:self userInfo:@{VSUniqueIDsKey: @[@(uniqueID)], VSNotesKey: @[note]}];
}


#pragma mark - Timeline Notes

- (VSTimelineNote *)timelineNoteWithUniqueID:(int64_t)uniqueID {
	
	__block VSTimelineNote *timelineNote = nil;
	
	[self.queue fetchSync:^(FMDatabase *database) {
		
		timelineNote = [self.timelineNotesTable fetchObjectWithUniqueID:@(uniqueID) database:database];
	}];
	
	return timelineNote;
}


#if !TARGET_OS_IPHONE

- (QSFetchRequest *)fetchRequestForAllNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		FMResultSet *rs = [database executeQuery:@"select * from notes where archived=0 order by sortDate DESC;"];
		return rs;
	}];
}

- (QSFetchRequest *)fetchRequestForArchivedNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select * from notes where archived=1 order by sortDate DESC;"];
	}];
}


- (QSFetchRequest *)fetchRequestForUntaggedNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select * from notes where archived=0 and uniqueID not in (select distinct noteID from tagsNotesLookup) order by sortDate DESC;"];
	}];
}

- (QSFetchRequest *)fetchRequestForNotesWithTag:(VSTag *)tag {
	
	NSString *tagUniqueID = tag.uniqueID;
	
	return [[QSFetchRequest alloc] initWithTable:self.notesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select * from notes where (uniqueID in (select noteID from tagsNotesLookup where tagID = ?)) and (archived=0) order by sortDate DESC;", tagUniqueID];
	}];
}

#else

- (QSFetchRequest *)fetchRequestForAllNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.timelineNotesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		FMResultSet *rs = [database executeQuery:@"select uniqueID, truncatedText, links, sortDate, thumbnailID, archived from notes where archived=0 order by sortDate DESC;"];
		return rs;
	}];
}


- (QSFetchRequest *)fetchRequestForArchivedNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.timelineNotesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select uniqueID, truncatedText, links, sortDate, thumbnailID, archived from notes where archived=1 order by sortDate DESC;"];
	}];
}


- (QSFetchRequest *)fetchRequestForUntaggedNotes {
	
	return [[QSFetchRequest alloc] initWithTable:self.timelineNotesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select uniqueID, truncatedText, links, sortDate, thumbnailID, archived from notes where archived=0 and uniqueID not in (select distinct noteID from tagsNotesLookup) order by sortDate DESC;"];
	}];
}


- (QSFetchRequest *)fetchRequestForNotesWithTag:(VSTag *)tag {
	
	NSString *tagUniqueID = tag.uniqueID;
	
	return [[QSFetchRequest alloc] initWithTable:self.timelineNotesTable resultSetBlock:^FMResultSet *(FMDatabase *database) {
		
		return [database executeQuery:@"select uniqueID, truncatedText, links, sortDate, thumbnailID, archived from notes where (uniqueID in (select noteID from tagsNotesLookup where tagID = ?)) and (archived=0) order by sortDate DESC;", tagUniqueID];
	}];
}

#endif


- (void)timelineNotesContainingSearchString:(NSString *)searchString tag:(VSTag *)tag includeArchivedNotes:(BOOL)includeArchivedNotes archivedNotesOnly:(BOOL)archivedNotesOnly fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {
	
	[self.timelineNotesTable objects:^FMResultSet *(FMDatabase *database) {
		
		NSMutableString *sql = [NSMutableString stringWithString:@"select uniqueID, truncatedText, links, sortDate, thumbnailID, archived from notes where "];
		
		if (!includeArchivedNotes) {
			[sql appendString:@"archived=0 and "];
		}
		else if (archivedNotesOnly) {
			[sql appendString:@"archived=1 and "];
		}
		
		if (tag) {
			[sql appendString:@"uniqueID in (select noteID from tagsNotesLookup where tagID=?) and "];
		}
		
		[sql appendString:@"textMatchesSearchString(text, ?) order by sortDate DESC;"];
		
		FMResultSet *rs = nil;
		if (tag) {
			rs = [database executeQuery:sql, tag.uniqueID, searchString];
		}
		else {
			rs = [database executeQuery:sql, searchString];
		}
		
		return rs;
		
	} fetchResultsBlock:fetchResultsBlock];
	
}

#pragma mark - Startup - Loading Data

- (void)postDataMigrationDidCompleteNotification {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDataMigrationDidCompleteNotification object:nil];
}


- (void)loadTutorialDataOrMigrateDataIfNeeded {
	
	if ([self hasV1DatabaseFile]) {
		
		[[NSNotificationCenter defaultCenter] postNotificationName:VSDataMigrationDidBeginNotification object:nil];
		
		[self migrateV1Data:^{
			
			[self postDataMigrationDidCompleteNotification];
			
		}];
	}
	
	else if ([self shouldLoadTutorialData]) {
		
		[self loadTutorialData:^{
			
			;
		}];
	}
	
	else {
		
		if ([app_delegate.theme boolForKey:@"updatingNotes.testByShowingAtStartup"]) {
			
			[[NSNotificationCenter defaultCenter] postNotificationName:VSDataMigrationDidBeginNotification object:nil];
			
			[self performSelector:@selector(postDataMigrationDidCompleteNotification) withObject:nil afterDelay:3.0];
		}
		
		[self cleanupAttachments];
	}
}


#pragma mark - Tutorial Data

static NSString *VSDidLoadTutorialDataKey = @"didLoadTutorialNotes";

- (void)loadTutorialData:(QSVoidCompletionBlock)completion {
	
	[VSTutorialDataImporter loadTutorialData:^{
		
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:VSDidLoadTutorialDataKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		QSCallCompletionBlock(completion);
	}];
}


- (BOOL)shouldLoadTutorialData {
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:VSDidLoadTutorialDataKey]) {
		return NO;
	}
	
	if ([self.tags count] > 0) {
		return NO;
	}
	
	__block BOOL hasAtLeastOneNoteOrTag = NO;
	
	[self.queue fetchSync:^(FMDatabase *database) {
		
		hasAtLeastOneNoteOrTag = ![self.tagsTable isEmpty:database] || ![self.notesTable isEmpty:database];
	}];
	
	return !hasAtLeastOneNoteOrTag;
}


#pragma mark - Migrate Old Data

- (NSString *)v1DatabaseFile {
	
	NSString *dataFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *databaseFile = [dataFolder stringByAppendingPathComponent:@"Vesper-Notes.sqlite3"];
	
	return databaseFile;
}


- (BOOL)hasV1DatabaseFile {
	
	BOOL isDirectory = NO;
	NSString *databaseFile = [self v1DatabaseFile];
	
	return [[NSFileManager defaultManager] fileExistsAtPath:databaseFile isDirectory:&isDirectory];
}


- (NSString *)movedV1DatabaseFile {
	
	NSString *dataFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *databaseFile = [dataFolder stringByAppendingPathComponent:@"Vesper-Notes.migrated.sqlite3"];
	
	BOOL isDirectory = NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:databaseFile isDirectory:&isDirectory]) {
		
		NSString *uniqueFileName = [NSString stringWithFormat:@"Vesper-Notes.%@.migrated.sqlite3", [[NSUUID UUID] UUIDString]];
		databaseFile = [dataFolder stringByAppendingPathComponent:uniqueFileName];
	}
	
	return databaseFile;
}


- (void)moveV1DatabaseFile {
	
	NSString *databaseFile = [self v1DatabaseFile];
	NSString *movedDatabaseFile = [self movedV1DatabaseFile];
	
	[[NSFileManager defaultManager] moveItemAtPath:databaseFile toPath:movedDatabaseFile error:nil];
}


- (void)migrateV1Data:(QSVoidCompletionBlock)completion {
	
#if TARGET_OS_IPHONE
	__block QSDatabaseQueue *queue = [[QSDatabaseQueue alloc] initWithFilepath:[self v1DatabaseFile] excludeFromBackup:NO];
	
	[queue fetch:^(FMDatabase *database) {
		
		NSArray *notes = VSV1Data(database);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			queue = nil;
			[self moveV1DatabaseFile];
			
			VSImportV1Notes(notes, self);
			completion();
		});
	}];
#endif
	
}


#pragma mark - Attachments

- (void)allAttachmentIDs:(QSFetchResultsBlock)fetchResultsBlock {
	
	return [self.attachmentsTable allUniqueIDs:fetchResultsBlock];
}


- (void)attachmentIDsInLookupTable:(QSFetchResultsBlock)fetchResultsBlock {
	
	[self.attachmentsLookupTable allChildIDs:self.queue fetchResultsBlock:fetchResultsBlock];
}


- (void)allReferencedAttachmentIDs:(QSFetchResultsBlock)fetchResultsBlock {
	
	/*All attachment IDs in attachments table and in attachments lookup table.*/
	
	[self allAttachmentIDs:^(NSArray *attachmentUniqueIDs) {
		
		[self attachmentIDsInLookupTable:^(NSArray *attachmentIDsInLookupTable) {
			
			NSMutableSet *uniqueIDs = [NSMutableSet new];
			[uniqueIDs addObjectsFromArray:attachmentUniqueIDs];
			[uniqueIDs addObjectsFromArray:attachmentIDsInLookupTable];
			
			QSCallFetchResultsBlock(fetchResultsBlock, [uniqueIDs allObjects]);
		}];
	}];
}


- (void)deleteAttachmentsWithUniqueIDs:(NSArray *)uniqueIDs {
	
	if ([uniqueIDs count] < 1) {
		return;
	}
	
	/*Remove from lookup tables. Delete from attachments table.
	 Delete file from disk. Delete thumbnails.*/
	
	[self.attachmentsTable deleteObjectsWithUniqueIDs:uniqueIDs];
	[self.attachmentsLookupTable deleteChildIDs:uniqueIDs queue:self.queue];
	[[VSAttachmentStorage sharedStorage] deleteImages:uniqueIDs];
	[[VSThumbnailDatabase sharedDatabase] deleteThumbnails:uniqueIDs];
}


- (void)deleteAttachments:(NSArray *)attachments {
	
	NSArray *uniqueIDs = [attachments valueForKeyPath:QSUniqueIDKey];
	[self deleteAttachmentsWithUniqueIDs:uniqueIDs];
}


- (void)cleanupAttachments {
	
	[self allReferencedAttachmentIDs:^(NSArray *referencedAttachmentIDs) {
		
		[[VSThumbnailDatabase sharedDatabase] deleteUnreferencedThumbnails:referencedAttachmentIDs];
	}];
}


#pragma mark - Client IDs

static int64_t getUniqueID(void) {
	
	while (true) {
		
		/*Eventually SecRandomCopyBytes has to succeed. I think.*/
		
		int64_t uniqueID = 0;
		int err = 0;
		err = SecRandomCopyBytes(kSecRandomDefault, 8, (uint8_t *)&uniqueID);
		
		if (uniqueID < 0) { /*Positive only*/
			uniqueID = -(uniqueID);
		}
		while (uniqueID > VSNoteMaxID) {
			uniqueID = uniqueID / 2;
		}
		
		while (uniqueID < VSTutorialNoteMaxID) {
			uniqueID += VSTutorialNoteMaxID;  /*0 - VSTutorialNoteMaxID are reserved.*/
		}
		if (uniqueID > VSNoteMaxID) {
			continue; /*JavaScript 53-bit limit*/
		}
		
		if (err == 0) {
			return uniqueID;
		}
	}
	
	return 0; /*can't get here*/
}


- (int64_t)generateUniqueIDForNote {
	
	while (true) {
		
		/*Eventually we have to find a non-colliding uniqueID.*/
		
		int64_t uniqueID = getUniqueID();
		if ([self.noteIDs containsObject:@(uniqueID)]) {
			continue;
		}
		return uniqueID;
	}
	
	return 0; /*can't get here*/
}


#pragma mark - Deleted Notes

- (void)uniqueIDsInDeletedNotesTable:(QSFetchResultsBlock)fetchResultsBlock {
	
	[self.queue fetch:^(FMDatabase *database) {
		
		FMResultSet *rs = [database qs_selectColumnWithKey:QSUniqueIDKey tableName:@"deletedNotes"];
		NSArray *uniqueIDs = [rs qs_arrayForSingleColumnResultSet];
		QSCallFetchResultsBlock(fetchResultsBlock, uniqueIDs);
	}];
}


- (void)addUniqueIDsToDeletedNotesTable:(NSArray *)uniqueIDs {
	
	[self.queue update:^(FMDatabase *database) {
		
		for (NSString *oneUniqueID in uniqueIDs) {
			[database qs_insertRowWithDictionary:@{QSUniqueIDKey : oneUniqueID} insertType:QSDatabaseInsertOrIgnore tableName:@"deletedNotes"];
		}
	}];
}


- (void)removeUniqueIDsFromDeletedNotesTable:(NSArray *)uniqueIDs {
	
	if (QSIsEmpty(uniqueIDs)) {
		return;
	}
	
	[self.queue update:^(FMDatabase *database) {
		
		[database qs_deleteRowsWhereKey:QSUniqueIDKey inValues:uniqueIDs tableName:@"deletedNotes"];
	}];
}


#pragma mark - QSDatabaseQueueDelegate

static BOOL textContainsSearchString(NSString *text, NSString *searchString) {
	
	if (QSStringIsEmpty(text) || QSStringIsEmpty(searchString)) {
		return NO;
	}
	
	@autoreleasepool {
		
		/*Check each individual word. Return YES if all found.*/
		
		__block BOOL found = YES;
		
		[searchString enumerateSubstringsInRange:NSMakeRange(0, [searchString length]) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			
			NSRange range = [text rangeOfString:substring options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
			if (range.location == NSNotFound) {
				found = NO;
				*stop = YES;
			}
		}];
		
		return found;
	}
}


- (void)makeFunctionsForDatabase:(FMDatabase *)database queue:(QSDatabaseQueue *)queue {
	
	/* https://gist.github.com/ccgus/3238464 */
	
	[database makeFunctionNamed:@"textMatchesSearchString" maximumArguments:2 withBlock:^(sqlite3_context *context, int argc, sqlite3_value **argv) {
		
		@autoreleasepool {
			
			if (sqlite3_value_type(argv[0]) == SQLITE_TEXT) {
				
				const unsigned char *a = sqlite3_value_text(argv[0]);
				const unsigned char *b = sqlite3_value_text(argv[1]);
				
				NSString *text = [NSString stringWithUTF8String:(const char *)a];
				NSString *searchString = [NSString stringWithUTF8String:(const char *)b];
				
				BOOL matches = textContainsSearchString(text, searchString);
				sqlite3_result_int(context, (int)matches);
			}
			
			else {
				sqlite3_result_null(context);
			}
		}
	}];
}

@end

