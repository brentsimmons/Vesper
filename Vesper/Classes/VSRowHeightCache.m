//
//  VSRowHeightCache.m
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSRowHeightCache.h"
#import "VSTypographySettings.h"


@interface VSRowHeightCache ()

@property (nonatomic) NSMutableDictionary *cache;

@end


@implementation VSRowHeightCache


#pragma mark - Class Methods

+ (instancetype)sharedCache {
	
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
	if (!self) {
		return nil;
	}
	
	_cache = [NSMutableDictionary new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typographySettingsDidChange:) name:VSTypographySettingsDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidSave:) name:VSNotesDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidSave:) name:VSAttachmentsForNoteDidSaveNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)typographySettingsDidChange:(NSNotification *)note {
	[self empty];
}

- (void)empty {
	[self.cache removeAllObjects];
}


- (void)notesDidSave:(NSNotification *)note {
	
	[self.cache removeObjectsForKeys:[note userInfo][VSUniqueIDsKey]];
}


#pragma mark - API

- (CGFloat)cachedHeightForTimelineNote:(VSTimelineNote *)timelineNote {
	
	NSNumber *num = self.cache[@(timelineNote.uniqueID)];
	if (!num) {
		return 0.0;
	}
	return (CGFloat)[num floatValue];
}


- (void)cacheHeight:(CGFloat)height forTimelineNote:(VSTimelineNote *)timelineNote {
	
	self.cache[@(timelineNote.uniqueID)] = @(height);
}


@end

