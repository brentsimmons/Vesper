//
//  VSExportViewController.m
//  Vesper
//
//  Created by Brent Simmons on 7/1/16.
//  Copyright © 2016 Q Branch LLC. All rights reserved.
//

@import MobileCoreServices;
#import "VSExportViewController.h"
#import "VSSyncUI.h"
#import "VSNavbarView.h"
#import "VSUI.h"
#import "VSBaseViewController.h"
#import "VSExportHeaderView.h"
#import "VSExporter.h"


@interface VSExportViewController () <UIGestureRecognizerDelegate, UIDocumentPickerDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) VSExportHeaderView *headerView;
@property (nonatomic) VSNavbarView *navbar;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerToCloseSidebar;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, assign) BOOL sidebarShowing;
@property (nonatomic) UIStatusBarStyle savedStatusBarStyle;
@property (nonatomic) VSExporter *exporter;
@property (nonatomic) BOOL exportDidSucceed;

@end

static void *VSSidebarShowingContext = &VSSidebarShowingContext;

@implementation VSExportViewController

#pragma mark - Init

- (instancetype)init {

	self = [self initWithNibName:nil bundle:nil];
	if (!self) {
		return nil;
	}

	self.title = NSLocalizedString(@"Export", @"Export");

	[(id)app_delegate addObserver:self forKeyPath:VSSidebarShowingKey options:0 context:VSSidebarShowingContext];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exportDidComplete:) name:VSExportDidCompleteNotification object:nil];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {

	[(id)app_delegate removeObserver:self forKeyPath:VSSidebarShowingKey context:VSSidebarShowingContext];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_panGestureRecognizer.delegate = nil;
	_panGestureRecognizerToCloseSidebar.delegate = nil;
	_tapGestureRecognizer.delegate = nil;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (context == VSSidebarShowingContext) {
		self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	}
}


#pragma mark - UIViewController

- (void)loadView {

	self.view = [VSSyncUI view];
	self.tableView = [VSSyncUI tableViewForViewController:self];
	self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	[self.view addSubview:self.tableView];

	self.headerView = [[VSExportHeaderView alloc] initWithFrame:CGRectZero];
	CGRect rHeader = CGRectZero;
	rHeader.size.width = CGRectGetWidth([UIScreen mainScreen].bounds);
	CGSize bestSize = [self.headerView sizeThatFits:CGSizeMake(CGRectGetWidth(rHeader), CGFLOAT_MAX)];
	rHeader.size.height = bestSize.height;
	self.headerView.frame = rHeader;
	self.tableView.tableHeaderView = self.headerView;

	self.navbar = [VSNavbarView new];
	self.navbar.showComposeButton = NO;
	self.navbar.frame = RSNavbarRect();
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
	self.navbar.title = NSLocalizedString(@"Export", @"Export");
	[self.view addSubview:self.navbar];

	self.panGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	((UIScreenEdgePanGestureRecognizer *)self.panGestureRecognizer).edges = UIRectEdgeLeft;
	self.panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizer];

	self.panGestureRecognizerToCloseSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	self.panGestureRecognizerToCloseSidebar.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizerToCloseSidebar];

	self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSidebar:)];
	[self.view addGestureRecognizer:self.tapGestureRecognizer];
	self.tapGestureRecognizer.delegate = self;
}

- (void)viewDidLayoutSubviews {

	CGRect rNavbar = RSNavbarRect();
	[self.navbar qs_setFrameIfNotEqual:rNavbar];

	CGRect rTable = CGRectZero;
	rTable.origin = CGPointZero;
	rTable.origin.y = CGRectGetMaxY(rNavbar);
	rTable.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(rNavbar);
	rTable.size.width = CGRectGetWidth(self.view.bounds);
	[self.tableView qs_setFrameIfNotEqual:rTable];
}


#pragma mark - Panning

- (void)openSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
	self.sidebarShowing = YES;
}


- (void)postFocusedViewControllerDidChangeNotification:(UIViewController *)focusedViewController {

	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (focusedViewController != nil)
		userInfo[VSFocusedViewControllerKey] = focusedViewController;

	[[NSNotificationCenter defaultCenter] postNotificationName:VSFocusedViewControllerDidChangeNotification object:self userInfo:userInfo];
}


- (void)closeSidebar:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(closeSidebar:) withObject:sender];
	self.sidebarShowing = NO;
	[self postFocusedViewControllerDidChangeNotification:self];
}


