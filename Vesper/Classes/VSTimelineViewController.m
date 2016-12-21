//
//  VSTimelineViewController.m
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSTimelineViewController.h"
#import "UIView+RSExtras.h"
#import "VSNavbarButton.h"
#import "VSTimelineCell.h"
#import "VSNote.h"
#import "VSNavbarView.h"
#import "VSDetailViewController.h"
#import "VSRootViewController.h"
#import "VSThumbnail.h"
#import "VSAttachment.h"
#import "VSSearchBarContainerView.h"
#import "VSTimelineTableView.h"
#import "VSSearchResultsViewController.h"
#import "VSDetailTransitionView.h"
#import "VSDetailTransitionNavbarView.h"
#import "VSDetailNavbarView.h"
#import "VSDetailTextView.h"
#import "VSRowHeightCache.h"
#import "VSNoNotesView.h"
#import "VSTagDetailScrollView.h"
#import "VSDetailView.h"
#import "VSDetailToolbar.h"
#import "VSTableViewDragController.h"
#import "VSTimelineNotesController.h"
#import "VSTimelineContext.h"
#import "VSTimelineToDetailAnimator.h"
#import "VSDetailToTimelineAnimator.h"
#import "VSSearchResultsToDetailAnimator.h"
#import "VSDetailToSearchResultsAnimator.h"
#import "VSProgressView.h"
#import "VSAttachmentStorage.h"


@interface VSTimelineViewController () <UISearchBarDelegate, VSTimelineCellDelegate, UITableViewDataSource, UITableViewDelegate, VSTableViewDragControllerDelegate, UIGestureRecognizerDelegate, VSTimelineNotesControllerDelegate>

@property (nonatomic, readwrite) VSNavbarView *navbar;
@property (nonatomic) VSDetailViewController *detailViewController;
@property (nonatomic, readwrite) VSSearchBarContainerView *searchBarContainerView;
@property (nonatomic) BOOL sidebarShowing;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizerToCloseSidebar;
@property (nonatomic, readwrite) CGFloat searchBarContainerViewHeight;
@property (nonatomic) CGFloat searchBarContainerViewSearchingHeight;
@property (nonatomic) CGFloat searchBarContainerDragShowThreshold;
@property (nonatomic) CGFloat searchBarContainerDragHideThreshold;
@property (nonatomic) BOOL searchBarShowing;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) BOOL searchFieldActive;
@property (nonatomic, readwrite) UIView *searchOverlay;
@property (nonatomic) BOOL inSearchMode;
@property (nonatomic) BOOL keyboardShowing;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizerToCloseSidebar;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizerToOpenSidebar;
@property (nonatomic) VSTableViewDragController *dragController;
@property (nonatomic) NSIndexPath *selectedRowIndexPath;
@property (nonatomic) BOOL composeViewShowing;
@property (nonatomic) UIImage *detailAnimationImage;
@property (nonatomic) UIView *searchUnderlayView; /*For solid backing below faded-out timeline view*/
@property (nonatomic) VSNoNotesView *noNotesView;
@property (nonatomic) BOOL isPanning;
@property (nonatomic) BOOL hasSelectedRow;
@property (nonatomic) BOOL isDraggingRow;
@property (nonatomic, readwrite) UITableView *tableView;
@property (nonatomic) VSSearchResultsViewController *searchResultsViewController;
@property (nonatomic) VSTimelineCell *panningCell;
@property (nonatomic) BOOL inManualTableUpdate;
@property (nonatomic) UIView *dataMigrationView;
@property (nonatomic) VSProgressView *dataMigrationProgressView;
@property (nonatomic) BOOL migratingData;

@end


@implementation VSTimelineViewController


#pragma mark - Init

- (instancetype)initWithContext:(VSTimelineContext *)context {
	
	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}
	
	_context = context;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailCached:) name:VSThumbnailCachedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameDidChange:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataMigrationDidBegin:) name:VSDataMigrationDidBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataMigrationDidComplete:) name:VSDataMigrationDidCompleteNotification object:nil];
	
	[self addObserver:self forKeyPath:@"sidebarShowing" options:0 context:nil];
	[self addObserver:self forKeyPath:@"title" options:0 context:nil];
	[self addObserver:self forKeyPath:@"isFocusedViewController" options:0 context:nil];
	
	self.title = context.title;
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	_tableView.delegate = nil;
	_searchBar.delegate = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self removeObserver:self forKeyPath:@"sidebarShowing"];
	[self removeObserver:self forKeyPath:@"title"];
	[self removeObserver:self forKeyPath:@"isFocusedViewController"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"sidebarShowing"] && object == self) {
		[self updateGestureRecognizersforDataViewController];
		self.searchBar.userInteractionEnabled = !self.sidebarShowing;
		self.tableView.scrollEnabled = !self.sidebarShowing;
		self.dragController.enabled = !self.sidebarShowing;
	}
	
	else if ([keyPath isEqualToString:@"title"] && object == self) {
		self.navbar.title = self.title;
	}
	
	else if ([keyPath isEqualToString:@"isFocusedViewController"]) {
		self.tableView.scrollsToTop = self.isFocusedViewController;
	}
}


#pragma mark - Notifications

- (void)sidebarDidChangeDisplayState:(NSNotification *)note {
	
	BOOL sidebarShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	if (sidebarShowing != self.sidebarShowing)
		self.sidebarShowing = sidebarShowing;
	if (!sidebarShowing) {
		if (self.view.superview != nil)
			[self postFocusedViewControllerDidChangeNotification:self];
	}
}


- (void)dataMigrationDidBegin:(NSNotification *)note {
	
	self.migratingData = YES;
	[self showDataMigrationActivityView];
}


- (void)dataMigrationDidComplete:(NSNotification *)note {
	
	/*Don't set self.migratingData = NO until data is actually coming in --
	 it gets set in tableView:cellForRowAtIndexPath:.
	 This prevents the no-notes view from appearing.*/
	
	[self removeDataMigrationActivityView];
}


#pragma mark - Data Migration

- (void)showDataMigrationActivityView {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	CGRect r = self.tableView.frame;
	
	self.dataMigrationView = [[UIView alloc] initWithFrame:r];
	self.dataMigrationView.opaque = YES;
	self.dataMigrationView.backgroundColor = self.tableView.backgroundColor;
	
	CGFloat labelY = [app_delegate.theme floatForKey:@"updatingNotes.labelY"];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, labelY, CGRectGetWidth(r), 30.0f)];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	label.font = [app_delegate.theme fontForKey:@"updatingNotes.font"];
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [app_delegate.theme colorForKey:@"updatingNotes.textColor"];
	label.text = NSLocalizedString(@"Updating Notes", @"Updating Notes");
	[self.dataMigrationView addSubview:label];
	
	self.dataMigrationProgressView = [VSProgressView new];
	CGSize progressViewSize = [self.dataMigrationProgressView sizeThatFits:CGSizeMake(CGRectGetWidth(r), CGFLOAT_MAX)];
	CGRect rProgress = CGRectZero;
	rProgress.origin.y = [app_delegate.theme floatForKey:@"updatingNotes.circleProgressY"];
	rProgress.size = progressViewSize;
	rProgress = CGRectCenteredHorizontallyInRect(rProgress, r);
	rProgress.size = progressViewSize;
	self.dataMigrationProgressView.frame = rProgress;
	
	[self.dataMigrationView addSubview:self.dataMigrationProgressView];
	
	[self.dataMigrationProgressView startAnimating];
	
	[self.view addSubview:self.dataMigrationView];
}


