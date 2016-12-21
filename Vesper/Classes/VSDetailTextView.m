//
//  VSDetailTextView.m
//  Vesper
//
//  Created by Brent Simmons on 4/17/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailTextView.h"
#import "VSTagDetailScrollView.h"
#import "VSTagSuggestionView.h"
#import "VSDetailTextStorage.h"
#import "VSTypographySettings.h"


typedef struct {
	UIEdgeInsets imageInsets;
	CGSize imageViewSize;
	CGFloat tagsHeight;
	CGFloat tagsMarginTop;
	CGFloat marginLeft; /*Outside the view, to the edge of the superview*/
	UIEdgeInsets tagsEdgeInsets;
} VSDetailTextViewLayoutBits;


static VSDetailTextViewLayoutBits textViewLayoutBits(VSTheme *theme) {

	VSDetailTextViewLayoutBits layoutBits;

	layoutBits.imageInsets = [theme edgeInsetsForKey:@"detailImageViewMargin"];
	layoutBits.tagsHeight = [theme floatForKey:@"tagDetailScrollViewHeight"];
	layoutBits.tagsMarginTop = [theme floatForKey:@"tagDetailScrollViewMarginTop"];
	layoutBits.marginLeft = [theme floatForKey:@"detailTextMarginLeft"];

	CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	CGFloat imageViewWidth = screenWidth;
	CGFloat imageViewHeight = screenWidth;
	layoutBits.imageViewSize = CGSizeMake(imageViewWidth, imageViewHeight);

	return layoutBits;
}


#pragma mark -

@interface VSDetailTextView ()

@property (nonatomic, assign) VSDetailTextViewLayoutBits layoutBits;

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, strong, readwrite) UIFont *titleFont;
@property (nonatomic, strong, readwrite) UIColor *titleColor;
@property (nonatomic, assign) BOOL editing;
@end


@implementation VSDetailTextView


