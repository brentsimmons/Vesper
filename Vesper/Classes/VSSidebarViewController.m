//
//  VSSidebarViewController.m
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSSidebarViewController.h"
#import "VSTag.h"
#import "VSCreditsViewController.h"
#import "VSSidebarTableViewCell.h"
#import "VSSidebarView.h"
#import "VSTypographyViewController.h"
#import "VSSidebarTagsController.h"
#import "VSTimelineViewController.h"
#import "VSTimelineNotesController.h"
#import "VSTimelineContext.h"
#import "QSFetchRequest.h"
#import "VSSyncUI.h"
#import "VSSidebarArchiveStatusController.h"
#import "VSSidebarUntaggedStatusController.h"
#import "VSExportViewController.h"
#import "VSUI.h"


@interface VSSidebarSelectionSpecifier : NSObject

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) VSTag *tag;
@end


@implementation VSSidebarSelectionSpecifier
@end


#pragma mark -

@interface VSSidebarViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *orderedTags;
@property (nonatomic, assign) BOOL didSelectTopRowOnLaunch;
@property (nonatomic, strong) VSSidebarSelectionSpecifier *selectedObject;
@property (nonatomic, strong) VSSidebarTagsController *tagsController;
@property (nonatomic) UINavigationController *syncNavigationController;
@property (nonatomic, readonly) VSSidebarArchiveStatusController *archiveStatusController;
@property (nonatomic) BOOL hasAtLeastOneArchivedNote;
@property (nonatomic) VSSidebarUntaggedStatusController *untaggedStatusController;
@property (nonatomic) BOOL hasAtLeastOneUntaggedNote;

@end


@implementation VSSidebarViewController


#pragma mark - Init

- (id)init {

	self = [super initWithNibName:nil bundle:nil];
	if (self == nil)
		return nil;

	_orderedTags = [NSArray new];

	[self addObserver:self forKeyPath:@"orderedTags" options:0 context:nil];
	[self addObserver:self forKeyPath:@"isFocusedViewController" options:0 context:nil];
	[self addObserver:self forKeyPath:@"hasAtLeastOneArchivedNote" options:0 context:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rightSideViewFrameDidChange:) name:VSRightSideViewFrameDidChangeNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChangeState:) name:VSAccountDidAttemptLoginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChangeState:) name:VSAccountUserDidSignOutNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChangeState:) name:VSAccountExistsNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountDidChangeState:) name:VSAccountDoesNotExistNotification object:nil];

	_selectedObject = [VSSidebarSelectionSpecifier new];
	_selectedObject.indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

	_tagsController = [VSSidebarTagsController new];
	[_tagsController addObserver:self forKeyPath:@"orderedTags" options:NSKeyValueObservingOptionInitial context:nil];

	_archiveStatusController = [VSSidebarArchiveStatusController new];
	[_archiveStatusController addObserver:self forKeyPath:@"hasAtLeastOneArchivedNote" options:NSKeyValueObservingOptionInitial context:nil];

	_untaggedStatusController = [VSSidebarUntaggedStatusController new];
	[_untaggedStatusController addObserver:self forKeyPath:@"hasAtLeastOneUntaggedNote" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"hasAtLeastOneUntaggedNote" options:0 context:nil];

	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"orderedTags" context:nil];
	[self removeObserver:self forKeyPath:@"isFocusedViewController" context:nil];
	[self removeObserver:self forKeyPath:@"hasAtLeastOneArchivedNote" context:nil];
	[self removeObserver:self forKeyPath:@"hasAtLeastOneUntaggedNote" context:nil];
	[_archiveStatusController removeObserver:self forKeyPath:@"hasAtLeastOneArchivedNote" context:nil];
	[_tagsController removeObserver:self forKeyPath:@"orderedTags" context:nil];
	[_untaggedStatusController removeObserver:self forKeyPath:@"hasAtLeastOneUntaggedNote" context:nil];
}


#pragma mark KVO

