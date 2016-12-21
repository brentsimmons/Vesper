//
//  VSSearchResultsViewController.m
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSearchResultsViewController.h"
#import "VSNote.h"
#import "VSTag.h"
#import "VSTimelineCell.h"
#import "VSAttachment.h"
#import "VSRowHeightCache.h"
#import "VSTimelineViewController.h"
#import "VSDetailViewController.h"
#import "VSTimelineSectionHeaderView.h"
#import "VSTimelineContext.h"


@interface VSSearchResultsViewController () <VSTimelineCellDelegate>

@property (nonatomic) VSTimelineContext *context;
@property (nonatomic, strong) NSArray *timelineNotes;
@property (nonatomic, strong) NSArray *archivedNotes;
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong) NSTimer *reloadDataTimer;
@property (nonatomic, assign) BOOL archivedNotesOnly;
@property (nonatomic, assign) BOOL includeArchivedNotes;
@property (nonatomic, assign) BOOL animatingTableUpdate;
@property (nonatomic, weak) VSTimelineViewController *timelineViewController;
@property (nonatomic, strong) VSDetailViewController *detailViewController;
@property (nonatomic, strong) VSNote *detailViewNote;
@property (nonatomic, strong) NSIndexPath *detailViewIndexPath;
@property (nonatomic, weak) VSTimelineCell *panningCell;
@property (nonatomic, assign) BOOL isPanning;
@property (nonatomic, assign) BOOL hasSelectedRow;
@property (nonatomic, assign) BOOL isDraggingRow;

@end


@implementation VSSearchResultsViewController


#pragma mark - Init

- (instancetype)initWithContext:(VSTimelineContext *)context includeArchivedNotes:(BOOL)includeArchivedNotes archivedNotesOnly:(BOOL)archivedNotesOnly timelineViewController:(VSTimelineViewController *)timelineViewController {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	_context = context;
	_timelineViewController = timelineViewController;
	_archivedNotesOnly = archivedNotesOnly;
	_includeArchivedNotes = includeArchivedNotes;
	
	[self addObserver:self forKeyPath:@"notes" options:0 context:nil];
	[self addObserver:self forKeyPath:@"archivedNotes" options:0 context:nil];
	[self addObserver:self forKeyPath:@"searchString" options:0 context:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self.reloadDataTimer qs_invalidateIfValid];
	self.reloadDataTimer = nil;
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	[self removeObserver:self forKeyPath:@"notes"];
	[self removeObserver:self forKeyPath:@"archivedNotes"];
	[self removeObserver:self forKeyPath:@"searchString"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"notes"] && object == self) {
		
		NSArray *thumbnailsIDs = [self.timelineNotes qs_map:^id(id obj) {
			return ((VSTimelineNote *)obj).thumbnailID;
		}];
		
		[[VSThumbnailCache sharedCache] loadThumbnailsWithAttachmentIDs:thumbnailsIDs];
		if (!self.animatingTableUpdate) {
			[self reloadData];
		}
	}
	
	else if ([keyPath isEqualToString:@"archivedNotes"] && object == self) {
		
		NSArray *thumbnailsIDs = [self.archivedNotes qs_map:^id(id obj) {
			return ((VSTimelineNote *)obj).thumbnailID;
		}];
		
		[[VSThumbnailCache sharedCache] loadThumbnailsWithAttachmentIDs:thumbnailsIDs];
		
		if (!self.animatingTableUpdate) {
			[self reloadData];
		}
	}
	
	else if ([keyPath isEqualToString:@"searchString"] && object == self) {
		self.timelineNotes = nil;
		self.archivedNotes = nil;
		if ([self.searchString length] > 0) {
			[self fetch];
		}
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	self.tableView.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.tableView.opaque = YES;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.showsHorizontalScrollIndicator = NO;
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	self.view = self.tableView;
}


#pragma mark - VSTimelineCellDelegate

- (BOOL)timelineCellIsPanning:(VSTimelineCell *)timelineCell {
	return (timelineCell == self.panningCell);
}


- (void)timelineCellWillBeginPanning:(VSTimelineCell *)timelineCell {
	
	self.panningCell = timelineCell;
}


