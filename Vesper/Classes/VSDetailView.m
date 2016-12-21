//
//  VSDetailView.m
//  Vesper
//
//  Created by Brent Simmons on 4/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailView.h"
#import "VSDetailNavbarView.h"
#import "VSDetailTextView.h"
#import "VSTagDetailScrollView.h"
#import "VSDetailToolbar.h"
#import "VSTypographySettings.h"


NSString *VSFastSwitchFirstResponderNotification = @"VSFastSwitchFirstResponderNotification";

typedef struct {
	CGFloat navbarHeight;
	CGFloat textMarginLeft;
	CGFloat textMarginRight;
	CGFloat tagsHeight;
	CGFloat tagsMarginTop;
	BOOL tagsHugKeyboard;
} VSDetailViewLayoutBits;


static VSDetailViewLayoutBits detailViewLayoutBits(VSTheme *theme) {

	VSDetailViewLayoutBits layoutBits;

	layoutBits.navbarHeight = [theme floatForKey:@"navbarHeight"];
	layoutBits.textMarginLeft = [theme floatForKey:@"detailTextMarginLeft"];
	layoutBits.textMarginRight = [theme floatForKey:@"detailTextMarginRight"];
	layoutBits.tagsHeight = [theme floatForKey:@"tagDetailScrollViewHeight"];
	layoutBits.tagsMarginTop = [theme floatForKey:@"tagDetailScrollViewMarginTop"];
	layoutBits.tagsHugKeyboard = [theme boolForKey:@"tagsHugKeyboard"];

	return layoutBits;
}


@interface VSDetailView ()

@property (nonatomic, strong, readwrite) UIView *leftBorderView;
@property (nonatomic, strong, readwrite) UIView *backingViewForTextView;
@property (nonatomic, strong, readwrite) VSDetailToolbar *toolbar;
@property (nonatomic, assign) VSDetailViewLayoutBits layoutBits;
@property (nonatomic, strong) UITapGestureRecognizer *linkTapGestureRecognizer;
@property (nonatomic, assign) CGRect keyboardFrame;
@property (nonatomic, assign, readwrite) BOOL keyboardShowing;
@property (nonatomic, strong) UIView *editingView;
@property (nonatomic, assign) BOOL readOnly;
@property (nonatomic, assign) BOOL fastSwitchFirstResponderInProgress;

@end


