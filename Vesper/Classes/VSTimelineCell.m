//
//  VSTimelineCell.m
//  Vesper
//
//  Created by Brent Simmons on 5/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTimelineCell.h"
#import "VSNoteTextRenderer.h"
#import "VSTextView.h"
#import "VSArchiveIndicatorView.h"
#import "VSThumbnail.h"
#import "VSTimelineCellButtonContainer.h"
#import "VSTimelineCellButton.h"
#import "VSTypographySettings.h"


typedef struct {
	UIEdgeInsets edgeInsets;
	CGSize viewSize;
	CGSize thumbnailSize;
	CGFloat thumbnailMarginRight;
	CGFloat thumbnailMarginTop;
	CGFloat thumbnailMarginLeft;
	CGFloat thumbnailMarginBottom;
	CGRect thumbnailRect;
	BOOL thumbnailCenterVertically;
	CGFloat textWidth;
	CGFloat textWidthWithAttachment;
	BOOL centerText;
	BOOL titleOnly;
	CGFloat thumbnailBorderWidth;
	CGFloat thumbnailShadowOpacity;
	CGFloat thumbnailShadowOffsetY;
	CGFloat thumbnailShadowBlurRadius;
} VSTimelineCellLayoutBits;


static VSTimelineCellLayoutBits timelineCellLayoutBitsWithSize(VSTheme *theme, CGSize viewSize) {
	
	VSTimelineCellLayoutBits layoutBits;
	
	layoutBits.edgeInsets = [theme edgeInsetsForKey:@"notePadding"];
	if (CGSizeEqualToSize(viewSize, CGSizeZero)) {
		viewSize = [UIScreen mainScreen].applicationFrame.size;
	}
	CGFloat screenWidth = viewSize.width;
	layoutBits.viewSize = CGSizeMake(screenWidth, [theme floatForKey:@"timelineRowHeight"]);
	
	CGFloat thumbnailWidth = [theme floatForKey:@"thumbnailWidth"];
	CGFloat thumbnailHeight = [theme floatForKey:@"thumbnailHeight"];
	layoutBits.thumbnailSize = CGSizeMake(thumbnailWidth, thumbnailHeight);
	
	layoutBits.thumbnailMarginRight = [theme floatForKey:@"thumbnailMarginRight"];
	layoutBits.thumbnailMarginTop = [theme floatForKey:@"thumbnailMarginTop"];
	layoutBits.thumbnailMarginLeft = [theme floatForKey:@"thumbnailMarginLeft"];
	layoutBits.thumbnailMarginBottom = [theme floatForKey:@"thumbnailMarginBottom"];
	
	CGRect rThumbnail = CGRectZero;
	rThumbnail.size = layoutBits.thumbnailSize;
	rThumbnail.origin.y = layoutBits.thumbnailMarginTop;
	rThumbnail.origin.x = layoutBits.viewSize.width - (layoutBits.thumbnailSize.width + layoutBits.thumbnailMarginRight);
	layoutBits.thumbnailRect = rThumbnail;
	
	layoutBits.thumbnailCenterVertically = [theme boolForKey:@"thumbnailCenterVertically"];
	
	layoutBits.textWidth = layoutBits.viewSize.width - (layoutBits.edgeInsets.left + layoutBits.edgeInsets.right);
	layoutBits.textWidthWithAttachment = layoutBits.viewSize.width - (layoutBits.edgeInsets.left + layoutBits.thumbnailMarginLeft + layoutBits.thumbnailSize.width + layoutBits.thumbnailMarginRight);
	
	layoutBits.centerText = [theme boolForKey:@"timelineCenterInRow"];
	layoutBits.titleOnly = [theme boolForKey:@"timelineTitlesOnly"];
	
	layoutBits.thumbnailBorderWidth = [theme floatForKey:@"thumbnailBorderWidth"];
	layoutBits.thumbnailShadowOpacity = [theme floatForKey:@"thumbnailShadowAlpha"];
	layoutBits.thumbnailShadowOffsetY = [theme floatForKey:@"thumbnailShadowOffsetY"];
	layoutBits.thumbnailShadowBlurRadius = [theme floatForKey:@"thumbnailShadowBlurRadius"];
	
	return layoutBits;
}

static VSTimelineCellLayoutBits timelineCellLayoutBits(VSTheme *theme) {
	return timelineCellLayoutBitsWithSize(theme, CGSizeZero);
}

static NSString *VSTimelineCellPanGestureDidBeginNotification = @"VSTimelineCellPanGestureDidBeginNotification";
static NSString *VSTimelineCellPanGestureDidEndNotification = @"VSTimelineCellPanGestureDidEndNotification";
NSString *VSTimelineCellShouldCancelPanNotification = @"VSTimelineCellShouldCancelPanNotification";

@interface VSTimelineCell () <UIActionSheetDelegate>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *links;
@property (nonatomic, assign) BOOL hasThumbnail;
@property (nonatomic, strong) VSTextView *textView;
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIImageView *truncatedIndicatorImageView;
@property (nonatomic, strong) UIView *archiveIndicatorView;
@property (nonatomic, assign) CGFloat noteViewOriginX;
@property (nonatomic, assign) BOOL archiveIndicatorShowing;
//@property (nonatomic, strong) UIColor *backgroundColorEven;
//@property (nonatomic, strong) UIColor *backgroundColorOdd;
@property (nonatomic, assign) BOOL useItalicFonts;
@property (nonatomic, assign) BOOL lockedInToArchive;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIView *noteView; /*Content. Archive/trash appear on contentView.*/
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, assign) BOOL truncateIfNeeded; /*Defaults to YES*/

