//
//  VSTextView.m
//  Vesper
//
//  Created by Brent Simmons on 2/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "VSTextView.h"
#import "VSNoteTextRenderer.h"
#import "UIView+RSExtras.h"
#import "VSTextRendererView.h"


static UIEdgeInsets kEdgeInsets = {4.0f, 4.0f, 4.0f, 4.0f};

@interface VSTextView ()

@property (nonatomic, assign) BOOL highlightingLink;
@property (nonatomic, assign, readwrite) BOOL truncated;
@property (nonatomic, assign, readwrite) CGFloat widthOfTruncatedLine;
@property (nonatomic, assign) BOOL didCalculateWidthOfTruncatedLine;
@property (nonatomic, strong) NSArray *linkRects;
@property (nonatomic, strong) NSString *highlightedLink;
@property (nonatomic, strong) id highlightedLinkUniqueID;
@property (nonatomic, strong) VSTextRendererView *textRendererView;
@end


@implementation VSTextView


#pragma mark Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.clipsToBounds = YES;
	_highlightedLinkBackgroundColor = [app_delegate.theme colorForKey:@"noteLinkSelectedBackgroundColor"];
	_edgeInsets = kEdgeInsets;
	
	_textRendererView = [[VSTextRendererView alloc] initWithFrame:CGRectZero];
	[self addSubview:_textRendererView];
	
	self.backgroundColor = [UIColor clearColor];//[app_delegate.theme colorForKey:@"notesBackgroundColor"];
	
	[self addObserver:self forKeyPath:@"highlightedLinkUniqueID" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"highlightingLink" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"textRenderer" options:0 context:NULL];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"highlightedLinkUniqueID"];
	[self removeObserver:self forKeyPath:@"highlightingLink"];
	[self removeObserver:self forKeyPath:@"textRenderer"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"highlightedLinkUniqueID"])
		self.textRendererView.highlightedLinkID = self.highlightedLinkUniqueID;
	
	else if ([keyPath isEqualToString:@"highlightingLink"])
		self.textRendererView.highlightingLink = self.highlightingLink;
	
	else if ([keyPath isEqualToString:@"textRenderer"]) {
		self.textRendererView.textRenderer = self.textRenderer;
		self.truncated = self.textRenderer.truncated;
		self.didCalculateWidthOfTruncatedLine = NO;
		self.widthOfTruncatedLine = 0.0f;
		self.highlightedLink = nil;
		[self unhighlightLink];
		[self setNeedsDisplay];
	}
	
	[self setNeedsLayout];
}


#pragma mark Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (QSIsEmpty(self.textRenderer.links)) {
		[super touchesBegan:touches withEvent:event];
		return;
	}
	
	UITouch *touch = [[event touchesForView:self] anyObject];
	if (touch == nil) {
		[self unhighlightLink];
		return;
	}
	
	CTRunRef touchedRun = [self runForPoint:[touch locationInView:self]];
	if (touchedRun == nil || ![self runHasLink:touchedRun]) {
		[self unhighlightLink];
		return;
	}
	
	NSString *linkForRun = [self linkForRun:touchedRun];
	self.highlightedLink = linkForRun;
	self.highlightedLinkUniqueID = [self uniqueIDForRun:touchedRun];
	[self highlightLink];
	
	NSArray *rectsForRun = [self rectsForSurroundingRunsForRun:touchedRun];
	self.linkRects = rectsForRun;
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (QSIsEmpty(self.textRenderer.links)) {
		[super touchesMoved:touches withEvent:event];
		return;
	}
	
	UITouch *touch = [[event touchesForView:self] anyObject];
	if (touch == nil) {
		[self unhighlightLink];
		return;
	}
	
	if ([self pointIsInLink:[touch locationInView:self]])
		[self highlightLink];
	else
		[self unhighlightLink];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self performSelector:@selector(unhighlightLink) withObject:self afterDelay:0.1f];
	
	if (QSIsEmpty(self.textRenderer.links)) {
		[super touchesEnded:touches withEvent:event];
		return;
	}
	
	if (QSStringIsEmpty(self.highlightedLink))
		[self qs_performSelectorViaResponderChain:@selector(textLabelTapped:) withObject:self];
	else
		[self qs_performSelectorViaResponderChain:@selector(openLinkInBrowser:) withObject:self.highlightedLink];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self unhighlightLink];
	
	if (QSIsEmpty(self.textRenderer.links)) {
		[super touchesCancelled:touches withEvent:event];
		return;
	}
}


