//
//  VSNote.m
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSNote.h"
#import "VSAttachment.h"
#import "QSDateParser.h"
#import "VSAttachmentStorage.h"
#import "VSDateManager.h"
#import "VSDataController.h"


NSString *VSNoteUserDidEditNotification = @"VSNoteUserDidEditNotification";


@implementation VSNote


#pragma mark - Init

- (instancetype)init {
	
	return [self initWithUniqueID:0];
}


- (instancetype)initWithUniqueID:(int64_t)uniqueID {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	if (uniqueID < 1) {
		_uniqueID = [[VSDataController sharedController] generateUniqueIDForNote];
	}
	else {
		_uniqueID = uniqueID;
	}
	
	_creationDate = [[VSDateManager sharedManager] currentDate];
	_sortDate = _creationDate;
	_modificationDate = _creationDate;
	_archived = NO;
	
	return self;
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	
	VSNote *note = [[[self class] allocWithZone:zone] initWithUniqueID:self.uniqueID];
	
	note.text = self.text;
	note.archived = self.archived;
	note.archivedModificationDate = self.archivedModificationDate;
	note.creationDate = self.creationDate;
	note.sortDate = self.sortDate;
	note.sortDateModificationDate = self.sortDateModificationDate;
	note.tagsModificationDate = self.tagsModificationDate;
	note.textModificationDate = self.textModificationDate;
	note.attachmentsModificationDate = self.attachmentsModificationDate;
	note.truncatedText = self.truncatedText;
	note.modificationDate = self.modificationDate;
	note.attachments = self.attachments;
	note.tags = self.tags;
	note.links = self.links;
	note.thumbnailID = self.thumbnailID;
	
	return note;
}


#pragma mark - Copy

- (VSNote *)copyWithNewUniqueIDAndCreationDate {
	
	VSNote *note = [self copy];
	note.uniqueID = [[VSDataController sharedController] generateUniqueIDForNote];
	note.creationDate = [[VSDateManager sharedManager] currentDate];
	note.modificationDate = note.creationDate;
	
	return note;
}


#pragma mark - Attachments

- (NSString *)thumbnailID {
	
	VSAttachment *imageAttachment = [self firstImageAttachment];
	return imageAttachment.uniqueID;
}


- (VSAttachment *)firstImageAttachment {
	
	return [self.attachments qs_firstObjectWhereValueForKey:@"isImage" equalsValue:@YES];
}


- (BOOL)hasThumbnail {
	return self.thumbnailID != nil;
}


#pragma mark - Sync

- (NSArray *)tagNames {
	
	return [self.tags valueForKeyPath:@"name"];
}


#pragma mark - QSAPIObject Utilities

- (NSString *)JSONDateForKey:(NSString *)key {
	
	NSDate *d = [self valueForKey:key];
	if (d && (id)d != [NSNull null]) {
		return [d qs_iso8601DateString];
	}
	
	return nil;
}


+ (NSDate *)dateForKey:(NSString *)key JSONDictionary:(NSDictionary *)JSONDictionary {
	
	NSString *dateString = JSONDictionary[key];
	if (!dateString || (id)dateString == [NSNull null]) {
		return nil;
	}
	
	return QSDateWithString(dateString);
}


#pragma mark - QSAPIObject

- (NSDictionary *)JSONRepresentation {
	
	NSMutableDictionary *d = [NSMutableDictionary new];
	
	d[VSSyncNoteIDKey] = @(self.uniqueID);
	d[VSSyncArchivedKey] = @(self.archived);
	
	d[VSSyncTextKey] = self.text ? self.text : @"";
	
	[d qs_safeSetObject:[self JSONDateForKey:@"creationDate"] forKey:VSSyncCreationDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"textModificationDate"] forKey:VSSyncTextModificationDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"archivedModificationDate"] forKey:VSSyncArchivedModificationDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"sortDate"] forKey:VSSyncSortDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"sortDateModificationDate"] forKey:VSSyncSortDateModificationDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"tagsModificationDate"] forKey:VSSyncTagsModificationDateKey];
	[d qs_safeSetObject:[self JSONDateForKey:@"attachmentsModificationDate"] forKey:VSSyncAttachmentsModificationDateKey];
	
	NSAssert(d[VSSyncSortDateKey] != nil, nil);
	NSAssert(d[VSSyncCreationDateKey] != nil, nil);
	
	if (!d[VSSyncSortDateKey]) {
		d[VSSyncSortDateKey] = VSOldDate();
	}
	if (!d[VSSyncCreationDateKey]) {
		d[VSSyncCreationDateKey] = VSOldDate();
	}
	
	NSArray *tagNames = [self.tags valueForKey:@"name"];
	if ([tagNames count] > 0) {
		d[VSSyncTagNamesKey] = [tagNames componentsJoinedByString:@"  "]; /*JSON tag names are two-space-separated strings.*/
	}
	
	NSArray *JSONAttachments = [QSAPIObject JSONArrayWithObjects:self.attachments];
	
	if ([JSONAttachments count] > 0) {
		
		/*Attachments are serialized to JSON then base64-encoded for transmission to the server.*/
		
		NSError *error = nil;
		NSData *attachmentsData = [NSJSONSerialization dataWithJSONObject:JSONAttachments options:0 error:&error];
		NSString *base64EncodedString = [attachmentsData base64EncodedStringWithOptions:0];
		d[VSSyncAttachmentsKey] = base64EncodedString;
	}
	
	return [d copy];
}