static void *VSDetailTextViewImageObserverContext = &VSDetailTextViewImageObserverContext;
static void *VSDetailTextViewReadOnlyObserverContext = &VSDetailTextViewReadOnlyObserverContext;
static void *VSDetailTextViewKeyboardFrameObserverContext = &VSDetailTextViewKeyboardFrameObserverContext;
static void *VSDetailTextViewEditingObserverContext = &VSDetailTextViewEditingObserverContext;


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame imageSize:(CGSize)imageSize tagProxies:(NSArray *)tagProxies readonly:(BOOL)readonly {

	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	layoutManager.allowsNonContiguousLayout = NO;

	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(frame.size.width, CGFLOAT_MAX)];
	textContainer.widthTracksTextView = NO;
	textContainer.heightTracksTextView = NO;
	[layoutManager addTextContainer:textContainer];

	VSDetailTextStorage *textStorage = [[VSDetailTextStorage alloc] initAsReadOnly:readonly];
	[textStorage addLayoutManager:layoutManager];

	self = [self initWithFrame:frame textContainer:textContainer];
	if (self == nil)
		return nil;

	_layoutBits = textViewLayoutBits(app_delegate.theme);
	_imageSize = imageSize;
	_titleFont = app_delegate.typographySettings.titleFont;
	_titleColor = [app_delegate.theme colorForKey:@"noteTitleFontColor"];

	_keyboardFrame = CGRectZero;

	self.clipsToBounds = NO;
	self.font = self.titleFont;
	self.textColor = self.titleColor;
	self.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.showsHorizontalScrollIndicator = NO;
	self.bounces = YES;
	self.alwaysBounceVertical = YES;

	self.tintColor = [app_delegate.theme colorForKey:@"detailTextViewTintColor"];

	[self updateContentInset];

	CGPoint contentOffset = self.contentOffset;
	if (imageSize.height > 1.0f) {
		contentOffset.y = -(_layoutBits.imageViewSize.height);
	}
	else {
		contentOffset.y = -4.0f;
	}
	self.contentOffset = contentOffset;

	[self updateScrollIndicator];

	[self addObserver:self forKeyPath:@"image" options:0 context:VSDetailTextViewImageObserverContext];
	[self addObserver:self forKeyPath:@"readonly" options:0 context:VSDetailTextViewReadOnlyObserverContext];
	[self addObserver:self forKeyPath:@"keyboardFrame" options:0 context:VSDetailTextViewKeyboardFrameObserverContext];
	[self addObserver:self forKeyPath:@"editing" options:0 context:VSDetailTextViewEditingObserverContext];

	[self updateUI];
	[self setNeedsLayout];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"image" context:VSDetailTextViewImageObserverContext];
	[self removeObserver:self forKeyPath:@"readonly" context:VSDetailTextViewReadOnlyObserverContext];
	[self removeObserver:self forKeyPath:@"keyboardFrame" context:VSDetailTextViewKeyboardFrameObserverContext];
	[self removeObserver:self forKeyPath:@"editing" context:VSDetailTextViewEditingObserverContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (context == VSDetailTextViewImageObserverContext) {

		[self createImageViewIfNeeded];

		self.imageView.image = self.image;
		if (self.image == nil)
			self.imageSize = CGSizeZero;
		else
			self.imageSize = self.image.size;
		[self updateUI];
	}

	else if (context == VSDetailTextViewReadOnlyObserverContext) {
		if (self.readonly) {
			if ([self isFirstResponder])
				[self resignFirstResponder];
		}
	}

	else if (context == VSDetailTextViewKeyboardFrameObserverContext) {
		[self updateContentInset];
		[self updateScrollIndicator];
	}

	else if (context == VSDetailTextViewEditingObserverContext) {
		if (self.editing)
			[self unhighlightLinks];
		else
			[self detectAndHighlightLinks];
	}

	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark - Layout

- (CGRect)rectOfImageView {

	if (CGSizeEqualToSize(self.imageSize, CGSizeZero))
		return CGRectZero;

	CGRect rImageView = CGRectZero;
	CGSize imageViewSize = self.layoutBits.imageViewSize;
	rImageView.size = imageViewSize;

	rImageView.origin.y = self.layoutBits.imageInsets.top;
	rImageView.origin.x = self.layoutBits.imageInsets.left;

	CGRect rContainer = rImageView;
	rContainer.size.width = self.layoutBits.imageViewSize.width;
	rImageView = CGRectCenteredHorizontallyInRect(rImageView, self.bounds);

	rImageView.origin.y = 0.0f;//-= rImageView.size.height;

	return rImageView;
}


static const CGFloat textTopPadding = 12.0f;

- (void)updateContentInset {

	/*Use textContainerInset for top. Works around bugs using contentInset.*/

	UIEdgeInsets textContainerInset = UIEdgeInsetsZero;
	CGRect rImageView = [self rectOfImageView];
	textContainerInset.top = rImageView.size.height + textTopPadding;

	if (textContainerInset.top < 1.0f) { /*No picture?*/
		textContainerInset.top = textTopPadding;
	}

	if (!UIEdgeInsetsEqualToEdgeInsets(textContainerInset, self.textContainerInset)) {
		self.textContainerInset = textContainerInset;
	}

	/*Bottom -- keyboard and toolbar -- is handled by contentInset.*/

	UIEdgeInsets contentInset = UIEdgeInsetsZero;

	contentInset.bottom = self.layoutBits.tagsHeight + self.layoutBits.tagsMarginTop;
	if (CGRectEqualToRect(self.keyboardFrame, CGRectZero)) {
		contentInset.bottom += VSNavbarHeight; /*toolbar at bottom of detail view.*/
	}
	else {
		contentInset.bottom += self.keyboardFrame.size.height;
	}

	if (!UIEdgeInsetsEqualToEdgeInsets(contentInset, self.contentInset)) {
		self.contentInset = contentInset;
	}
}


- (void)layout {
	[self.imageView qs_setFrameIfNotEqual:[self rectOfImageView]];
}


- (void)updateUI {

	[self updateContentInset];
	[self layout];
}


- (void)layoutSubviews {

	[super layoutSubviews];
	[self layout];
}


- (void)updateScrollIndicator {

	UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(0.0f, 0.0f, VSNavbarHeight, -(self.layoutBits.marginLeft));

	if (!CGRectEqualToRect(self.keyboardFrame, CGRectZero)) {
		scrollIndicatorInsets.bottom = CGRectGetHeight(self.keyboardFrame);
	}

	if (!UIEdgeInsetsEqualToEdgeInsets(self.scrollIndicatorInsets, scrollIndicatorInsets))
		self.scrollIndicatorInsets = scrollIndicatorInsets;
}


- (CGSize)vs_contentSize {

	return self.contentSize;
//	[self.layoutManager ensureLayoutForTextContainer:self.textContainer];
//	CGRect r = [self.layoutManager usedRectForTextContainer:self.textContainer];
//	CGSize size = r.size;
//
//	size.height = QSCeil(size.height);
//	size.width = QSCeil(size.width);
//
//	return size;
}


#pragma mark - UITextView

- (void)setAttributedText:(NSAttributedString *)attributedText {

	[super setAttributedText:attributedText];

	if (!self.editing)
		[self detectAndHighlightLinksOnMainThread];
}


- (void)setContentSize:(CGSize)contentSize {

	CGSize vsContentSize = [self vs_contentSize];
	//	if (contentSize.height < vsContentSize.height) {
	//		return;
	//	}

	/*On showing the keyboard, especially after tapping the ghost tag button,
	 sometimes the system sets the contentSize to a value equal to the height of the view.
	 Don't let that happen. Get the line height from the font and add it.
	 (Because contentSize is taller than vs_contentSize by one line.)
	 It might be off by some number of points, but it's *way* closer than what
	 the system thinks it should be.*/

//	NSLog(@"attempted contentSize: %@", NSStringFromCGSize(contentSize));
	CGRect r = self.bounds;
	//	NSLog(@"r %@", NSStringFromCGRect(r));
	if (contentSize.height == r.size.height) {
		UIFont *font = app_delegate.typographySettings.titleFont;
		CGFloat lineHeight = font.lineHeight + font.descender;
		lineHeight = QSFloor(lineHeight);
		contentSize.height = vsContentSize.height + lineHeight;
	}

//	NSLog(@"actual contentSize: %@", NSStringFromCGSize(contentSize));

	[super setContentSize:contentSize];
}


/*We have to disable animation, because it causes the tags to bounce down when a line is added.*/

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {

	[super setContentOffset:contentOffset animated:NO];
}


- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {

	[super scrollRectToVisible:rect animated:NO];
}


- (void)setContentOffSetAnimatedForReal:(CGPoint)contentOffset {

	[super setContentOffset:contentOffset animated:YES];
}


#pragma mark - Image View

- (void)createImageViewIfNeeded {

	if (self.imageView != nil || self.image == nil)
		return;

	self.imageView = [[UIImageView alloc] initWithImage:self.image];
	self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	self.imageView.userInteractionEnabled = YES;
	self.imageView.clipsToBounds = YES;

	[self addSubview:self.imageView];

	UITapGestureRecognizer *imageTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
	[self.imageView addGestureRecognizer:imageTapGestureRecognizer];
}


#pragma mark - Links

- (void)unhighlightLinks {
	[(VSDetailTextStorage *)(self.textStorage) unhighlightLinks];
}


- (void)highlightLinks:(NSArray *)links {
	[(VSDetailTextStorage *)(self.textStorage) highlightLinks:links];
}


- (void)highlightLinksIfNeeded:(NSArray *)links {

	if (self.editing)
		return;
	[self highlightLinks:links];
}


- (void)detectAndHighlightLinksOnMainThread {

	if (self.editing)
		return;

	NSArray *links = [self.text qs_links];
	[self highlightLinks:links];
}


- (void)detectAndHighlightLinks {

	__weak VSDetailTextView *weakself = self;
	NSString *text = [self.text copy];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

		NSArray *links = [text qs_links];
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakself highlightLinksIfNeeded:links];
		});
	});
}