- (void)timelineCellDidCancelOrEndPanning:(VSTimelineCell *)timelineCell {
	
	if (timelineCell == self.panningCell)
		self.panningCell = nil;
}


- (BOOL)timelineCellShouldBeginPanning:(VSTimelineCell *)timelineCell {
	
	if (self.isPanning || self.isDraggingRow || self.hasSelectedRow)
		return NO;
	return YES;
}


- (void)timelineCellDidBeginPanning:(VSTimelineCell *)timelineCell {
	
	;
}


- (void)timelineCellDidDelete:(VSTimelineCell *)timelineCell {
	
	VSTimelineNote *timelineNote = [self timelineNoteForSender:timelineCell];
	if (timelineNote) {
		[self deleteTimelineNote:timelineNote];
	}
}


#pragma mark - Cells

- (void)configureCell:(VSTimelineCell *)cell note:(VSTimelineNote *)timelineNote {
	
	@autoreleasepool {
		
		cell.delegate = self;
		
		if (timelineNote.archived) {
			cell.archiveControlStyle = VSArchiveControlStyleRestoreDelete;
			cell.archiveActionText = NSLocalizedString(@"Restore", @"Restore");
			cell.archiveIndicatorUseItalicFont = NO;
		}
		else {
			cell.archiveControlStyle = VSArchiveControlStyleArchive;
			cell.archiveActionText = NSLocalizedString(@"Archive", @"Archive");
			cell.archiveIndicatorUseItalicFont = YES;
		}
		
		[cell configureWithTitle:timelineNote.title text:timelineNote.remainingText links:timelineNote.links useItalicFonts:timelineNote.archived hasThumbnail:timelineNote.hasThumbnail truncateIfNeeded:YES];
		
		UIImage *thumbnail = timelineNote.thumbnail;
		if (thumbnail != cell.thumbnail) {
			cell.thumbnail = thumbnail;
		}
		
		[cell setNeedsDisplay];
	}
}


- (void)updateCellForAttachmentUniqueID:(NSString *)attachmentUniqueID {
	
	@autoreleasepool {
		
		for (NSIndexPath *oneIndexPath in [self.tableView indexPathsForVisibleRows]) {
			
			VSTimelineNote *oneNote = [self timelineNoteAtIndexPath:oneIndexPath];
			if (![oneNote.thumbnailID isEqualToString:attachmentUniqueID]) {
				continue;
			}
			
			VSTimelineCell *cell = (VSTimelineCell *)[self.tableView cellForRowAtIndexPath:oneIndexPath];
			[self configureCell:cell note:oneNote];
		}
	}
}


#pragma mark - Fetching

- (void)fetch {
	
	[[VSDataController sharedController] timelineNotesContainingSearchString:self.searchString tag:self.context.tag includeArchivedNotes:self.includeArchivedNotes archivedNotesOnly:self.archivedNotesOnly fetchResultsBlock:^(NSArray *timelineNotes) {
		
		NSMutableArray *notes = [NSMutableArray new];
		NSMutableArray *archivedNotes = [NSMutableArray new];
		
		for (VSTimelineNote *oneTimelineNote in timelineNotes) {
			
			if (oneTimelineNote.archived) {
				[archivedNotes addObject:oneTimelineNote];
			}
			else {
				[notes addObject:oneTimelineNote];
			}
		}
		
		if (![self.timelineNotes isEqualToArray:notes]) {
			self.timelineNotes = [notes copy];
		}
		
		if (![self.archivedNotes isEqualToArray:archivedNotes]) {
			self.archivedNotes = [archivedNotes copy];
		}
	}];
}


#pragma mark - Pan-back Animation Support

- (UIImage *)dragImageForNote:(VSNote *)note {
	
	VSTimelineNote *timelineNote = [VSTimelineNote timelineNoteWithNote:note];
	NSIndexPath *indexPath = [self indexPathOfTimelineNote:timelineNote];
	if (indexPath == nil)
		return nil;
	
	VSTimelineNote *draggedNote = self.draggedNote;
	self.draggedNote = nil;
	
	[self reloadData];
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	cell.highlighted = NO;
	UIImage *image = [(VSTimelineCell *)cell imageForDetailPanBackAnimation];
	
	self.draggedNote = draggedNote;
	
	return image;
}