- (void)removeDataMigrationActivityView {
	
	[self.dataMigrationProgressView stopAnimating];
	
	[UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
		
		self.dataMigrationView.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		
		[self.dataMigrationView removeFromSuperview];
		self.dataMigrationView = nil;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
	
}


#pragma mark - Interaction States

- (BOOL)isPanning {
	return (self.panningCell != nil);
}


- (BOOL)hasSelectedRow {
	return ([self.tableView indexPathForSelectedRow] != nil);
}


- (BOOL)isDraggingRow {
	return (self.draggedNote != nil);
}


#pragma mark - No Notes

- (void)setupNoNotesImageView {
	
	self.noNotesView = [[VSNoNotesView alloc] initWithFrame:CGRectZero image:[self.context noNotesImage]];
	CGRect rNoNotes = CGRectZero;
	rNoNotes.size = [self.noNotesView sizeThatFits:CGSizeZero];
	self.noNotesView.frame = rNoNotes; /*Will get x,y set later*/
	self.noNotesView.hidden = YES;
}


- (void)updateNoNotesImageView {
	
	if (self.context.timelineNotesController.hasNotes || self.migratingData) {
		self.noNotesView.hidden = YES;
		[self.noNotesView removeFromSuperview];
	}
	
	else {
		
		NSDate *firstRunDate = app_delegate.firstRunDate;
		if (app_delegate.firstRun && [[NSDate date] timeIntervalSinceDate:firstRunDate] < 4) {
			return; /*Hack to prevent flash on first run.*/
		}
		
		BOOL noNotesViewIsInView = (self.noNotesView.superview != nil);
		
		if (!self.noNotesView) {
			[self setupNoNotesImageView];
		}
		
		CGRect r = self.tableView.frame;
		CGSize noNotesSize = self.noNotesView.frame.size;
		r.size = noNotesSize;
		r.origin.y = [app_delegate.theme floatForKey:@"noNotesOriginY"];
		r = CGRectCenteredHorizontallyInRect(r, self.view.bounds);
		r.size = noNotesSize;
		
		[self.noNotesView qs_setFrameIfNotEqual:r];
		
		if (!noNotesViewIsInView) {
			[self.view insertSubview:self.noNotesView aboveSubview:self.tableView];
			self.noNotesView.alpha = 0.0f;
			self.noNotesView.hidden = NO;
			
			[UIView animateWithDuration:0.25f animations:^{
				self.noNotesView.alpha = 1.0f;
			}];
		}
	}
}


#pragma mark - Gesture Recognizers

- (void)animateSidebarBasedOnListViewPosition {
	
	CGRect rListView = self.view.frame;
	
	if (rListView.origin.x < [app_delegate.theme floatForKey:@"sidebarOpenThreshold"])
		[self closeSidebar:self];
	else
		[self openSidebar:self];
}


- (void)animateSidebarBasedOnListViewPositionForAltNavbar {
	
	CGRect rListView = self.view.frame;
	
	if (rListView.origin.x < [app_delegate.theme floatForKey:@"sidebarCloseThreshold"])
		[self closeSidebar:self];
	else
		[self openSidebar:self];
}


- (void)addGestureRecognizersToCloseSidebar {
	
	self.tapGestureRecognizerToCloseSidebar = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSidebar:)];
	[self.view addGestureRecognizer:self.tapGestureRecognizerToCloseSidebar];
	
	self.panGestureRecognizerToCloseSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panInListView:)];
	[self.view addGestureRecognizer:self.panGestureRecognizerToCloseSidebar];
	self.panGestureRecognizerToCloseSidebar.delegate = self;
}


- (void)removeGestureRecognizersToCloseSidebar {
	[self.view removeGestureRecognizer:self.tapGestureRecognizerToCloseSidebar];
	self.tapGestureRecognizerToCloseSidebar = nil;
	
	[self.view removeGestureRecognizer:self.panGestureRecognizerToCloseSidebar];
	self.panGestureRecognizerToCloseSidebar.delegate = nil;
	self.panGestureRecognizerToCloseSidebar = nil;
}


- (void)addGestureRecognizerToOpenSidebar {
	
	if ([app_delegate.theme boolForKey:@"sidebarOpenPanRequiresEdge"]) {
		self.panGestureRecognizerToOpenSidebar = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panInListView:)];
		((UIScreenEdgePanGestureRecognizer *)self.panGestureRecognizerToOpenSidebar).edges = UIRectEdgeLeft;
	}
	else
		self.panGestureRecognizerToOpenSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panInListView:)];
	[self.view addGestureRecognizer:self.panGestureRecognizerToOpenSidebar];
	self.panGestureRecognizerToOpenSidebar.delegate = self;
}


- (void)removeGestureRecognizerToOpenSidebar {
	
	[self.view removeGestureRecognizer:self.panGestureRecognizerToOpenSidebar];
	self.panGestureRecognizerToOpenSidebar.delegate = nil;
	self.panGestureRecognizerToOpenSidebar = nil;
}


- (void)updateGestureRecognizersforDataViewController {
	if (self.sidebarShowing) {
		[self addGestureRecognizersToCloseSidebar];
		[self removeGestureRecognizerToOpenSidebar];
	}
	else {
		[self removeGestureRecognizersToCloseSidebar];
		[self addGestureRecognizerToOpenSidebar];
	}
}


- (void)panInNavbar:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	[self adjustAnchorPointForGestureRecognizer:panGestureRecognizer];
	
	UIGestureRecognizerState gestureRecognizerState = panGestureRecognizer.state;
	
	switch (gestureRecognizerState) {
			
		case UIGestureRecognizerStateBegan:
		case UIGestureRecognizerStateChanged:
			[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self animateSidebarBasedOnListViewPosition];
			break;
			
		default:
			break;
	}
	
}


- (void)panInAltNavbar:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	[self adjustAnchorPointForGestureRecognizer:panGestureRecognizer];
	
	UIGestureRecognizerState gestureRecognizerState = panGestureRecognizer.state;
	
	switch (gestureRecognizerState) {
			
		case UIGestureRecognizerStateBegan:
		case UIGestureRecognizerStateChanged:
			[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self animateSidebarBasedOnListViewPositionForAltNavbar];
			break;
			
		default:
			break;
	}
}


- (void)panInListView:(UIPanGestureRecognizer *)panGestureRecognizer {
	if (panGestureRecognizer == self.panGestureRecognizerToOpenSidebar)
		[self panInNavbar:panGestureRecognizer];
	else
		[self panInAltNavbar:panGestureRecognizer];
}


- (void)handlePanGestureStateBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	CGPoint translation = [panGestureRecognizer translationInView:self.view.superview];
	CGFloat frameX = self.view.frame.origin.x + translation.x;
	if (frameX < 0.0f)
		frameX = 0.0f;
	
	CGRect frame = self.view.frame;
	frame.origin.x = frameX;
	self.view.frame = frame;
	
	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	CGFloat distanceFromLeft = frameX;
	CGFloat percentMoved = distanceFromLeft / sidebarWidth;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDataViewDidPanToRevealSidebarNotification object:self userInfo:@{VSPercentMovedKey: @(percentMoved)}];
	
	VSSendRightSideViewFrameDidChangeNotification(self, frame);
	
	[panGestureRecognizer setTranslation:CGPointZero inView:self.view.superview];
}


- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		
		CGPoint locationInView = [gestureRecognizer locationInView:self.view];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.view.superview];
		
		self.view.layer.anchorPoint = CGPointMake(locationInView.x / self.view.bounds.size.width, locationInView.y / self.view.bounds.size.height);
		self.view.center = locationInSuperview;
	}
}


- (BOOL)gestureRecognizerToOpenSidebarShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	if (self.inSearchMode)
		return NO;
	
	CGPoint translation = [panGestureRecognizer translationInView:self.view];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	if (translation.x < 0.0f)
		return NO;
	
	return YES;
}


