//
//  VSTimelineNote.m
//  Vesper
//
//  Created by Brent Simmons on 3/1/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSTimelineNote.h"
#import "FMDatabase.h"
#import "VSNote.h"


@interface VSTimelineNote ()

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSString *remainingText;
@property (nonatomic, readwrite) BOOL hasThumbnail;

/*readwrite to make timelineNoteWithNote and -copy work.*/

@property (nonatomic, assign, readwrite) int64_t uniqueID;
@property (nonatomic, readwrite) NSString *truncatedText;
@property (nonatomic, readwrite) NSArray *links;
@property (nonatomic, readwrite) NSString *thumbnailID;

@end


@implementation VSTimelineNote


#pragma mark - Class Methods

+ (VSTimelineNote *)timelineNoteWithNote:(VSNote *)note {

	VSTimelineNote *timelineNote = [VSTimelineNote new];

	timelineNote.uniqueID = note.uniqueID;
	timelineNote.links = note.links;
	timelineNote.truncatedText = note.truncatedText;
	timelineNote.sortDate = note.sortDate;
	timelineNote.thumbnailID = note.thumbnailID;
	timelineNote.archived = note.archived;

	return timelineNote;
}


#pragma mark - Copying

- (instancetype)copyWithZone:(NSZone *)zone {

	VSTimelineNote *timelineNote = [[[self class] allocWithZone:zone] init];

	timelineNote.uniqueID = self.uniqueID;
	timelineNote.links = self.links;
	timelineNote.truncatedText = self.truncatedText;
	timelineNote.sortDate = self.sortDate;
	timelineNote.thumbnailID = self.thumbnailID;
	timelineNote.archived = self.archived;

	return timelineNote;
}


#pragma mark - Calculated

NSString *QSTitleKey = @"QSTitleKey";
NSString *QSRemainingTextKey = @"QSRemainingTextKey";

+ (NSDictionary *)titleAndRemainingText:(NSString *)s {

	if ([s length] < 1) {
		return nil;
	}

	static NSMutableDictionary *cache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		cache = [NSMutableDictionary new];
	});

	NSDictionary *cachedDictionary = [cache objectForKey:s];
	if (cachedDictionary) {
		return cachedDictionary;
	}

	__block NSString *title = nil;
	[s enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {

		title = line;
		*stop = YES;
	}];

	NSUInteger titlePlusLineFeedLength = [title length] + 1;
	NSString *remainingText = @"";

	if ([s length] > titlePlusLineFeedLength) {
		remainingText = [s substringFromIndex:titlePlusLineFeedLength];
	}

	NSDictionary *d = @{QSTitleKey : title, QSRemainingTextKey : remainingText};
	[cache setObject:d forKey:s];

	return d;
}


- (void)updateTitleAndRemainingText {

	NSDictionary *titleAndRemainingText = [[self class] titleAndRemainingText:self.truncatedText];

	if (!titleAndRemainingText) {
		self.title = nil;
		self.remainingText = nil;
	}

	else {
		self.title = titleAndRemainingText[QSTitleKey];
		self.remainingText = titleAndRemainingText[QSRemainingTextKey];
	}
}


- (NSString *)title {

	if (!_title) {
		[self updateTitleAndRemainingText];
	}

	return _title;
}


- (NSString *)remainingText {

	if (!_remainingText) {
		[self updateTitleAndRemainingText];
	}

	return _remainingText;
}


- (void)setTruncatedText:(NSString *)truncatedText {

	if (truncatedText == _truncatedText || [_truncatedText isEqualToString:truncatedText]) {
		return;
	}

	_truncatedText = truncatedText;
	[self updateTitleAndRemainingText];
}


#pragma mark - Thumbnail

- (QS_IMAGE *)thumbnail {

	if (!self.hasThumbnail) {
		return nil;
	}

	return [[VSThumbnailCache sharedCache] thumbnailForAttachmentID:self.thumbnailID];
}


- (BOOL)hasThumbnail {
	return self.thumbnailID != nil;
}


#pragma mark - VSNote

- (void)takeValuesFromNote:(VSNote *)note {

	self.truncatedText = note.truncatedText;
	self.links = note.links;
	self.thumbnailID = note.thumbnailID;
	self.sortDate = note.sortDate;
	self.archived = note.archived;
}


@end