- (CGRect)frameOfCellForNote:(VSNote *)note {
	
	VSTimelineNote *timelineNote = [VSTimelineNote timelineNoteWithNote:note];
	NSIndexPath *indexPath = [self indexPathOfTimelineNote:timelineNote];
	if (indexPath == nil)
		return CGRectZero;
	
	return  [self.tableView rectForRowAtIndexPath:indexPath];
}


- (void)prepareForPanBackAnimationWithNote:(VSTimelineNote *)timelineNote {
	
	self.draggedNote = timelineNote;
	[self reloadData];
}


- (UIView *)tableAnimationView {
	
	[self.tableView reloadData];
	
	UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	[self.view.layer renderInContext:context];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImageView *tableAnimationView = [[UIImageView alloc] initWithImage:image];
	tableAnimationView.clipsToBounds = YES;
	tableAnimationView.contentMode = UIViewContentModeBottom;
	tableAnimationView.autoresizingMask = UIViewAutoresizingNone;
	
	return tableAnimationView;
}


#pragma mark - Actions

- (void)detailViewDone:(id)sender {
	
	[self.timelineViewController searchResultsViewController:self popDetailViewController:self.detailViewController indexPath:self.detailViewIndexPath note:self.detailViewNote animated:YES];
	
	self.detailViewController = nil;
	self.detailViewIndexPath = nil;
	self.detailViewNote = nil;
}


- (void)detailViewDoneViaPanBackAnimation:(id)sender {
	
	[self.timelineViewController searchResultsViewController:self popDetailViewController:self.detailViewController indexPath:self.detailViewIndexPath note:self.detailViewNote animated:NO];
	
	self.detailViewController = nil;
	self.detailViewIndexPath = nil;
	self.detailViewNote = nil;
}


#pragma mark - Data

- (void)timedReloadData:(id)sender {
	[self.reloadDataTimer qs_invalidateIfValid];
	self.reloadDataTimer = nil;
	[self.tableView reloadData];
}


- (void)reloadData {
	[self.reloadDataTimer qs_invalidateIfValid];
	self.reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(timedReloadData:) userInfo:nil repeats:NO];
}


enum {
	VSSearchSectionNotes,
	VSSearchSectionArchivedNotes,
	VSSearchNumberOfSections
};


- (NSArray *)noteArrayForSection:(NSInteger)section {
	
	if (section == VSSearchSectionNotes)
		return self.timelineNotes;
	else if (section == VSSearchSectionArchivedNotes)
		return self.archivedNotes;
	return nil;
}


- (VSTimelineNote *)timelineNoteAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *noteArray = [self noteArrayForSection:indexPath.section];
	return [noteArray qs_safeObjectAtIndex:(NSUInteger)indexPath.row];
}


- (NSIndexPath *)indexPathOfTimelineNote:(VSTimelineNote *)timelineNote {
	
	NSUInteger indexOfNote = [self.timelineNotes indexOfObjectIdenticalTo:timelineNote];
	if (indexOfNote != NSNotFound)
		return [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:VSSearchSectionNotes];
	
	indexOfNote = [self.archivedNotes indexOfObjectIdenticalTo:timelineNote];
	if (indexOfNote != NSNotFound)
		return [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:VSSearchSectionArchivedNotes];
	
	return nil;
}


- (VSTimelineNote *)timelineNoteForSender:(id)sender {
	
	if ([sender isKindOfClass:[UIGestureRecognizer class]])
		sender = ((UIGestureRecognizer *)sender).view;
	if (![sender isKindOfClass:[UIView class]])
		return nil;
	
	for (NSIndexPath *oneIndexPath in [self.tableView indexPathsForVisibleRows]) {
		
		UITableViewCell *oneTableViewCell = [self.tableView cellForRowAtIndexPath:oneIndexPath];
		if (oneTableViewCell == nil)
			continue;
		if ([(UIView *)sender isDescendantOfView:oneTableViewCell])
			return [self timelineNoteAtIndexPath:oneIndexPath];
	}
	
	return nil;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return VSSearchNumberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSArray *noteArray = [self noteArrayForSection:section];
	return (NSInteger)[noteArray count];
}