- (BOOL)gestureRecognizerToCloseSidebarShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	CGPoint translation = [panGestureRecognizer translationInView:self.view];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	if (translation.x > 0.0f)
		return NO;
	
	return YES;
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	if (!self.isFocusedViewController && gestureRecognizer != self.panGestureRecognizerToCloseSidebar)
		return NO;
	
	if (gestureRecognizer == self.panGestureRecognizerToOpenSidebar)
		return [self gestureRecognizerToOpenSidebarShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer];
	
	else if (gestureRecognizer == self.panGestureRecognizerToCloseSidebar)
		return [self gestureRecognizerToCloseSidebarShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer];
	
	return YES;
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.view = [[UIView alloc] initWithFrame:RSFullViewRect()];
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.view.opaque = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	self.tableView = [[VSTimelineTableView alloc] initWithFrame:RSRectForMainView()];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:self.tableView];
	
	if (self.context.canReorderNotes) {
		self.dragController = [[VSTableViewDragController alloc] initWithTableView:self.tableView delegate:self];
	}
	
	self.searchBarContainerViewHeight = [app_delegate.theme floatForKey:@"searchBarContainerViewHeight"];
	self.searchBarContainerViewSearchingHeight = [app_delegate.theme floatForKey:@"searchBarContainerViewSearchingHeight"];
	self.searchBarContainerDragShowThreshold = [app_delegate.theme floatForKey:@"searchBarContainerDragShowThreshold"];
	self.searchBarContainerDragHideThreshold = [app_delegate.theme floatForKey:@"searchBarContainerDragHideThreshold"];
	
	self.searchBarContainerView = [[VSSearchBarContainerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.searchBarContainerViewHeight)];
	self.searchBarContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	self.searchBar = self.searchBarContainerView.searchBar;
	self.searchBar.delegate = self;
	
	self.searchOverlay = [[UIView alloc] initWithFrame:CGRectZero];
	self.searchOverlay.backgroundColor = [app_delegate.theme colorForKey:@"searchOverlayColor"];
	self.searchOverlay.hidden = YES;
	[self.view insertSubview:self.searchOverlay aboveSubview:self.tableView];
	UITapGestureRecognizer *overlayTapGestureRecognizer  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchOverlayTapped:)];
	[self.searchOverlay addGestureRecognizer:overlayTapGestureRecognizer];
	
	UIView *tableHeaderView = [[UIView alloc] initWithFrame:self.searchBarContainerView.frame];
	tableHeaderView.opaque = NO;
	tableHeaderView.backgroundColor = [UIColor clearColor];
	self.tableView.tableHeaderView = tableHeaderView;
	
	[self.view insertSubview:self.searchBarContainerView aboveSubview:self.searchOverlay];
	
	self.navbar = [VSNavbarView new];
	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panInNavbar:)];
	panGestureRecognizer.maximumNumberOfTouches = 1;
	[self.navbar.sidebarButton addGestureRecognizer:panGestureRecognizer];
	self.navbar.frame = RSNavbarRect();
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	self.navbar.title = self.title;
	[self.view addSubview:self.navbar];
	
	[self.view setNeedsLayout];
	
	self.context.timelineNotesController.delegate = self;
	
	[self fetchNotes];
	
	[self setFramesToNormalMode];
	
	[self updateGestureRecognizersforDataViewController];
	
	CGRect rSearchUnderlay = self.tableView.frame;
	self.searchUnderlayView = [[UIView alloc] initWithFrame:rSearchUnderlay];
	self.searchUnderlayView.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	
	if (self.context.showInitialNoNotesView) {
		[self updateNoNotesImageView];
	}
	[self performSelector:@selector(updateNoNotesImageView) withObject:nil afterDelay:2.0f];
}

#pragma mark - Layout

- (void)setFramesWithYOrigin:(CGFloat)y searchContainerViewHeight:(CGFloat)searchContainerViewHeight {
	
	CGRect rBounds = self.view.bounds;
	
	CGRect rNavbar = RSNavbarRect();
	rNavbar.origin.y = y;
	self.navbar.frame = rNavbar;
	
	CGRect rTable = self.tableView.frame;
	rTable.origin.y = CGRectGetMaxY(rNavbar);
	rTable.size.height = rBounds.size.height - rNavbar.size.height;
	rTable.size.height -= RSStatusBarHeight(); /*rNavbar.size.height already takes status bar into account. Why is this necessary?*/
	[self.tableView qs_setFrameIfNotEqual:rTable];
	self.tableView.frame = rTable;
	
	CGRect rOverlay = rBounds;
	rOverlay.origin.y = rTable.origin.y + searchContainerViewHeight;
	rOverlay.size.height = rBounds.size.height - rOverlay.origin.y;
	self.searchOverlay.frame = rOverlay;
}


- (void)setFramesToNormalMode {
	[self setFramesWithYOrigin:0.0f searchContainerViewHeight:self.searchBarContainerViewHeight];
	[self updateSearchBarContainerFrameWithScrollView:self.tableView];
	[self.searchUnderlayView removeFromSuperview];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}


- (void)setFramesToSearchMode {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	[self setFramesWithYOrigin:-(self.navbar.frame.size.height) searchContainerViewHeight:self.searchBarContainerViewSearchingHeight];
	
	CGRect r = self.searchBarContainerView.frame;
	r.origin.y = -3.0f + RSStatusBarHeight();
	r.size.height = self.searchBarContainerViewSearchingHeight;
	self.searchBarContainerView.frame = r;
	[self.view insertSubview:self.searchUnderlayView belowSubview:self.tableView];
	self.searchUnderlayView.frame = [UIScreen mainScreen].bounds;
}


- (void)layoutViewWithStatusBarFrame:(CGRect)rStatusBar {
	
	CGRect r = self.view.frame;
	CGRect rScreenBounds = [UIScreen mainScreen].bounds;
	r.origin.y = 0.0f;
	CGFloat extraStatusBarHeight = CGRectGetHeight(rStatusBar) - VSNormalStatusBarHeight();
	r.size.height = CGRectGetHeight(rScreenBounds) - extraStatusBarHeight;
	r.size.width = rScreenBounds.size.width;
	
	[self.view qs_setFrameIfNotEqual:r];
}


- (void)layoutWithStatusBarFrame:(CGRect)rStatusBar {
	
	CGRect rScreenBounds = [UIScreen mainScreen].bounds;
	CGFloat extraStatusBarHeight = CGRectGetHeight(rStatusBar) - VSNormalStatusBarHeight();
	
	CGRect rNavbar = self.navbar.frame;
	CGRect rTableView = self.tableView.frame;
	rTableView.origin.y = CGRectGetMaxY(rNavbar);
	rTableView.size.height = (CGRectGetHeight(rScreenBounds) - CGRectGetMinY(rTableView)) - extraStatusBarHeight;
	[self.tableView qs_setFrameIfNotEqual:rTableView];
}


- (void)layout {
	[self layoutViewWithStatusBarFrame:RSStatusBarFrame()];
	[self layoutWithStatusBarFrame:RSStatusBarFrame()];
}

- (void)viewDidLayoutSubviews {
	[self layoutWithStatusBarFrame:RSStatusBarFrame()];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[VSTimelineCell adjustLayoutBitsWithSize:size];
	[[VSRowHeightCache sharedCache] empty];
	[VSTimelineCell emptyCaches];
	[self reloadData];
}

#pragma mark - UIScrollViewDelegate


- (void)updateSearchBarContainerFrameWithScrollView:(UIScrollView *)scrollView {
	
	CGFloat currentOffsetY = scrollView.contentOffset.y;
	CGRect r = self.searchBarContainerView.frame;
	
	CGFloat yHidden = CGRectGetMaxY(self.navbar.frame) - self.searchBarContainerViewHeight;
	CGFloat yMax = CGRectGetMinY(self.tableView.frame);
	
	r.origin.y = yHidden + (self.searchBarContainerViewHeight - currentOffsetY);
	if (r.origin.y > yMax)
		r.origin.y = yMax;
	
	[self.searchBarContainerView qs_setFrameIfNotEqual:r];
}


- (void)setSearchBarContainerViewFrame:(BOOL)showing {
	
	CGRect rNavbar = self.navbar.frame;
	
	CGFloat y = CGRectGetMaxY(rNavbar);
	if (!showing)
		y -= self.searchBarContainerViewHeight;
	
	self.searchBarContainerView.frame = CGRectMake(0.0f, y, rNavbar.size.width, self.searchBarContainerViewHeight);
	
}


- (void)animateToShowSearchBar {
	
	self.searchBarShowing = YES;
	
	CGPoint contentOffset = CGPointMake(0.0f, 0.0f);
	if (CGPointEqualToPoint(contentOffset, self.tableView.contentOffset)) {
		[self setSearchBarContainerViewFrame:YES];
		return;
	}
	
	
	[UIView animateWithDuration:0.25f animations:^{
		
		self.tableView.contentOffset = contentOffset;
		[self setSearchBarContainerViewFrame:YES];
	}];
	
}


- (void)animateToHideSearchBar {
	
	self.searchBarShowing = NO;
	
	CGPoint contentOffset = CGPointMake(0.0f, self.searchBarContainerViewHeight);
	if (CGPointEqualToPoint(contentOffset, self.tableView.contentOffset)) {
		[self setSearchBarContainerViewFrame:NO];
		return;
	}
	
	[UIView animateWithDuration:0.25f animations:^{
		
		self.tableView.contentOffset = contentOffset;
		[self setSearchBarContainerViewFrame:NO];
	}];
	
}


