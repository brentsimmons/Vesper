//
//  VSThumbnailCache.m
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSThumbnailCache.h"
#import "VSThumbnail.h"
#import "VSThumbnailDatabase.h"


@interface VSThumbnailCache ()

@property (nonatomic) NSMutableDictionary *cache;

@end


@implementation VSThumbnailCache


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

- (id)init {
	
	self = [super init];
	if (self == nil) {
		return nil;
	}
	
	_cache = [NSMutableDictionary new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailRendered:) name:VSThumbnailRenderedNotification object:nil];
	
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)appDidReceiveMemoryWarning:(NSNotification *)note {
	
	@autoreleasepool {
		
		@synchronized(self) {
			[self.cache removeAllObjects];
		}
	}
}


- (void)thumbnailRendered:(NSNotification *)note {
	
	VSThumbnail *thumbnail = [note userInfo][VSThumbnailKey];
	[self cacheThumbnail:thumbnail];
}


- (void)sendThumbnailCachedNotification:(VSThumbnail *)thumbnail {
	
	[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:VSThumbnailCachedNotification object:self userInfo:@{QSImageKey : thumbnail.image, QSUniqueIDKey : thumbnail.uniqueID}];
}


#pragma mark - Getting

NSString *VSThumbnailCachedNotification = @"VSThumbnailCachedNotification";

- (void)loadThumbnailsWithAttachmentIDs:(NSArray *)attachmentIDs {
	
	NSMutableArray *attachmentIDsToFetch = [NSMutableArray new];
	
	for (NSString *oneAttachmentID in attachmentIDs) {
		
		if (![self thumbnailForAttachmentID:oneAttachmentID]) {
			[attachmentIDsToFetch addObject:oneAttachmentID];
		}
	}
	
	if ([attachmentIDsToFetch count] < 1) {
		return;
	}
	
	[[VSThumbnailDatabase sharedDatabase] fetchThumbnails:attachmentIDsToFetch callback:^(NSArray *fetchedThumbnails) {
		
		[self cacheThumbnails:fetchedThumbnails];
		
		NSMutableSet *attachmentIDsNotFetched = [NSMutableSet setWithArray:attachmentIDsToFetch];
		NSArray *fetchedThumbnailIDs = [fetchedThumbnails valueForKeyPath:@"uniqueID"];
		NSSet *fetchedIDs = [NSSet setWithArray:fetchedThumbnailIDs];
		
		[attachmentIDsNotFetched minusSet:fetchedIDs];
		
		for (NSString *oneAttachmentID in attachmentIDsNotFetched) {
			
			[VSThumbnail renderAndSaveThumbnailForAttachmentID:oneAttachmentID thumbnailResultBlock:^(VSThumbnail *thumbnail) {
				
				[self cacheThumbnail:thumbnail];
			}];
		}
	}];
}


#pragma mark - Cache

- (QS_IMAGE *)thumbnailForAttachmentID:(NSString *)attachmentID {
	
	NSParameterAssert(attachmentID);
	
	@synchronized(self) {
		return self.cache[attachmentID];
	}
}


- (void)cacheThumbnails:(NSArray *)thumbnails {
	
	for (VSThumbnail *oneThumbnail in thumbnails) {
		[self cacheThumbnail:oneThumbnail];
	}
}


- (void)cacheThumbnail:(VSThumbnail *)thumbnail {
	
	NSParameterAssert(thumbnail.image);
	NSParameterAssert(thumbnail.uniqueID);
	
	if (!thumbnail.image || !thumbnail.uniqueID) {
		return;
	}
	
	@synchronized(self) {
		if (!self.cache[thumbnail.uniqueID]) {
			self.cache[thumbnail.uniqueID] = thumbnail.image;
		}
	}
	
	[self sendThumbnailCachedNotification:thumbnail];
}


@end