- (UITableViewCell *)blankCellForDraggedNote:(VSTimelineNote *)note {
	
	static NSString *reuseIdentifier = @"searchResultsBlankCell";
	
	VSTimelineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
		cell = [[VSTimelineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	
	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	if (timelineNote == self.draggedNote) {
		return [self blankCellForDraggedNote:timelineNote];
	}
	
	static NSString *reuseIdentifier = @"VSTimelineCell";
	VSTimelineCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
		cell = [[VSTimelineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	
	[self configureCell:cell note:[self timelineNoteAtIndexPath:indexPath]];
	
	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	CGFloat height = [[VSRowHeightCache sharedCache] cachedHeightForTimelineNote:timelineNote];
	
	if (height < 1.0) {
		height = [VSTimelineCell heightWithTitle:timelineNote.title text:timelineNote.remainingText links:timelineNote.links useItalicFonts:timelineNote.archived hasThumbnail:timelineNote.hasThumbnail truncateIfNeeded:YES];
		[[VSRowHeightCache sharedCache] cacheHeight:height forTimelineNote:timelineNote];
	}
	
	return height;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[self qs_performSelectorViaResponderChain:@selector(stopEditingSearchBar:) withObject:self];
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	if (!timelineNote) {
		return;
	}
	
	VSNote *note = [[VSDataController sharedController] noteWithUniqueID:timelineNote.uniqueID];
	self.detailViewNote = note;
	self.detailViewIndexPath = indexPath;
	self.detailViewController = [self.timelineViewController searchResultsViewController:self showComposeViewWithNote:note timelineNote:timelineNote indexPath:indexPath];
}


static const CGFloat VSSearchSectionHeightArchivedNotes = 22.0f;

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	if (section == VSSearchSectionArchivedNotes && [self.archivedNotes count] > 0)
		return VSSearchSectionHeightArchivedNotes;
	
	return 0.0f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section != VSSearchSectionArchivedNotes || [self.archivedNotes count] < 1)
		return nil;
	
	CGFloat sectionHeaderHeight = [app_delegate.theme floatForKey:@"timelineSectionHeaderHeight"];
	CGRect r = CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, sectionHeaderHeight);
	
	VSTimelineSectionHeaderView *headerView = [[VSTimelineSectionHeaderView alloc] initWithFrame:r title:NSLocalizedString(@"Archived", @"Archived")];
	
	return headerView;
}


#pragma mark - Touches

- (void)textLabelTapped:(id)sender {
	
	
	VSTimelineNote *timelineNote = [self timelineNoteForSender:sender];
	if (!timelineNote) {
		return;
	}
	
	NSIndexPath *indexPath = [self indexPathOfTimelineNote:timelineNote];
	if (!indexPath) {
		return;
	}
	
	[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self qs_performSelectorViaResponderChain:@selector(stopEditingSearchBar:) withObject:self];
}


#pragma mark - Archive/Restore

- (void)removeNoteAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSSearchSectionNotes) {
		NSMutableArray *notesCopy = [self.timelineNotes mutableCopy];
		[notesCopy removeObjectAtIndex:(NSUInteger)indexPath.row];
		self.timelineNotes = [notesCopy copy];
	}
	
	else if (indexPath.section == VSSearchSectionArchivedNotes) {
		NSMutableArray *notesCopy = [self.archivedNotes mutableCopy];
		[notesCopy removeObjectAtIndex:(NSUInteger)indexPath.row];
		self.archivedNotes = [notesCopy copy];
	}
}


- (void)sortNotes:(NSMutableArray *)notes {
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortDate" ascending:NO];
	[notes sortUsingDescriptors:@[sortDescriptor]];
}