- (void)handleScrollViewDrag:(UIScrollView *)scrollView {
	
	CGFloat currentY = scrollView.contentOffset.y;
	
	static CGFloat fudge = 5.0f;
	
	if (self.searchBarShowing) {
		
		if (currentY < self.searchBarContainerDragHideThreshold && currentY > 0.0f)
			[self performSelectorOnMainThread:@selector(animateToShowSearchBar) withObject:nil waitUntilDone:NO];
		
		
		else if (currentY >= self.searchBarContainerDragHideThreshold && currentY < self.searchBarContainerViewHeight + fudge)
			[self performSelectorOnMainThread:@selector(animateToHideSearchBar) withObject:nil waitUntilDone:NO];
		
		return;
	}
	
	else {
		
		if (currentY > self.searchBarContainerDragShowThreshold && currentY < self.searchBarContainerViewHeight + fudge)
			[self performSelectorOnMainThread:@selector(animateToHideSearchBar) withObject:nil waitUntilDone:NO];
		
		else if (currentY <= self.searchBarContainerDragShowThreshold && currentY > 0.0f)
			[self performSelectorOnMainThread:@selector(animateToShowSearchBar) withObject:nil waitUntilDone:NO];
	}
}


#pragma mark Sidebar

- (void)openSidebar:(id)sender {
	if (self.composeViewShowing)
		return;
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
}


- (void)closeSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(closeSidebar:) withObject:sender];
}


#pragma mark Notifications

- (void)thumbnailCached:(NSNotification *)note {
	[self updateCellForAttachmentUniqueID:[note userInfo][QSUniqueIDKey]];
}


- (void)resetContentOffsetToHideSearchBar {
	self.tableView.contentOffset = CGPointMake(0.0f, self.searchBarContainerViewHeight);
	
}


- (void)statusBarFrameDidChange:(NSNotification *)note {
	
	CGPoint currentOffset = self.tableView.contentOffset;
	if (currentOffset.y == self.searchBarContainerViewHeight)
		[self performSelectorOnMainThread:@selector(resetContentOffsetToHideSearchBar) withObject:nil waitUntilDone:NO];
	[self layout];
}


#pragma mark Data

- (void)reloadData {
	
	NSAssert([NSThread isMainThread], @"Should be in main thread");
	
	[self executeBlockPreservingContentOffset:^{
		[self.tableView reloadData];
	}];
}

- (void)executeBlockPreservingContentOffset:(void (^)(void))executionBlock {
	NSParameterAssert(executionBlock);
	CGPoint contentOffset = self.tableView.contentOffset;
	executionBlock();
	self.tableView.contentOffset = contentOffset;
}


#pragma mark Cells

- (void)updateCellForAttachmentUniqueID:(NSString *)attachmentUniqueID {
	
	@autoreleasepool {
		for (NSIndexPath *oneIndexPath in [self.tableView indexPathsForVisibleRows]) {
			
			VSTimelineNote *oneNote = [self timelineNoteAtIndexPath:oneIndexPath];
			if (![attachmentUniqueID isEqualToString:oneNote.thumbnailID])
				continue;
			
			VSTimelineCell *cell = (VSTimelineCell *)[self.tableView cellForRowAtIndexPath:oneIndexPath];
			[self configureCell:cell note:oneNote indexPath:oneIndexPath];
		}
	}
	
}


#pragma mark - Searching

- (void)createSearchResultsViewController {
	
	if (self.context.tag) {
		self.searchResultsViewController = [[VSSearchResultsViewController alloc] initWithContext:self.context includeArchivedNotes:NO archivedNotesOnly:NO timelineViewController:self];
	}
	
	else if (self.context.searchesArchivedNotesOnly) { /*Archived notes screen*/
		self.searchResultsViewController = [[VSSearchResultsViewController alloc] initWithContext:self.context includeArchivedNotes:YES archivedNotesOnly:YES timelineViewController:self];
	}
	
	else { /*All notes screen -- includes archived notes in search results.*/
		self.searchResultsViewController = [[VSSearchResultsViewController alloc] initWithContext:self.context includeArchivedNotes:YES archivedNotesOnly:NO timelineViewController:self];
	}
}


- (void)showSearchResultsTableView {
	
	if (self.searchResultsViewController) {
		[self popViewController:self.searchResultsViewController];
	}
	
	[self createSearchResultsViewController];
	[self pushViewController:self.searchResultsViewController];
	[self.view bringSubviewToFront:self.searchBarContainerView];
	
	CGRect r = self.view.bounds;
	r.origin.y = CGRectGetMaxY(self.searchBarContainerView.frame);
	r.size.height = self.view.bounds.size.height - r.origin.y;
	
	[self.searchResultsViewController.tableView qs_setFrameIfNotEqual:r];
}


- (void)removeSearchResultsViewController {
	
	if (self.searchResultsViewController) {
		[self popViewController:self.searchResultsViewController];
	}
	self.searchResultsViewController = nil;
	[self.view insertSubview:self.searchBarContainerView belowSubview:self.navbar];
}


- (void)stopEditingSearchBar:(id)sender {
	[self.view endEditing:NO];
}


#pragma mark - UISearchBarDelegate

- (void)runSearch:(UISearchBar *)searchBar {
	
	[self showSearchResultsTableView];
	NSString *searchString = searchBar.text;
	if (![searchString isEqualToString:self.searchResultsViewController.searchString]) {
		self.searchResultsViewController.searchString = searchString;
	}
}


static NSTimeInterval kAnimationDuration = 0;
static UIViewAnimationOptions kAnimationOptions = 0;