static const NSTimeInterval VSSidebarCoalescedInterval = 0.1f;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([keyPath isEqualToString:@"orderedTags"] && object == self.tagsController) {

		if (![self.orderedTags isEqual:self.tagsController.orderedTags]) {
			self.orderedTags = self.tagsController.orderedTags;

			NSMutableDictionary *userInfo = [NSMutableDictionary new];
			[userInfo qs_safeSetObject:self.orderedTags forKey:VSTagsKey];
			[[NSNotificationCenter defaultCenter] postNotificationName:VSSidebarTagsDidChangeNotification object:self userInfo:userInfo];
		}


	}

	else if ([keyPath isEqualToString:@"orderedTags"] && object == self) {
		[self qs_performSelectorCoalesced:@selector(reloadData) withObject:nil afterDelay:VSSidebarCoalescedInterval];
	}

	else if ([keyPath isEqualToString:@"isFocusedViewController"])
		self.tableView.scrollsToTop = self.isFocusedViewController;

	else if ([keyPath isEqualToString:@"hasAtLeastOneArchivedNote"] && object == self.archiveStatusController) {

		if (self.hasAtLeastOneArchivedNote != self.archiveStatusController.hasAtLeastOneArchivedNote) {
			self.hasAtLeastOneArchivedNote = self.archiveStatusController.hasAtLeastOneArchivedNote;
		}
	}

	else if ([keyPath isEqualToString:@"hasAtLeastOneUntaggedNote"] && object == self.untaggedStatusController) {
		if (self.hasAtLeastOneUntaggedNote != self.untaggedStatusController.hasAtLeastOneUntaggedNote) {
			self.hasAtLeastOneUntaggedNote = self.untaggedStatusController.hasAtLeastOneUntaggedNote;
		}
	}
	else if ([keyPath isEqualToString:@"hasAtLeastOneUntaggedNote"] && object == self) {
		[self qs_performSelectorCoalesced:@selector(reloadData) withObject:nil afterDelay:VSSidebarCoalescedInterval];
	}

	else if ([keyPath isEqualToString:@"hasAtLeastOneArchivedNote"] && object == self) {
		[self reloadArchiveRow];
	}
}


#pragma mark Notifications

- (void)rightSideViewFrameDidChange:(NSNotification *)note {
	[self updateUserInteractionEnabled];
}


- (void)sidebarDidChangeDisplayState:(NSNotification *)note {

	BOOL sidebarIsShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	if (sidebarIsShowing)
		[self postFocusedViewControllerDidChangeNotification:self];
	[self updateUserInteractionEnabled];
}


- (void)accountDidChangeState:(NSNotification *)note {

	[self reloadSyncRow];
}


#pragma mark - User Interaction

- (void)updateUserInteractionEnabled {

	if (!app_delegate.sidebarShowing) {
		self.tableView.userInteractionEnabled = NO;
		return;
	}

	UIViewController *rightSideViewController = app_delegate.rootRightSideViewController;
	CGRect r = rightSideViewController.view.frame;
	if (r.origin.x < [app_delegate.theme floatForKey:@"sidebarWidth"]) {
		self.tableView.userInteractionEnabled = NO;
		return;
	}

	self.tableView.userInteractionEnabled = YES;
}


#pragma mark Reloading Data

static NSUInteger VSSidebarNumberOfSections = 5;

typedef enum _VSSidebarSection {
	VSSidebarSectionAllNotes,
	VSSidebarSectionTags,
	VSSidebarSectionUntagged,
	VSSidebarSectionArchive,
	VSSidebarSectionMisc
} VSSidebarSection;


static NSInteger VSSidebarSectionAllNotesSize = 1;

typedef enum _VSSidebarSectionAllNotesItem {
	VSSidebarAllNotes
} VSSidebarSectionAllNotesItem;


static NSInteger VSSidebarSectionArchiveSize = 1;

typedef enum _VSSidebarSectionArchiveItem {
	VSSidebarArchive
} _VSSidebarSectionArchiveItem;