#pragma mark Highlighting Links

- (void)highlightLink {
	self.highlightingLink = YES;
	[self setNeedsDisplay];
}


- (void)unhighlightLink {
	self.highlightingLink = NO;
	self.linkRects = nil;
	self.highlightedLink = nil;
	self.highlightedLinkUniqueID = nil;
	[self setNeedsDisplay];
}


#pragma mark AttributedText

- (NSUInteger)indexOfCharacterAtPoint:(CGPoint)point {
	
	point.y = self.bounds.size.height - point.y; /*CoreText is flipped.*/
	
	NSArray *lines = (__bridge NSArray *)CTFrameGetLines(self.textRenderer.frameref);
	CGPoint origins[[lines count]];
	CTFrameGetLineOrigins(self.textRenderer.frameref, CFRangeMake(0, (NSInteger)[lines count]), origins);
	
	for (NSInteger i = 0; i < (NSInteger)[lines count]; i++) {
		CGPoint oneOrigin = origins[i];
		
		CGFloat ascent, descent, leading;
		CTLineGetTypographicBounds((__bridge CTLineRef)(lines[(NSUInteger)i]), &ascent, &descent, &leading);
		oneOrigin.y -= descent;
		
		if (point.y > oneOrigin.y) {
			CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:(NSUInteger)i];
			return (NSUInteger)CTLineGetStringIndexForPosition(line, point);
		}
	}
	return  NSNotFound;
}


- (BOOL)runHasLink:(CTRunRef)run {
	return !QSStringIsEmpty([self linkForRun:run]);
}


- (NSDictionary *)attributesForRun:(CTRunRef)run {
	return (__bridge NSDictionary *)CTRunGetAttributes(run);
}


- (NSString *)linkForRun:(CTRunRef)run {
	return [self attributesForRun:run][VSLinkAttributeName];
}


- (NSString *)uniqueIDForRun:(CTRunRef)run {
	return [self attributesForRun:run][VSLinkUniqueIDAttributeName];
}


- (CTRunRef)runForPoint:(CGPoint)point {
	
	point.y = self.bounds.size.height - point.y; /*CoreText is flipped.*/
	
	NSArray *lines = (__bridge NSArray *)CTFrameGetLines(self.textRenderer.frameref);
	CGPoint origins[[lines count]];
	CTFrameGetLineOrigins(self.textRenderer.frameref, CFRangeMake(0, (NSInteger)[lines count]), origins);
	
	for (NSInteger i = 0; i < (NSInteger)[lines count]; i++) {
		
		CGPoint oneOrigin = origins[i];
		CTLineRef oneLine = (__bridge CTLineRef)lines[(NSUInteger)i];
		//		NSLog(@"oneOrigin.y %f", oneOrigin.y);
		
		
		CGFloat ascent, descent, leading;
		CTLineGetTypographicBounds(oneLine, &ascent, &descent, &leading);
		//		NSLog(@"ascent %f descent %f leading %f", ascent, descent, leading);
		oneOrigin.y -= descent;
		//		NSLog(@"origin plus descent: %f", oneOrigin.y);
		
		if (point.y > oneOrigin.y) {
			
			CFIndex stringIndex = CTLineGetStringIndexForPosition(oneLine, point);
			for (id runObject in (__bridge NSArray *)CTLineGetGlyphRuns(oneLine)) {
				
				CTRunRef oneRun = (__bridge CTRunRef)runObject;
				CFRange stringRangeForRun = CTRunGetStringRange(oneRun);
				if (stringIndex >= stringRangeForRun.location && stringIndex < stringRangeForRun.location + stringRangeForRun.length)
					return oneRun;
			}
			
			return nil; /*Found line but no run*/
		}
	}
	
	return  nil;
}