+ (instancetype)objectWithJSONRepresentation:(NSDictionary *)JSONRepresentation {
	
	/*Doesn't create tags and attachments related objects.*/
	
	
	NSNumber *uniqueID = JSONRepresentation[VSSyncNoteIDKey];
	VSNote *note = [[VSNote alloc] initWithUniqueID:[uniqueID longLongValue]];
	
	note.archived = [JSONRepresentation qs_boolForKey:VSSyncArchivedKey];
	
	NSString *text = JSONRepresentation[VSSyncTextKey];
	if (!text || (id)text == [NSNull null]) {
		note.text = nil;
	}
	else {
		note.text = text;
	}
	[note textDidChange];
	
	note.creationDate = [self dateForKey:VSSyncCreationDateKey JSONDictionary:JSONRepresentation];
	note.textModificationDate = [self dateForKey:VSSyncTextModificationDateKey JSONDictionary:JSONRepresentation];
	note.archivedModificationDate = [self dateForKey:VSSyncArchivedModificationDateKey JSONDictionary:JSONRepresentation];
	note.sortDate = [self dateForKey:VSSyncSortDateKey JSONDictionary:JSONRepresentation];
	note.sortDateModificationDate = [self dateForKey:VSSyncSortDateModificationDateKey JSONDictionary:JSONRepresentation];
	note.tagsModificationDate = [self dateForKey:VSSyncTagsModificationDateKey JSONDictionary:JSONRepresentation];
	note.attachmentsModificationDate = [self dateForKey:VSSyncAttachmentsModificationDateKey JSONDictionary:JSONRepresentation];
	
	//	id tagNames = JSONRepresentation[VSSyncTagNamesKey];
	//	if (!tagNames || (id)tagNames == [NSNull null]) {
	//		note.tagNames = nil;
	//	}
	//	else {
	//		/*JSON tag names are two-space-separated strings.*/
	//		note.tagNames = [tagNames componentsSeparatedByString:@"  "];
	//	}
	//
	//	NSArray *attachments = [QSAPIObject objectsWithJSONArray:JSONRepresentation[VSSyncAttachmentsKey] class:[VSAttachment class]];
	//	note.attachments = attachments;
	
	return note;
}

#pragma mark - Calculated Properties

- (BOOL)isTutorialNote {
	
	return self.uniqueID <= VSTutorialNoteMaxID;
}


static const NSUInteger kLengthOfTruncatedText = 500;

- (void)updateTruncatedText:(NSString *)s {
	
	NSString *truncatedText = s;
	if ([truncatedText length] > kLengthOfTruncatedText) {
		truncatedText = [s substringToIndex:kLengthOfTruncatedText];
	}
	self.truncatedText = truncatedText;
}


- (void)updateLinks:(NSString *)s {
	
	static NSMutableDictionary *linksCache = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		linksCache = [NSMutableDictionary new];
	});
	
	NSArray *links = [linksCache objectForKey:s];
	if (!links) {
		
		links = [s qs_links];
		if (links) {
			[linksCache setObject:links forKey:s];
		}
	}
	
	if ([links count] < 1) {
		self.links = nil;
	}
	else {
		self.links = links;
	}
}


- (void)textDidChange {
	
	[self updateTruncatedText:self.text];
	[self updateLinks:self.text];
}