- (void)keyboardWillShow:(NSNotification *)note {
	
	self.keyboardShowing = YES;
	if (!self.searchFieldActive)
		return;
	
	if (self.inSearchMode)
		return;
	
	self.inSearchMode = YES;
	
	UIViewAnimationCurve animationCurve = [[note userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
	UIViewAnimationOptions animationOptions = [UIView rs_animationOptionsWithAnimationCurve:animationCurve];
	
	NSTimeInterval duration = [[note userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	/*We save these as statics in case we have to animate closing search outside a keyboardWillHide: context.*/
	if (kAnimationDuration == 0)
		kAnimationDuration = duration;
	if (kAnimationOptions == 0)
		kAnimationOptions = animationOptions;
	
	self.searchOverlay.alpha = 0.0f;
	self.searchOverlay.hidden = NO;
	self.searchBarContainerView.shadowImageView.alpha = 0.0f;
	self.searchBarContainerView.hasShadow = YES;
	self.searchBarContainerView.inSearchMode = YES;
	
	[UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
		self.searchOverlay.alpha = [app_delegate.theme floatForKey:@"searchOverlayAlpha"];
		
	} completion:NULL];
	
	[UIView animateWithDuration:duration delay:0.0f options:animationOptions animations:^{
		
		[self.searchBar setShowsCancelButton:YES animated:YES];
		self.searchBarContainerView.shadowImageView.alpha = 1.0f;
		[self setFramesToSearchMode];
		
	} completion:NULL];
	
}


- (void)keyboardWillHide:(NSNotification *)note {
	
	self.keyboardShowing = NO;
	
	if (!self.searchFieldActive)
		return;
	//    [self.searchBarContainerView enableCancelButton];
	[self.searchBarContainerView setNeedsDisplay];
	self.searchFieldActive = NO;
	
	if (self.inSearchMode) { /*Still searching -- interacting with search results.*/
		[self.searchBarContainerView performSelectorOnMainThread:@selector(enableCancelButton) withObject:nil waitUntilDone:NO];
		//        [self.searchBarContainerView performSelector:@selector(enableCancelButton) withObject:nil afterDelay:0.1f];
		return;
	}
	
	UIViewAnimationCurve animationCurve = [[note userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
	UIViewAnimationOptions animationOptions = [UIView rs_animationOptionsWithAnimationCurve:animationCurve];
	
	NSTimeInterval duration = [[note userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	/*We save these as statics in case we have to animate closing search outside a keyboardWillHide: context.*/
	if (kAnimationDuration == 0)
		kAnimationDuration = duration;
	if (kAnimationOptions == 0)
		kAnimationOptions = animationOptions;
	
	[self animateClosingSearch:duration animationOptions:animationOptions];
}


- (void)animateClosingSearch:(NSTimeInterval)duration animationOptions:(UIViewAnimationOptions)animationOptions {
	
	self.searchBar.text = nil;
	[self removeSearchResultsViewController];
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:duration delay:0.0f options:animationOptions animations:^{
		
		[self.searchBar setShowsCancelButton:NO animated:YES];
		self.searchBarContainerView.shadowImageView.alpha = 0.0f;
		[self setFramesToNormalMode];
		self.searchOverlay.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		
		self.searchOverlay.hidden = YES;
		self.searchBarContainerView.hasShadow = NO;
		self.searchBarContainerView.inSearchMode = YES;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}


- (void)endSearchMode {
	
	self.inSearchMode = NO;
	
	if (!self.keyboardShowing) {
		[self animateClosingSearch:kAnimationDuration animationOptions:kAnimationOptions];
		return;
	}
	
	[self.view endEditing:NO];
}


- (void)searchOverlayTapped:(id)sender {
	[self endSearchMode];
}


#pragma mark - VSTableViewDragControllerDelegate

- (UIImage *)dragImageForNote:(VSNote *)note {
	
	NSIndexPath *indexPath = [self indexPathOfTimelineNoteWithUniqueID:note.uniqueID];
	if (indexPath == nil) {
		return nil;
	}
	
	VSTimelineNote *draggedNote = self.draggedNote;
	self.draggedNote = nil;
	
	[self reloadData];
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	cell.highlighted = NO;
	UIImage *image = [(VSTimelineCell *)cell imageForDetailPanBackAnimation];
	
	self.draggedNote = draggedNote;
	
	return image;
}


#pragma mark - Child View Controllers


- (void)popViewController:(UIViewController *)viewController {
	[self removeViewControllerAndItsView:viewController];
	if (viewController == self.detailViewController)
		self.detailViewController = nil;
}

#pragma mark - Animation - Timeline to Detail

- (UIView *)tableAnimationView:(BOOL)clearBackground {
	
	BOOL originalOpaque = self.tableView.isOpaque;
	UIColor *originalBackgroundColor = self.tableView.backgroundColor;
	
	if (clearBackground) {
		self.tableView.opaque = NO;
		self.tableView.backgroundColor = [UIColor clearColor];
	}
	
	UIView *tableAnimationView = [self.tableView snapshotViewAfterScreenUpdates:YES];
	
	//	UIGraphicsBeginImageContextWithOptions(self.tableView.bounds.size, NO, [UIScreen mainScreen].scale);
	//	CGContextRef context = UIGraphicsGetCurrentContext();
	//	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	//	CGContextTranslateCTM(context, 0, -(self.tableView.contentOffset.y));
	//	[self.tableView.layer renderInContext:context];
	//	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	//	UIGraphicsEndImageContext();
	
	self.tableView.opaque = originalOpaque;
	self.tableView.backgroundColor = originalBackgroundColor;
	
	//	UIImageView *tableAnimationView = [[UIImageView alloc] initWithImage:image];
	tableAnimationView.clipsToBounds = YES;
	tableAnimationView.contentMode = UIViewContentModeBottom;
	tableAnimationView.autoresizingMask = UIViewAutoresizingNone;
	
	return tableAnimationView;
}




- (void)cleanupAfterAnimateTableAway {
	//	[self reloadData];
}


#pragma mark - Animation - Search Results to Detail

- (VSDetailViewController *)searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController showComposeViewWithNote:(VSNote *)note timelineNote:(VSTimelineNote *)timelineNote indexPath:(NSIndexPath *)indexPath {
	
	VSCloseSidebar();
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
	[VSTimelineCell emptyCaches];
	self.detailViewController = [[VSDetailViewController alloc] initWithNote:note tag:nil backButtonTitle:NSLocalizedString(@"Search", @"Search")];
	self.detailViewController.parentTimelineViewController = self;
	self.detailViewController.parentSearchResultsViewController = searchResultsViewController;
	
	[self postFocusedViewControllerDidChangeNotification:self.detailViewController];
	
	self.detailAnimationImage = nil;
	self.composeViewShowing = YES;
	
	(void)self.detailViewController.view;
	[self.detailViewController.navbar layoutSubviews];
	
	if (!note.hasThumbnail) {
		
		[self pushViewController:self.detailViewController];
		
		__block VSSearchResultsToDetailAnimator *animator = [[VSSearchResultsToDetailAnimator alloc] initWithNote:note timelineNote:timelineNote indexPath:indexPath image:nil searchResultsViewController:searchResultsViewController timelineViewController:self detailViewController:self.detailViewController];
		[animator animate:^{
			animator = nil;
		}];
		
	}
	
	else {
		
		[[VSAttachmentStorage sharedStorage] fetchBestImageAttachment:note.thumbnailID callback:^(UIImage *image) {
			
			[self.detailViewController setInitialFullSizeImage:image];
			[self pushViewController:self.detailViewController];
			self.detailAnimationImage = image;
			
			__block VSSearchResultsToDetailAnimator *animator = [[VSSearchResultsToDetailAnimator alloc] initWithNote:note timelineNote:timelineNote indexPath:indexPath image:image searchResultsViewController:searchResultsViewController timelineViewController:self detailViewController:self.detailViewController];
			[animator animate:^{
				animator = nil;
			}];
		}];
	}
	
	return self.detailViewController;
}


#pragma mark - Animation - Detail to Search Results

- (void)prepareForAnimation {
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[self incrementSmokeScreenViewUseCount];
}


- (void)finishAnimation {
	[self decrementSmokeScreenViewUseCount];
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}



- (void)searchResultsViewController:(VSSearchResultsViewController *)searchResultsViewController popDetailViewController:(VSDetailViewController *)detailViewController indexPath:(NSIndexPath *)indexPath note:(VSNote *)note animated:(BOOL)animated {
	
	[VSTimelineCell emptyCaches];
	searchResultsViewController.draggedNote = nil;
	[searchResultsViewController.tableView reloadData];
	[searchResultsViewController.tableView setNeedsLayout];
	[searchResultsViewController.tableView layoutIfNeeded];
	
	if (animated) {
		
		VSTimelineNote *timelineNote = [[VSDataController sharedController] timelineNoteWithUniqueID:note.uniqueID];
		
		__block VSDetailToSearchResultsAnimator *animator = [[VSDetailToSearchResultsAnimator alloc] initWithNote:note timelineNote:timelineNote indexPath:indexPath timelineViewController:self searchResultsViewController:searchResultsViewController detailViewController:detailViewController];
		[animator animate:^{
			animator = nil;
		}];
		
	}
	
	[self popViewController:detailViewController];
	
	self.detailViewController = nil;
	self.composeViewShowing = NO;
	
	[self postFocusedViewControllerDidChangeNotification:searchResultsViewController];
}


#pragma mark - Detail View Pan-Back Animation

- (void)prepareForPanBackAnimationWithNote:(VSNote *)note {
	
	VSTimelineNote *timelineNote = [self timelineNoteWithUniqueID:note.uniqueID];
	
	self.draggedNote = timelineNote;
	[self reloadData];
}


- (CGRect)frameOfCellForNote:(VSNote *)note {
	
	VSTimelineNote *timelineNote = [self timelineNoteWithUniqueID:note.uniqueID];
	NSIndexPath *indexPath = [self indexPathOfTimelineNote:timelineNote];
	if (indexPath == nil) {
		return CGRectZero;
	}
	
	return  [self.tableView rectForRowAtIndexPath:indexPath];
}


#pragma mark - Push/Pop Detail View Controller

- (BOOL)hasDetailViewController {
	
	for (UIViewController *oneViewController in self.childViewControllers) {
		if ([oneViewController isKindOfClass:[VSDetailViewController class]])
			return YES;
	}
	
	return NO;
}


- (void)beginEditingDetailView:(VSDetailViewController *)detailViewController {
	[detailViewController.textView becomeFirstResponder];
}


- (void)animateAndBeginEditingDetailViewController:(VSDetailViewController *)detailViewController note:(VSNote *)note fullSizeImage:(UIImage *)fullSizeImage {
	
	[detailViewController setInitialFullSizeImage:fullSizeImage];
	
	[self pushViewController:detailViewController];
	
	__block VSTimelineToDetailAnimator *animator = [[VSTimelineToDetailAnimator alloc] initWithNote:note indexPath:self.selectedRowIndexPath detailAnimationImage:fullSizeImage timelineViewController:self detailViewController:detailViewController];
	[animator animate:^(void) {
		animator = nil;
	}];
	
	if (self.selectedRowIndexPath == nil) { /*new note*/
		[self beginEditingDetailView:detailViewController];
	}
}


- (void)pushDetailViewController:(VSDetailViewController *)detailViewController {
	
	VSCloseSidebar();
	if ([self hasDetailViewController]) {
		return;
	}
	
	self.detailAnimationImage = nil;
	self.composeViewShowing = YES;
	
	self.detailViewController = detailViewController;
	(void)self.detailViewController.view;
	[self.detailViewController.navbar layoutSubviews];
	
	self.selectedRowIndexPath = [self.tableView indexPathForSelectedRow];
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:self.selectedRowIndexPath];
	VSNote *note = [[VSDataController sharedController] noteWithUniqueID:timelineNote.uniqueID];
	
	if (!note.hasThumbnail) {
		
		[self animateAndBeginEditingDetailViewController:detailViewController note:note fullSizeImage:nil];
		return;
	}
	
	[[VSAttachmentStorage sharedStorage] fetchBestImageAttachment:note.thumbnailID callback:^(UIImage *image) {
		
		[self animateAndBeginEditingDetailViewController:detailViewController note:note fullSizeImage:image];
	}];
}


- (void)popDetailViewController:(VSDetailViewController *)detailViewController animated:(BOOL)animated {
	
	self.draggedNote = nil;
	[self reloadData];
	[self.tableView setNeedsLayout];
	[self.tableView layoutIfNeeded];
	
	//	if (animated) {
	//		[self addSmokescreenViewOfClass:[VSDetailTransitionView class]];
	//		[self.smokescreenView setNeedsDisplay];
	//	}
	
	VSNote *note = [detailViewController.note copy];
	NSIndexPath *indexPathOfTimelineNote = [self indexPathOfTimelineNoteWithUniqueID:note.uniqueID];
	
	//    if (![self shouldIncludeNote:note]) { /*TODO*/
	//        NSMutableArray *notesCopy = [self.notes mutableCopy];
	//        [notesCopy removeObject:note];
	//        self.notes = notesCopy;
	//        indexPathOfNote = nil;
	//    }
	
	if (animated) {
		
		__block VSDetailToTimelineAnimator *animator = [[VSDetailToTimelineAnimator alloc] initWithNote:note indexPath:indexPathOfTimelineNote timelineViewController:self detailViewController:detailViewController];
		[animator animate:^{
			animator = nil;
		}];
	}
	
	[self popViewController:detailViewController];
	self.detailViewController = nil;
	self.composeViewShowing = NO;
}


#pragma mark - VSTableViewDragControllerDelegate Utilities

- (void)updateDateForDraggedNote:(NSIndexPath *)indexPath {
	
	if (indexPath == nil)
		return;
	
	NSInteger row = indexPath.row;
	NSDate *dateNow = [[VSDateManager sharedManager] currentDate];
	NSDate *updatedSortDate = dateNow;
	
	if (row > 0) {
		
		NSIndexPath *indexPathForPreviousNote = [NSIndexPath indexPathForRow:row - 1  inSection:indexPath.section];
		VSTimelineNote *previousNote = [self timelineNoteAtIndexPath:indexPathForPreviousNote];
		//        NSLog(@"previousNote: %f %@", [previousNote.sortDate timeIntervalSince1970], previousNote.title);
		NSDate *previousSortDate = previousNote.sortDate;
		updatedSortDate = [previousSortDate dateByAddingTimeInterval:-1.0f];
		
		NSIndexPath *indexPathForNextNote = [NSIndexPath indexPathForRow:row + 1 inSection:indexPath.section];
		VSTimelineNote *nextNote = [self timelineNoteAtIndexPath:indexPathForNextNote];
		//    NSLog(@"nextNote: %f %@", [nextNote.sortDate timeIntervalSince1970], nextNote.title);
		if (nextNote != nil) {
			NSDate *nextSortDate = nextNote.sortDate;
			if ([nextSortDate isEqualToDate:updatedSortDate] || [nextSortDate compare:updatedSortDate] == NSOrderedDescending) {
				NSTimeInterval interval = [previousSortDate timeIntervalSince1970] - [nextSortDate timeIntervalSince1970];
				interval = interval / 2.0;
				updatedSortDate = [nextSortDate dateByAddingTimeInterval:interval];
				//                NSLog(@"fitted sort date: %f", [updatedSortDate timeIntervalSince1970]);
			}
		}
	}
	
	//    NSLog(@"updatedSortDate: %f %@", [updatedSortDate timeIntervalSince1970], self.draggedNote.title);
	
	self.draggedNote.sortDate = updatedSortDate;
	[[VSDataController sharedController] updateSortDate:updatedSortDate uniqueID:self.draggedNote.uniqueID];
}


#pragma mark - VSTableViewDragControllerDelegate

- (UIImage *)dragController:(VSTableViewDragController *)dragController dragImageForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	cell.highlighted = NO;
	
	UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, [UIScreen mainScreen].scale);
	
	[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return image;
}


- (BOOL)dragController:(VSTableViewDragController *)dragController dragShouldBeginForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (self.isPanning || self.isDraggingRow)
		return NO;
	
	return YES;
}


- (void)dragController:(VSTableViewDragController *)dragController dragDidBeginForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	self.inManualTableUpdate = YES;
	//	NSLog(@"dragDidBeginForRowAtIndexPath %ld", (long)indexPath.row);
	
	VSTimelineNote *note = [self timelineNoteAtIndexPath:indexPath];
	self.draggedNote = note;
	
	if (indexPath == nil || self.draggedNote == nil) {
		self.inManualTableUpdate = NO;
		return;
	}
	
	[self.tableView reloadData];
}


- (void)dragController:(VSTableViewDragController *)dragController dragDidHoverOverRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// 	NSLog(@"dragDidHoverOverRowAtIndexPath %ld", (long)indexPath.row);
	
	NSInteger newRow = indexPath.row;
	NSIndexPath *indexPathForDraggedNote = [self indexPathOfTimelineNote:self.draggedNote];
	NSInteger oldRow = indexPathForDraggedNote.row;
	
	if (newRow == oldRow) {
		return;
	}
	
	[self.context.timelineNotesController removeNoteAtIndex:(NSUInteger)oldRow];
	[self.context.timelineNotesController insertNote:self.draggedNote atIndex:(NSUInteger)newRow];
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForDraggedNote] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
	
	NSString *announcement = nil;
	NSInteger row = indexPath.row;
	NSInteger section = indexPath.section;
	NSInteger count = [self tableView:self.tableView numberOfRowsInSection:indexPath.section];
	if (row == 0 && count > 1) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row+1 inSection:section]];
		if (cell.accessibilityLabel)
			announcement = [NSString stringWithFormat:NSLocalizedString(@"Moved above %@", nil), cell.accessibilityLabel];
	} else if (row < count) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row-1 inSection:section]];
		if (cell.accessibilityLabel)
			announcement = [NSString stringWithFormat:NSLocalizedString(@"Moved below %@", nil), cell.accessibilityLabel];
	}
	if (announcement) {
		UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
	}
}