- (NSArray *)rectsForSurroundingRunsForRun:(CTRunRef)run {
	
	/*Return array of CGRect of runs next to this run that have the same link.
	 The array will include a rect for the run itself.
	 The runs will be in top-to-bottom order (visually).
	 The run must have a VSLinkAttributeName attribute.*/
	
	
	NSString *link = [self linkForRun:run];
	if (QSStringIsEmpty(link))
		return nil;
	
	NSArray *lines = (__bridge NSArray *)CTFrameGetLines(self.textRenderer.frameref);
	CGPoint origins[[lines count]];
	CTFrameGetLineOrigins(self.textRenderer.frameref, CFRangeMake(0, 0), origins);
	
	NSMutableArray *rects = [NSMutableArray new];
	BOOL foundRun = NO;
	NSUInteger lineIndex = 0;
	
	for (id oneLineObj in lines) {
		
		CTLineRef oneLine = (__bridge CTLineRef)oneLineObj;
		
		for (id runObject in (__bridge NSArray *)CTLineGetGlyphRuns(oneLine)) {
			
			CTRunRef oneRun = (__bridge CTRunRef)runObject;
			
			if (oneRun == run)
				foundRun = YES;
			
			NSString *oneLink = [self linkForRun:oneRun];
			if ([link isEqualToString:oneLink]) {
				
				CGRect runBounds = CGRectZero;
				
				CGFloat leading, ascent, descent;
				runBounds.size.width = (CGFloat)CTRunGetTypographicBounds(oneRun, CFRangeMake(0, 0), &ascent, &descent, &leading);
				runBounds.size.height = ascent + descent;
				
				CGFloat xOffset = CTLineGetOffsetForStringIndex(oneLine, CTRunGetStringRange(oneRun).location, NULL);
				runBounds.origin.x = origins[lineIndex].x + xOffset;
				runBounds.origin.y = origins[lineIndex].y;
				runBounds.origin.y -= descent;
				
				[rects addObject:[NSValue valueWithCGRect:runBounds]];
			}
			else {
				if (foundRun)
					return rects;
				[rects removeAllObjects];
			}
		}
		
		lineIndex++;
	}
	
	if (foundRun)
		return rects;
	
	return nil;
}


- (NSDictionary *)attributesOfCharacterAtPoint:(CGPoint)point {
	
	NSUInteger ix = [self indexOfCharacterAtPoint:point];
	if (ix == NSNotFound || ix >= self.textRenderer.fullText.length)
		return nil;
	
	NSRange range;
	return [self.textRenderer.attributedText attributesAtIndex:ix effectiveRange:&range];
}


- (BOOL)pointIsInLink:(CGPoint)point {
	
	point.y = self.bounds.size.height - point.y; /*CoreText is flipped.*/
	
	NSDictionary *attributes = [self attributesOfCharacterAtPoint:point];
	if (QSStringIsEmpty(attributes[VSLinkAttributeName]))
		return NO;
	return YES;
}


#pragma mark Truncation