- (NSDate *)mostRecentModificationDate {
	
	NSDate *modificationDate = self.creationDate;
	
	if ([modificationDate laterDate:self.modificationDate] == self.modificationDate) {
		modificationDate = self.modificationDate;
	}
	if ([modificationDate laterDate:self.archivedModificationDate] == self.archivedModificationDate) {
		modificationDate = self.archivedModificationDate;
	}
	if ([modificationDate laterDate:self.sortDateModificationDate] == self.sortDateModificationDate) {
		modificationDate = self.sortDateModificationDate;
	}
	if ([modificationDate laterDate:self.tagsModificationDate] == self.tagsModificationDate) {
		modificationDate = self.tagsModificationDate;
	}
	if ([modificationDate laterDate:self.textModificationDate] == self.textModificationDate) {
		modificationDate = self.textModificationDate;
	}
	if ([modificationDate laterDate:self.attachmentsModificationDate] == self.attachmentsModificationDate) {
		modificationDate = self.attachmentsModificationDate;
	}
	
	return modificationDate;
}


#pragma mark - User Changes

- (void)userDidUpdateText:(NSString *)text {
	
	if ([text isEqualToString:self.text]) {
		return;
	}
	
	self.text = text;
	self.textModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.textModificationDate;
	
	[self textDidChange];
	[[VSDataController sharedController] saveNotes:@[self]];
	[[self class] sendUserDidEditNoteNotification];
}


- (void)userDidMarkAsArchived:(BOOL)archived {
	
	if (archived == self.archived) {
		return;
	}
	
	self.archived = archived;
	self.archivedModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.archivedModificationDate;
	[self userDidUpdateSortDate:[[VSDateManager sharedManager] currentDate]];
	[[self class] sendUserDidEditNoteNotification];
}


- (void)userDidUpdateSortDate:(NSDate *)sortDate {
	
	if ([sortDate compare:self.sortDate] == NSOrderedSame) {
		return;
	}
	
	self.sortDate = sortDate;
	self.sortDateModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.sortDateModificationDate;
	
	[[VSDataController sharedController] saveNotes:@[self]];
	[[self class] sendUserDidEditNoteNotification];
}


- (void)userDidRemoveAllAttachments {
	
	if (QSIsEmpty(self.attachments)) {
		return;
	}
	
	self.attachments = nil;
	self.attachmentsModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.attachmentsModificationDate;
	
	[[VSDataController sharedController] saveAttachmentsForNote:self];
	[[VSDataController sharedController] saveNotes:@[self]];
	[[self class] sendUserDidEditNoteNotification];
}


- (void)userDidReplaceAllAttachmentsWithAttachment:(VSAttachment *)attachment {
	
	if ([self.attachments count] == 1 && [[self.attachments firstObject] isEqual:attachment]) {
		return;
	}
	
	self.attachments = @[attachment];
	self.attachmentsModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.attachmentsModificationDate;
	
	[[VSDataController sharedController] saveAttachmentsForNote:self];
	[[VSDataController sharedController] saveNotes:@[self]];
	[[self class] sendUserDidEditNoteNotification];
}


- (void)userDidReplaceAllAttachmentsWithImage:(QS_IMAGE *)image {
	
	if (!image) {
		[self userDidRemoveAllAttachments];
		return;
	}
	
	NSString *attachmentUniqueID = [[NSUUID UUID] UUIDString];
	NSString *mimeType = [[VSAttachmentStorage sharedStorage] saveImageAttachment:image attachmentID:attachmentUniqueID];
	
	VSAttachment *attachment = [VSAttachment attachmentWithUniqueID:attachmentUniqueID mimeType:mimeType height:(int64_t)(image.size.height) width:(int64_t)(image.size.width)];
	[self userDidReplaceAllAttachmentsWithAttachment:attachment];
}


- (void)userDidUpdateTags:(NSArray *)tags {
	
	if (QSIsEmpty(tags) && QSIsEmpty(self.tags)) {
		return;
	}
	if ([tags isEqual:self.tags])
		return;
	
	self.tags = tags;
	self.tagsModificationDate = [[VSDateManager sharedManager] currentDate];
	self.modificationDate = self.tagsModificationDate;
	
	[[VSDataController sharedController] saveTagsForNote:self];
	[[VSDataController sharedController] saveNotes:@[self]];
	[[self class] sendUserDidEditNoteNotification];
}


+ (void)sendUserDidEditNoteNotification {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNoteUserDidEditNotification object:nil];
}


@end