- (void)dragController:(VSTableViewDragController *)dragController dragDidCompleteAtIndexPath:(NSIndexPath *)indexPath {
	
	//	NSLog(@"dragDidCompleteAtIndexPath %ld", (long)indexPath.row);
	
	[self updateDateForDraggedNote:indexPath];
	
	//    if (indexPath != nil)
	//        [self.dataController saveNotes:@[self.draggedNote]];
	
	self.draggedNote = nil;
	[self reloadData];
	
	// Send the VO cursor to the newly placed cell
	id cell = [self.tableView cellForRowAtIndexPath:indexPath];
	if (cell) {
		UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, cell);
	}
	
	self.inManualTableUpdate = NO;
}


- (void)draggingDidCancel:(VSTableViewDragController *)dragController {
	//	NSLog(@"draggingDidCancel");
	self.draggedNote = nil;
	[self reloadData];
	self.inManualTableUpdate = NO;
}


- (void)dragControllerDidScroll:(VSTableViewDragController *)dragController {
	[self scrollViewDidScroll:self.tableView];
}


#pragma mark - UISearchBarDelegate Utilities

static BOOL characterStringIsDigit(NSString *s) {
	return [s isEqualToString:@"0"] || [s isEqualToString:@"1"] || [s isEqualToString:@"2"] || [s isEqualToString:@"3"] || [s isEqualToString:@"4"] || [s isEqualToString:@"5"] || [s isEqualToString:@"6"] || [s isEqualToString:@"7"] || [s isEqualToString:@"8"] || [s isEqualToString:@"9"];
}