@end


@implementation VSTimelineCell


#pragma mark Class Methods

static NSMutableDictionary *textRendererCache = nil;
static NSMutableDictionary *textRendererWithThumbnailCache = nil;
static NSMutableDictionary *italicTextRendererCache = nil;
static NSMutableDictionary *italicTextRendererWithThumbnailCache = nil;

static VSTimelineCellLayoutBits layoutBits;
//static UIColor *backgroundColorEven = nil;
//static UIColor *backgroundColorOdd = nil;

+ (void)initialize {
	
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		
		textRendererCache = [NSMutableDictionary new];
		textRendererWithThumbnailCache = [NSMutableDictionary new];
		italicTextRendererCache = [NSMutableDictionary new];
		italicTextRendererWithThumbnailCache = [NSMutableDictionary new];
		
		layoutBits = timelineCellLayoutBits(app_delegate.theme);
		
		//        backgroundColorEven = [app_delegate.theme colorForKey:@"timelineRowsEven"];
		//        backgroundColorOdd = [app_delegate.theme colorForKey:@"timelineRowsOdd"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarning:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typographySettingsDidChange:) name:VSTypographySettingsDidChangeNotification object:nil];
	});
}


+ (void)applicationDidReceiveMemoryWarning:(NSNotification *)note {
	[self emptyCaches];
}


+ (void)typographySettingsDidChange:(NSNotification *)note {
	[self emptyCaches];
}


+ (void)emptyCaches {
	@autoreleasepool {
		textRendererCache = [NSMutableDictionary new];
		textRendererWithThumbnailCache = [NSMutableDictionary new];
		italicTextRendererCache = [NSMutableDictionary new];
		italicTextRendererWithThumbnailCache = [NSMutableDictionary new];
	}
}


+ (UIImage *)truncationIndicatorImage {
	
	static UIImage *truncationIndicatorImage = nil;
	
	if (truncationIndicatorImage != nil)
		return truncationIndicatorImage;
	
	NSString *truncationIndicatorText = [app_delegate.theme stringForKey:@"noteTruncationIndicator"];
	
	UILabel *truncationIndicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 5.0f, 5.0f)];
	truncationIndicatorLabel.text = truncationIndicatorText;
	truncationIndicatorLabel.font = [app_delegate.theme fontForKey:@"noteTruncationIndicatorFont"];
	truncationIndicatorLabel.textColor = [app_delegate.theme colorForKey:@"noteTruncationIndicatorFontColor"];
	truncationIndicatorLabel.backgroundColor = [UIColor clearColor];
	truncationIndicatorLabel.opaque = NO;
	
	[truncationIndicatorLabel sizeToFit];
	CGRect r = truncationIndicatorLabel.frame;
	
	UIGraphicsBeginImageContextWithOptions(r.size, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[truncationIndicatorLabel.layer renderInContext:context];
	
	truncationIndicatorImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return truncationIndicatorImage;
}


+ (VSNoteTextRenderer *)textRendererForTitle:(NSString *)title text:(NSString *)text width:(CGFloat)textWidth links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded {
	
	if (layoutBits.titleOnly)
		text = nil;
	
	if (QSStringIsEmpty(text))
		text = @"";
	if (QSStringIsEmpty(title))
		title = @"";
	
	NSString *fullText = title;
	if (fullText == nil)
		fullText = @"";
	if (!QSStringIsEmpty(text))
		fullText = [fullText stringByAppendingFormat:@"\n%@", text];
	
	NSMutableDictionary *cacheToUse = nil;
	if (hasThumbnail)
		cacheToUse = useItalicFonts ? italicTextRendererWithThumbnailCache : textRendererWithThumbnailCache;
	else
		cacheToUse = useItalicFonts ? italicTextRendererCache : textRendererCache;
	
	VSNoteTextRenderer *cachedTextRenderer = [cacheToUse objectForKey:fullText];
	if (cachedTextRenderer != nil)
		return cachedTextRenderer;
	
	VSNoteTextRenderer *textRenderer = [[VSNoteTextRenderer alloc] initWithTitle:title text:text links:links width:textWidth useItalicFonts:useItalicFonts truncateIfNeeded:truncateIfNeeded];
	
	if (textRenderer == nil)
		return nil;
	[cacheToUse setObject:textRenderer forKey:fullText];
	
	return textRenderer;
}


+ (NSString *)titleForPhotoOnlyNote {
	return NSLocalizedString(@"Untitled photo", @"Untitled photo");
}


typedef struct {
	CGRect textRect;
	CGRect thumbnailRect;
} VSTimelineCellRects;


+ (VSTimelineCellRects)rectsWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded {
	
	if (layoutBits.titleOnly)
		text = nil;
	
	if (QSStringIsEmpty(title) && QSStringIsEmpty(text) && hasThumbnail)
		title = [self titleForPhotoOnlyNote];
	
	VSTimelineCellRects rects = {CGRectZero, CGRectZero};
	CGRect rBounds = CGRectZero;
	rBounds.size = layoutBits.viewSize;
	
	CGFloat textWidth = [self textWidth:hasThumbnail];
	
	VSNoteTextRenderer *textRenderer = [self textRendererForTitle:title text:text width:textWidth links:links useItalicFonts:useItalicFonts hasThumbnail:hasThumbnail truncateIfNeeded:truncateIfNeeded];
	
	CGRect rText = CGRectZero;
	rText.origin.x = layoutBits.edgeInsets.left;
	rText.origin.y = layoutBits.edgeInsets.top;
	rText.size.height = textRenderer.height;
	rText.size.width = textWidth;
	
	//    if (layoutBits.centerText) {
	//        rText = CGRectCenteredVerticallyInRect(rText, rBounds);
	//        rText.size.height = textRenderer.height;
	//    }
	
	rects.textRect = rText;
	
	if (hasThumbnail)
		rects.thumbnailRect = layoutBits.thumbnailRect;
	
	return rects;
}


