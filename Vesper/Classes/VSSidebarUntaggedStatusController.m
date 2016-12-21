//
//  VSSidebarUntaggedStatusController.m
//  Vesper
//
//  Created by Brent Simmons on 6/9/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSidebarUntaggedStatusController.h"


@interface VSSidebarUntaggedStatusController ()

@property (nonatomic, readwrite) BOOL hasAtLeastOneUntaggedNote;

@end


@implementation VSSidebarUntaggedStatusController


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	[self performSelectorOnMainThread:@selector(fetchUntaggedStatus) withObject:nil waitUntilDone:NO];

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

static const NSTimeInterval kCoalesceInterval = 0.1;

- (void)objectsDidChange:(NSNotification *)note {

	[self qs_performSelectorCoalesced:@selector(fetchUntaggedStatus) withObject:nil afterDelay:kCoalesceInterval];
}


#pragma mark - Fetching

- (void)fetchUntaggedStatus {

	[[VSDataController sharedController] hasAtLeastOneUntaggedNote:^(BOOL flag) {
		if (self.hasAtLeastOneUntaggedNote != flag) {
			self.hasAtLeastOneUntaggedNote = flag;
		}
	}];
}

@end