static BOOL stringContainsAnyDigit(NSString *s) {
	
	for (NSUInteger i = 0; i < [s length]; i++) {
		
		NSString *oneCharacterString = [s substringWithRange:NSMakeRange(i, 1)];
		if (characterStringIsDigit(oneCharacterString)) {
			return YES;
		}
	}
	
	return NO;
}


- (BOOL)stringIsSearchWorthy:(NSString *)s {
	
	if (QSStringIsEmpty(s)) {
		return NO;
	}
	
	if ([s length] >= 2 || stringContainsAnyDigit(s)) {
		return YES;
	}
	
	if ([s characterAtIndex:0] > 0x2e80) {
		return YES;
	}
	
	return NO;
}



#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
	self.searchFieldActive = YES;
	return YES;
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	
	if (![self stringIsSearchWorthy:searchText]) {
		self.tableView.alpha = 1.0f;
		self.searchResultsViewController.searchString = nil;
		[self removeSearchResultsViewController];
		return;
	}
	
	self.tableView.alpha = 0.0f;
	[self runSearch:searchBar];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	
	self.tableView.alpha = 1.0f;
	self.searchBar.text = nil;
	self.inSearchMode = NO;
	
	if (!self.keyboardShowing) {
		[self animateClosingSearch:kAnimationDuration animationOptions:kAnimationOptions];
		return;
	}
	
	[self.view endEditing:NO];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self stopEditingSearchBar:searchBar];
}


#pragma mark - VSTimelineCellDelegate

- (BOOL)timelineCellIsPanning:(VSTimelineCell *)timelineCell {
	return (timelineCell == self.panningCell);
}


- (void)timelineCellWillBeginPanning:(VSTimelineCell *)timelineCell {
	
	self.panningCell = timelineCell;
}


- (void)timelineCellDidCancelOrEndPanning:(VSTimelineCell *)timelineCell {
	
	if (timelineCell == self.panningCell) {
		self.panningCell = nil;
	}
}


- (BOOL)timelineCellShouldBeginPanning:(VSTimelineCell *)timelineCell {
	
	if (self.isPanning || self.isDraggingRow || self.hasSelectedRow) {
		return NO;
	}
	
	return YES;
}


- (void)timelineCellDidBeginPanning:(VSTimelineCell *)timelineCell {
	
	;
}