- (CGFloat)widthOfTruncatedLine {
	
	if (!self.truncated)
		return 0.0f;
	
	if (self.didCalculateWidthOfTruncatedLine)
		return _widthOfTruncatedLine;
	
	self.didCalculateWidthOfTruncatedLine = YES;
	
	NSUInteger maximumNumberOfLines = self.textRenderer.maximumNumberOfLines;
	
	NSArray *lines = (__bridge NSArray *)CTFrameGetLines(self.textRenderer.frameref);
	
	if ([lines count] < maximumNumberOfLines) {
		NSAssert([lines count] >= maximumNumberOfLines, @"the number of lines is less than the maximum, but supposedly the text is truncated");
		return 0.0f;
	}
	
	CTLineRef truncatedLine = (__bridge CTLineRef)[lines objectAtIndex:maximumNumberOfLines - 1];
	NSAssert(truncatedLine != NULL, @"truncatedLine is NULL");
	
	_widthOfTruncatedLine = (CGFloat)CTLineGetTypographicBounds(truncatedLine, NULL, NULL, NULL);
	CGFloat trailingWhitespaceWidth = (CGFloat)CTLineGetTrailingWhitespaceWidth(truncatedLine);
	_widthOfTruncatedLine -= trailingWhitespaceWidth;
#if __LP64__
	_widthOfTruncatedLine = ceil(_widthOfTruncatedLine);
#else
	_widthOfTruncatedLine = ceilf(_widthOfTruncatedLine);
#endif
	
	/*Check for empty string*/
	
	if (_widthOfTruncatedLine < 10.0f) { /*10.0f is arbitrary: looking for a short line with just \n (or similar)*/
		CFRange cfRange = CTLineGetStringRange(truncatedLine);
		NSRange range = NSMakeRange((NSUInteger)cfRange.location, (NSUInteger)cfRange.length);
		NSString *lineString = [self.textRenderer.fullText substringWithRange:range];
		lineString = [lineString qs_stringByTrimmingWhitespace];
		if (QSStringIsEmpty(lineString))
			_widthOfTruncatedLine = 0.0f;
	}
	
	return _widthOfTruncatedLine;
}


#pragma mark Layout

- (void)layoutSubviews {
	CGRect r = [[self class] textRectForBounds:self.bounds];
	[self.textRendererView qs_setFrameIfNotEqual:r];
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return NO;
}


- (void)flipContext:(CGContextRef)context rect:(CGRect)rect {
	
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	
	CGContextTranslateCTM(context, 0.0f, rect.origin.y );
	CGContextScaleCTM(context, 1.0f, -1.0f );
	CGContextTranslateCTM(context, 0.0f, - ( rect.origin.y + rect.size.height ) );
	
}

+ (CGFloat)linkCornerRadius {
	return [app_delegate.theme floatForKey:@"noteLinkCornerRadius"];
}


typedef enum {
	VSLeftSide,
	VSRightSide,
	VSSideBoth,
	VSSideNeither
} VSSide;