+ (CGFloat)textWidth:(BOOL)hasThumbnail {
	return hasThumbnail ? layoutBits.textWidthWithAttachment : layoutBits.textWidth;
}

+ (void)adjustLayoutBitsWithSize:(CGSize)newSize {
	layoutBits = timelineCellLayoutBitsWithSize(app_delegate.theme, newSize);
}

+ (CGFloat)height {
	return layoutBits.viewSize.height;
}


+ (CGFloat)heightWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded {
	
	text = [text qs_stringByTrimmingWhitespace];
	if (layoutBits.titleOnly)
		text = nil;
	
	VSTimelineCellRects rects = [self rectsWithTitle:title text:text links:links useItalicFonts:useItalicFonts hasThumbnail:hasThumbnail truncateIfNeeded:truncateIfNeeded];
	
	CGFloat height = CGRectGetMaxY(rects.textRect);
	height = MAX(height, CGRectGetMaxY(rects.thumbnailRect));
	if (CGRectGetMaxY(rects.thumbnailRect) > height)
		return CGRectGetMaxY(rects.thumbnailRect) + layoutBits.thumbnailMarginBottom;
	
	height += layoutBits.edgeInsets.bottom;
	
	return height;
}



#pragma mark Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self == nil)
		return nil;
	
	_truncateIfNeeded = YES;
	self.contentMode = UIViewContentModeRedraw;
	
	_noteView = [[UIView alloc] initWithFrame:CGRectZero];
	_textView = [[VSTextView alloc] initWithFrame:CGRectZero];
	_textView.contentMode = UIViewContentModeRedraw;
	[_noteView addSubview:_textView];
	
	self.contentView.backgroundColor = [app_delegate.theme colorForKey:@"timelineCellBackgroundColor"];
	self.contentView.opaque = NO;
	
	self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.selectedBackgroundView.backgroundColor = [app_delegate.theme colorForKey:@"noteSelectedBackgroundColor"];
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = [app_delegate.theme colorForKey:@"timelineCellBackgroundColor"];
	
	//    self.backgroundColor = backgroundColorEven;//self.contentView.backgroundColor;
	self.opaque = YES;
	_noteView.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	_noteView.opaque = YES;
	[self.contentView addSubview:_noteView];
	
	_thumbnailView = [[UIImageView alloc] initWithImage:nil];
	_thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	_thumbnailView.clipsToBounds = NO;
	
	//    if (layoutBits.thumbnailBorderWidth > 0.0f) {
	//        _thumbnailView.layer.borderWidth = layoutBits.thumbnailBorderWidth;
	//        _thumbnailView.layer.borderColor = [app_delegate.theme colorForKey:@"thumbnailBorderColor"].CGColor;
	//    }
	//
	//    if (layoutBits.thumbnailShadowOpacity > 0.0f) {
	//        _thumbnailView.layer.shadowOffset = CGSizeMake(0, layoutBits.thumbnailShadowOffsetY);
	//        _thumbnailView.layer.shadowRadius = layoutBits.thumbnailShadowBlurRadius;
	//        _thumbnailView.layer.shadowColor = [app_delegate.theme colorForKey:@"thumbnailShadowColor"].CGColor;
	//        _thumbnailView.layer.shadowOpacity = layoutBits.thumbnailShadowOpacity;
	//    }
	
	[_noteView insertSubview:_thumbnailView aboveSubview:_textView];
	
	_truncatedIndicatorImageView = [[UIImageView alloc] initWithImage:[[self class] truncationIndicatorImage]];
	_truncatedIndicatorImageView.contentMode = UIViewContentModeCenter;
	[_noteView insertSubview:_truncatedIndicatorImageView aboveSubview:_textView];
	
	
	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
	panGestureRecognizer.maximumNumberOfTouches = 1;
	panGestureRecognizer.delegate = self;
	self.panGestureRecognizer = panGestureRecognizer;
	[self addGestureRecognizer:panGestureRecognizer];
	
	[self addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionInitial context:0];
	[self addObserver:self forKeyPath:@"renderingForAnimation" options:0 context:0];
	[self addObserver:self forKeyPath:@"hideThumbnail" options:0 context:0];
	
	[self setNeedsLayout];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSSidebarDidChangeDisplayStateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sidebarDidChangeDisplayState:) name:VSDataViewDidPanToRevealSidebarNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePanGestureRecognizerDidBeginNotification:) name:VSTimelineCellPanGestureDidBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCancelPanHandling:) name:VSTimelineCellShouldCancelPanNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePanGestureDidEndNotification:) name:VSTimelineCellPanGestureDidEndNotification object:nil];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"thumbnail"];
	[self removeObserver:self forKeyPath:@"renderingForAnimation"];
	[self removeObserver:self forKeyPath:@"hideThumbnail"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"thumbnail"])
		[self updateThumbnailView];
	
	else if ([keyPath isEqualToString:@"renderingForAnimation"]) {
		if (self.renderingForAnimation)
			self.highlighted = NO;
	}
	
	else if ([keyPath isEqualToString:@"hideThumbnail"])
		self.thumbnailView.hidden = self.hideThumbnail;
	
	[self setNeedsLayout];
}