- (NSIndexPath *)addNote:(VSTimelineNote *)note section:(NSUInteger)section {
	
	NSUInteger indexOfNote = NSNotFound;
	
	if (section == VSSearchSectionNotes && !self.archivedNotesOnly) {
		
		NSMutableArray *notesCopy = [self.timelineNotes mutableCopy];
		[notesCopy insertObject:note atIndex:0];
		[self sortNotes:notesCopy];
		if (![self.timelineNotes isEqualToArray:notesCopy]) {
			self.timelineNotes = [notesCopy copy];
		}
		
		indexOfNote = [self.timelineNotes indexOfObjectIdenticalTo:note];
	}
	
	else if (section == VSSearchSectionArchivedNotes) {
		
		NSMutableArray *notesCopy = [self.archivedNotes mutableCopy];
		[notesCopy insertObject:note atIndex:0];
		[self sortNotes:notesCopy];
		if (![self.archivedNotes isEqualToArray:notesCopy]) {
			self.archivedNotes = [notesCopy copy];
		}
		
		indexOfNote = [self.archivedNotes indexOfObjectIdenticalTo:note];
	}
	
	if (section == VSSearchSectionNotes && self.archivedNotesOnly) {
		return nil;
	}
	return [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:(NSInteger)section];
}


- (void)markTimelineNote:(VSTimelineNote *)timelineNote asArchived:(BOOL)archived {
	
	self.animatingTableUpdate = YES;
	
	timelineNote.archived = archived;
	[[VSDataController sharedController] updateArchived:archived uniqueID:timelineNote.uniqueID];
	
	NSInteger noteSection = (archived ? VSSearchSectionNotes : VSSearchSectionArchivedNotes);
	NSUInteger indexOfNote = [[self noteArrayForSection:noteSection] indexOfObjectIdenticalTo:timelineNote];
	NSIndexPath *indexPathOfRemovedNote = nil;
	
	if (indexOfNote != NSNotFound) {
		indexPathOfRemovedNote = [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:noteSection];
		[self removeNoteAtIndexPath:indexPathOfRemovedNote];
	}
	
	NSUInteger noteDestinationSection = VSSearchSectionNotes;
	if (noteSection == VSSearchSectionNotes)
		noteDestinationSection = VSSearchSectionArchivedNotes;
	
	NSIndexPath *indexPathOfAddedNote = [self addNote:timelineNote section:noteDestinationSection];
	(void)indexPathOfAddedNote;
	
	[self.tableView beginUpdates];
	
	if (indexPathOfRemovedNote != nil && indexPathOfRemovedNote.row != NSNotFound)
		[self.tableView deleteRowsAtIndexPaths:@[indexPathOfRemovedNote] withRowAnimation:UITableViewRowAnimationFade];
	
	if (indexPathOfAddedNote != nil && indexPathOfAddedNote.row != NSNotFound)
		[self.tableView insertRowsAtIndexPaths:@[indexPathOfAddedNote] withRowAnimation:UITableViewRowAnimationFade];
	
	[self.tableView endUpdates];
	
	
	self.animatingTableUpdate = NO;
}


- (void)archiveNote:(VSTimelineNote *)timelineNote {
	
	[self markTimelineNote:timelineNote asArchived:YES];
}


- (void)deleteTimelineNote:(VSTimelineNote *)timelineNote {
	
	self.animatingTableUpdate = YES;
	
	[[VSDataController sharedController] deleteNotes:@[@(timelineNote.uniqueID)] userDidDelete:YES];
	
	NSInteger noteSection = (!timelineNote.archived ? VSSearchSectionNotes : VSSearchSectionArchivedNotes);
	NSUInteger indexOfNote = [[self noteArrayForSection:noteSection] indexOfObjectIdenticalTo:timelineNote];
	NSIndexPath *indexPathOfRemovedNote = nil;
	
	if (indexOfNote != NSNotFound) {
		indexPathOfRemovedNote = [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:noteSection];
		[self removeNoteAtIndexPath:indexPathOfRemovedNote];
	}
	
	[self.tableView beginUpdates];
	
	if (indexPathOfRemovedNote != nil && indexPathOfRemovedNote.row != NSNotFound)
		[self.tableView deleteRowsAtIndexPaths:@[indexPathOfRemovedNote] withRowAnimation:UITableViewRowAnimationFade];
	
	[self.tableView endUpdates];
	
	self.animatingTableUpdate = NO;
}


- (void)restoreNote:(VSTimelineNote *)timelineNote {
	
	[self markTimelineNote:timelineNote asArchived:NO];
}


- (void)archiveOrRestoreNote:(id)sender {
	
	VSTimelineNote *note = [self timelineNoteForSender:sender];
	if (note.archived)
		[self restoreNote:note];
	else
		[self archiveNote:note];
}

@end

