//
//  VSSidebarTagsController.m
//  Vesper
//
//  Created by Brent Simmons on 9/28/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSidebarTagsController.h"


@interface VSSidebarTagsController ()

@property (nonatomic, readwrite) NSArray *orderedTags;
@property (nonatomic) NSArray *sortDescriptors;

@end


@implementation VSSidebarTagsController


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	[self performSelectorOnMainThread:@selector(fetchTags) withObject:nil waitUntilDone:NO];

	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	_sortDescriptors = @[sortDescriptor];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:VSNotesDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:VSTagsForNoteDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:VSNotesDeletedNotification object:nil];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)objectsDidChange:(NSNotification *)note {
	[self qs_performSelectorCoalesced:@selector(fetchTags) withObject:nil afterDelay:0.1];
}


#pragma mark - Fetching

- (void)fetchTags {

	[[VSDataController sharedController] tagsForSidebar:^(NSArray *fetchedObjects) {

		NSMutableArray *tags = [fetchedObjects mutableCopy];
		[tags sortUsingDescriptors:self.sortDescriptors];
		
		if (![tags isEqualToArray:self.orderedTags]) {
			self.orderedTags = tags;
		}
	}];
}

@end
