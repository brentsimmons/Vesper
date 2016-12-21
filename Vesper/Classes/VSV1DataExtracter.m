//
//  VSV1DataExtracter.m
//  Vesper
//
//  Created by Brent Simmons on 9/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSV1DataExtracter.h"
#import "FMDatabase.h"
#import "FMDatabase+QSKit.h"
#import "VSNote.h"
#import "VSAttachment.h"
#import "VSTag.h"


/*1.x schema:

 @"CREATE TABLE if not exists notes (uniqueID TEXT UNIQUE, text TEXT, textModificationDate DATE, searchText TEXT, archived INTEGER, archivedModificationDate DATE, creationDate DATE, tags TEXT, tagsModificationDate DATE, links TEXT, linksModificationDate DATE, sortDate DATE, sortDateModificationDate DATE, attachmentUniqueID TEXT, attachmentMimeType TEXT, attachmentHeight INTEGER, attachmentWidth INTEGER, attachmentModificationDate DATE);"

 */

static NSString *VSImportUniqueIDKey = @"uniqueID";
static NSString *VSImportTextKey = @"text";
static NSString *VSImportArchivedKey = @"archived";
static NSString *VSImportCreationDateKey = @"creationDate";
static NSString *VSImportSortDateKey = @"sortDate";
static NSString *VSImportTagsKey = @"tags";
static NSString *VSImportAttachmmentUniqueIDKey = @"attachmentUniqueID";
static NSString *VSImportAttachmentMimeTypeKey = @"attachmentMimeType";
static NSString *VSImportAttachmentHeightKey = @"attachmentHeight";
static NSString *VSImportAttachmentWidthKey = @"attachmentWidth";


#pragma mark - Attachments

static VSAttachment *attachmentWithNoteDictionary(NSDictionary *d) {

	NSCParameterAssert(!QSIsEmpty(d));

	NSString *uniqueID = d[VSImportAttachmmentUniqueIDKey];
	if (QSStringIsEmpty(uniqueID)) { /*No attachment; not an error*/
		return nil;
	}

	NSString *mimeType = d[VSImportAttachmentMimeTypeKey];
	NSCAssert(!QSStringIsEmpty(mimeType), nil);
	if (QSStringIsEmpty(mimeType)) {
		return nil;
	}

	int32_t height = (int32_t)[d[VSImportAttachmentHeightKey] integerValue];
	int32_t width = (int32_t)[d[VSImportAttachmentWidthKey] integerValue];

	VSAttachment *attachment = [VSAttachment attachmentWithUniqueID:uniqueID mimeType:mimeType height:height width:width];
	NSCAssert(attachment != nil, nil);

	return attachment;
}


static void addAttachmentToNote(VSNote *note, NSDictionary *d) {

	VSAttachment *attachment = attachmentWithNoteDictionary(d);

	if (attachment) {
		note.attachments = @[attachment];
	}
}


#pragma mark - Tags

static NSArray *tagsWithNoteDictionary(NSDictionary *d) {

	NSString *tagsString = d[VSImportTagsKey];
	if (QSStringIsEmpty(tagsString)) {
		return nil;
	}

	NSArray *tagComponents = [tagsString componentsSeparatedByString:@"  "]; /*two spaces separate tags*/
	if (QSIsEmpty(tagComponents)) {
		return nil;
	}

	NSMutableArray *tags = [NSMutableArray new];
	NSMutableSet *tagNames = [NSMutableSet new];

	for (NSString *oneTagString in tagComponents) {

		if ([tagNames containsObject:oneTagString]) {
			continue;
		}

		VSTag *oneTag = [[VSTag alloc] initWithName:oneTagString];
		[tags addObject:oneTag];
	}

	return [tags copy];
}


static void addTagsToNote(VSNote *note, NSDictionary *d) {

	note.tags = tagsWithNoteDictionary(d);
}


#pragma mark - Notes

static NSString *v1TutorialText1 = @"Collect your thoughts\nAdd tags to notes to group related items in playlist-like collections. These notes have all been tagged “Tutorial.”";
static NSString *v1TutorialText2 = @"Slide to archive\nDone with a note? Just slide it to the left to send it to the archive.";
static NSString *v1TutorialText3 = @"Attach photos\nTake a new picture, or choose one from your photo library.";
static NSString *v1TutorialText4 = @"Prioritize\nTap and hold, then drag notes up or down to reorder them.";
static NSString *v1TutorialText5 = @"Need more help?\nVisit us at vesperapp.co.";
static NSString *v1TutorialText5a = @"Need more help?\nVisit us on the web at vesperapp.co";