@implementation VSDetailView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame backButtonTitle:(NSString *)backButtonTitle imageSize:(CGSize)imageSize tagProxies:(NSArray *)tagProxies readOnly:(BOOL)readOnly {

	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;

	_layoutBits = detailViewLayoutBits(app_delegate.theme);
	_readOnly = readOnly;

	self.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.autoresizingMask = UIViewAutoresizingNone;

	CGRect bounds = frame;
	bounds.origin.x = 0.0f;
	bounds.origin.y = 0.0f;

	CGRect rNavbar = RSNavbarRect();
	_navbar = [[VSDetailNavbarView alloc] initWithFrame:rNavbar backButtonTitle:backButtonTitle];
	_navbar.autoresizingMask = UIViewAutoresizingNone;
	[self addSubview:_navbar];

	CGRect rToolbar = frame;
	rToolbar.size.height = VSNavbarHeight;
	rToolbar.origin.y = CGRectGetMaxY(frame) - CGRectGetHeight(rToolbar);
	_toolbar = [[VSDetailToolbar alloc] initWithFrame:rToolbar];
	if (readOnly)
		_toolbar.showRestoreButton = YES;
	[self addSubview:_toolbar];

	CGRect rBackingView = rectOfBackingViewWithBounds(bounds, _layoutBits);;
	_backingViewForTextView = [[UIView alloc] initWithFrame:rBackingView];
	_backingViewForTextView.autoresizingMask = UIViewAutoresizingNone;
	_backingViewForTextView.backgroundColor = self.backgroundColor;
	_backingViewForTextView.opaque = YES;
	[self insertSubview:self.backingViewForTextView belowSubview:_navbar];

	CGRect rBackingViewBounds = rBackingView;
	rBackingViewBounds.origin = CGPointZero;
	CGRect rText = rectOfTextViewWithBounds(rBackingViewBounds, CGRectZero, _layoutBits);
	_textView = [[VSDetailTextView alloc] initWithFrame:rText imageSize:imageSize tagProxies:tagProxies readonly:readOnly];
	_textView.autoresizingMask = UIViewAutoresizingNone;
	_textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
	_textView.keyboardFrame = CGRectZero;
	[_backingViewForTextView addSubview:_textView];

	_tagsScrollView = [[VSTagDetailScrollView alloc] initWithFrame:[self rectOfTagsView] tagProxies:tagProxies];
	_tagsScrollView.autoresizingMask = UIViewAutoresizingNone;
	[self addSubview:_tagsScrollView];

	_tagSuggestionView = [[VSTagSuggestionView alloc] initWithFrame:[self rectOfTagSuggestionView] delegate:self];
	_tagSuggestionView.autoresizingMask = UIViewAutoresizingNone;
	[self addSubview:_tagSuggestionView];
	_tagSuggestionView.hidden = YES;

	CGRect rBorderView = bounds;
	rBorderView.size.width = [app_delegate.theme floatForKey:@"detailPan.detailBorderWidth"];
	rBorderView.origin.y = CGRectGetHeight(rNavbar);
	rBorderView.size.height -= CGRectGetMinY(rNavbar);
	rBorderView.origin.x -= rBorderView.size.width;
	UIColor *borderColor = [app_delegate.theme colorForKey:@"detailPan.detailBorderColor"];
	borderColor = [borderColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"detailPan.detailBorderColorAlpha"]];
	_leftBorderView = [[UIView alloc] initWithFrame:rBorderView];
	_leftBorderView.backgroundColor = borderColor;
	_leftBorderView.opaque = NO;
	[self addSubview:_leftBorderView];

	[self bringSubviewToFront:_toolbar];
	[self bringSubviewToFront:_leftBorderView];

	[self addObserver:self forKeyPath:@"image" options:0 context:NULL];

	[self addLinkTapGestureRecognizer];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidBecomeFirstResponder:) name:VSDidBecomeFirstResponderNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResignFirstResponder:) name:VSDidResignFirstResponderNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameDidChange:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFastSwitchFirstResponder:) name:VSFastSwitchFirstResponderNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	_linkTapGestureRecognizer.delegate = nil;
	[self removeObserver:self forKeyPath:@"image"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([keyPath isEqualToString:@"image"]) {
		self.textView.image = self.image;
		[self setNeedsLayout];
	}

}


#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)note {

	NSValue *keyboardFrameValue = [note userInfo][UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
	self.keyboardFrame = [self convertRect:keyboardFrame fromView:nil];

	if (self.aboutToClose || self.fastSwitchFirstResponderInProgress) {
		self.fastSwitchFirstResponderInProgress = NO;
		return;
	}

	self.keyboardShowing = YES;
	if (!self.navbar.editMode) {
		self.navbar.editMode = YES;
	}

	[self removeLinkTapGestureRecognizer];

	self.textView.keyboardFrame = self.keyboardFrame;
	[self.textView layoutSubviews];

	BOOL tagIsBeingEdited = [self.editingView isKindOfClass:[UITextField class]];

	if (tagIsBeingEdited) {

		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];

		NSTimeInterval duration = [[note userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

			[self scrollToEndAnimated:YES];
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		});
	}

	[self layout];

	[self updateScrollEnabled];
}


- (void)keyboardWillHide:(NSNotification *)note {

	if (self.aboutToClose || self.fastSwitchFirstResponderInProgress) {
		return;
	}

	self.keyboardShowing = NO;
	self.keyboardFrame = CGRectZero;
	if (self.navbar.editMode) {
		self.navbar.editMode = NO;
	}

	self.textView.keyboardFrame = CGRectZero;

	[self layout];
	[self addLinkTapGestureRecognizer];
}


