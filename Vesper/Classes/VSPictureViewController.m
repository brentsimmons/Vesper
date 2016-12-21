//
//  VSPictureViewController.m
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "VSPictureViewController.h"
#import "VSImageScrollView.h"
#import "VSPictureNavbarView.h"
#import "VSNavbarButton.h"
#import "VSTagPopover.h"


@interface VSPictureViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong, readwrite) VSImageScrollView *scrollView;
@property (nonatomic, strong, readwrite) VSPictureNavbarView *navbar;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) NSTimer *fadeOutToolbarTimer;
@property (nonatomic, assign) BOOL shouldDoInitialFadeOutToolbar;
@property (nonatomic, strong) VSTagPopover *pictureCopyPopover;

@end


@implementation VSPictureViewController


#pragma mark - Init

- (instancetype)initWithImage:(UIImage *)image {

	self = [self initWithNibName:nil bundle:nil];
	if (self == nil)
		return nil;

	_image = image;

	[self addObserver:self forKeyPath:@"readonly" options:0 context:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popoverDidDismiss:) name:VSPopoverDidDismissNotification object:nil];

	return self;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {


	if ([keyPath isEqualToString:@"readonly"])
		self.navbar.trashButton.hidden = self.readonly;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"readonly"];
	[_fadeOutToolbarTimer qs_invalidateIfValid];
	_fadeOutToolbarTimer = nil;
}


#pragma mark - UIViewController

- (void)loadView {

	self.view = [[UIView alloc] initWithFrame:RSFullViewRect()];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor clearColor];
	self.view.opaque = NO;

	self.scrollView = [[VSImageScrollView alloc] initWithFrame:RSFullViewRect() image:self.image];
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.scrollView];

	self.navbar = [[VSPictureNavbarView alloc] initWithFrame:RSNavbarRect()];
	self.navbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
	[self.view insertSubview:self.navbar aboveSubview:self.scrollView];

	self.singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
	[self.scrollView addGestureRecognizer:self.singleTapGestureRecognizer];

	self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
	self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
	[self.scrollView addGestureRecognizer:self.doubleTapGestureRecognizer];

	[self.singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];

	self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	[self.scrollView addGestureRecognizer:self.longPressGestureRecognizer];

	NSTimeInterval delay = [app_delegate.theme timeIntervalForKey:@"photoDetailToolbarInitialFadeDelay"];
	self.fadeOutToolbarTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(fadeOutToolbarTimerDidFire:) userInfo:nil repeats:NO];
	self.shouldDoInitialFadeOutToolbar = YES;

	self.navbar.trashButton.hidden = self.readonly;
}


- (void)viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
	self.shouldDoInitialFadeOutToolbar = NO;
	if ([app_delegate.theme boolForKey:@"statusBarHidden"])
		[UIApplication sharedApplication].statusBarHidden = YES;
	else
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}


- (BOOL)prefersStatusBarHidden {
	return YES;
}


#pragma mark - Notifications

- (void)popoverDidDismiss:(NSNotification *)note {

	VSMenuPopover *popover = [note object];
	if (popover == self.pictureCopyPopover) {
		self.pictureCopyPopover = nil;
	}
}


#pragma mark - Timer

- (void)fadeOutToolbarTimerDidFire:(NSTimer *)timer {

	self.fadeOutToolbarTimer = nil;
	if (self.shouldDoInitialFadeOutToolbar)
		[self fadeOutToolbarAndStatusBar];
}


#pragma mark - Animations

- (void)fadeToolbarToAlpha:(CGFloat)alpha {
	
	self.shouldDoInitialFadeOutToolbar = NO;
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"photoDetailToolbarFadeDuration"];
	
	[UIView animateWithDuration:duration animations:^{
		
		self.navbar.alpha = alpha;
		
	} completion:^(BOOL finished) {
		;
	}];
}