#pragma mark - Actions

- (void)imageViewTapped:(id)sender {
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(imageViewTapped:) withObject:sender];
}


#pragma mark - UIResponder

- (void)sendDidBecomeFirstResponderNotification {
	self.editing = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDidBecomeFirstResponderNotification object:self userInfo:@{VSResponderKey : self}];
}


- (void)sendDidResignFirstResponderNotification {
	self.editing = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDidResignFirstResponderNotification object:self userInfo:@{VSResponderKey : self}];
}


- (BOOL)becomeFirstResponder {
	if (self.readonly)
		return NO;
	BOOL didBecomeFirstResponder = [super becomeFirstResponder];
	if (didBecomeFirstResponder)
		[self sendDidBecomeFirstResponderNotification];
	return didBecomeFirstResponder;
}


- (BOOL)resignFirstResponder {
	BOOL didResignFirstResponder = [super resignFirstResponder];
	if (didResignFirstResponder)
		[self sendDidResignFirstResponderNotification];
	return didResignFirstResponder;
}


- (BOOL)canBecomeFirstResponder {
	if (self.readonly)
		return NO;
	return [super canBecomeFirstResponder];
}


#pragma mark - Animation

- (UIView *)viewForAnimation:(BOOL)clearBackground {

	UIColor *originalBackgroundColor = self.backgroundColor;
	BOOL originalIsOpaque = self.isOpaque;

	if (clearBackground) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}

	UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	CGContextTranslateCTM(context, 0, -(self.contentOffset.y));
	[self.layer renderInContext:context];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	UIImageView *animationView = [[UIImageView alloc] initWithImage:image];
	animationView.clipsToBounds = YES;
	animationView.contentMode = UIViewContentModeBottom;
	animationView.autoresizingMask = UIViewAutoresizingNone;

	if (clearBackground) {
		self.opaque = originalIsOpaque;
		self.backgroundColor = originalBackgroundColor;
	}

	return animationView;
}


@end