static NSInteger VSSidebarSectionMiscSize = 4;

typedef enum _VSSidebarSectionMiscItem {
	VSSidebarExport,
	VSSidebarSync,
	VSSidebarTypography,
	VSSidebarCredits
} VSSidebarSectionMiscItem;


- (void)reloadSyncRow {

	[self reloadData];
}


- (void)reloadArchiveRow {

	[self reloadData];
}


- (void)saveSelection {

	VSSidebarSelectionSpecifier *selection = [VSSidebarSelectionSpecifier new];
	selection.indexPath = [self.tableView indexPathForSelectedRow];

	if (selection.indexPath.section == VSSidebarSectionTags) {
		VSTag *tag = [self tagAtIndex:(NSUInteger)selection.indexPath.row];
		selection.tag = tag;
	}

	self.selectedObject = selection;
}


- (void)restoreSelection {

	if (self.selectedObject.tag != nil)
		[self selectRowForTag:self.selectedObject.tag];
	else if (self.selectedObject.indexPath != nil)
		[self.tableView selectRowAtIndexPath:self.selectedObject.indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	else
		[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}


- (void)reloadData {

	[self.tableView reloadData];
	[self restoreSelection];
}


#pragma mark - UIViewController

- (void)loadView {

	self.view = [[VSSidebarView alloc] initWithFrame:RSFullViewRect()];
	self.sidebarView = (VSSidebarView *)(self.view);
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view setNeedsLayout];

	UIView *backgroundView = [[UIView alloc] initWithFrame:RSFullViewRect()];
	backgroundView.opaque = NO;
	backgroundView.backgroundColor = [UIColor clearColor];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	backgroundView.contentMode = UIViewContentModeTopLeft;
	[self.view addSubview:backgroundView];
	((VSSidebarView *)(self.view)).backgroundView = backgroundView;

	self.tableView = [[UITableView alloc] initWithFrame:RSFullViewRect() style:UITableViewStylePlain];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.opaque = NO;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.contentInset = UIEdgeInsetsMake(VSNormalStatusBarHeight(), 0.0f, 0.0f, 0.0f);
	[backgroundView addSubview:self.tableView];
	((VSSidebarView *)(self.view)).tableView = self.tableView;
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.contentMode = UIViewContentModeTopLeft;
	self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;

	[self.view setNeedsLayout];

	self.tableView.scrollsToTop = NO;

	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	CGFloat viewWidth = self.view.frame.size.width;
	CGFloat insetRight = viewWidth - sidebarWidth;
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, insetRight);
}


#pragma mark - Tags

- (VSTag *)tagAtIndex:(NSUInteger)tagIndex {
	return [self.orderedTags qs_safeObjectAtIndex:tagIndex];
}


- (NSString *)titleForTagAtIndex:(NSUInteger)tagIndex {

	VSTag *tag = [self tagAtIndex:tagIndex];
	return tag.name;
}


- (NSUInteger)indexOfTag:(VSTag *)tag {
	return [self.orderedTags indexOfObjectIdenticalTo:tag];
}


#pragma mark - Selection

- (void)selectRowForTag:(VSTag *)tag {

	NSUInteger indexOfTag = [self indexOfTag:tag];
	if (indexOfTag == NSNotFound)
		return;

	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)indexOfTag inSection:VSSidebarSectionTags];
	[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	[self saveSelection];
}


#pragma mark - Images

+ (UIImage *)tintedImageForKey:(NSString *)key {

	static NSMutableDictionary *imageCache = nil;

	if (imageCache == nil) {
		imageCache = [NSMutableDictionary new];
	}

	UIImage *cachedImage = [imageCache objectForKey:key];
	if (cachedImage != nil)
		return cachedImage;

	NSString *imageName = [app_delegate.theme stringForKey:key];
	if (QSStringIsEmpty(imageName))
		return nil;

	UIImage *rawImage = [UIImage imageNamed:imageName];
	if (rawImage == nil)
		return nil;

	UIColor *tintColor = [app_delegate.theme colorForKey:@"sidebarIconColor"];
	UIImage *image = [rawImage qs_imageTintedWithColor:tintColor];

	if (image != nil)
		[imageCache setObject:image forKey:key];

	return image;
}