- (void)scrollToEndAnimated:(BOOL)animated {

	CGRect rTags = self.tagsScrollView.frame;
	if (CGRectGetMaxY(rTags) < (CGRectGetMinY(self.keyboardFrame) + 10.0f)) {
		return; /*Tags already visible.*/
	}

	CGSize contentSize = [self.textView vs_contentSize];
	contentSize.height += self.textView.textContainerInset.top;
	contentSize.height += self.layoutBits.tagsMarginTop;
	contentSize.height += CGRectGetHeight(self.tagsScrollView.frame);

	CGRect rText = self.textView.frame;
	CGRect rKeyboard = self.keyboardFrame;
	CGFloat visibleHeight = CGRectGetHeight(rText) - CGRectGetHeight(rKeyboard);

	CGPoint contentOffset = CGPointMake(0.0f, contentSize.height);
	contentOffset.y -= visibleHeight;

	CGPoint originalContentOffset = self.textView.contentOffset;
	if (fabs(contentOffset.y - originalContentOffset.y) < 12.0f) {
		return; /*Close enough.*/
	}

	[self.textView setContentOffSetAnimatedForReal:contentOffset];
}


- (void)updateScrollEnabled {

	BOOL tagIsBeingEdited = [self.editingView isKindOfClass:[UITextField class]];
	self.textView.scrollEnabled = !tagIsBeingEdited;
}


- (void)viewDidBecomeFirstResponder:(NSNotification *)note {

	UIResponder *responder = [note userInfo][VSResponderKey];

	if ([responder isKindOfClass:[UIView class]]) {

		UIView *view = (UIView *)responder;

		self.editingView = view;

		BOOL editMode = [view isDescendantOfView:self.textView];
		if (!editMode)
			editMode = [view isKindOfClass:[UITextView class]];
		if (!editMode)
			editMode = [view isKindOfClass:[UITextField class]];
		if (self.navbar.editMode != editMode)
			self.navbar.editMode = editMode;
	}

	else
		self.editingView = nil;

	[self updateScrollEnabled];
}


- (void)viewDidResignFirstResponder:(NSNotification *)note {

	UIResponder *responder = [note userInfo][VSResponderKey];
	UIView *view = (UIView *)responder;

	if (view == self.editingView) {
		self.editingView = nil;
	}

	[self updateScrollEnabled];
}


- (void)handleFastSwitchFirstResponder:(NSNotification *)note {
	self.fastSwitchFirstResponderInProgress = YES;
}


- (void)statusBarFrameDidChange:(NSNotification *)note {
	[self setNeedsLayout];
}


#pragma mark - Gesture Recognizer

- (void)addLinkTapGestureRecognizer {

	if (self.linkTapGestureRecognizer == nil)
		self.linkTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)];

	if ([self.textView.gestureRecognizers containsObject:self.linkTapGestureRecognizer])
		return;

	[self.textView addGestureRecognizer:self.linkTapGestureRecognizer];
	self.linkTapGestureRecognizer.delegate = self;
}


- (void)removeLinkTapGestureRecognizer {
	[self.textView removeGestureRecognizer:self.linkTapGestureRecognizer];
	self.linkTapGestureRecognizer.delegate = nil;
}


#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (gestureRecognizer != self.linkTapGestureRecognizer)
		return NO;

	CGPoint tapPoint = [touch locationInView:self.textView];
	NSString *link = [self.textView rs_linkAtPoint:tapPoint];
	if ([link length] > 0)
		return YES;
	return NO;
}



#pragma mark - VSTagSuggestionViewDelegate

- (void)tagSuggestionView:(VSTagSuggestionView *)tagSuggestionView didChooseTagName:(NSString *)tagName {

	if ([tagName length] < 1)
		return;
	[self.tagsScrollView userChoseSuggestedTagName:tagName];
	self.tagSuggestionView.userTypedTag = nil;
}


#pragma mark - Actions

