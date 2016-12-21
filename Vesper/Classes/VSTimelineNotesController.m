//
//  VSTimelineNotesController.m
//  Vesper
//
//  Created by Brent Simmons on 3/11/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSTimelineNotesController.h"
#import "VSNote.h"
#import "QSFetchRequest.h"
#import "QSTable.h"
#import "VSTimelineNote.h"
//#import "NSIndexPath+QSPlatform.h"


@interface VSTimelineNotesController ()

@property (nonatomic, copy) QSFetchRequest *fetchRequest;
@property (nonatomic, copy) QSNoteBelongsBlock noteBelongsBlock;

@end


static void *VSDetailNotesContext = &VSDetailNotesContext;

@implementation VSTimelineNotesController


#pragma mark - Init

- (instancetype)initWithFetchRequest:(QSFetchRequest *)fetchRequest noteBelongsBlock:(QSNoteBelongsBlock)noteBelongsBlock {

	self = [super init];
	if (!self) {
		return nil;
	}

	_fetchRequest = fetchRequest;
	_noteBelongsBlock = noteBelongsBlock;

	[self addObserver:self forKeyPath:@"notes" options:0 context:VSDetailNotesContext];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidSave:) name:VSNotesDidSaveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDeleted:) name:VSNotesDeletedNotification object:nil];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeObserver:self forKeyPath:@"notes" context:VSDetailNotesContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (context == VSDetailNotesContext) {

		NSArray *thumbnailIDs = [self.notes qs_map:^id(VSTimelineNote *oneTimelineNote) {
			return oneTimelineNote.thumbnailID;
		}];

		[[VSThumbnailCache sharedCache] loadThumbnailsWithAttachmentIDs:thumbnailIDs];
	}
}


#pragma mark - Fetching

- (void)performFetch {

	[self.fetchRequest performFetch:^(NSArray *fetchedObjects) {

		if (!self.notes || ![self.notes isEqualToArray:fetchedObjects]) {
			self.notes = fetchedObjects;
			[self.delegate controllerDidPerformFetch:self updatedNotes:self.notes];
		}
	}];
}


- (void)performFetchCoalesced {

	[self qs_performSelectorCoalesced:@selector(performFetch) withObject:nil afterDelay:0.1];
}


#pragma mark - Data

- (BOOL)hasNotes {
	return self.numberOfNotes > 0;
}


- (NSUInteger)numberOfNotes {
	return [self.notes count];
}


- (void)sortNotes:(NSMutableArray *)notes {

	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
	[notes sortUsingDescriptors:@[sortDescriptor]];
}


- (void)updateTimelineNotesWithNotes:(NSArray *)notes {

	for (VSNote *oneNote in notes) {
		[self updateTimelineNoteWithNote:oneNote];
	}
}


- (void)updateTimelineNoteWithNote:(VSNote *)note {

	VSTimelineNote *timelineNote = [self timelineNoteWithUniqueID:note.uniqueID];
	[timelineNote takeValuesFromNote:note];
}


- (NSUInteger)indexOfTimelineNoteWithID:(int64_t)uniqueID {

	return [self.notes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return ((VSTimelineNote *)obj).uniqueID == uniqueID;
	}];
}


- (VSTimelineNote *)timelineNoteAtIndex:(NSUInteger)ix {

	return [self.notes qs_safeObjectAtIndex:ix];
}


- (VSTimelineNote *)timelineNoteAtIndexPath:(NSIndexPath *)indexPath {

	if (!indexPath) {
		return nil;
	}

	return [self timelineNoteAtIndex:(NSUInteger)indexPath.row];
}


- (NSUInteger)indexOfTimelineNote:(VSTimelineNote *)timelineNote {

	return [self.notes indexOfObjectIdenticalTo:timelineNote];
}


- (NSIndexPath *)indexPathOfTimelineNote:(VSTimelineNote *)timelineNote {

	NSUInteger ix = [self indexOfTimelineNote:timelineNote];
	if (ix == NSNotFound) {
		return nil;
	}

	return [NSIndexPath indexPathForRow:(NSInteger)ix inSection:0];
}


- (NSUInteger)indexOfTimelineNoteWithUniqueID:(int64_t)uniqueID {

	NSUInteger ix = [self.notes indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {

		return ((VSTimelineNote *)obj).uniqueID == uniqueID;
	}];

	return ix;
}


- (NSIndexPath *)indexPathOfTimelineNoteWithUniqueID:(int64_t)uniqueID {

	NSUInteger ix = [self indexOfTimelineNoteWithUniqueID:uniqueID];
	if (ix == NSNotFound) {
		return nil;
	}

	return [NSIndexPath indexPathForRow:(NSInteger)ix inSection:0];
}