+ (UIImage *)tintedHighlightedImageForKey:(NSString *)key {

	static NSMutableDictionary *imageCache = nil;

	if (imageCache == nil) {
		imageCache = [NSMutableDictionary new];
	}

	UIImage *cachedImage = [imageCache objectForKey:key];
	if (cachedImage != nil)
		return cachedImage;

	NSString *imageName = [app_delegate.theme stringForKey:key];
	if (QSStringIsEmpty(imageName))
		return nil;

	UIImage *rawImage = [UIImage imageNamed:imageName];
	if (rawImage == nil)
		return nil;

	UIColor *tintColor = [app_delegate.theme colorForKey:@"sidebarSelectedIconColor"];
	UIImage *image = [rawImage qs_imageTintedWithColor:tintColor];

	if (image != nil)
		[imageCache setObject:image forKey:key];

	return image;
}


- (NSString *)imageKeyForIndexPath:(NSIndexPath *)indexPath {

	NSString *imageKey = nil;

	switch (indexPath.section) {

		case VSSidebarSectionAllNotes:
			imageKey = @"sidebarAllNotesIconAsset";
			break;

		case VSSidebarSectionArchive: {

			imageKey = @"sidebarArchiveIconAsset";
			if (self.hasAtLeastOneArchivedNote) {
				imageKey = @"sidebarArchiveNotEmptyAsset";
			}
		}
			break;

		case VSSidebarSectionMisc: {
			if (indexPath.row == VSSidebarCredits)
				imageKey = @"sidebarCreditsIconAsset";
			else if (indexPath.row == VSSidebarTypography)
				imageKey = @"sidebarTypographyIconAsset";

			else if (indexPath.row == VSSidebarSync) {

				imageKey = @"sidebarSyncIconAsset";

				if (![[VSAccount account] hasUsernameAndPassword]) {
					imageKey = @"sidebarSyncDisabledIconAsset";
				}

				else if ([VSAccount account].loginDidFailWithAuthenticationError) {
					imageKey = @"sidebarSyncErrorIconAsset";
				}
			}
			else if (indexPath.row == VSSidebarExport) {
				imageKey = @"sidebarExportIconAsset";
			}

			break;
		}

		case VSSidebarSectionTags:
			imageKey = @"sidebarTagIconAsset";
			break;

		case VSSidebarSectionUntagged:
			imageKey = @"sidebarUntaggedIconAsset";
			break;

		default:
			break;
	}

	return imageKey;
}


- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath {

	NSString *imageKey = [self imageKeyForIndexPath:indexPath];
	if (QSStringIsEmpty(imageKey))
		return nil;
	return [[self class] tintedImageForKey:imageKey];
}


- (UIImage *)highlightedImageForIndexPath:(NSIndexPath *)indexPath {

	NSString *imageKey = [self imageKeyForIndexPath:indexPath];
	if (QSStringIsEmpty(imageKey))
		return nil;
	return [[self class] tintedHighlightedImageForKey:imageKey];
}


#pragma mark - Table View Utilities

- (void)configureCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {

	cell.textLabel.textColor = [app_delegate.theme colorForKey:@"sidebarTextColor"];
	cell.textLabel.highlightedTextColor = [app_delegate.theme colorForKey:@"sidebarSelectedTextColor"];

	if (indexPath.section == VSSidebarSectionArchive)
		cell.textLabel.font = [app_delegate.theme fontForKey:@"sidebarTextItalicFont"];
	else
		cell.textLabel.font = [app_delegate.theme fontForKey:@"sidebarTextFont"];

	NSDictionary *attributes = @{NSForegroundColorAttributeName : cell.textLabel.textColor, NSFontAttributeName : cell.textLabel.font, NSKernAttributeName : [NSNull null]};
	NSString *s = [self titleForIndexPath:indexPath];
	cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:s attributes:attributes];

	cell.imageView.image = [self highlightedImageForIndexPath:indexPath];//[self imageForIndexPath:indexPath];
	cell.imageView.highlightedImage = [self highlightedImageForIndexPath:indexPath];


	((VSSidebarTableViewCell *)cell).showIcon = YES;//[self shouldShowIconForIndexPath:indexPath];

}