#pragma mark - UITableViewCell

- (void)prepareForReuse {
	[super prepareForReuse];
	_truncateIfNeeded = YES;
	[self removeArchiveIndicatorView];
	self.hasThumbnail = NO;
	self.textView.textRenderer = nil;
	self.title = nil;
	self.text = nil;
	self.renderingForAnimation = NO;
	self.hideThumbnail = NO;
	self.noteViewOriginX = 0.0f;
	self.archiveIndicatorShowing = NO;
	self.lockedInToArchive = NO;
	self.useItalicFonts = NO;
	self.archiveIndicatorUseItalicFont = NO;
	self.contentView.alpha = 1.0f;
	self.contentView.frame = self.bounds;
	self.noteView.frame = self.bounds;
}


#pragma mark - Values

- (void)configureWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded {
	
	text = [text qs_stringByTrimmingWhitespace];
	self.truncateIfNeeded = truncateIfNeeded;
	self.hasThumbnail = hasThumbnail;
	self.useItalicFonts = useItalicFonts;
	self.links = links;
	if (layoutBits.titleOnly)
		text = nil;
	self.text = text;
	
	if (QSStringIsEmpty(title) && QSStringIsEmpty(text) && hasThumbnail)
		title = [[self class] titleForPhotoOnlyNote];
	self.title = title;
	
	CGFloat textWidth = [[self class] textWidth:hasThumbnail];
	self.textView.textRenderer = [[self class] textRendererForTitle:title text:text width:textWidth links:links useItalicFonts:useItalicFonts hasThumbnail:hasThumbnail truncateIfNeeded:truncateIfNeeded];
	
	[self setNeedsLayout];
	[self setNeedsDisplay];
}


#pragma mark - Notifications

- (void)appWillResignActive:(NSNotification *)note {
	[self cancelPanHandling];
}


- (void)sidebarDidChangeDisplayState:(NSNotification *)note {
	[self cancelPanHandling];
}


#pragma mark - Gesture Recognizers

- (void)cancelPanHandling {
	
	CGRect r = self.contentView.frame;
	r.origin.x = 0.0f;
	[self.contentView qs_setFrameIfNotEqual:r];
	
	BOOL shouldLayout = NO;
	
	//	CGRect rBounds = self.bounds;
	CGRect rNoteView = self.noteView.frame;
	
	if (rNoteView.origin.x <= -0.1f || rNoteView.origin.x > 0.1f || rNoteView.origin.y < -0.1f || rNoteView.origin.y > 0.1f) {
		/*There's something weird where rNoteView.origin.x and y could be super-close to 0.0f but not exact.*/
		self.noteView.frame = self.bounds;
		shouldLayout = YES;
	}
	
	if (self.archiveIndicatorShowing) {
		self.archiveIndicatorShowing = NO;
		shouldLayout = YES;
	}
	if (self.noteViewOriginX != 0.0f) {
		self.noteViewOriginX = 0.0f;
		shouldLayout = YES;
	}
	if (self.lockedInToArchive) {
		self.lockedInToArchive = NO;
		shouldLayout = YES;
	}
	
	if (shouldLayout) {
		[self setNeedsLayout];
		//    [self setNeedsDisplay];
	}
	
	[self.delegate timelineCellDidCancelOrEndPanning:self];
}


- (void)handleCancelPanHandling:(NSNotification *)note {
	[self cancelPanHandling];
}


- (void)handlePanGestureDidEndNotification:(NSNotification *)note {
	self.panGestureRecognizer.enabled = YES;
}


- (void)handlePanGestureStateBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	switch (self.archiveControlStyle) {
			
		case VSArchiveControlStyleRestoreDelete:
			[self handleRestoreDeleteGestureBeganOrChanged:panGestureRecognizer];
			break;
			
		case VSArchiveControlStyleArchive:
			[self handleArchiveGestureBeganOrChanged:panGestureRecognizer];
			break;
			
		default:
			break;
	}
	
}


- (void)handleArchiveGestureBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	VSArchiveIndicatorView *archiveIndicatorView = (VSArchiveIndicatorView *)[self createArchiveIndicatorView];
	CGRect rArchiveIndicatorView = archiveIndicatorView.frame;
	
	CGPoint translation = [panGestureRecognizer translationInView:self.contentView.superview];
	CGFloat currentX = self.noteView.frame.origin.x;
	CGFloat noteLockinPoint = [app_delegate.theme floatForKey:@"archiveNoteLockinPoint"];
	
	if (translation.x < 0.0f && currentX < noteLockinPoint) {
		CGFloat extraX = noteLockinPoint - currentX;
		CGFloat molassesFactor = [app_delegate.theme floatForKey:@"archiveNoteMolasses"] / 100.0f;
		CGFloat molasses = extraX * molassesFactor;
		if (molasses < 1.1f)
			molasses = 1.1f;
		translation.x = translation.x / molasses;
	}
	
	CGFloat frameX = self.noteView.frame.origin.x + translation.x;
	if (frameX > 0.0f)
		frameX = 0.0f;
	BOOL lockedIn = (frameX <= noteLockinPoint);
	
	CGRect frame = self.noteView.frame;
	frame.origin.x = frameX;
	self.noteView.frame = frame;
	self.noteViewOriginX = frameX;
	
	CGFloat indicatorMarginRight = [app_delegate.theme floatForKey:@"archiveIndicatorMarginRight"];
	rArchiveIndicatorView.origin.x = self.frame.size.width - (archiveIndicatorView.frame.size.width + indicatorMarginRight);
	
	if (lockedIn) {
		
		self.lockedInToArchive = YES;
		
		if (archiveIndicatorView.archiveIndicatorState != VSArchiveIndicatorStateIndicating)
		{
			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"will %@ note", nil), self.archiveActionText]);
			archiveIndicatorView.archiveIndicatorState = VSArchiveIndicatorStateIndicating;
		}
		
		self.archiveIndicatorView.alpha = 1.0f;
	}
	
	else {
		
		self.lockedInToArchive = NO;
		
		if (archiveIndicatorView.archiveIndicatorState != VSArchiveIndicatorStateHinting)
		{
			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"will not %@ note", nil), self.archiveActionText]);
			archiveIndicatorView.archiveIndicatorState = VSArchiveIndicatorStateHinting;
		}
		
		CGFloat percentageMovedTowardLockin = self.noteViewOriginX / noteLockinPoint;
		self.archiveIndicatorView.alpha = percentageMovedTowardLockin;
		
	}
	
	CGFloat translationX = frameX * 0.1f;
	archiveIndicatorView.arrowTranslationX = translationX;
	
	[archiveIndicatorView qs_setFrameIfNotEqual:rArchiveIndicatorView];
	
	[panGestureRecognizer setTranslation:CGPointZero inView:self.contentView.superview];
}


