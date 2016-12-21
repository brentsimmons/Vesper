//
//  VSTutorialDataImporter.m
//  Vesper
//
//  Created by Brent Simmons on 3/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTutorialDataImporter.h"
#import "VSAttachmentStorage.h"
#import "QSDateParser.h"


@implementation VSTutorialDataImporter


#pragma mark - Class Methods

+ (void)loadTutorialData:(QSVoidCompletionBlock)completion {

	VSTutorialDataImporter *dataImporter = [VSTutorialDataImporter new];

	NSString *tutorialFilePath = [[NSBundle mainBundle] pathForResource:@"TutorialData" ofType:@"plist"];
	NSArray *tutorialArray = [NSArray arrayWithContentsOfFile:tutorialFilePath];

	[dataImporter loadTutorialData:tutorialArray completion:completion];
}


#pragma mark - Attachments

- (void)attachImageWithName:(NSString *)imageName attachmentID:(NSString *)attachmentID note:(VSNote *)note {

	@autoreleasepool {

		QS_IMAGE *image = [QS_IMAGE imageNamed:imageName];
		CGSize imageSize = image.size;

		NSString *mimeType = [[VSAttachmentStorage sharedStorage] saveImageAttachment:image attachmentID:attachmentID];

		VSAttachment *attachment = [VSAttachment attachmentWithUniqueID:attachmentID mimeType:mimeType height:(int32_t)(imageSize.height) width:(int32_t)(imageSize.width)];
		note.attachments = @[attachment];
	}
}


#pragma mark - Tags

- (NSArray *)tagsWithNames:(NSArray *)tagNames {

	NSMutableArray *tags = [NSMutableArray new];

	for (NSString *oneTagName in tagNames) {

		VSTag *oneTag = [[VSDataController sharedController] tagWithName:oneTagName];
		if (oneTag == nil) {
			continue; /*Shouldn't happen.*/
		}

		if (![tags containsObject:oneTag]) {
			[tags addObject:oneTag];
		}
	}

	return [tags copy];
}


#pragma mark - Notes

- (VSNote *)noteWithDictionary:(NSDictionary *)noteDictionary {

	NSNumber *uniqeIDNumber = noteDictionary[@"uniqueID"];
	NSAssert(uniqeIDNumber != nil, nil);
	NSAssert([uniqeIDNumber isKindOfClass:[NSNumber class]], nil);

	int64_t uniqueID = [uniqeIDNumber longLongValue];
	VSNote *note = [[VSNote alloc] initWithUniqueID:uniqueID];

	NSDate *creationDate = QSDateWithString(noteDictionary[@"date"]);
	note.creationDate = creationDate;
	note.sortDate = note.creationDate;

	NSString *text = noteDictionary[@"text"];
	text = QSStringReplaceAll(text, @"\\n", @"\n");
	note.text = text;
	[note textDidChange];

	NSArray *tagNamesArray = noteDictionary[@"tags"];
	note.tags = [self tagsWithNames:tagNamesArray];
	[[VSDataController sharedController] saveTagsForNote:note];

	NSString *imageAttachmentName = noteDictionary[@"pictureAttachment"];
	NSString *imageAttachmentID = noteDictionary[@"pictureAttachmentID"];

	if (!QSStringIsEmpty(imageAttachmentName)) {

		NSAssert(!QSStringIsEmpty(imageAttachmentID), nil);
		[self attachImageWithName:imageAttachmentName attachmentID:imageAttachmentID note:note];

		[[VSDataController sharedController] saveAttachmentsForNote:note];

//		[[VSDataController sharedController] setAttachmentsCreatedLocally:YES uniqueIDs:@[imageAttachmentID]];
//		[[VSDataController sharedController] setAttachmentsAsTutorialAttachments:YES uniqueIDs:@[imageAttachmentID]];
	}

	NSAssert(note.creationDate != nil, nil);
	NSAssert(note.uniqueID > 0, nil);
	NSAssert(note.uniqueID <= VSTutorialNoteMaxID, nil);

	return note;
}


#pragma mark - Loading

- (void)loadTutorialData:(NSArray *)tutorialArray completion:(QSVoidCompletionBlock)completion {

	/*Load them in reverse order -- because the list view is reverse-chronological.*/

	NSMutableArray *notes = [NSMutableArray new];

	for (NSDictionary *oneNoteDictionary in tutorialArray) {

		VSNote *oneNote = [self noteWithDictionary:oneNoteDictionary];
		[notes addObject:oneNote];
	}

	[[VSDataController sharedController] saveNotes:[notes copy]];

	QSCallCompletionBlock(completion);
}


@end