- (void)textViewTapped:(UITapGestureRecognizer *)sender {

	CGPoint tapPoint = [sender locationOfTouch:0 inView:self.textView];

	NSString *link = [self.textView rs_linkAtPoint:tapPoint];
	if ([link length] > 0) {
		[self qs_performSelectorViaResponderChain:@selector(openLinkInBrowser:) withObject:link];
		return;
	}

	[self becomeFirstResponder];
}


- (void)ghostTagDoneButtonTapped:(id)sender {
	self.tagSuggestionView.userTypedTag = nil;
	self.fastSwitchFirstResponderInProgress = YES;
}


#pragma mark - Layout

- (CGRect)rectOfToolbarWithBounds:(CGRect)bounds {

	CGRect r = bounds;
	r.size.height = VSNavbarHeight;
	r.origin.y = CGRectGetMaxY(bounds) - CGRectGetHeight(r);
	return r;
}


- (CGRect)rectOfToolbar {
	return [self rectOfToolbarWithBounds:self.bounds];
}


static CGRect rectOfBackingViewWithBounds(CGRect bounds, VSDetailViewLayoutBits layoutBits) {

	CGRect r = bounds;
	r.origin.y = RSNavbarPlusStatusBarHeight();
	r.size.height -= r.origin.y;
	return r;
}


static CGRect rectOfTextViewWithBounds(CGRect bounds, CGRect keyboardFrame, VSDetailViewLayoutBits layoutBits) {

	CGRect r = bounds;

	r.origin.x = layoutBits.textMarginLeft;
	r.origin.y = 0.0f;

	r.size.width = CGRectGetWidth(bounds) - (layoutBits.textMarginLeft + layoutBits.textMarginRight);
	r.size.height = CGRectGetHeight(bounds) - r.origin.y;

	return r;
}


- (CGRect)rectOfTagsView {

	CGRect r = self.bounds;

	r.size.height = self.layoutBits.tagsHeight;
	//	CGSize contentSize = [self.textView vs_contentSize];
	//	NSLog(@"contentSize: %@", NSStringFromCGSize(contentSize));
	//	NSLog(@"reported contentSize: %@", NSStringFromCGSize(self.textView.contentSize));

	r.origin.y = [self.textView vs_contentSize].height + self.textView.textContainerInset.top;
	r.origin.y += self.layoutBits.tagsMarginTop;

	r = [self.textView convertRect:r toView:self];

	/*Treat as upside down table header. Pin to keyboard if short note.*/

	if (self.layoutBits.tagsHugKeyboard && !CGRectEqualToRect(self.keyboardFrame, CGRectZero)) {

		//		CGRect rText = self.textView.frame;
		//		CGFloat availableTextViewHeight = CGRectGetHeight(rText) - CGRectGetHeight(self.keyboardFrame);

		CGRect rPinnedTags = [UIScreen mainScreen].bounds;
		rPinnedTags.size.height = r.size.height;
		CGFloat keyboardOriginY = CGRectGetMaxY([UIScreen mainScreen].bounds) - self.keyboardFrame.size.height;
		CGFloat pinnedTagsOriginY = keyboardOriginY - self.layoutBits.tagsHeight;
		rPinnedTags.origin.y = pinnedTagsOriginY;
		rPinnedTags = [self convertRect:rPinnedTags fromView:nil];
		r.origin.y = MAX(rPinnedTags.origin.y, r.origin.y);

		/*Deal with jitter.*/

		if (rPinnedTags.origin.y != r.origin.y) {

			if (fabs(rPinnedTags.origin.y - r.origin.y) < 8.0f) {
				r.origin.y = rPinnedTags.origin.y;
			}
		}
	}

	r.origin.x = self.bounds.origin.x;
	r.size.width = self.bounds.size.width;

	return r;
}