- (void)handleRestoreDeleteGestureBeganOrChanged:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	(void)[self createArchiveIndicatorView];
	//    CGRect rArchiveIndicatorView = archiveIndicatorView.frame;
	
	CGPoint translation = [panGestureRecognizer translationInView:self.contentView.superview];
	//    CGFloat currentX = self.noteView.frame.origin.x;
	CGFloat noteLockinPoint = CGRectGetMaxX(self.bounds) - [app_delegate.theme floatForKey:@"timelineArchiveDelete.buttonWidth"];
	
	//    if (translation.x < 0.0f && currentX < noteLockinPoint) {
	//        CGFloat extraX = noteLockinPoint - currentX;
	//        CGFloat molassesFactor = [app_delegate.theme floatForKey:@"archiveNoteMolasses"] / 100.0f;
	//        CGFloat molasses = extraX * molassesFactor;
	//        if (molasses < 1.1f)
	//            molasses = 1.1f;
	//        translation.x = translation.x / molasses;
	//    }
	
	CGFloat frameX = self.noteView.frame.origin.x + translation.x;
	if (frameX > 0.0f)
		frameX = 0.0f;
	BOOL lockedIn = ((frameX + CGRectGetWidth(self.noteView.frame)) <= noteLockinPoint);
	self.lockedInToArchive = lockedIn;
	
	CGRect frame = self.noteView.frame;
	frame.origin.x = frameX;
	self.noteView.frame = frame;
	self.noteViewOriginX = frameX;
	
	//    CGFloat indicatorMarginRight = [app_delegate.theme floatForKey:@"archiveIndicatorMarginRight"];
	//    rArchiveIndicatorView.origin.x = self.frame.size.width - (archiveIndicatorView.frame.size.width + indicatorMarginRight);
	
	//    if (lockedIn) {
	//
	//        self.lockedInToArchive = YES;
	//
	//        if (archiveIndicatorView.archiveIndicatorState != VSArchiveIndicatorStateIndicating)
	//		{
	//			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"will %@ note", nil), self.archiveActionText]);
	//			archiveIndicatorView.archiveIndicatorState = VSArchiveIndicatorStateIndicating;
	//		}
	//
	//        self.archiveIndicatorView.alpha = 1.0f;
	//    }
	//
	//    else {
	//
	//        self.lockedInToArchive = NO;
	//
	//        if (archiveIndicatorView.archiveIndicatorState != VSArchiveIndicatorStateHinting)
	//		{
	//			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:NSLocalizedString(@"will not %@ note", nil), self.archiveActionText]);
	//			archiveIndicatorView.archiveIndicatorState = VSArchiveIndicatorStateHinting;
	//		}
	//
	//        CGFloat percentageMovedTowardLockin = self.noteViewOriginX / noteLockinPoint;
	//        self.archiveIndicatorView.alpha = percentageMovedTowardLockin;
	//
	//    }
	
	//    CGFloat translationX = frameX * 0.1f;
	//    self.archiveIndicatorView.arrowTranslationX = translationX;
	
	//    [archiveIndicatorView qs_setFrameIfNotEqual:rArchiveIndicatorView];
	
	[panGestureRecognizer setTranslation:CGPointZero inView:self.contentView.superview];
}


- (BOOL)shouldArchive:(CGRect)rArchiveIndicatorView {
	
	/*Return YES if archive indicator is in indicator position rather than in hint position.*/
	
	return self.lockedInToArchive;
}


- (void)archiveOrRestoreNote {
	
	
	[self animateNoteToArchive:^(void) {
		[self qs_performSelectorViaResponderChain:@selector(archiveOrRestoreNote:) withObject:self];
		self.archiveIndicatorShowing = NO;
		self.archiveIndicatorView.hidden = YES;
		[self removeArchiveIndicatorView];
	}];
	
}


- (void)animateNoteToArchive:(void (^)(void))completion {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		self.archiveIndicatorView.alpha = 0.0f;
		
		self.contentView.alpha = 0.0f;
		
		CGRect r = self.noteView.frame;
		r.origin.x = 0.0f - CGRectGetMaxX(self.bounds);
		self.noteView.frame = r;
		
	} completion:^(BOOL finished) {
		
		if (completion != nil)
			completion();
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}


