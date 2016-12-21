//
//  VSTypographyViewController.m
//  Vesper
//
//  Created by Brent Simmons on 8/28/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTypographyViewController.h"
#import "VSNavbarView.h"
#import "VSTimelineCell.h"
#import "VSTypographySmallCapsCell.h"
#import "VSTypographyFontSizeCell.h"
#import "VSTypographyTextWeightCell.h"
#import "VSCheckmarkAccessoryView.h"
#import "VSTypographySettings.h"


@interface VSTypographyViewController () <UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerToOpenSidebar;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizerToCloseSidebar;
@property (nonatomic, assign) BOOL sidebarShowing;
@property (nonatomic, strong) VSNavbarView *navbar;
@property (nonatomic, strong) UIView *textWeightHeader;
@property (nonatomic, assign) CGFloat sidebarWidth;
@property (nonatomic, strong) VSTypographyTextWeightCell *lightWeightCell;
@property (nonatomic, strong) VSTypographyTextWeightCell *regularWeightCell;
@property (nonatomic, strong) NSString *sampleNoteTitle;
@property (nonatomic, strong) NSString *sampleNoteBody;

@end


static void *VSTypographySidebarShowingContext = &VSTypographySidebarShowingContext;


@implementation VSTypographyViewController


#pragma mark - Init

- (instancetype)init {
	
	self = [self initWithNibName:nil bundle:nil];
	if (self == nil)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
	
	_sampleNoteTitle = NSLocalizedString(@"Typography controls", @"Typography controls");
	_sampleNoteBody = NSLocalizedString(@"As you choose from the options above, your selections will be reflected in this sample note.", @"As you choose from the options above, your selections will be reflected in this sample note.");
	
	_sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typographySettingsDidChange:) name:VSTypographySettingsDidChangeNotification object:nil];
	
	[(id)app_delegate addObserver:self forKeyPath:VSSidebarShowingKey options:0 context:VSTypographySidebarShowingContext];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	_tapGestureRecognizer.delegate = nil;
	_panGestureRecognizerToOpenSidebar = nil;
	_panGestureRecognizerToCloseSidebar = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[(id)app_delegate removeObserver:self forKeyPath:VSSidebarShowingKey context:VSTypographySidebarShowingContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if (context == VSTypographySidebarShowingContext) {
		self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	self.title = NSLocalizedString(@"Typography", @"Typography");
	
	self.view = [[UIView alloc] initWithFrame:RSFullViewRect()];
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"typographyScreen.backgroundColor"];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	
	self.navbar = [[VSNavbarView alloc] initWithFrame:RSNavbarRect()];
	self.navbar.showComposeButton = NO;
	self.navbar.title = self.title;
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.navbar];
	
	self.tableView = [[UITableView alloc] initWithFrame:RSRectForMainView() style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.opaque = NO;
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.tableView.scrollEnabled = !app_delegate.sidebarShowing;
	[self.view addSubview:self.tableView];
	
	if ([app_delegate.theme boolForKey:@"sidebarOpenPanRequiresEdge"]) {
		self.panGestureRecognizerToOpenSidebar = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
		((UIScreenEdgePanGestureRecognizer *)self.panGestureRecognizerToOpenSidebar).edges = UIRectEdgeLeft;
	}
	else {
		self.panGestureRecognizerToOpenSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	}
	
	self.panGestureRecognizerToOpenSidebar.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizerToOpenSidebar];
	
	self.panGestureRecognizerToCloseSidebar = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	self.panGestureRecognizerToCloseSidebar.delegate = self;
	[self.view addGestureRecognizer:self.panGestureRecognizerToCloseSidebar];
	
	self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSidebar:)];
	self.tapGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:self.tapGestureRecognizer];
	
	[self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
}


#pragma mark - Scrolling

- (BOOL)viewIsAtLeftEdge {
	return self.view.frame.origin.x < 1.0f;
}


#pragma mark - Gesture Recognizers

- (void)openSidebar:(id)sender {
	self.sidebarShowing = YES;
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(openSidebar:) withObject:sender];
}


