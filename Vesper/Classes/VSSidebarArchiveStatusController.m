//
//  VSSidebarArchiveStatusController.m
//  Vesper
//
//  Created by Brent Simmons on 5/15/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSSidebarArchiveStatusController.h"


@interface VSSidebarArchiveStatusController ()

@property (nonatomic, readwrite) BOOL hasAtLeastOneArchivedNote;

@end


@implementation VSSidebarArchiveStatusController


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	[self performSelectorOnMainThread:@selector(checkIfHasAtLeastOneArchivedNote) withObject:nil waitUntilDone:NO];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:VSNotesDidSaveNotification object:nil];
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

	[self qs_performSelectorCoalesced:@selector(checkIfHasAtLeastOneArchivedNote) withObject:nil afterDelay:kCoalesceInterval];
}


#pragma mark - Fetching

- (void)checkIfHasAtLeastOneArchivedNote {

	[[VSDataController sharedController] hasAtLeastOneArchivedNote:^(BOOL flag) {
		if (self.hasAtLeastOneArchivedNote != flag) {
			self.hasAtLeastOneArchivedNote = flag;
		}
	}];
}

@end