- (void)animateToEndOfTimelineButtons {
	
	CGRect r = self.noteView.frame;
	CGFloat widthOfButtons = ((VSTimelineCellButtonContainer *)(self.archiveIndicatorView)).widthOfButtons;
	r.origin.x = -widthOfButtons;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"timelineArchiveDelete.showButtonsAnimationDuration"];
	UIViewAnimationOptions options = [app_delegate.theme curveForKey:@"timelineArchiveDelete.showButtonsAnimationCurve"];
	
	[UIView animateWithDuration:duration delay:0.0f options:options animations:^{
		
		self.noteView.frame = r;
		
	} completion:^(BOOL finished) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		
	}];
}


- (void)animateNoteBouncingBack {
	
	self.lockedInToArchive = NO;
	
	CGRect r = self.noteView.frame;
	
	CGRect rLeftPosition = r;
	rLeftPosition.origin.x = 0.0f;
	rLeftPosition.origin.y = 0.0f;
	
	CGFloat bounceCoefficient = [app_delegate.theme floatForKey:@"archiveIndicatorBounceCoefficient"];
	CGFloat bounceX = r.origin.x * bounceCoefficient;
	
	if (r.origin.x > -1.0f) {
		r.origin.x = 0.0f;
		self.noteView.frame = r;
		self.archiveIndicatorShowing = NO;
		self.noteViewOriginX = 0.0f;
		[self removeArchiveIndicatorView];
		return;
	}
	
	if (r.origin.x > -20.0f) {
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
			
			self.noteView.frame = rLeftPosition;
			
		} completion:^(BOOL finished) {
			
			self.archiveIndicatorShowing = NO;
			self.noteViewOriginX = 0.0f;
			[self removeArchiveIndicatorView];
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			
		}];
		
		return;
	}
	
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
		
		self.noteView.frame = rLeftPosition;
		
	} completion:^(BOOL finished) {
		
		[UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
			
			CGRect rBouncePosition = rLeftPosition;
			rBouncePosition.origin.x = bounceX;
			self.noteView.frame = rBouncePosition;
			
		} completion:^(BOOL finished2) {
			
			[UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
				self.noteView.frame = rLeftPosition;
			} completion:^(BOOL finished3) {
				self.archiveIndicatorShowing = NO;
				self.noteViewOriginX = 0.0f;
				[self removeArchiveIndicatorView];
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			}];
		}];
		
	}];
}


- (void)handlePanGestureEnded:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	switch (self.archiveControlStyle) {
			
		case VSArchiveControlStyleRestoreDelete: {
			
			if (self.lockedInToArchive) {
				[self animateToEndOfTimelineButtons];
			}
			else {
				[self animateNoteBouncingBack];
			}
		}
			break;
			
		case VSArchiveControlStyleArchive: {
			
			CGRect rArchiveIndicator = self.archiveIndicatorView.frame;
			BOOL shouldArchive = [self shouldArchive:rArchiveIndicator];
			
			if (shouldArchive) {
				[self archiveOrRestoreNote];
			}
			else {
				[self animateNoteBouncingBack];
			}
		}
			break;
			
		default:
			break;
	}
}


- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
	
	self.archiveIndicatorShowing = YES;
	
	[self adjustAnchorPointForGestureRecognizer:panGestureRecognizer];
	
	UIGestureRecognizerState gestureRecognizerState = panGestureRecognizer.state;
	
	switch (gestureRecognizerState) {
			
		case UIGestureRecognizerStateBegan:
			[self.delegate timelineCellDidBeginPanning:self];
			
			if (self.archiveControlStyle == VSArchiveControlStyleRestoreDelete) {
				[[NSNotificationCenter defaultCenter] postNotificationName:VSTimelineCellPanGestureDidBeginNotification object:self];
			}
			
			[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateChanged:
			if ([self.delegate timelineCellIsPanning:self])
				[self handlePanGestureStateBeganOrChanged:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self handlePanGestureEnded:panGestureRecognizer];
			[self.delegate timelineCellDidCancelOrEndPanning:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:VSTimelineCellPanGestureDidEndNotification object:self];
			break;
			
		default:
			break;
	}
}


- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)panGestureRecognizer {
	
	if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		
		CGPoint locationInView = [panGestureRecognizer locationInView:self.noteView];
		CGPoint locationInSuperview = [panGestureRecognizer locationInView:self.noteView.superview];
		
		self.noteView.layer.anchorPoint = CGPointMake(locationInView.x / self.noteView.bounds.size.width, locationInView.y / self.noteView.bounds.size.height);
		self.noteView.center = locationInSuperview;
	}
}


- (void)handlePanGestureRecognizerDidBeginNotification:(NSNotification *)note {
	
	if ([note object] != self)
		[self cancelPanHandling];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	if (app_delegate.sidebarShowing)
		return NO;
	
	if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
		return NO;
	
	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
	
	/*Ignore vertical pans -- so the UIScrollView can scroll.*/
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	
	if (translation.x > 0.0f && !self.lockedInToArchive)
		return NO;
	
	if (gestureRecognizer.numberOfTouches > 1)
		return NO;
	
	if (![self.delegate timelineCellShouldBeginPanning:self]) {
		gestureRecognizer.enabled = NO;
		return NO;
	}
	
	[self.delegate timelineCellWillBeginPanning:self];
	
	return YES;
}


#pragma mark - Archive Indicator View

- (void)archiveNote:(id)sender {
	
	[self archiveOrRestoreNote];
}


