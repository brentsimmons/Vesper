//
//  VSSyncNote.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "VSSyncNote.h"


@implementation VSSyncNote


+ (instancetype)syncObjectWithManagedObject:(NSManagedObject *)managedObject {

	VSNote *note = (VSNote *)managedObject;

	VSSyncNote *syncObject = [VSSyncNote new];

	syncObject.clientID = note.clientID;
	syncObject.creationDate = note.creationDate;
	syncObject.text = note.text;
	syncObject.textModificationDate = note.textModificationDate;
	syncObject.archived = note.archived;
	syncObject.archivedModificationDate = note.archivedModificationDate;
	syncObject.sortDate = note.sortDate;
	syncObject.sortDateModificationDate = note.sortDateModificationDate;
	syncObject.tagUniqueIDs = note.tagUniqueIDs;
	syncObject.tagsModificationDate = note.tagsModificationDate;
	syncObject.attachments = note.attachments;
	syncObject.attachmentsModificationDate = note.attachmentsModificationDate;

	return syncObject;
}


+ (instancetype)syncObjectWithJSONDictionary:(NSDictionary *)JSONDictionary {

	VSSyncNote *syncObject = [VSSyncNote new];

	@autoreleasepool {

		syncObject.clientID = JSONDictionary[VSSyncClientIDKey];
		syncObject.creationDate = [JSONDictionary vs_JSONDateForKey:VSSyncCreationDateKey];
		syncObject.text = JSONDictionary[VSSyncTextKey];
		syncObject.textModificationDate = [JSONDictionary vs_JSONDateForKey:VSSyncTextModificationDateKey];
		syncObject.archived = [JSONDictionary[VSSyncArchivedKey] boolValue];
		syncObject.archivedModificationDate = [JSONDictionary vs_JSONDateForKey:VSSyncArchivedModificationDateKey];
		syncObject.sortDate = [JSONDictionary vs_JSONDateForKey:VSSyncSortDateKey];
		syncObject.sortDateModificationDate = [JSONDictionary vs_JSONDateForKey:VSSyncSortDateModificationDateKey];
		syncObject.tagsModificationDate = [JSONDictionary vs_JSONDateForKey:VSSyncTagsModificationDateKey];
		syncObject.attachmentsModificationDate = [JSONDictionary vs_JSONDateForKey:VSSyncAttachmentsModificationDateKey];

		syncObject.tagUniqueIDs = [JSONDictionary vs_JSONArrayForKey:VSSyncTagUniqueIDsKey];

		NSString *attachmentsString = JSONDictionary[VSSyncAttachmentsKey];
		if (!QSStringIsEmpty(attachmentsString)) {

			NSData *JSONData = [[NSData alloc] initWithBase64EncodedString:attachmentsString options:NSDataBase64DecodingIgnoreUnknownCharacters];
			NSArray *attachments = [VSAttachment attachmentsWithJSONData:JSONData];
			syncObject.attachments = attachments;
		}
	}
	
	return syncObject;
}


- (NSDictionary *)JSONDictionary {

	NSAssert([self.clientID longLongValue] != 0LL, nil);

	NSMutableDictionary *d = [NSMutableDictionary new];

	@autoreleasepool {

		d[VSSyncClientIDKey] = self.clientID;

		[d vs_setJSONDate:self.creationDate forKey:VSSyncCreationDateKey];

		d[VSSyncTextKey] = self.text ? self.text : @"";
		[d vs_setJSONDate:self.textModificationDate forKey:VSSyncTextModificationDateKey];

		d[VSSyncArchivedKey] = @(self.archived);
		[d vs_setJSONDate:self.archivedModificationDate forKey:VSSyncArchivedModificationDateKey];

		[d vs_setJSONDate:self.sortDate forKey:VSSyncSortDateKey];
		[d vs_setJSONDate:self.sortDateModificationDate forKey:VSSyncSortDateModificationDateKey];

		[d vs_setJSONArray:self.tagUniqueIDs forKey:VSSyncTagUniqueIDsKey];
		[d vs_setJSONDate:self.tagsModificationDate forKey:VSSyncTagsModificationDateKey];

		if (!QSIsEmpty(self.attachments)) {
			NSData *attachmentsJSONData = [VSAttachment JSONDataWithAttachments:self.attachments];
			NSString *base64EncodedAttachments = [attachmentsJSONData base64EncodedStringWithOptions:0];
			d[VSSyncAttachmentsKey] = base64EncodedAttachments;
		}

		[d vs_setJSONDate:self.attachmentsModificationDate forKey:VSSyncAttachmentsModificationDateKey];
	}

	return [d copy];
}


@end