- (CGRect)rectOfTagSuggestionView {

	CGRect rTagsScrollView = [self rectOfTagsView];
	CGRect r = rTagsScrollView;
	r.size = [VSTagSuggestionView size];
	r.origin.y = CGRectGetMinY(rTagsScrollView) - r.size.height;
	r.origin.y += [app_delegate.theme floatForKey:@"autoCompleteBubbleOffsetY"];
	r.origin.x = 0.0f;

	return r;
}


- (void)layout {

	CGRect rBounds = self.bounds;

	[self.navbar qs_setFrameIfNotEqual:RSNavbarRect()];

	CGRect rBackingView = rectOfBackingViewWithBounds(rBounds, self.layoutBits);
	[self.backingViewForTextView qs_setFrameIfNotEqual:rBackingView];

	CGRect rBackingViewBounds = rBackingView;
	rBackingViewBounds.origin = CGPointZero;
	CGRect rText = rectOfTextViewWithBounds(rBackingViewBounds, self.keyboardFrame, self.layoutBits);
	[self.textView qs_setFrameIfNotEqual:rText];

	CGRect rTags = [self rectOfTagsView];
	CGRect rTagsCurrent = self.tagsScrollView.frame;
	//	NSLog(@"rTags: %@, rTagsCurrent: %@", NSStringFromCGRect(rTags), NSStringFromCGRect(rTagsCurrent));
	if (!CGRectEqualToRect(rTags, rTagsCurrent)) {
		self.tagsScrollView.frame = rTags;
	}
	//	[self.tagsScrollView qs_setFrameIfNotEqual:[self rectOfTagsView]];
	[self.tagSuggestionView qs_setFrameIfNotEqual:[self rectOfTagSuggestionView]];
	[self.toolbar qs_setFrameIfNotEqual:[self rectOfToolbar]];
}


- (void)layoutSubviews {
	[self layout];
}


#pragma mark - Animation

- (UIImage *)imageForAnimation {

	CGRect originalImageViewFrame = self.textView.imageView.frame;
	[self.textView.imageView removeFromSuperview];

	UIGraphicsBeginImageContextWithOptions(self.backingViewForTextView.frame.size, NO, [UIScreen mainScreen].scale);

	UIColor *backingOriginalBackgroundColor = self.backingViewForTextView.backgroundColor;
	BOOL backingOriginalOpaque = self.backingViewForTextView.isOpaque;

	UIColor *textViewOriginalBackgroundColor = self.textView.backgroundColor;
	BOOL textViewOriginalOpaque = self.textView.isOpaque;

	self.backingViewForTextView.backgroundColor = [UIColor clearColor];
	self.backingViewForTextView.opaque = NO;

	self.textView.backgroundColor = [UIColor clearColor];
	self.textView.opaque = NO;

	[self.backingViewForTextView.layer renderInContext:UIGraphicsGetCurrentContext()];

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	self.backingViewForTextView.backgroundColor = backingOriginalBackgroundColor;
	self.backingViewForTextView.opaque = backingOriginalOpaque;

	self.textView.backgroundColor = textViewOriginalBackgroundColor;
	self.textView.opaque = textViewOriginalOpaque;

	[self.textView addSubview:self.textView.imageView];
	self.textView.imageView.frame = originalImageViewFrame;

	return image;
}


- (UIImage *)textImageForAnimation {

	/*Just the text -- not the attachment or tags view.*/

	UIImage *animationImage = [self imageForAnimation];

	/*Draw the animation image so that the attachment is outside the image.
	 Get the text only.*/

	UIGraphicsBeginImageContextWithOptions(animationImage.size, NO, [UIScreen mainScreen].scale);

	CGFloat attachmentHeight = CGRectGetHeight(self.textView.imageView.frame);
	if (!self.textView.imageView) {
		attachmentHeight = 0.0f;
	}
	
	CGFloat textMarginLeft = CGRectGetMinX(self.textView.frame);
	CGRect rAnimationImage = CGRectMake(-textMarginLeft, -attachmentHeight, animationImage.size.width, animationImage.size.height);
	[animationImage drawInRect:rAnimationImage];

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return image;
}



@end