- (void)timelineCellDidDelete:(VSTimelineCell *)timelineCell {
	
	self.inManualTableUpdate = YES;
	VSTimelineNote *note = [self timelineNoteForSender:timelineCell];
	if (note) {
		[self deleteTimelineNote:note];
	}
	self.inManualTableUpdate = NO;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	[self updateSearchBarContainerFrameWithScrollView:scrollView];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	
	CGPoint currentOffset = scrollView.contentOffset;
	
	if (currentOffset.y < self.searchBarContainerViewHeight)
		self.searchBarShowing = YES;
	else
		self.searchBarShowing = NO;
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
	if (!decelerate) {
		[self handleScrollViewDrag:scrollView];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	[self handleScrollViewDrag:scrollView];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (self.sidebarShowing)
		return NO;
	if (self.isPanning || self.isDraggingRow)
		return NO;
	
	return YES;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	VSTimelineNote *note = [self timelineNoteAtIndexPath:indexPath];
	CGFloat height = [[VSRowHeightCache sharedCache] cachedHeightForTimelineNote:note];
	if (height < 1.0f) {
		height = 47.0f;
		if (note.hasThumbnail) {
			height = 68.0f;
		}
	}
	
	return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	CGFloat height = [[VSRowHeightCache sharedCache] cachedHeightForTimelineNote:timelineNote];
	
	if (height < 1.0) {
		height = [VSTimelineCell heightWithTitle:timelineNote.title text:timelineNote.remainingText links:timelineNote.links useItalicFonts:timelineNote.archived hasThumbnail:timelineNote.hasThumbnail truncateIfNeeded:YES];
		[[VSRowHeightCache sharedCache] cacheHeight:height forTimelineNote:timelineNote];
	}
	
	return height;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (!self.sidebarShowing)
		return indexPath;
	
	return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (![self.view endEditing:NO]) {
		return;
	}
	
	if (self.sidebarShowing) {
		[self closeSidebar:self];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSTimelineCellShouldCancelPanNotification object:nil];
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	VSNote *note = [[VSDataController sharedController] noteWithUniqueID:timelineNote.uniqueID];
	[self showComposeViewWithNote:note tag:self.context.tag];
}


#pragma mark - VSTimelineNotesControllerDelegate

- (void)controllerDidPerformFetch:(VSTimelineNotesController *)controller updatedNotes:(NSArray *)updatedNotes {
	
	[self reloadData];
}


- (void)controllerWillChangeContent:(VSTimelineNotesController *)controller {
	
	if ([self qs_hasChildViewController]) {
		return;
	}
	if (self.inManualTableUpdate) {
		return;
	}
	
	[self.tableView beginUpdates];
}


- (void)controllerDidChangeContent:(VSTimelineNotesController *)controller {
	
	[self updateNoNotesImageView];
	
	if (self.inManualTableUpdate) {
		return;
	}
	if ([self qs_hasChildViewController]) {
		[self reloadData];
		return;
	}
	
	
	[self.tableView endUpdates];
}


- (void)controller:(VSTimelineNotesController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(VSTimelineNotesChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	if ([self qs_hasChildViewController]) {
		return;
	}
	if (self.inManualTableUpdate) {
		return;
	}
	
	switch (type) {
			
		case VSTimelineNotesChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case VSTimelineNotesChangeDelete:
			if (indexPath.row >= (NSInteger)self.context.timelineNotesController.numberOfNotes) {
				break;
			}
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case VSTimelineNotesChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case VSTimelineNotesChangeMove:
			[self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
			break;
			
		default:
			break;
	}
}


#pragma mark - UITableViewDataSource Utilities

- (void)fetchNotes {
	
	[self.context.timelineNotesController performFetch];
}


- (VSTimelineNote *)timelineNoteAtIndexPath:(NSIndexPath *)indexPath {
	
	return [self.context.timelineNotesController timelineNoteAtIndexPath:indexPath];
}


- (NSIndexPath *)indexPathOfTimelineNote:(VSTimelineNote *)timelineNote {
	
	return [self.context.timelineNotesController indexPathOfTimelineNote:timelineNote];
}


- (NSIndexPath *)indexPathOfTimelineNoteWithUniqueID:(int64_t)uniqueID {
	
	return [self.context.timelineNotesController indexPathOfTimelineNoteWithUniqueID:uniqueID];
}


- (VSTimelineNote *)timelineNoteWithUniqueID:(int64_t)uniqueID {
	
	return [self.context.timelineNotesController timelineNoteWithUniqueID:uniqueID];
}


- (void)configureCell:(VSTimelineCell *)cell note:(VSTimelineNote *)note indexPath:(NSIndexPath *)indexPath {
	
	@autoreleasepool {
		
		cell.delegate = self;
		
		if (note.archived) {
			cell.archiveControlStyle = VSArchiveControlStyleRestoreDelete;
			cell.archiveActionText = NSLocalizedString(@"Restore", @"Restore");
			cell.archiveIndicatorUseItalicFont = NO;
		}
		else {
			cell.archiveControlStyle = VSArchiveControlStyleArchive;
			cell.archiveActionText = NSLocalizedString(@"Archive", @"Archive");
			cell.archiveIndicatorUseItalicFont = YES;
		}
		
		[cell configureWithTitle:note.title text:note.remainingText links:note.links useItalicFonts:note.archived hasThumbnail:note.hasThumbnail truncateIfNeeded:YES];
		
		UIImage *thumbnail = note.thumbnail;
		if (thumbnail != cell.thumbnail) {
			cell.thumbnail = thumbnail;
		}
		
		[cell setNeedsDisplay];
	}
}


- (void)configureCell:(VSTimelineCell *)cell indexPath:(NSIndexPath *)indexPath {
	
	VSTimelineNote *note = [self timelineNoteAtIndexPath:indexPath];
	[self configureCell:cell note:note indexPath:indexPath];
}


- (UITableViewCell *)blankCellForDraggedNote:(VSTimelineNote *)note {
	
	static NSString *reuseIdentifier = @"blankCell";
	
	VSTimelineCell *cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
		cell = [[VSTimelineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	
	return cell;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.context.timelineNotesController.numberOfNotes;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (self.noNotesView && !self.noNotesView.hidden) {
		self.noNotesView.hidden = YES;
	}
	if (self.migratingData) {
		self.migratingData = NO;
	}
	
	VSTimelineNote *timelineNote = [self timelineNoteAtIndexPath:indexPath];
	if (timelineNote == self.draggedNote) {
		return [self blankCellForDraggedNote:timelineNote];
	}
	
	static NSString *reuseIdentifier = @"VSTimelineCell";
	VSTimelineCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil) {
		cell = [[VSTimelineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	}
	
	[self configureCell:cell note:timelineNote indexPath:indexPath];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	;
}


#pragma mark - Actions

- (void)showComposeView:(id)sender {
	
	if (self.isDraggingRow) {
		return;
	}
	
	[self showComposeViewWithNote:nil tag:self.context.tag];
}


- (BOOL)showingComposeView {
	
	for (UIViewController *oneViewController in self.childViewControllers) {
		if ([oneViewController isKindOfClass:[VSDetailViewController class]])
			return YES;
	}
	
	return NO;
}


- (void)showComposeViewWithNote:(VSNote *)note tag:(VSTag *)tag {
	
	if (self.sidebarShowing || [self showingComposeView] || self.isDraggingRow)
		return;
	
	[VSTimelineCell emptyCaches];
	self.detailViewController = [[VSDetailViewController alloc] initWithNote:note tag:tag backButtonTitle:self.title];
	self.detailViewController.parentNavbarView = self.navbar;
	self.detailViewController.parentTimelineViewController = self;
	
	[self pushDetailViewController:self.detailViewController];
	
	[self postFocusedViewControllerDidChangeNotification:self.detailViewController];
	
}


- (void)showComposeViewWithNote:(VSNote *)note {
	[self showComposeViewWithNote:note tag:nil];
}


- (void)detailViewDone:(id)sender {
	
	if (self.searchResultsViewController != nil) {
		[self.searchResultsViewController detailViewDone:sender];
		return;
	}
	
	
	[VSTimelineCell emptyCaches];
	[self reloadData];
	[self popDetailViewController:self.detailViewController animated:YES];
	
	//    CGFloat animationDuration = [app_delegate.theme floatForKey:@"detailCloseAnimationDuration"];
	//    [self popViewController:self.detailViewController animated:YES duration:animationDuration completion:^(BOOL finished) {
	//        self.detailViewController = nil;
	//    }];
	[self postFocusedViewControllerDidChangeNotification:self];
}


- (void)detailViewDoneViaPanBackAnimation:(id)sender {
	
	if (self.searchResultsViewController != nil) {
		[self.searchResultsViewController detailViewDoneViaPanBackAnimation:sender];
		return;
	}
	
	[VSTimelineCell emptyCaches];
	[self popDetailViewController:self.detailViewController animated:NO];
	
	[self postFocusedViewControllerDidChangeNotification:self];
}


- (VSTimelineNote *)timelineNoteForSender:(id)sender {
	
	if ([sender isKindOfClass:[VSTimelineNote class]]) {
		return (VSTimelineNote *)sender;
	}
	
	else if ([sender isKindOfClass:[VSNote class]]) {
		return [VSTimelineNote timelineNoteWithNote:(VSNote *)sender];
	}
	
	if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
		sender = ((UIGestureRecognizer *)sender).view;
	}
	if (![sender isKindOfClass:[UIView class]]) {
		return nil;
	}
	
	for (NSIndexPath *oneIndexPath in [self.tableView indexPathsForVisibleRows]) {
		
		UITableViewCell *oneTableViewCell = [self.tableView cellForRowAtIndexPath:oneIndexPath];
		if (oneTableViewCell == nil) {
			continue;
		}
		if ([(UIView *)sender isDescendantOfView:oneTableViewCell]) {
			return [self timelineNoteAtIndexPath:oneIndexPath];
		}
	}
	
	return nil;
}


- (void)textLabelTapped:(id)sender {
	
	if (self.sidebarShowing) {
		[self closeSidebar:sender];
		return;
	}
	
	[self.view endEditing:NO];
	
	VSTimelineNote *timelineNote = [self timelineNoteForSender:sender];
	if (!timelineNote) {
		return;
	}
	
	NSIndexPath *indexPath = [self indexPathOfTimelineNote:timelineNote];
	if (!indexPath) {
		return;
	}
	
	[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
	
	for (UITableViewCell *oneCell in self.tableView.visibleCells) {
		if ([indexPath isEqual:[self.tableView indexPathForCell:oneCell]])
			[oneCell setSelected:YES animated:NO];
	}
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	dispatch_async(dispatch_get_main_queue(), ^{
		
		/*This dispatch_async is so that the cell has a chance to show the pressed state before animations run.*/
		
		[self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	});
	
}


- (void)markTimelineNote:(VSTimelineNote *)timelineNote asArchived:(BOOL)archived {
	
	self.inManualTableUpdate = YES;
	
	NSUInteger indexOfNote = [self.context.timelineNotesController indexOfTimelineNote:timelineNote];
	timelineNote.archived = archived;
	[[VSDataController sharedController] updateArchived:archived uniqueID:timelineNote.uniqueID];
	
	if (indexOfNote == NSNotFound) {
		self.inManualTableUpdate = NO;
		return;
	}
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:0];
	
	[self executeBlockPreservingContentOffset:^{
		if ([self qs_hasChildViewController]) {
			[self reloadData];
		}
		else {
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
		}
	}];
	
	if (archived)
		UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Did archive note", nil));
	else
		UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Did restore note", nil));
	
	self.inManualTableUpdate = NO;
	
	[VSNote sendUserDidEditNoteNotification];
	[self updateNoNotesImageView];
}


- (void)markTimelineNoteAsArchived:(VSTimelineNote *)timelineNote {
	[self markTimelineNote:timelineNote asArchived:YES];
}


- (void)markTimelineNoteAsRestored:(VSTimelineNote *)timelineNote {
	[self markTimelineNote:timelineNote asArchived:NO];
}


- (void)archiveTimelineNote:(id)sender {
	
	VSTimelineNote *timelineNote = [self timelineNoteForSender:sender];
	if (timelineNote) {
		[self markTimelineNote:timelineNote asArchived:YES];
	}
}


- (void)restoreTimelineNote:(id)sender {
	
	VSTimelineNote *note = [self timelineNoteForSender:sender];
	if (note == nil)
		return;
	[self markTimelineNote:note asArchived:NO];
}


- (void)archiveOrRestoreNote:(id)sender {
	
	VSTimelineNote *timelineNote = [self timelineNoteForSender:sender];
	if (timelineNote.archived)
		[self restoreTimelineNote:sender];
	else
		[self archiveTimelineNote:sender];
}


- (void)deleteTimelineNote:(VSTimelineNote *)timelineNote {
	
	if (!timelineNote) {
		return;
	}
	
	NSUInteger indexOfNote = [self.context.timelineNotesController indexOfTimelineNote:timelineNote];
	if (indexOfNote != NSNotFound) {
		[self.context.timelineNotesController removeNoteAtIndex:indexOfNote];
	}
	
	if (indexOfNote == NSNotFound) {
		return;
	}
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)indexOfNote inSection:0];
	
	[self executeBlockPreservingContentOffset:^{
		if ([self qs_hasChildViewController]) {
			[self reloadData];
		}
		else {
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
		}
		
	}];
	
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Did delete note", nil));
	
	[[VSDataController sharedController] deleteNotes:@[@(timelineNote.uniqueID)] userDidDelete:YES];
	
	[VSNote sendUserDidEditNoteNotification];
	[self updateNoNotesImageView];
}


- (void)toggleSidebar:(id)sender {
	
	if ([self qs_hasChildViewController]) {
		return;
	}
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(toggleSidebar:) withObject:sender];
}


@end