- (void)didConfirmDeleteNote:(id)sender {
	
	[self.delegate timelineCellDidDelete:self];
	
}


- (void)cancelConfirmDeleteNote:(id)sender {
	[self animateNoteBouncingBack];
}


- (UIScrollView *)enclosingScrollView {
	
	UIView *nomad = self;
	while (nomad != nil) {
		if ([nomad isKindOfClass:[UIScrollView class]])
			return (UIScrollView *)nomad;
		nomad = nomad.superview;
	}
	
	return nil;
}


- (UIView *)viewForActionSheet {
	
	UIScrollView *scrollView = [self enclosingScrollView];
	return scrollView.superview;
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		[self didConfirmDeleteNote:nil];
	}
	else {
		[self cancelConfirmDeleteNote:nil];
	}
}


- (void)confirmDeleteNote:(id)sender {
	
	VSSendUIEventHappenedNotification();
	
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Note", nil) otherButtonTitles:nil];
	
	[self.actionSheet showInView:[self viewForActionSheet]];
}


- (UIView *)createArchiveView {
	
	VSArchiveIndicatorView *archiveView = [[VSArchiveIndicatorView alloc] initWithFrame:CGRectZero];
	
	archiveView.font = [app_delegate.theme fontForKey:@"archiveIndicatorFontNonItalic"];
	if (self.archiveIndicatorUseItalicFont)
		archiveView.font = [app_delegate.theme fontForKey:@"archiveIndicatorFont"];
	
	archiveView.archiveIndicatorState = VSArchiveIndicatorStateHinting;
	archiveView.text = self.archiveActionText;
	
	CGRect r = archiveView.frame;
	r.size = [archiveView sizeThatFits:CGSizeZero]; /*ignores parameter*/
	r = CGRectCenteredVerticallyInRect(r, self.bounds);
	archiveView.frame = r;
	
	return archiveView;
	
}


- (UIView *)createRestoreDeleteView {
	
	VSTimelineCellButton *deleteButton = [[VSTimelineCellButton alloc] initWithFrame:CGRectZero themeSpecifier:@"timelineArchiveDelete.delete" title:NSLocalizedString(@"Delete", @"Delete")];
	[deleteButton addTarget:self action:@selector(confirmDeleteNote:) forControlEvents:UIControlEventTouchUpInside];
	
	//	NSString *archiveThemeSpecifier = @"timelineArchiveDelete.archive";
	//	if (!self.archiveIndicatorUseItalicFont)
	//		archiveThemeSpecifier = @"timelineArchiveDelete.restore";
	VSTimelineCellButton *archiveButton = [[VSTimelineCellButton alloc] initWithFrame:CGRectZero themeSpecifier:@"timelineArchiveDelete.restore" title:self.archiveActionText];
	[archiveButton addTarget:self action:@selector(archiveNote:) forControlEvents:UIControlEventTouchUpInside];
	
	VSTimelineCellButtonContainer *archiveDeleteView = [[VSTimelineCellButtonContainer alloc] initWithFrame:CGRectZero buttons:@[deleteButton, archiveButton] themeSpecifier:@"timelineArchiveDelete"];
	
	CGRect rContainer = CGRectZero;
	rContainer.size.width = archiveDeleteView.widthOfButtons;
	rContainer.size.height = CGRectGetHeight(self.bounds);
	rContainer.origin.x = CGRectGetMaxX(self.bounds) - CGRectGetWidth(rContainer);
	archiveDeleteView.frame = rContainer;
	
	return archiveDeleteView;
}


- (UIView *)createArchiveIndicatorView {
	
	if (self.archiveIndicatorView == nil) {
		
		switch (self.archiveControlStyle) {
				
			case VSArchiveControlStyleArchive:
				self.archiveIndicatorView = [self createArchiveView];
				break;
				
			case VSArchiveControlStyleRestoreDelete:
				self.archiveIndicatorView = [self createRestoreDeleteView];
				break;
				
			default:
				break;
		}
	}
	
	[self.contentView insertSubview:self.archiveIndicatorView belowSubview:self.noteView];
	
	return self.archiveIndicatorView;
}


- (void)removeArchiveIndicatorView {
	
	//    self.archiveIndicatorView.arrowTranslationX = 0.0f;
	[self.archiveIndicatorView removeFromSuperview];
	self.archiveIndicatorView = nil;
}


#pragma mark - Thumbnail

- (void)updateThumbnailView {
	
	if (self.thumbnail == nil) {
		self.thumbnailView.image = nil;
		self.thumbnailView.hidden = YES;
	}
	else {
		self.thumbnailView.image = self.thumbnail;
		self.thumbnailView.hidden = NO;
		[self.thumbnailView setNeedsDisplay];
	}
}


#pragma mark UIView

- (CGRect)thumbnailRect {
	
	if (!self.hasThumbnail)
		return CGRectZero;
	
	VSTimelineCellRects rects = [[self class] rectsWithTitle:self.title text:self.text links:self.links  useItalicFonts:self.useItalicFonts hasThumbnail:self.hasThumbnail truncateIfNeeded:self.truncateIfNeeded];
	
	CGRect rBounds = self.bounds;
	CGRect rThumbnail = rects.thumbnailRect;
	if (layoutBits.thumbnailCenterVertically) {
		rThumbnail = CGRectCenteredVerticallyInRect(rThumbnail, rBounds);
		rThumbnail.size = rects.thumbnailRect.size;
	}
	
	rThumbnail = [VSThumbnail thumbnailRectForApparentRect:rThumbnail];
	
	return rThumbnail;
}