- (void)drawRoundedCornerInRect:(CGRect)rect side:(VSSide)side cornerRadius:(CGFloat)cornerRadius {
	
	/*The rect is relative to the inner text. Take kEdgeInsets into account.*/
	
	rect.origin.y += kEdgeInsets.top;
	rect.origin.x += kEdgeInsets.left;
	
	static const CGFloat extraSpaceForRoundedCorners = 3.0f;
	CGFloat offsetToHideRoundedCorner = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	
	CGRect roundRect = rect;
	
	switch (side) {
			
		case VSRightSide:
			roundRect.origin.x -= extraSpaceForRoundedCorners;
			roundRect.size.width += (extraSpaceForRoundedCorners * 2);
			break;
			
		case VSLeftSide:
			roundRect.size.width += offsetToHideRoundedCorner;
			roundRect.origin.x -= extraSpaceForRoundedCorners;
			break;
			
		case VSSideBoth:
			roundRect.origin.x -= extraSpaceForRoundedCorners;
			roundRect.size.width += (extraSpaceForRoundedCorners * 2);
			break;
			
		case VSSideNeither:
			roundRect.origin.x -= extraSpaceForRoundedCorners;
			roundRect.size.width += (extraSpaceForRoundedCorners * 2);
			break;
			
		default:
			break;
	}
	
#if __LP64__
	roundRect.origin.x = floor(roundRect.origin.x);
	roundRect.origin.x += 0.5f;
	roundRect.origin.y = floor(roundRect.origin.y);
	roundRect.origin.y += 0.5f;
	roundRect.size.width = floor(roundRect.size.width);
	roundRect.size.height = floor(roundRect.size.height);
#else
	roundRect.origin.x = floorf(roundRect.origin.x);
	roundRect.origin.x += 0.5f;
	roundRect.origin.y = floorf(roundRect.origin.y);
	roundRect.origin.y += 0.5f;
	roundRect.size.width = floorf(roundRect.size.width);
	roundRect.size.height = floorf(roundRect.size.height);
#endif
	
	if (side == VSSideNeither) {
		[self.highlightedLinkBackgroundColor set];
		UIRectFill(roundRect);
		return;
	}
	
	if (side == VSRightSide) {
		CGRect squareRect = roundRect;
		squareRect.origin.x = rect.origin.x;
		squareRect.origin.x -= extraSpaceForRoundedCorners;
		squareRect.size.width = 4.0f;
#if __LP64__
		squareRect.origin.x = floor(squareRect.origin.x);
#else
		squareRect.origin.x = floorf(squareRect.origin.x);
#endif
		squareRect.origin.x += 0.5f;
		[self.highlightedLinkBackgroundColor set];
		UIRectFill(squareRect);
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIBezierPath *roundRectPath = [UIBezierPath bezierPathWithRoundedRect:roundRect cornerRadius:cornerRadius];
	CGContextAddPath(context, roundRectPath.CGPath);
	[self.highlightedLinkBackgroundColor set];
	CGContextFillPath(context);
}


+ (CGRect)textRectForBounds:(CGRect)bounds {
	
	/*Bounds is full rect. Returns apparent rect.*/
	
	CGRect r = bounds;
	
	r.origin.y += kEdgeInsets.top;
	r.size.height -= (kEdgeInsets.top + kEdgeInsets.bottom);
	r.origin.x += kEdgeInsets.left;
	r.size.width -= (kEdgeInsets.left + kEdgeInsets.right);
	
	return r;
}


+ (CGRect)fullRectForApparentRect:(CGRect)apparentRect {
	
	CGRect r = apparentRect;
	
	r.origin.y -= kEdgeInsets.top;
	r.size.height += (kEdgeInsets.top + kEdgeInsets.bottom);
	r.origin.x -= kEdgeInsets.left;
	r.size.width += (kEdgeInsets.left + kEdgeInsets.right);
	
	return r;
}


- (void)drawRect:(CGRect)rect {
	
	if (self.highlightingLink && !QSIsEmpty(self.linkRects)) {
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSaveGState(context);
		
		[self flipContext:context rect:rect];
		
		[self.highlightedLinkBackgroundColor set];
		for (NSValue *oneValue in self.linkRects) {
			
			BOOL isFirst = (oneValue == self.linkRects[0]);
			BOOL isLast = (oneValue == [self.linkRects lastObject]);
			
			CGRect oneRect = [oneValue CGRectValue];
			//			oneRect = CGRectInset(oneRect, -2.0f, -3.0f);
			CGFloat cornerRadius = [[self class] linkCornerRadius];
			
			if (isFirst && isLast)
				[self drawRoundedCornerInRect:oneRect side:VSSideBoth cornerRadius:cornerRadius];
			
			else if (isFirst)
				[self drawRoundedCornerInRect:oneRect side:VSLeftSide cornerRadius:cornerRadius];
			
			else if (isLast)
				[self drawRoundedCornerInRect:oneRect side:VSRightSide cornerRadius:cornerRadius];
			
			else
				[self drawRoundedCornerInRect:oneRect side:VSSideNeither cornerRadius:cornerRadius];
		}
		
		CGContextRestoreGState(context);
	}
}


@end