static void handlePotentialTutorialNote(VSNote *note) {

	/*If note has one tag and it's the Tutorial tag,
	 and note text matches v1 tutorial text,
	 then it's a tutorial note.

	 Its uniqueID is special,
	 so it's the same on each machine,
	 so we don't end up with duplicates.*/

	@autoreleasepool {

		NSArray *tags = note.tags;
		if ([tags count] != 1) {
			return;
		}

		NSString *noteText = note.text;
		if (QSStringIsEmpty(noteText)) {
			return;
		}

		VSTag *noteTag = tags[0];
		if (![noteTag.name isEqualToString:@"Tutorial"]) {
			return;
		}

		NSArray *tutorialText = @[v1TutorialText1, v1TutorialText2, v1TutorialText3, v1TutorialText4, v1TutorialText5];
		int64_t i = 1;

		for (NSString *oneTutorialText in tutorialText) {

			if ([oneTutorialText isEqualToString:noteText]) {

				note.uniqueID = i;
				return;
			}
			
			i++;
		}

		if ([noteText isEqualToString:v1TutorialText5a]) {
			note.uniqueID = 5;
		}
	}
}


static VSNote *noteWithDictionary(NSDictionary *d) {

	@autoreleasepool {

		VSNote *note = [VSNote new];
		NSDate *creationDate = d[VSImportCreationDateKey];
		note.creationDate = creationDate ? creationDate : [NSDate date];

		note.text = d[VSImportTextKey];
		[note textDidChange];

		note.archived = [[d objectForKey:VSImportArchivedKey] boolValue];

		NSDate *sortDate = d[VSImportSortDateKey];
		note.sortDate = sortDate ? sortDate : note.creationDate;

		addAttachmentToNote(note, d);
		addTagsToNote(note, d);

		handlePotentialTutorialNote(note);

		return note;
	}
}


static NSArray *notesWithDatabase(FMDatabase *database) {

	NSMutableArray *notes = [NSMutableArray new];

	@autoreleasepool {

		FMResultSet *resultSet = [database executeQuery:@"select * from notes;"];

		while ([resultSet next]) {

			@autoreleasepool {

				NSMutableDictionary *d = [NSMutableDictionary new];

				[d qs_safeSetObject:[resultSet stringForColumn:VSImportUniqueIDKey] forKey:VSImportUniqueIDKey];
				[d qs_safeSetObject:[resultSet stringForColumn:VSImportTextKey] forKey:VSImportTextKey];
				[d qs_safeSetObject:@([resultSet boolForColumn:VSImportArchivedKey]) forKey:VSImportArchivedKey];
				[d qs_safeSetObject:[resultSet dateForColumn:VSImportCreationDateKey] forKey:VSImportCreationDateKey];
				[d qs_safeSetObject:[resultSet stringForColumn:VSImportTagsKey] forKey:VSImportTagsKey];
				[d qs_safeSetObject:[resultSet dateForColumn:VSImportSortDateKey] forKey:VSImportSortDateKey];
				[d qs_safeSetObject:[resultSet stringForColumn:VSImportAttachmmentUniqueIDKey] forKey:VSImportAttachmmentUniqueIDKey];
				[d qs_safeSetObject:[resultSet stringForColumn:VSImportAttachmentMimeTypeKey] forKey:VSImportAttachmentMimeTypeKey];
				[d qs_safeSetObject:@([resultSet intForColumn:VSImportAttachmentHeightKey]) forKey:VSImportAttachmentHeightKey];
				[d qs_safeSetObject:@([resultSet intForColumn:VSImportAttachmentWidthKey]) forKey:VSImportAttachmentWidthKey];

				if (QSIsEmpty(d)) {
					continue;
				}

				VSNote *oneNote = noteWithDictionary(d);
				[notes qs_safeAddObject:oneNote];
			}
		}
	}
	
	return [notes copy];
}


#pragma mark - API

NSArray *VSV1Data(FMDatabase *database) {

	NSCParameterAssert(database != nil);

	NSArray *notes = notesWithDatabase(database);
	return notes;
}

