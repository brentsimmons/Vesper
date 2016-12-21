//
//  VSNoteTextRenderer.m
//  Vesper
//
//  Created by Brent Simmons on 5/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "VSNoteTextRenderer.h"
#import "VSTypographySettings.h"


typedef struct {
	CGFloat lineSpacingAfterTitle;
	CGFloat lineSpacing;
	NSUInteger maximumNumberOfLines;
} VSNoteTextRendererLayoutBits;


static VSNoteTextRendererLayoutBits noteTextRendererLayoutBits(VSTheme *theme) {
	
	VSNoteTextRendererLayoutBits layoutBits;
	
#if !TARGET_OS_IPHONE
	
	layoutBits.lineSpacingAfterTitle = [theme floatForKey:@"MainWindow.Timeline.note.titleLineSpacing"];
	layoutBits.lineSpacing = [theme floatForKey:@"MainWindow.Timeline.note.lineSpacing"];
	layoutBits.maximumNumberOfLines = (NSUInteger)[theme integerForKey:@"MainWindow.Timeline.note.maximumNumberOfLines"];
	
#else
	
	layoutBits.lineSpacingAfterTitle = [theme floatForKey:@"noteTitleLineSpacing"];
	layoutBits.lineSpacing = [theme floatForKey:@"noteLineSpacing"];
	layoutBits.maximumNumberOfLines = (NSUInteger)[theme integerForKey:@"noteMaximumNumberOfLines"];
	
#endif
	
	return layoutBits;
}


@interface VSNoteTextRenderer ()

@property (nonatomic, assign, readwrite) CGFloat height;
@property (nonatomic, assign, readwrite) BOOL truncated;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *text;
@property (nonatomic, strong, readwrite) NSString *fullText;
@property (nonatomic, strong, readwrite) NSArray *links;
@property (nonatomic, assign, readonly) CGFloat lineSpacing;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign, readwrite) CTFramesetterRef framesetter;
@property (nonatomic, assign, readwrite) CTFrameRef frameref;
@property (nonatomic, strong, readwrite) NSAttributedString *attributedText;
@property (nonatomic, assign) BOOL useItalicFonts;
@property (nonatomic, assign, readonly) BOOL truncateIfNeeded;

@end


@implementation VSNoteTextRenderer


static VSNoteTextRendererLayoutBits layoutBits;
static QS_COLOR *titleColor = nil;
static QS_COLOR *textColor = nil;
static QS_COLOR *linkColor = nil;
static QS_COLOR *linkHighlightedColor = nil;


+ (void)initialize {
	
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		
		layoutBits = noteTextRendererLayoutBits(app_delegate.theme);
		
		titleColor = [app_delegate.theme colorForKey:@"noteTitleFontColor"];
		textColor = [app_delegate.theme colorForKey:@"noteFontColor"];
		linkColor = [app_delegate.theme colorForKey:@"noteLinkColor"];
		linkHighlightedColor = [app_delegate.theme colorForKey:@"noteLinkSelectedColor"];
	});
}


#pragma mark Init

- (instancetype)initWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links width:(CGFloat)textWidth useItalicFonts:(BOOL)useItalicFonts truncateIfNeeded:(BOOL)truncateIfNeeded {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	if (app_delegate.typographySettings.useSmallCaps)
		title = [title lowercaseString];
	_title = title;
	_text = text;
	_links = links;
	_width = textWidth;
	_height = 0.0f;
	_useItalicFonts = useItalicFonts;
	_truncateIfNeeded = truncateIfNeeded;
	
	if (title == nil)
		_fullText = text;
	else if (text == nil)
		_fullText = _title;
	else if (title != nil && text != nil)
		_fullText = [NSString stringWithFormat:@"%@\n%@", title, text];
	
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	
	if (_framesetter != nil)
		CFRelease(_framesetter);
	
	if (_frameref != nil)
		CFRelease(_frameref);
}

#pragma mark Accessors

- (CGFloat)height {
	
	if ([self.fullText length] < 1)
		return 0.0f;
	if (_height > 0.1f)
		return _height;
	
	_height = [self calculateHeight];
	return _height;
}


- (BOOL)truncated {
	if (!self.truncateIfNeeded)
		return NO;
	(void)self.height; /*Sets self.truncated if not set yet*/
	return _truncated;
}


- (NSUInteger)maximumNumberOfLines {
	if (self.truncateIfNeeded)
		return layoutBits.maximumNumberOfLines;
	return 0; /*Means don't truncate*/
}


NSString *VSLinkAttributeName = @"vs_link";
NSString *VSLinkUniqueIDAttributeName = @"vs_uniqueID";


