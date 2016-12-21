//
//  VSV1Importer.m
//  Vesper
//
//  Created by Brent Simmons on 3/28/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSV1Importer.h"
#import "VSDataController.h"
#import "VSNote.h"
#import "VSTag.h"


static NSArray *uniquedTags(NSArray *tags, VSDataController *dataController) {

	if ([tags count] < 1) {
		return nil;
	}

	NSMutableArray *uniqueTags = [NSMutableArray new];

	for (VSTag *oneTag in tags) {

		VSTag *uniquedTag = [dataController tagWithName:oneTag.name];

		[uniqueTags qs_safeAddObject:uniquedTag];
	}

	return [uniqueTags copy];
}


void VSImportV1Notes(NSArray *notes, VSDataController *dataController) {

	NSMutableArray *notesToSave = [NSMutableArray new];

	for (VSNote *oneNote in notes) {

		oneNote.tags = uniquedTags(oneNote.tags, dataController);
		[dataController saveTagsForNote:oneNote];

		[dataController saveAttachmentsForNote:oneNote];

//		if (oneNote.isTutorialNote) {
//			NSArray *attachmentUniqueIDs = [oneNote.attachments valueForKeyPath:QSUniqueIDKey];
//			if ([attachmentUniqueIDs count] > 0) {
//				[dataController setAttachmentsAsTutorialAttachments:YES uniqueIDs:attachmentUniqueIDs];
//			}
//		}

		[notesToSave addObject:oneNote];
	}

	[dataController saveNotes:[notesToSave copy]];
}
