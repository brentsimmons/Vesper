//
//  VSNote.h
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "QSAPIObject.h"


/*Mutable.*/

@class VSAttachment;
@class VSTimelineNote;


extern NSString *VSNoteUserDidEditNotification;


@interface VSNote : NSObject <NSCopying, QSAPIObject>

@property (nonatomic, assign) int64_t uniqueID;
@property (nonatomic) NSString *text;
@property (nonatomic, assign) BOOL archived;
@property (nonatomic) NSDate *creationDate;
@property (nonatomic) NSDate *sortDate;
@property (nonatomic) NSArray *links;
@property (nonatomic) NSString *truncatedText; /*For timeline*/
@property (nonatomic) NSDate *modificationDate;
@property (nonatomic) NSString *thumbnailID;

@property (nonatomic) NSDate *archivedModificationDate;
@property (nonatomic) NSDate *sortDateModificationDate;
@property (nonatomic) NSDate *tagsModificationDate;
@property (nonatomic) NSDate *textModificationDate;
@property (nonatomic) NSDate *attachmentsModificationDate;

/*Relationships*/

@property (nonatomic) NSArray *tags;
@property (nonatomic) NSArray *attachments;

/*Convenience*/

@property (nonatomic, readonly) VSAttachment *firstImageAttachment;
@property (nonatomic, assign, readonly) BOOL hasThumbnail;
@property (nonatomic) NSArray *tagNames; /*Used by sync system only.*/
@property (nonatomic, assign, readonly) BOOL isTutorialNote;
@property (nonatomic, readonly) NSDate *mostRecentModificationDate;

@property (nonatomic) QS_IMAGE *thumbnail;


/*Just use -init if you don't have a uniqueID -- it will generate one.*/

- (instancetype)initWithUniqueID:(int64_t)uniqueID;


/*User updating. Use these instead of the properties when the user makes a change.
 This ensures that the various dates and derived values are also updated.
 If any change isn't really an update
 -- the parameter value matches the property value --
 then nothing happens.*/


/*The below triggers a save of the note.*/

- (void)userDidUpdateText:(NSString *)text;

- (void)userDidMarkAsArchived:(BOOL)archived;
- (void)userDidUpdateSortDate:(NSDate *)sortDate;

/*The below triggers a save of attachments and lookup table.*/

- (void)userDidRemoveAllAttachments;
- (void)userDidReplaceAllAttachmentsWithImage:(QS_IMAGE *)image;

/*The below triggers a save of tags and lookup table.*/

- (void)userDidUpdateTags:(NSArray *)tags;


/*For sync system and migraters.*/

- (void)textDidChange;


- (instancetype)copyWithNewUniqueIDAndCreationDate;


+ (void)sendUserDidEditNoteNotification;

@end