- (void)closeSidebar:(id)sender {
	self.sidebarShowing = NO;
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(closeSidebar:) withObject:sender];
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
	[self.view qs_setFrameIfNotEqual:frame];
	
	CGFloat sidebarWidth = self.sidebarWidth;
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

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	BOOL viewIsAtLeftEdge = [self viewIsAtLeftEdge];
	
	if (gestureRecognizer == self.tapGestureRecognizer && !viewIsAtLeftEdge)
		return YES;
	
	if (gestureRecognizer != self.panGestureRecognizerToOpenSidebar && gestureRecognizer != self.panGestureRecognizerToCloseSidebar)
		return NO;
	
	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	
	
	if (gestureRecognizer == self.panGestureRecognizerToOpenSidebar) {
		if (viewIsAtLeftEdge && translation.x < 0.0f) /*Sidebar closed*/
			return NO;
		
		if (viewIsAtLeftEdge && translation.x >= 0.0f)
			return ![self qs_hasChildViewController]; /*Normally would work, but there's a view pushed on top*/
		
		if (viewIsAtLeftEdge && translation.x > 0.0f) /*Sidebar open*/
			return NO;
	}
	
	else if (gestureRecognizer == self.panGestureRecognizerToCloseSidebar) {
		
		if (viewIsAtLeftEdge)
			return NO;
		if (translation.x > 0.0f)
			return NO;
		if ([self qs_hasChildViewController])
			return NO;
	}
	
	return YES;
}


#pragma mark - Notifications

- (void)userDefaultsDidChange:(NSNotification *)note {
	[self updateTextWeightCells];
}


#pragma mark - UITableViewDataSource / UITableViewDelegate

typedef NS_ENUM(NSUInteger, VSTypographyTableSection) {
	VSTypographySectionSmallCaps,
	VSTypographySectionFontSize,
	VSTypographySectionTextWeight,
	VSTypographySectionSampleText
};

static NSInteger VSTypographyNumberOfSections = VSTypographySectionSampleText + 1;

typedef NS_ENUM(NSUInteger, VSTypographyTextWeightRow) {
	VSTypographyTextWeightLight,
	VSTypographyTextWeightRegular
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return VSTypographyNumberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (section == VSTypographySectionTextWeight)
		return 2;
	return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	if (section == VSTypographySectionTextWeight)
		return [app_delegate.theme floatForKey:@"typographyScreen.textWeightTableHeaderHeight"];
	return [app_delegate.theme floatForKey:@"typographyScreen.spaceBetweenSections"];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 1.0f;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	if (section == VSTypographySectionTextWeight) {
		NSString *s = [app_delegate.theme stringForKey:@"typographyScreen.textWeightTableHeaderText"];
		s = [app_delegate.theme string:s transformedWithTextCaseTransformKey:@"typographyScreen.tableHeaderTextTransform"];
		return s;
	}
	
	return nil;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section != VSTypographySectionTextWeight)
		return nil;
	
	if (self.textWeightHeader == nil) {
		
		CGRect r = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), [app_delegate.theme floatForKey:@"typographyScreen.textWeightTableHeaderHeight"]);
		self.textWeightHeader = [[UIView alloc] initWithFrame:r];
		
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:r];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.opaque = NO;
		
		NSString *text = [self tableView:tableView titleForHeaderInSection:section];
		UIColor *color = [app_delegate.theme colorForKey:@"typographyScreen.tableHeaderTextColor"];
		UIFont *font = [app_delegate.theme fontForKey:@"typographyScreen.tableHeaderFont"];
		NSDictionary *attributes = @{NSForegroundColorAttributeName : color, NSFontAttributeName : font, NSKernAttributeName : [NSNull null]};
		NSAttributedString *attString = [[NSAttributedString alloc] initWithString:text attributes:attributes];
		titleLabel.attributedText = attString;
		
		CGRect rTitleLabel = r;
		rTitleLabel.origin = [app_delegate.theme pointForKey:@"typographyScreen.textWeightTableHeaderOrigin"];
		rTitleLabel.size.width = CGRectGetWidth(self.view.bounds) - rTitleLabel.origin.x;
		titleLabel.frame = rTitleLabel;
		
		[self.textWeightHeader addSubview:titleLabel];
	}
	
	return self.textWeightHeader;
}


- (UIView *)checkmarkAccessoryView {
	
	static UIImage *checkmarkImage = nil;
	if (checkmarkImage == nil)
		checkmarkImage = [UIImage qs_imageNamed:@"checkmark" tintedWithColor:[app_delegate.theme colorForKey:@"typographyScreen.textWeightCheckmarkColor"]];
	
	CGFloat checkmarkOriginY = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCheckmarkOriginY"];
	CGFloat checkmarkMarginRight = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCheckmarkMarginRight"];
	
	CGRect r = CGRectZero;
	r.size.width = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCheckmarkViewWidth"];
	r.size.height = 1024.0f; /*whatever*/
	
	UIView *accessoryView = [[VSCheckmarkAccessoryView alloc] initWithFrame:CGRectZero checkmarkOriginY:checkmarkOriginY checkmarkMarginRight:checkmarkMarginRight checkmarkImage:checkmarkImage];
	[accessoryView setNeedsLayout];
	
	return accessoryView;
}


