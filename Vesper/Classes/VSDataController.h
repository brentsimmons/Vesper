//
//  VSDataController.h
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


/*Call on main thread only.*/


@class QSDatabaseQueue;
@class VSNote;
@class VSTimelineNote;
@class QSFetchRequest;
@class VSTag;


/*DidSave userInfo: VSUniqueIDsKey, VSNotesKey.
 Deleted userInfo: VSUniqueIDsKey, VSUserDidDeleteKey.*/

extern NSString *VSNotesDidSaveNotification;
extern NSString *VSTagsForNoteDidSaveNotification;
extern NSString *VSAttachmentsForNoteDidSaveNotification;
extern NSString *VSNotesDeletedNotification;
extern NSString *VSUserDidDeleteKey;

@interface VSDataController : NSObject

+ (instancetype)sharedController;



@property (nonatomic, readonly) QSDatabaseQueue *queue;


/*Tags*/

@property (nonatomic, readonly) NSArray *allTags;
@property (nonatomic, readonly) NSArray *tagsWithAtLeastOneNote;

- (VSTag *)existingTagWithName:(NSString *)name;
- (VSTag *)tagWithName:(NSString *)name;

- (void)saveTags:(NSArray *)tags;

- (void)tagsForSidebar:(QSFetchResultsBlock)fetchResultsBlock;


/*Notes*/

- (void)hasAtLeastOneUntaggedNote:(QSBoolResultBlock)resultBlock;
- (void)hasAtLeastOneArchivedNote:(QSBoolResultBlock)resultBlock;

- (void)saveNotes:(NSArray *)notes;
- (void)saveTagsForNote:(VSNote *)note;
- (void)saveAttachmentsForNote:(VSNote *)note;
- (void)saveNotesIncludingTagsAndAttachments:(NSArray *)notes; /*Calls all three above.*/

- (int64_t)generateUniqueIDForNote;

- (void)deleteNotes:(NSArray *)uniqueIDs userDidDelete:(BOOL)userDidDelete;

- (void)JSONNotesModifiedSinceDate:(NSDate *)d fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;

- (VSNote *)noteWithUniqueID:(int64_t)uniqueID; /*Fetches existing note. Blocks main thread.*/
- (void)noteWithUniqueID:(int64_t)uniqueID objectResultBlock:(QSObjectResultBlock)objectResultBlock; /*Use this instead.*/

- (NSArray *)notesWithUniqueIDs:(NSArray *)uniqueIDs; /*Blocks. Use async version instead.*/
- (void)notesWithUniqueIDs:(NSArray *)uniqueIDs fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;

- (void)activeNotes:(QSFetchResultsBlock)fetchResultsBlock;
- (void)archivedNotes:(QSFetchResultsBlock)fetchResultsBlock;

/*Timeline notes*/

- (VSTimelineNote *)timelineNoteWithUniqueID:(int64_t)uniqueID; /*Blocks main thread. Try not to use.*/

- (void)updateSortDate:(NSDate *)sortDate uniqueID:(int64_t)uniqueID;
- (void)updateArchived:(BOOL)archived uniqueID:(int64_t)uniqueID;

- (QSFetchRequest *)fetchRequestForAllNotes;
- (QSFetchRequest *)fetchRequestForArchivedNotes;
- (QSFetchRequest *)fetchRequestForNotesWithTag:(VSTag *)tag;
- (QSFetchRequest *)fetchRequestForUntaggedNotes;

/*Fetched notes are sorted by sortDate.*/

- (void)timelineNotesContainingSearchString:(NSString *)searchString tag:(VSTag *)tag includeArchivedNotes:(BOOL)includeArchivedNotes archivedNotesOnly:(BOOL)archivedNotesOnly fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;


/*Attachments*/

- (void)allAttachmentIDs:(QSFetchResultsBlock)fetchResultsBlock;
- (void)deleteAttachments:(NSArray *)attachments;
- (void)attachmentIDsInLookupTable:(QSFetchResultsBlock)fetchResultsBlock;

/*Deleted Notes*/

- (void)uniqueIDsInDeletedNotesTable:(QSFetchResultsBlock)fetchResultsBlock;
- (void)addUniqueIDsToDeletedNotesTable:(NSArray *)uniqueIDs;
- (void)removeUniqueIDsFromDeletedNotesTable:(NSArray *)uniqueIDs;


@end
