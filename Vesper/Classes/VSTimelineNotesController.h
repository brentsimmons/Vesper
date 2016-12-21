//
//  VSTimelineNotesController.h
//  Vesper
//
//  Created by Brent Simmons on 3/11/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


typedef NS_ENUM(NSUInteger, VSTimelineNotesChangeType) {
	VSTimelineNotesChangeInsert,
	VSTimelineNotesChangeDelete,
	VSTimelineNotesChangeMove,
	VSTimelineNotesChangeUpdate
};


@class VSTimelineNotesController;

@protocol VSTimelineNotesControllerDelegate <NSObject>

@required

/*When controllerDidPerformFetch is called, other delegate methods won't be called.
 Expectation is that a delegate would call reloadData on a table view.*/

- (void)controllerDidPerformFetch:(VSTimelineNotesController *)controller updatedNotes:(NSArray *)updatedNotes;

- (void)controllerWillChangeContent:(VSTimelineNotesController *)controller;
- (void)controllerDidChangeContent:(VSTimelineNotesController *)controller;

- (void)controller:(VSTimelineNotesController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(VSTimelineNotesChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

@end


@class QSFetchRequest;
@class VSNote;
@class VSTimelineNote;


/*Takes a VSNote instead of a VSTimelineNote, because VSNote has properties
 such as tags that may be relevant.*/

typedef BOOL (^QSNoteBelongsBlock)(VSNote *note);


@interface VSTimelineNotesController : NSObject


- (instancetype)initWithFetchRequest:(QSFetchRequest *)fetchRequest noteBelongsBlock:(QSNoteBelongsBlock)noteBelongsBlock;


@property (nonatomic, weak) id<VSTimelineNotesControllerDelegate> delegate;
@property (nonatomic) NSArray *notes;
@property (nonatomic, assign, readonly) BOOL hasNotes;
@property (nonatomic, assign, readonly) NSUInteger numberOfNotes;

- (VSTimelineNote *)timelineNoteAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)indexOfTimelineNote:(VSTimelineNote *)timelineNote;
- (NSIndexPath *)indexPathOfTimelineNote:(VSTimelineNote *)timelineNote;
- (NSIndexPath *)indexPathOfTimelineNoteWithUniqueID:(int64_t)uniqueID;
- (VSTimelineNote *)timelineNoteWithUniqueID:(int64_t)uniqueID;

- (void)removeNoteAtIndex:(NSUInteger)ix; /*Doesn't inform delegate.*/
- (void)insertNote:(VSTimelineNote *)note atIndex:(NSUInteger)ix;

- (void)performFetch;


@end