- (void)updateAccessoryViewForCell:(VSTypographyTextWeightCell *)cell {
	
	BOOL cellShouldHaveAccessoryView = NO;
	VSTextWeight textWeight = VSDefaultsTextWeight();
	
	if (cell == self.regularWeightCell && textWeight == VSTextWeightRegular)
		cellShouldHaveAccessoryView = YES;
	else if (cell == self.lightWeightCell && textWeight == VSTextWeightLight)
		cellShouldHaveAccessoryView = YES;
	
	if (cellShouldHaveAccessoryView && cell.accessoryView == nil) {
		cell.accessoryView = [self checkmarkAccessoryView];
		[cell setNeedsDisplay];
	}
	else if (!cellShouldHaveAccessoryView && cell.accessoryView != nil) {
		cell.accessoryView = nil;
		[cell setNeedsDisplay];
	}
}


- (void)updateTextWeightCells {
	
	[self updateAccessoryViewForCell:self.lightWeightCell];
	[self updateAccessoryViewForCell:self.regularWeightCell];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	
	switch (indexPath.section) {
			
		case VSTypographySectionSmallCaps:
			cell = [[VSTypographySmallCapsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			break;
			
		case VSTypographySectionFontSize:
			cell = [[VSTypographyFontSizeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			break;
			
		case VSTypographySectionTextWeight: {
			
			if (indexPath.row == VSTypographyTextWeightLight) {
				
				if (self.lightWeightCell == nil) {
					NSString *text = NSLocalizedString(@"Light", @"Light");
					self.lightWeightCell = [[VSTypographyTextWeightCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil text:text];
				}
				cell = self.lightWeightCell;
			}
			else {
				
				if (self.regularWeightCell == nil) {
					NSString *text = NSLocalizedString(@"Book", @"Book");
					self.regularWeightCell = [[VSTypographyTextWeightCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil text:text];
				}
				cell = self.regularWeightCell;
			}
			
			[cell.textLabel sizeToFit];
			[self updateAccessoryViewForCell:(VSTypographyTextWeightCell *)cell];
			[cell setNeedsLayout];
		}
			break;
			
		case VSTypographySectionSampleText: {
			
			VSTimelineCell *timelineCell = [[VSTimelineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			[timelineCell configureWithTitle:self.sampleNoteTitle text:self.sampleNoteBody links:nil useItalicFonts:NO hasThumbnail:NO truncateIfNeeded:NO];
			timelineCell.isSampleText = YES;
			cell = timelineCell;
		}
			break;
			
		default:
			break;
	}
	
	if (!cell) {
		// Shouldn't get here. Added 19 Dec. 2016 to make Xcode 8.2.1 happy.
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	}
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	return cell;
	
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section == VSTypographySectionTextWeight)
		return YES;
	return NO;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat height = 0.0f;
	
	switch (indexPath.section) {
			
		case VSTypographySectionSmallCaps:
			height = [app_delegate.theme floatForKey:@"typographyScreen.smallCapsCellHeight"];
			break;
			
		case VSTypographySectionFontSize:
			height = [app_delegate.theme floatForKey:@"typographyScreen.sliderCellHeight"];
			break;
			
		case VSTypographySectionTextWeight:
			height = [app_delegate.theme floatForKey:@"typographyScreen.textWeightCellHeight"];
			break;
			
		case VSTypographySectionSampleText:
			height = [VSTimelineCell heightWithTitle:self.sampleNoteTitle text:self.sampleNoteBody links:nil useItalicFonts:NO hasThumbnail:NO truncateIfNeeded:NO];
			break;
			
		default:
			break;
	}
	
	return height;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (indexPath.section != VSTypographySectionTextWeight)
		return;
	
	VSTextWeight textWeight = VSTextWeightRegular;
	if (indexPath.row == VSTypographyTextWeightLight)
		textWeight = VSTextWeightLight;
	
	VSTextWeight currentTextWeight = VSDefaultsTextWeight();
	if (currentTextWeight != textWeight)
		VSDefaultsSetTextWeight(textWeight);
	
	[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Notifications

- (void)typographySettingsDidChange:(NSNotification *)note {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		/*Use dispatch_async because we want to run after everything else has handled VSTypographySettingsDidChangeNotification.*/
		
		[self.tableView beginUpdates];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:VSTypographySectionSampleText];
		[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
		[self.tableView endUpdates];
	});
}


@end