- (void)toggleToolbarVisibility {

	if (self.navbar.alpha >= 0.99f)
		[self fadeOutToolbarAndStatusBar];
	else
		[self fadeInToolbarAndStatusBar];;
}


- (void)fadeInToolbarAndStatusBar {
	[self fadeToolbarToAlpha:1.0f];
	if ([app_delegate.theme boolForKey:@"statusBarHidden"])
		[UIApplication sharedApplication].statusBarHidden = YES;
	else
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}


- (void)fadeOutToolbarAndStatusBar {
	[self fadeToolbarToAlpha:0.0f];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}


#pragma mark - Actions

- (void)copyImage:(id)sender {

	@autoreleasepool {

		NSMutableArray *pasteboardItems = [NSMutableArray new];

		NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0f);
		NSString *uti = (__bridge  NSString *)kUTTypeJPEG;
		if (imageData == nil) {
			imageData = UIImagePNGRepresentation(self.image);
			uti = (__bridge NSString *)kUTTypePNG;
		}

		if (imageData != nil) {
			NSMutableDictionary *pictureItem = [NSMutableDictionary new];
			pictureItem[uti] = imageData;
			[pasteboardItems addObject:pictureItem];
		}

		if ([pasteboardItems count] > 0)
			[UIPasteboard generalPasteboard].items = pasteboardItems;
	}
}


- (void)longPress:(UILongPressGestureRecognizer *)gestureRecognizer {

	if (self.pictureCopyPopover != nil)
		return;

	VSSendUIEventHappenedNotification();

	self.pictureCopyPopover = [[VSTagPopover alloc] initWithPopoverSpecifier:@"picturePopover"];
	self.pictureCopyPopover.arrowOnTop = NO;

	[self.pictureCopyPopover addItemWithTitle:NSLocalizedString(@"Copy", @"Copy") image:nil target:self action:@selector(copyImage:)];

	CGPoint point = [gestureRecognizer locationInView:self.view];
	point.y += [app_delegate.theme floatForKey:@"picturePopoverOffsetY"];

	CGRect rBackground = self.view.bounds;

	[self.view bringSubviewToFront:self.pictureCopyPopover];

	[self.pictureCopyPopover showFromPoint:point inView:self.view backgroundViewRect:rBackground];
}


- (void)singleTap:(UITapGestureRecognizer *)tapRecognizer {
	[self toggleToolbarVisibility];
	VSSendUIEventHappenedNotification();
}


- (void)doubleTap:(UITapGestureRecognizer *)tapRecognizer {

	VSSendUIEventHappenedNotification();

	CGPoint locationInImage = [tapRecognizer locationInView:self.scrollView.imageView];

	CGFloat newZoomScale = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) ? self.scrollView.maximumZoomScale : self.scrollView.minimumZoomScale;

	CGRect zoomRect = CGRectZero;
	zoomRect.size.width = self.scrollView.bounds.size.width / newZoomScale;
	zoomRect.size.height = self.scrollView.bounds.size.height / newZoomScale;
	zoomRect.origin.x = locationInImage.x - zoomRect.size.width / 2;
	zoomRect.origin.y = locationInImage.y - zoomRect.size.height / 2;

	[self.scrollView zoomToRect:zoomRect animated:YES];
}


- (void)pictureDetailViewDone:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(pictureDetailViewDone:) withObject:self];
}


- (void)cancelDeleteAttachment:(id)sender {
	;
}


- (void)deleteAttachment:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(pictureDetailDeleteAttachment:) withObject:self];
	[self pictureDetailViewDone:nil];
	VSSendUIEventHappenedNotification();
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (buttonIndex == 0) {
		[self deleteAttachment:nil];
	}
	else {
		[self cancelDeleteAttachment:nil];
	}
}

- (void)trashButtonTapped:(id)sender {

	self.shouldDoInitialFadeOutToolbar = NO;

	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:@"Remove Photo" otherButtonTitles:nil];
	[self.actionSheet showInView:self.view];
}


@end