- (void)renderTextInRect:(CGRect)rect highlightedLinkID:(id)linkUniqueID {
	
	if (linkUniqueID == nil) {
		[self renderTextInRect:rect];
		return;
	}
	
	NSMutableAttributedString *attString = [self.attributedText mutableCopy];
	
	[attString enumerateAttributesInRange:NSMakeRange(0, [attString length]) options:0 usingBlock:^(NSDictionary *attributes, NSRange range, BOOL *stop) {
		
		id oneUniqueID = attributes[VSLinkUniqueIDAttributeName];
		if (![linkUniqueID isEqual:oneUniqueID])
			return;
		
		NSMutableDictionary *attributesHighlighted = [attributes mutableCopy];
		attributesHighlighted[NSForegroundColorAttributeName] = linkHighlightedColor;
		attributesHighlighted[NSKernAttributeName] = [NSNull null];
		
		[attString setAttributes:attributesHighlighted range:range];
	}];
	
	
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
	
	CGRect r = CGRectZero;
	r.size = CGSizeMake(self.width, self.height);
	
	CGPathRef path = CGPathCreateWithRect(r, NULL);
	NSDictionary *options = [self optionsDictionaryForRect:r];
	
	CTFrameRef frameref = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, (CFIndex)[attString length]), path, (__bridge CFDictionaryRef)options);
	
#if !TARGET_OS_IPHONE
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
#else
	CGContextRef context = UIGraphicsGetCurrentContext();
#endif
	CGContextSaveGState(context);
	
	[self flipContext:context rect:rect];
	CTFrameDraw(frameref, context);
	
	CGContextRestoreGState(context);
	
	CFRelease(path);
	CFRelease(frameref);
	CFRelease(framesetter);
}


- (QS_FONT *)titleFont {
	return self.useItalicFonts ? app_delegate.typographySettings.titleFontArchived : app_delegate.typographySettings.titleFont;
	//    return self.useItalicFonts ? titleFontItalic : titleFont;
}


- (QS_FONT *)textFont {
	return self.useItalicFonts ? app_delegate.typographySettings.bodyFontArchived : app_delegate.typographySettings.bodyFont;
	//    return self.useItalicFonts ? textFontItalic : textFont;
}


static int32_t linkIDCounter = 0;

- (NSAttributedString *)attributedText {
	
	if (_attributedText != nil)
		return _attributedText;
	
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineSpacing:layoutBits.lineSpacing];
	[paragraphStyle setParagraphSpacing:0.0f];
	[paragraphStyle setParagraphSpacingBefore:0.0f];
	
	NSDictionary *attributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : [self textFont], NSParagraphStyleAttributeName : paragraphStyle, NSKernAttributeName : [NSNull null]};
	
	NSString *text = self.fullText;
	if (text == nil)
		text = @"";
	
	NSUInteger titleLength = 0;
	
	NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:self.fullText attributes:attributes];
	if ([self.title length] > 0) {
		
		titleLength = [self.title length];
		NSDictionary *titleAttributes = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName : [self titleFont], NSParagraphStyleAttributeName : paragraphStyle, NSKernAttributeName : [NSNull null]};
		[attString addAttributes:titleAttributes range:NSMakeRange(0, titleLength)];
	}
	
	NSUInteger textLength = [text length];
	
	
	for (NSString *oneLink in self.links) {
		
		NSRange linkRange = [self.fullText rangeOfString:oneLink options:NSCaseInsensitiveSearch];
		while (linkRange.length > 0) {
			
			//            UIFont *linkFontToUse = self.useItalicFonts ? linkFontItalic : linkFont;
			QS_FONT *linkFontToUse = self.useItalicFonts ? app_delegate.typographySettings.bodyLinkFontArchived : app_delegate.typographySettings.bodyLinkFont;
			if (linkRange.location < titleLength)
				linkFontToUse = self.useItalicFonts ? app_delegate.typographySettings.titleLinkFontArchived : app_delegate.typographySettings.titleLinkFont;
			//                linkFontToUse = self.useItalicFonts ? titleLinkFontItalic : titleLinkFont;
			
			OSAtomicIncrement32Barrier(&linkIDCounter);
			
			NSDictionary *linkAtts = @{NSForegroundColorAttributeName : linkColor, VSLinkUniqueIDAttributeName : @(linkIDCounter), VSLinkAttributeName: oneLink, NSFontAttributeName : linkFontToUse, NSKernAttributeName : [NSNull null]};
			[attString addAttributes:linkAtts range:linkRange];
			
			NSUInteger indexOfCharacterAfterLink = linkRange.location + linkRange.length;
			if (indexOfCharacterAfterLink >= [text length])
				break;
			linkRange = [text rangeOfString:oneLink options:NSCaseInsensitiveSearch range:NSMakeRange(indexOfCharacterAfterLink, textLength - indexOfCharacterAfterLink)];
		}
	}
	
	_attributedText = attString;
	return _attributedText;
}