- (void)toggleSidebar:(id)sender {

	CGRect r = self.view.frame;
	if (r.origin.x > 0.1f)
		[self closeSidebar:sender];
	else
		[self openSidebar:sender];
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


- (void)animateSidebarOpenOrClosed {

	CGRect rListView = self.view.frame;

	CGFloat dragThreshold = [app_delegate.theme floatForKey:@"sidebarOpenThreshold"];
	if (self.sidebarShowing)
		dragThreshold = [app_delegate.theme floatForKey:@"sidebarCloseThreshold"];

	if (rListView.origin.x < dragThreshold)
		[self closeSidebar:self];
	else
		[self openSidebar:self];
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer {

	[self adjustAnchorPointForGestureRecognizer:panGestureRecognizer];

	UIGestureRecognizerState gestureRecognizerState = panGestureRecognizer.state;

	switch (gestureRecognizerState) {

		case UIGestureRecognizerStateBegan:
		case UIGestureRecognizerStateChanged:
			[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;

		case UIGestureRecognizerStateEnded:
			[self animateSidebarOpenOrClosed];
			break;

		default:
			break;
	}
}


- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {

	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

		CGPoint locationInView = [gestureRecognizer locationInView:self.view];
		CGPoint locationInSuperview = [gestureRecognizer locationInView:self.view.superview];

		self.view.layer.anchorPoint = CGPointMake(locationInView.x / self.view.bounds.size.width, locationInView.y / self.view.bounds.size.height);
		self.view.center = locationInSuperview;
	}
}


- (BOOL)viewIsAtLeftEdge {
	return self.view.frame.origin.x < 1.0f;
}


- (BOOL)viewIsAtRightEdge {
	return self.view.frame.origin.x >= [app_delegate.theme floatForKey:@"sidebarWidth"];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {


	BOOL viewIsAtLeftEdge = [self viewIsAtLeftEdge];

	if (gestureRecognizer == self.tapGestureRecognizer && !viewIsAtLeftEdge) {
		return YES;
	}

	if (gestureRecognizer != self.panGestureRecognizer && gestureRecognizer != self.panGestureRecognizerToCloseSidebar)
		return NO;

	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;

	if (gestureRecognizer == self.panGestureRecognizer) {
		if (viewIsAtLeftEdge && translation.x < 0.0f) /*Sidebar closed*/
			return NO;

		if (viewIsAtLeftEdge && translation.x >= 0.0f)
			return YES;

		if (viewIsAtLeftEdge && translation.x > 0.0f) /*Sidebar open*/
			return NO;
	}

	else if (gestureRecognizer == self.panGestureRecognizerToCloseSidebar) {

		if (viewIsAtLeftEdge)
			return NO;
		if (translation.x > 0.0f)
			return NO;
	}

	return YES;
}


#pragma mark - Actions

- (void)backButtonPressed:(id)sender {

	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
}


- (NSURL *)testFileURL {

	NSString *testFilePath = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
	return [NSURL fileURLWithPath:testFilePath];
}


- (void)runDocumentPicker:(NSString *)folder {

	self.savedStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];

	UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithURL:[NSURL fileURLWithPath:folder] inMode:UIDocumentPickerModeExportToService];
	picker.modalPresentationStyle = UIModalPresentationFullScreen;
	picker.delegate = self;

	[self presentViewController:picker animated:YES completion:nil];

}

#pragma mark - Notifications

- (void)sidebarDidChangeDisplayState:(NSNotification *)note {

	BOOL sidebarShowing = [[note userInfo][VSSidebarShowingKey] boolValue];
	self.sidebarShowing = sidebarShowing;
}



#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if (!self.exportDidSucceed) {
		return 1;
	}
	return 0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	NSString *labelText = NSLocalizedString(@"Export Notes and Pictures", @"");
	[VSUI configureGroupedTableButtonCell:cell labelText:labelText destructive:NO textAlignment:NSTextAlignmentCenter];

	return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	self.view.userInteractionEnabled = NO;

	[self exportNotes];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	});
}


#pragma mark - UIDocumentPickerDelegate

- (void)restoreStatusBarStyle {

	[[UIApplication sharedApplication] setStatusBarStyle:self.savedStatusBarStyle animated:YES];
}


- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {

	[self restoreStatusBarStyle];
	self.exportDidSucceed = YES;
	[self showSuccessMessage];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {

	[self restoreStatusBarStyle];
}


#pragma mark - Success

- (void)showSuccessMessage {
	
	// Reload so that the Export button is gone.
	[self.tableView reloadData];
	[self.headerView switchToSuccessMessage];
}


#pragma mark - Error

- (void)displayError:(NSString *)title message:(NSString *)message {
	
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
	[alertController addAction:okAction];
	
	[self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Export Notes

- (void)exportNotes {

	self.exporter = [VSExporter new];
	[self.exporter exportNotesAndPictures];
}


- (void)exportDidComplete:(NSNotification *)note {

	if (note.object != self.exporter) {
		return;
	}

	self.view.userInteractionEnabled = YES;
	
	if (self.exporter.exportError) {
		NSError *error = self.exporter.exportError;
		self.exporter = nil;
		[self displayError:error.localizedDescription message:error.localizedFailureReason];
		return;
	}
	
	NSString *folder = self.exporter.folder;
	self.exporter = nil;
	[self runDocumentPicker:folder];
}

@end
