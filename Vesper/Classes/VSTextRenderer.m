//
//  VSTextRenderer.m
//  Vesper
//
//  Created by Brent Simmons on 2/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "VSTextRenderer.h"


@interface VSTextRenderer ()

@property (nonatomic, assign, readwrite) CGFloat height;
@property (nonatomic, assign, readwrite) BOOL truncated;
@property (nonatomic, strong, readwrite) NSString *text;
@property (nonatomic, strong, readwrite) NSArray *links;
@property (nonatomic, assign, readonly) BOOL hasPunchoutRect;
@property (nonatomic, assign, readonly) CGFloat lineSpacing;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *linkColor;
@property (nonatomic, strong) UIColor *linkHighlightedColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIFont *linkFont;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign, readwrite) CTFramesetterRef framesetter;
@property (nonatomic, assign, readwrite) CTFrameRef frameref;
@property (nonatomic, strong, readwrite) NSAttributedString *attributedText;

@end


@implementation VSTextRenderer


#pragma mark Init

- (id)initWithText:(NSString *)text links:(NSArray *)links textColor:(UIColor *)textColor linkColor:(UIColor *)linkColor linkHighlightedColor:(UIColor *)linkHighlightedColor font:(UIFont *)font linkFont:(UIFont *)linkFont width:(CGFloat)width punchoutRect:(CGRect)punchoutRect maximumNumberOfLines:(NSUInteger)maximumNumberOfLines lineSpacing:(CGFloat)lineSpacing {

	self = [super init];
	if (self == nil)
		return nil;

    _maximumNumberOfLines = maximumNumberOfLines;
	_text = text;
	_links = links;
	_textColor = textColor;
	_linkColor = linkColor;
    _linkHighlightedColor = linkHighlightedColor;
	_font = font;
    _lineSpacing = lineSpacing;
    
    _linkFont = linkFont;
    if (_linkFont == nil)
        _linkFont = font;

	_width = width;
	_height = 0.0f;

    _punchoutRect = punchoutRect;
    _hasPunchoutRect = !CGRectEqualToRect(punchoutRect, CGRectZero);
    
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

	if (RSStringIsEmpty(self.text))
		return 0.0f;
	if (_height > 0.1f)
		return _height;

    _height = [self calculateHeight];
	return _height;
}


- (BOOL)truncated {
    (void)self.height; /*Sets self.truncated if not set yet*/
    return _truncated;
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
        attributesHighlighted[NSForegroundColorAttributeName] = self.linkHighlightedColor;
        attributesHighlighted[NSKernAttributeName] = [NSNull null];

        [attString setAttributes:attributesHighlighted range:range];
    }];


    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);

    CGRect r = CGRectZero;
    r.size = CGSizeMake(self.width, self.height);

    CGPathRef path = CGPathCreateWithRect(r, NULL);
    NSDictionary *options = [self optionsDictionaryForRect:r];

   	CTFrameRef frameref = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, (CFIndex)[attString length]), path, (__bridge CFDictionaryRef)options);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    [self flipContext:context rect:rect];
	CTFrameDraw(frameref, context);

    CGContextRestoreGState(context);

	CFRelease(path);
    CFRelease(frameref);
    CFRelease(framesetter);
}


static int32_t linkIDCounter = 0;

- (NSAttributedString *)attributedText {

	if (_attributedText != nil)
		return _attributedText;

	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineSpacing:self.lineSpacing];
	[paragraphStyle setParagraphSpacing:0.0f];
	[paragraphStyle setParagraphSpacingBefore:0.0f];

	NSDictionary *attributes = @{NSForegroundColorAttributeName : self.textColor, NSFontAttributeName : self.font, NSParagraphStyleAttributeName : paragraphStyle, NSKernAttributeName : [NSNull null]};

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];

    NSUInteger textLength = [self.text length];
    
	for (NSString *oneLink in self.links) {
        
		NSRange linkRange = [self.text rangeOfString:oneLink];
        while (linkRange.length > 0) {

            OSAtomicIncrement32Barrier(&linkIDCounter);
            
			NSDictionary *linkAtts = @{NSForegroundColorAttributeName : self.linkColor, VSLinkUniqueIDAttributeName : @(linkIDCounter), VSLinkAttributeName: oneLink, NSFontAttributeName : self.linkFont, NSKernAttributeName : [NSNull null]};
			[attString addAttributes:linkAtts range:linkRange];
            
            NSUInteger indexOfCharacterAfterLink = linkRange.location + linkRange.length;
            if (indexOfCharacterAfterLink >= [self.text length])
                break;
            linkRange = [self.text rangeOfString:oneLink options:NSCaseInsensitiveSearch range:NSMakeRange(indexOfCharacterAfterLink, textLength - indexOfCharacterAfterLink)];
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


static const CGFloat VSTextRendererMaxHeight = 2.0f * 536.0f;

static NSDictionary *clippingPathDictionaryForPathRect(CGRect rPath) {

    CGPathRef clipPath = CGPathCreateWithRect(rPath, NULL);
    NSDictionary *clippingPathDictionary = @{(__bridge NSString *)kCTFramePathClippingPathAttributeName : (__bridge id)clipPath};
    CFRelease(clipPath);

    return clippingPathDictionary;
}


- (NSDictionary *)optionsDictionaryForRect:(CGRect)r truncated:(BOOL)truncated {

    /*If there's a punchoutRect, returns a dictionary specifying the clipped-out portion. Also clips out space for the truncation indicator if needeed. Otherwise returns nil.*/

    if (!self.hasPunchoutRect && !truncated)
        return NULL;

    NSMutableArray *clippingPaths = [NSMutableArray new];

    if (self.hasPunchoutRect) {

        CGRect rPath = self.punchoutRect;
        rPath.origin.y = r.size.height - rPath.size.height; /*flipped*/

        NSDictionary *clippingPathDictionary = clippingPathDictionaryForPathRect(rPath);
        [clippingPaths addObject:clippingPathDictionary];
    }

    if (truncated) {

        static CGFloat truncationIndicatorWidth = 28.0f;
        static CGFloat truncationIndicatorHeight = 22.0f;

        CGRect rPath = r;
        rPath.size.width = truncationIndicatorWidth;
        rPath.size.height = truncationIndicatorHeight;
        rPath.origin.x = CGRectGetMaxX(r) - truncationIndicatorWidth;
        rPath.origin.y = 0.0f; /*flipped, so 0.0 is at bottom*/

        NSDictionary *clippingPathDictionary = clippingPathDictionaryForPathRect(rPath);
        [clippingPaths addObject:clippingPathDictionary];
    }

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
        height = ceilf(height);
        CFRelease(path);
        CFRelease(frameref);
       }

    return height;
}


- (void)renderTextInRect:(CGRect)r {

    CGContextRef context = UIGraphicsGetCurrentContext();
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