- (CTFramesetterRef)framesetter {
	
	if (_framesetter != nil)
		return _framesetter;
	if (self.attributedText == nil)
		return nil;
	
	_framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedText);
	return _framesetter;
}


#pragma mark Rendering

- (void)flipContext:(CGContextRef)context rect:(CGRect)rect {
	
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	
	CGContextTranslateCTM(context, 0.0f, rect.origin.y );
	CGContextScaleCTM(context, 1.0f, -1.0f );
	CGContextTranslateCTM(context, 0.0f, - ( rect.origin.y + rect.size.height ) );
}


static const CGFloat VSTextRendererMaxHeight = 300.0f;

static NSDictionary *clippingPathDictionaryForPathRect(CGRect rPath) {
	
	CGPathRef clipPath = CGPathCreateWithRect(rPath, NULL);
	NSDictionary *clippingPathDictionary = @{(__bridge NSString *)kCTFramePathClippingPathAttributeName : (__bridge id)clipPath};
	CFRelease(clipPath);
	
	return clippingPathDictionary;
}


- (NSDictionary *)optionsDictionaryForRect:(CGRect)r truncated:(BOOL)truncated {
	
	/*Clips out space for the truncation indicator if needeed. Otherwise returns nil.*/
	
	if (!truncated)
		return nil;
	
	NSMutableArray *clippingPaths = [NSMutableArray new];
	
	static CGFloat truncationIndicatorWidth = 28.0f;
	static CGFloat truncationIndicatorHeight = 22.0f;
	
	CGRect rPath = r;
	rPath.size.width = truncationIndicatorWidth;
	rPath.size.height = truncationIndicatorHeight;
	rPath.origin.x = CGRectGetMaxX(r) - truncationIndicatorWidth;
	rPath.origin.y = 0.0f; /*flipped, so 0.0 is at bottom*/
	
	NSDictionary *clippingPathDictionary = clippingPathDictionaryForPathRect(rPath);
	[clippingPaths addObject:clippingPathDictionary];
	
	NSDictionary *options = @{(__bridge NSString *)kCTFrameClippingPathsAttributeName : [clippingPaths copy]};
	
	return options;
}


- (NSDictionary *)optionsDictionaryForRect:(CGRect)r {
	return [self optionsDictionaryForRect:r truncated:NO];
}


- (CGFloat)calculateHeight {
	
	if (self.framesetter == nil)
		return 0.0f;
	
	CGFloat height = 0.0f;
	
	@autoreleasepool {
		
		CGRect r = CGRectMake(0.0f, 0.0f, self.width, VSTextRendererMaxHeight);
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRect(path, NULL, r);
		
		NSDictionary *options = [self optionsDictionaryForRect:r];
		CTFrameRef frameref = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, (CFIndex)[self.attributedText length]), path, (__bridge CFDictionaryRef)options);
		
		NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameref);
		NSUInteger indexOfLastLine = (NSUInteger)[lines count] - 1;
		if (self.maximumNumberOfLines > 0) {
			indexOfLastLine = MIN(self.maximumNumberOfLines - 1, indexOfLastLine);
			self.truncated = [lines count] > self.maximumNumberOfLines;
		}
		
		CGPoint origins[indexOfLastLine + 1];
		CTFrameGetLineOrigins(frameref, CFRangeMake(0, (CFIndex)indexOfLastLine + 1), origins);
		
		CTLineRef lastLine = (__bridge CTLineRef)lines[indexOfLastLine];
		CGPoint lastOrigin = origins[indexOfLastLine];
		CGFloat descent;
		CTLineGetTypographicBounds(lastLine, NULL, &descent, NULL);
		height = r.size.height - (lastOrigin.y - descent);
		height = QSCeil(height);
		CFRelease(path);
		CFRelease(frameref);
	}
	
	return height;
}


- (void)renderTextInRect:(CGRect)r {
	
#if !TARGET_OS_IPHONE
	CGContextRef context = [NSGraphicsContext currentContext].CGContext;
#else
	CGContextRef context = UIGraphicsGetCurrentContext();
#endif
	CGContextSaveGState(context);
	
	[self flipContext:context rect:r];
	
	CTFrameDraw(self.frameref, context);
	
	CGContextRestoreGState(context);
}


- (CTFrameRef)frameref {
	
	if (_frameref != nil)
		return _frameref;
	
	CGRect r = CGRectMake(0.0f, 0.0f, self.width, self.height);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, r);
	
	NSDictionary *options = [self optionsDictionaryForRect:r truncated:self.truncated];
	_frameref = CTFramesetterCreateFrame(self.framesetter, CFRangeMake(0, (CFIndex)[self.attributedText length]), path, (__bridge CFDictionaryRef)options);
	
	CFRelease(path);
	
	return _frameref;
}


@end