- (NSString *)titleForIndexPath:(NSIndexPath *)indexPath {

	NSString *title = nil;

	switch (indexPath.section) {

		case VSSidebarSectionAllNotes:
			title = NSLocalizedString(@"All Notes", @"All Notes");
			break;

		case VSSidebarSectionArchive:
			title = NSLocalizedString(@"Archive", @"Archive");
			break;

		case VSSidebarSectionUntagged:
			title = NSLocalizedString(@"Untagged", @"Untagged");
			break;

		case VSSidebarSectionMisc: {
			if (indexPath.row == VSSidebarCredits)
				title = NSLocalizedString(@"Credits", @"Credits");
			else if (indexPath.row == VSSidebarTypography)
				title = NSLocalizedString(@"Typography", @"Typography");
			else if (indexPath.row == VSSidebarSync)
				title = NSLocalizedString(@"Sync", @"Sync");
			else if (indexPath.row == VSSidebarExport) {
				title = NSLocalizedString(@"Export", @"Export");
			}
			break;

		}

		case VSSidebarSectionTags:
			title = [self titleForTagAtIndex:(NSUInteger)indexPath.row];
			break;

		default:
			break;
	}

	return title;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (NSInteger)VSSidebarNumberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	NSInteger numberOfRows = 0;

	switch (section) {

		case VSSidebarSectionAllNotes:
			numberOfRows = VSSidebarSectionAllNotesSize;
			break;
		case VSSidebarSectionTags:
			numberOfRows = (NSInteger)[self.orderedTags count];
			break;
		case VSSidebarSectionArchive:
			numberOfRows = VSSidebarSectionArchiveSize;
			break;
		case VSSidebarSectionMisc:
			numberOfRows = VSSidebarSectionMiscSize;
			break;
		case VSSidebarSectionUntagged:
			numberOfRows = self.hasAtLeastOneUntaggedNote ? 1 : 0;
			break;

		default:
			break;
	}

	return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *reuseIdentifier = @"VSSidebarTableViewCell";
	VSSidebarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil) {
		cell = [[VSSidebarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}

	[self configureCell:cell indexPath:indexPath];

	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	return [app_delegate.theme floatForKey:@"sidebarRowHeight"];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[self saveSelection];
	[self showViewControllerForIndexPath:indexPath];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	if (section != VSSidebarSectionMisc)
		return 0.0f;
	return [app_delegate.theme floatForKey:@"sidebarSectionMiscMarginTop"];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

	if (section != VSSidebarSectionMisc)
		return nil;

	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenWidth, [app_delegate.theme floatForKey:@"sidebarSectionMiscMarginTop"])];
	view.backgroundColor = [UIColor clearColor];
	view.opaque = NO;

	return view;
}


#pragma mark - View Controllers

- (VSTimelineViewController *)listViewControllerForAllNotes {

	VSTimelineContext *context = [VSTimelineContext new];

	context.title = NSLocalizedString(@"All Notes", @"All Notes");
	context.canReorderNotes = YES;
	context.canMakeNewNotes = YES;
	context.searchesArchivedNotesOnly = NO;
	context.noNotesImageName = @"nonotes";

	context.timelineNotesController = [[VSTimelineNotesController alloc] initWithFetchRequest:[[VSDataController sharedController] fetchRequestForAllNotes] noteBelongsBlock:^BOOL(VSNote *note) {

		return !note.archived;
	}];

	return [[VSTimelineViewController alloc] initWithContext:context];
}


