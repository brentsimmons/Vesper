//
//  VSSyncNoteMerger.m
//  Vesper
//
//  Created by Brent Simmons on 11/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSyncNoteMerger.h"
#import "VSSyncUtilities.h"
#import "QSAPIObject.h"
#import "VSDataController.h"
#import "QSDateParser.h"


static void addTagsToNote(VSNote *note, NSString *tagNames, VSDataController *dataController) {

	/*tagNames are two-space-separated string of tag names.*/

	if (QSStringIsEmpty(tagNames)) {

		if (QSIsEmpty(note.tags)) {
			return;
		}

		note.tags = nil;
		[dataController saveTagsForNote:note];
		return;
	}

	NSArray *tagNamesArray = [tagNames componentsSeparatedByString:@"  "];
	NSArray *tags = [tagNamesArray qs_map:^id(NSString *oneTagName) {

		return [dataController tagWithName:oneTagName];
	}];

	if (![tags isEqualToArray:note.tags]) {
		note.tags = tags;
		[dataController saveTagsForNote:note];
		[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncNoteTagsDidChangeNotification object:nil userInfo:@{VSNoteKey : note}];
	}
}


static void addAttachmentsToNote(VSNote *note, NSString *attachmentsString, VSDataController *dataController) {

	if (QSStringIsEmpty(attachmentsString)) {

		if (QSIsEmpty(note.attachments)) {
			return;
		}

		note.attachments = nil;
		[dataController saveAttachmentsForNote:note];
		return;
	}

	/*Attachments come in as base64-encoded JSON.*/

	NSData *attachmentsJSONData = [[NSData alloc] initWithBase64EncodedString:attachmentsString options:0];
	NSArray *attachmentsJSON = [NSJSONSerialization JSONObjectWithData:attachmentsJSONData options:0 error:nil];
	NSArray *attachments = [QSAPIObject objectsWithJSONArray:attachmentsJSON class:[VSAttachment class]];

	if (QSIsEmpty(attachments) && QSIsEmpty(note.attachments)) {
		return;
	}

	if ([note.attachments isEqualToArray:attachments]) {
		return;
	}

	note.attachments = attachments;
	[dataController saveAttachmentsForNote:note];
}


static NSDate *dateForKey(NSDictionary *JSONDictionary, NSString *key) {


	NSString *dateString = JSONDictionary[key];
	if (QSStringIsEmpty(dateString)) {
		return nil;
	}

	return QSDateWithString(dateString);
}


static VSNote *mergedNote(VSNote *existingNote, NSDictionary *syncNote, VSDataController *dataController) {

	@autoreleasepool {

		BOOL didChange = VSSyncProperty(existingNote, syncNote, @"text");
		if (didChange) {
			[existingNote textDidChange];
		}
		
		if (VSSyncProperty(existingNote, syncNote, @"archived")) {
			didChange = YES;
		}

		NSDate *syncSortDateModificationDate = dateForKey(syncNote, VSSyncSortDateModificationDateKey);
		if (VSSyncObjectHasLaterDate(syncSortDateModificationDate, existingNote.sortDateModificationDate)) {

			NSString *dateString = syncNote[VSSyncSortDateKey];
			if (dateString) {
				NSDate *sortDate = QSDateWithString(dateString);
				existingNote.sortDate = sortDate;
				didChange = YES;
			}
		}

		NSDate *syncTagsModificationDate = dateForKey(syncNote, VSSyncTagsModificationDateKey);

		if (VSSyncObjectHasLaterDate(syncTagsModificationDate, existingNote.tagsModificationDate)) {

			didChange = YES;
			existingNote.tagsModificationDate = syncTagsModificationDate;
			addTagsToNote(existingNote, syncNote[VSSyncTagNamesKey], dataController);
		}

		NSDate *syncAttachmentsModificationDate = dateForKey(syncNote, VSSyncAttachmentsModificationDateKey);
		if (VSSyncObjectHasLaterDate(syncAttachmentsModificationDate, existingNote.attachmentsModificationDate)) {

			didChange = YES;
			existingNote.attachmentsModificationDate = syncAttachmentsModificationDate;
			addAttachmentsToNote(existingNote, syncNote[VSSyncAttachmentsKey], dataController);
		}

		if (didChange) {
			return existingNote;
		}

		return nil;
	}
}


void VSSyncMergeNotes(NSArray *JSONNotes, VSDataController *dataController, QSVoidCompletionBlock completion) {

	if (QSIsEmpty(JSONNotes)) {
		QSCallCompletionBlock(completion);
		return;
	}

	NSArray *uniqueIDs = [JSONNotes valueForKeyPath:VSSyncNoteIDKey];

	[dataController notesWithUniqueIDs:uniqueIDs fetchResultsBlock:^(NSArray *fetchedObjects) {

		NSDictionary *existingNotes = [fetchedObjects qs_dictionaryUsingKey:QSUniqueIDKey];
		NSMutableArray *notesToSave = [NSMutableArray new];

		for (NSDictionary *oneSyncNote in JSONNotes) {

			int64_t oneSyncNoteUniqueID = [oneSyncNote[VSSyncNoteIDKey] longLongValue];
			NSCAssert(oneSyncNoteUniqueID != 0LL, nil);
			if (oneSyncNoteUniqueID == 0LL) {
				continue;
			}

			VSNote *oneExistingNote = existingNotes[@(oneSyncNoteUniqueID)];
			VSNote *oneNoteToSave = nil;

			if (oneExistingNote != nil) {
				oneNoteToSave = mergedNote(oneExistingNote, oneSyncNote, dataController);
			}
			else {
				oneNoteToSave = [VSNote objectWithJSONRepresentation:oneSyncNote];
				addTagsToNote(oneNoteToSave, oneSyncNote[VSSyncTagNamesKey], dataController);
				addAttachmentsToNote(oneNoteToSave, oneSyncNote[VSSyncAttachmentsKey], dataController);
			}

			if (oneNoteToSave) {
				[notesToSave addObject:oneNoteToSave];
			}
		}

		[dataController saveNotes:[notesToSave copy]];
		if (notesToSave.count > 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncNotesDidChangeNotification object:nil userInfo:@{VSNotesKey: notesToSave}];
		}

		QSCallCompletionBlock(completion);
	}];
}