- (VSTimelineNote *)timelineNoteWithUniqueID:(int64_t)uniqueID {

	return [self.notes qs_firstObjectWhereValueForKey:QSUniqueIDKey equalsValue:@(uniqueID)];
}


- (void)removeNoteAtIndex:(NSUInteger)ix {

	NSMutableArray *notes = [self.notes mutableCopy];
	[notes removeObjectAtIndex:(NSUInteger)ix];
	self.notes = [notes copy];
}


- (void)insertNote:(VSTimelineNote *)note atIndex:(NSUInteger)ix {

	if (!note) {
		return;
	}
	NSMutableArray *notes = [self.notes mutableCopy];
	[notes insertObject:note atIndex:ix];
	self.notes = [notes copy];
}


- (NSArray *)sortedIndexesInIndexPaths:(NSArray *)indexPaths {

	NSMutableSet *indexes = [NSMutableSet setWithArray:[indexPaths valueForKeyPath:@"row"]];
	NSMutableArray *indexArray = [[indexes allObjects] mutableCopy];
	[indexArray sortUsingSelector:@selector(compare:)];

	return [indexArray copy];
}


- (void)deleteObjectsAtIndexPaths:(NSArray *)indexPaths {

	if (QSIsEmpty(indexPaths)) {
		return;
	}

	NSArray *indexes = [self sortedIndexesInIndexPaths:indexPaths];
	NSMutableArray *notes = [self.notes mutableCopy];

	for (NSNumber *oneIndex in [indexes reverseObjectEnumerator]) {

		[notes removeObjectAtIndex:[oneIndex unsignedIntegerValue]];
	}

	self.notes = [notes copy];
}


- (void)deleteObjectsAtIndexPathsAndInformDelegate:(NSArray *)indexPathsOfDeletedNotes {

	[self.delegate controllerWillChangeContent:self];

	for (NSIndexPath *oneIndexPath in indexPathsOfDeletedNotes) {

		VSTimelineNote *oneTimelineNote = [self timelineNoteAtIndexPath:oneIndexPath];
		[self.delegate controller:self didChangeObject:oneTimelineNote atIndexPath:oneIndexPath forChangeType:VSTimelineNotesChangeDelete newIndexPath:nil];
	}

	[self deleteObjectsAtIndexPaths:[indexPathsOfDeletedNotes copy]];

	[self.delegate controllerDidChangeContent:self];

}


- (void)deleteNotesAndInformDelegate:(NSArray *)notesToDelete {

	NSArray *uniqueIDs = [notesToDelete valueForKeyPath:QSUniqueIDKey];

	NSMutableArray *indexPathsOfDeletedNotes = [NSMutableArray new];

	for (id oneUniqueID in uniqueIDs) {

		NSUInteger oneIndex = [self indexOfTimelineNoteWithID:[oneUniqueID longLongValue]];
		if (oneIndex != NSNotFound) {
			NSIndexPath *oneIndexPath = [NSIndexPath indexPathForRow:(NSInteger)oneIndex inSection:0];
			[indexPathsOfDeletedNotes addObject:oneIndexPath];
		}
	}

	if ([indexPathsOfDeletedNotes count] < 1) {
		return;
	}

	[self deleteObjectsAtIndexPathsAndInformDelegate:[indexPathsOfDeletedNotes copy]];
	
}


- (BOOL)allNotesInArrayShouldBeDeleted:(NSArray *)notes {

	for (VSNote *oneNote in notes){

		if (self.noteBelongsBlock(oneNote)) {
			return NO;
		}
	}

	return YES;
}


- (void)notifyDelegateOfInsertion:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath {

	[self.delegate controllerWillChangeContent:self];
	[self.delegate controller:self didChangeObject:timelineNote atIndexPath:nil forChangeType:VSTimelineNotesChangeInsert newIndexPath:indexPath];
	[self.delegate controllerDidChangeContent:self];
}


- (void)notifyDelegateOfMove:(VSTimelineNote *)timelineNote originalIndexPath:(NSIndexPath *)originalIndexPath newIndexPath:(NSIndexPath *)newIndexPath {

	[self.delegate controllerWillChangeContent:self];
	[self.delegate controller:self didChangeObject:timelineNote atIndexPath:originalIndexPath forChangeType:VSTimelineNotesChangeMove newIndexPath:newIndexPath];
	[self.delegate controllerDidChangeContent:self];
}


- (void)notifyDelegateOfUpdate:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath {

	[self.delegate controllerWillChangeContent:self];
	[self.delegate controller:self didChangeObject:timelineNote atIndexPath:indexPath forChangeType:VSTimelineNotesChangeUpdate newIndexPath:nil];
	[self.delegate controllerDidChangeContent:self];
}


#pragma mark - Change Processing