- (VSTimelineViewController *)listViewControllerForTag:(VSTag *)tag {

	VSTimelineContext *context = [VSTimelineContext new];

	context.title = tag.name;
	context.tag = tag;
	context.canReorderNotes = YES;
	context.canMakeNewNotes = YES;
	context.searchesArchivedNotesOnly = NO;
	context.noNotesImageName = @"nonotes";

	context.timelineNotesController = [[VSTimelineNotesController alloc] initWithFetchRequest:[[VSDataController sharedController] fetchRequestForNotesWithTag:tag] noteBelongsBlock:^BOOL(VSNote *note) {

		return [note.tags containsObject:tag] && !note.archived;
	}];

	return [[VSTimelineViewController alloc] initWithContext:context];
}


- (VSTimelineViewController *)listViewControllerForArchivedNotes {

	VSTimelineContext *context = [VSTimelineContext new];

	context.title = NSLocalizedString(@"Archive", @"Archive");
	context.canReorderNotes = NO;
	context.canMakeNewNotes = NO;
	context.searchesArchivedNotesOnly = YES;
	context.noNotesImageName = @"noarchive";
	context.showInitialNoNotesView = !self.hasAtLeastOneArchivedNote;

	context.timelineNotesController = [[VSTimelineNotesController alloc] initWithFetchRequest:[[VSDataController sharedController] fetchRequestForArchivedNotes] noteBelongsBlock:^BOOL(VSNote *note) {

		return note.archived;
	}];

	return [[VSTimelineViewController alloc] initWithContext:context];
}


- (VSTimelineViewController *)listViewControllerForUntaggedNotes {

	VSTimelineContext *context = [VSTimelineContext new];

	context.title = NSLocalizedString(@"Untagged", @"Untagged");
	context.canReorderNotes = YES;
	context.canMakeNewNotes = YES;
	context.searchesArchivedNotesOnly = NO;
	context.noNotesImageName = @"nonotes";
	context.showInitialNoNotesView = !self.hasAtLeastOneUntaggedNote;

	context.timelineNotesController = [[VSTimelineNotesController alloc] initWithFetchRequest:[[VSDataController sharedController] fetchRequestForUntaggedNotes] noteBelongsBlock:^BOOL(VSNote *note) {

		return [note.tags count] < 1 && !note.archived;
	}];

	return [[VSTimelineViewController alloc] initWithContext:context];
}


- (UIViewController *)viewControllerForIndexPath:(NSIndexPath *)indexPath {

	UIViewController *viewController = nil;

	switch (indexPath.section) {

		case VSSidebarSectionAllNotes:

			viewController = [self listViewControllerForAllNotes];
			break;

		case VSSidebarSectionTags: {

			VSTag *tag = [self tagAtIndex:(NSUInteger)indexPath.row];
			viewController = [self listViewControllerForTag:tag];
			break;
		}

		case VSSidebarSectionArchive:

			viewController = [self listViewControllerForArchivedNotes];
			break;

		case VSSidebarSectionMisc:

			if (indexPath.row == VSSidebarCredits) {
				viewController = [VSCreditsViewController new];
			}
			else if (indexPath.row == VSSidebarTypography) {
				viewController = [VSTypographyViewController new];
			}
			else if (indexPath.row == VSSidebarSync) {
				viewController = [VSSyncUI initialController];
			}
			else if (indexPath.row == VSSidebarExport) {
				viewController = [VSExportViewController new];
			}
			break;

		case VSSidebarSectionUntagged:
			viewController = [self listViewControllerForUntaggedNotes];
			break;

		default:
			break;
	}

	return viewController;
}


- (void)showViewControllerForIndexPath:(NSIndexPath *)indexPath {

	UIViewController *viewController = [self viewControllerForIndexPath:indexPath];
	if (viewController == nil)
		return;

	[self.rootViewManager showViewController:viewController];
}


- (void)showInitialViewController {

	[self.rootViewManager showViewController:[self listViewControllerForAllNotes]];
}


@end