- (void)layoutSubviews {
	
	[super layoutSubviews];
	if (self.archiveIndicatorShowing)
		return;
	
	
	CGRect rBounds = self.bounds;
	
	[self.backgroundView qs_setFrameIfNotEqual:rBounds];
	[self.selectedBackgroundView qs_setFrameIfNotEqual:rBounds];
	[self.noteView qs_setFrameIfNotEqual:rBounds];
	
	VSTimelineCellRects rects = [[self class] rectsWithTitle:self.title text:self.text links:self.links  useItalicFonts:self.useItalicFonts hasThumbnail:self.hasThumbnail truncateIfNeeded:self.truncateIfNeeded];
	
	CGRect rText = rects.textRect;
	
	if (layoutBits.centerText) {
		CGFloat height = rText.size.height;
		rText = CGRectCenteredVerticallyInRect(rText, rBounds);
		rText.size.height = height;
	}
	
	rText = [[self.textView class] fullRectForApparentRect:rText];
	
	[self.textView qs_setFrameIfNotEqual:rText];
	
	if (self.hasThumbnail) {
		CGRect rThumbnail = self.thumbnailRect;
		[self.thumbnailView qs_setFrameIfNotEqual:rThumbnail];
	}
	
	self.truncatedIndicatorImageView.hidden = !self.textView.truncated;
	
	if (!self.truncatedIndicatorImageView.hidden) {
		CGSize indicatorImageSize = self.truncatedIndicatorImageView.frame.size;
		CGRect rTruncationIndicator = CGRectZero;
		rTruncationIndicator.size = indicatorImageSize;
		rTruncationIndicator.origin.x = rects.textRect.origin.x + self.textView.widthOfTruncatedLine;
		CGFloat fudgeY = [app_delegate.theme floatForKey:@"noteTruncationIndicatorFudgeY"];
		rTruncationIndicator.origin.y = (CGRectGetMaxY(rects.textRect) - indicatorImageSize.height) + fudgeY;
		[self.truncatedIndicatorImageView qs_setFrameIfNotEqual:rTruncationIndicator];
	}
	
}


#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
	if (!self.isSampleText)
		return self.title;
	return [NSString stringWithFormat:@"%@\n%@", self.title, self.text];
}


- (UIAccessibilityTraits)accessibilityTraits {
	return [super accessibilityTraits] | UIAccessibilityTraitPlaysSound;
}


- (NSString *)accessibilityHint
{
	if (!self.isSampleText)
		return NSLocalizedString(@"Double tap to edit note. Draggable. Double tap and hold to reorder note. Wait for the sound and then drag to re-arrange.", nil);
	return nil;
}


- (CGPoint)accessibilityActivationPoint {
	return CGPointMake(CGRectGetMidX(self.accessibilityFrame), CGRectGetMidY(self.accessibilityFrame) - (self.bounds.size.height / 2.0f - 10.0f));
}


#pragma mark - Animation Support

- (UIImage *)imageForAnimationWithThumbnailHidden:(BOOL)thumbnailHidden {
	
	UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
	
	BOOL originalHideThumbnail = self.hideThumbnail;
	
	self.renderingForAnimation = YES;
	self.hideThumbnail = thumbnailHidden;
	
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	self.renderingForAnimation = NO;
	self.hideThumbnail = originalHideThumbnail;
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


- (UIImage *)imageForDetailPanBackAnimation {
	
	BOOL originalOpaque = self.isOpaque;
	BOOL originalContentViewOpaque = self.contentView.isOpaque;
	BOOL originalBackgroundViewOpaque = self.backgroundView.isOpaque;
	BOOL originalNoteViewOpaque = self.noteView.isOpaque;
	UIColor *originalBackgroundViewColor = self.backgroundView.backgroundColor;
	UIColor *originalBackgroundColor = self.backgroundColor;
	UIColor *originalNoteViewBackgroundColor = self.noteView.backgroundColor;
	UIColor *originalContentViewBackgroundColor = self.contentView.backgroundColor;
	BOOL originalFirstSubviewOpaque = ((UIView *)[self.subviews firstObject]).isOpaque;
	UIColor *originalFirstSubviewBackgroundColor = ((UIView *)[self.subviews firstObject]).backgroundColor;
	
	self.highlighted = NO;
	self.backgroundView.backgroundColor = [UIColor clearColor];
	self.backgroundView.opaque = NO;
	self.contentView.opaque = NO;
	self.contentView.backgroundColor = [UIColor clearColor];
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	self.noteView.opaque = NO;
	self.noteView.backgroundColor = [UIColor clearColor];
	((UIView *)[self.subviews firstObject]).opaque = NO;
	((UIView *)[self.subviews firstObject]).backgroundColor = [UIColor clearColor];
	
	UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
	
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.opaque = originalOpaque;
	self.contentView.opaque = originalContentViewOpaque;
	self.backgroundView.opaque = originalBackgroundViewOpaque;
	self.backgroundView.backgroundColor = originalBackgroundViewColor;
	self.backgroundColor = originalBackgroundColor;
	self.noteView.opaque = originalNoteViewOpaque;
	self.noteView.backgroundColor = originalNoteViewBackgroundColor;
	((UIView *)[self.subviews firstObject]).opaque = originalFirstSubviewOpaque;
	((UIView *)[self.subviews firstObject]).backgroundColor = originalFirstSubviewBackgroundColor;
	self.contentView.backgroundColor = originalContentViewBackgroundColor;
	
	return image;
}


@end