- (void)processOneInsertedNote:(VSNote *)note {

	/*Get VSTimelineNote, figure out its position, notify delegate, update notes array.*/

	VSTimelineNote *timelineNote = [[VSDataController sharedController] timelineNoteWithUniqueID:note.uniqueID];

	NSAssert(timelineNote != nil, nil);
	if (!timelineNote) {
		[self performFetchCoalesced];
		return;
	}

	NSMutableArray *sortedNotes = [self.notes mutableCopy];
	[sortedNotes addObject:timelineNote];
	[self sortNotes:sortedNotes];
	self.notes = [sortedNotes copy];

	NSUInteger destinationIndex = [self indexOfTimelineNoteWithID:timelineNote.uniqueID];

	[self notifyDelegateOfInsertion:timelineNote indexPath:[NSIndexPath indexPathForRow:(NSInteger)destinationIndex inSection:0]];
}


- (void)processOneSavedNote:(VSNote *)note {

	if ([self allNotesInArrayShouldBeDeleted:@[note]]) {

		[self deleteNotesAndInformDelegate:@[note]];
		return;
	}

	NSUInteger indexOfTimelineNote = [self indexOfTimelineNoteWithID:note.uniqueID];

	if (indexOfTimelineNote == NSNotFound) {
		[self processOneInsertedNote:note];
		return;
	}

	/*Exists -- might be a move.
	 If in correct position, do nothing.
	 If needs to move, notify delegate and then move it.*/

	VSTimelineNote *timelineNote = [self timelineNoteAtIndex:indexOfTimelineNote];

	NSMutableArray *sortedNotes = [self.notes mutableCopy];
	[self sortNotes:sortedNotes];

	if ([sortedNotes isEqualToArray:self.notes]) {

		/*Update. Might need to update thumbnail.*/
		if (timelineNote.thumbnailID) {
			[[VSThumbnailCache sharedCache] loadThumbnailsWithAttachmentIDs:@[timelineNote.thumbnailID]];
		}

		[self notifyDelegateOfUpdate:timelineNote indexPath:[NSIndexPath indexPathForRow:(NSInteger)indexOfTimelineNote inSection:0]];
		return;
	}

	self.notes = [sortedNotes copy];
	NSUInteger destinationIndex = [self indexOfTimelineNoteWithID:timelineNote.uniqueID];

	NSIndexPath *originalIndexPath = [NSIndexPath indexPathForRow:(NSInteger)indexOfTimelineNote inSection:0];
	NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:(NSInteger)destinationIndex inSection:0];

	[self notifyDelegateOfMove:timelineNote originalIndexPath:originalIndexPath newIndexPath:destinationIndexPath];
}


#pragma mark - Notifications

- (void)notesDeleted:(NSNotification *)note {

	NSArray *uniqueIDs = [note userInfo][VSUniqueIDsKey];

	NSMutableArray *indexPathsOfDeletedNotes = [NSMutableArray new];

	for (id oneUniqueID in uniqueIDs) {

		NSUInteger oneIndex = [self indexOfTimelineNoteWithID:[oneUniqueID longLongValue]];
		if (oneIndex != NSNotFound) {
			NSIndexPath *oneIndexPath = [NSIndexPath indexPathForRow:(NSInteger)oneIndex inSection:0];
			[indexPathsOfDeletedNotes addObject:oneIndexPath];
		}
	}

	if ([indexPathsOfDeletedNotes count] < 1) {
		return;
	}

	[self deleteObjectsAtIndexPathsAndInformDelegate:[indexPathsOfDeletedNotes copy]];
}


- (void)notesDidSave:(NSNotification *)note {

	/*Fetch notes that saved and update local timeline notes.
	 If any saved notes are not in self.notes but should be, add them.*/

	NSArray *uniqueIDs = [note userInfo][VSUniqueIDsKey];
	if ([uniqueIDs count] < 1) {
		return;
	}

	NSArray *savedNotes = [note userInfo][VSNotesKey];
	[self updateTimelineNotesWithNotes:savedNotes];

	if ([savedNotes count] == 1) {
		[self processOneSavedNote:savedNotes[0]];
		return;
	}

	if ([self allNotesInArrayShouldBeDeleted:savedNotes]) {
		[self deleteNotesAndInformDelegate:savedNotes];
		return;
	}

	[self performFetchCoalesced];
}


//#pragma mark - Changes
//
//- (void)userDidEditNote:(VSNote *)note {
//
//	BOOL noteBelongs = self.noteBelongsBlock(note);
//	NSUInteger indexOfNote = [self indexOfTimelineNoteWithID:note.uniqueID];
//	BOOL noteExistsInNotes = (indexOfNote != NSNotFound);
//
////	NSLog(@"noteBelongs %d noteExistsInNotes %d", noteBelongs, noteExistsInNotes);
//}

@end
