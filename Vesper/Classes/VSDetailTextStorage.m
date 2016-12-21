//
//  VSDetailTextStorage.m
//  Vesper
//
//  Created by Brent Simmons on 7/19/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailTextStorage.h"
#import "VSTypographySettings.h"


@interface VSDetailTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *backingString;
@property (nonatomic, assign) BOOL textNeedsUpdate;
@property (nonatomic, strong) UIColor *linkColor;
@property (nonatomic, strong) NSDictionary *titleLinkAttributes;
@property (nonatomic, strong) NSDictionary *bodyLinkAttributes;

@end


@implementation VSDetailTextStorage


#pragma mark - Init

- (instancetype)initAsReadOnly:(BOOL)readOnly {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_readOnly = readOnly;
	
	_backingString = [NSMutableAttributedString new];
	
	[self updateTitleAndBodyAttributes];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSTextStorage Required Overrides

- (NSString *)string {
	return [self.backingString string];
}


- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
	return [self.backingString attributesAtIndex:location effectiveRange:range];
}


- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)s {
	
	[self beginEditing];
	
	[self.backingString replaceCharactersInRange:range withString:s];
	[self edited:NSTextStorageEditedCharacters|NSTextStorageEditedAttributes range:range changeInLength:(NSInteger)[s length] - (NSInteger)range.length];
	self.textNeedsUpdate = YES;
	
	[self endEditing];
}


- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
	
	if (range.location == NSNotFound || range.length < 1 || range.length == NSNotFound)
		return;
	
	if ([self hasAlreadySetAttributes:attributes range:range])
		return;
	
	[self beginEditing];
	
	[self.backingString setAttributes:attributes range:range];
	[self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
	
	[self endEditing];
}


#pragma mark - Attributes Checking

static BOOL attributesAreEquivalent(NSDictionary *d1, NSDictionary *d2) {
	
	if ((d1 == nil || [d1 count] < 1) && (d2 == nil || [d2 count] < 1))
		return YES;
	if (d1 == nil || d2 == nil)
		return NO;
	
	UIColor *color1 = d1[NSForegroundColorAttributeName];
	UIColor *color2 = d2[NSForegroundColorAttributeName];
	if (![color1 isEqual:color2])
		return NO;
	
	UIFont *font1 = d1[NSFontAttributeName];
	UIFont *font2 = d2[NSFontAttributeName];
	if (![font1 isEqual:font2])
		return NO;
	
	return YES;
}


- (BOOL)hasAlreadySetAttributes:(NSDictionary *)attributes range:(NSRange)range {
	
	NSRange effectiveRange = NSMakeRange(0, 0);
	NSDictionary *currentAttributes = [self attributesAtIndex:range.location effectiveRange:&effectiveRange];
	
	NSRange rangeIntersection = NSIntersectionRange(range, effectiveRange);
	if (!NSEqualRanges(range, rangeIntersection))
		return NO;
	
	if (attributesAreEquivalent(attributes, currentAttributes)) {
		return YES;
	}
	
	return NO;
}


#pragma mark - NSTextStorage

- (void)processEditing {
	
	if (self.textNeedsUpdate) {
		
		self.textNeedsUpdate = NO;
		[self updateAttributesInRange:self.editedRange];
	}
	
	[super processEditing];
}


#pragma mark - Attributes

- (void)updateTitleAndBodyAttributes {
	
	UIColor *titleColor = [app_delegate.theme colorForKey:@"noteTitleFontColor"];
	UIColor *textColor = [app_delegate.theme colorForKey:@"noteFontColor"];
	UIColor *linkColor = [app_delegate.theme colorForKey:@"noteLinkColor"];
	
	UIFont *titleFont = app_delegate.typographySettings.titleFont;
	if (self.readOnly)
		titleFont = app_delegate.typographySettings.titleFontArchived;
	
	UIFont *textFont = app_delegate.typographySettings.bodyFont;
	if (self.readOnly)
		titleFont = app_delegate.typographySettings.bodyFontArchived;
	
	UIFont *titleLinkFont = app_delegate.typographySettings.titleLinkFont;
	if (self.readOnly)
		titleLinkFont = app_delegate.typographySettings.titleLinkFontArchived;
	
	UIFont *textLinkFont = app_delegate.typographySettings.bodyLinkFont;
	if (self.readOnly)
		textLinkFont = app_delegate.typographySettings.bodyLinkFontArchived;
	
	CGFloat titleMarginBottom = [app_delegate.theme floatForKey:@"detailNoteTitleMarginBottom"];
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.paragraphSpacing = MIN(8, titleMarginBottom);
	
	self.titleAttributes = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName : titleFont, NSParagraphStyleAttributeName : paragraphStyle};
	self.bodyAttributes = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont};
	
	NSMutableDictionary *titleLinkAttributes = [_titleAttributes mutableCopy];
	titleLinkAttributes[NSForegroundColorAttributeName] = linkColor;
	titleLinkAttributes[NSFontAttributeName] = titleLinkFont;
	self.titleLinkAttributes = [titleLinkAttributes copy];
	
	NSMutableDictionary *bodyLinkAttributes = [_bodyAttributes mutableCopy];
	bodyLinkAttributes[NSForegroundColorAttributeName] = linkColor;
	bodyLinkAttributes[NSFontAttributeName] = textLinkFont;
	self.bodyLinkAttributes = [bodyLinkAttributes copy];
}


- (void)setReadOnly:(BOOL)readOnly {
	
	if (readOnly == _readOnly)
		return;
	
	[self updateTitleAndBodyAttributes];
}


- (NSRange)rangeOfFirstLine {
	
	NSString *s = [self string];
	if ([s length] < 1)
		return NSMakeRange(NSNotFound, 0);
	
	NSUInteger ix = [s rs_indexOfCROrLF];
	if (ix == NSNotFound)
		ix = [s length];
	return NSMakeRange(0, ix);
}


- (NSRange)rangeOfBody {
	
	NSRange rangeOfFirstLine = [self rangeOfFirstLine];
	NSUInteger textLength = [[self string] length];
	
	if (rangeOfFirstLine.location == NSNotFound)
		return NSMakeRange(NSNotFound, 0);
	if (textLength <= rangeOfFirstLine.length)
		return NSMakeRange(NSNotFound, 0);
	
	NSRange rangeOfBody = NSMakeRange(0, 0);
	rangeOfBody.location = NSMaxRange(rangeOfFirstLine);
	rangeOfBody.length = textLength - rangeOfFirstLine.length;
	
	return rangeOfBody;
}


- (void)applyTitleAttributesInRange:(NSRange)range {
	
	[self setAttributes:self.titleAttributes range:range];
}


- (void)applyBodyAttributesInRange:(NSRange)range {
	
	[self setAttributes:self.bodyAttributes range:range];
}


- (void)updateAttributesInRange:(NSRange)range {
	
	if (range.location == NSNotFound)
		return;
	
	NSRange rangeOfFirstLine = [self rangeOfFirstLine];
	
	[self applyTitleAttributesInRange:rangeOfFirstLine];
	
	NSUInteger bodyLocation = rangeOfFirstLine.location + rangeOfFirstLine.length;
	NSUInteger bodyLength = [[self string] length] - bodyLocation;
	
	if (bodyLength < 1)
		return;
	
	NSRange bodyRange = NSMakeRange(bodyLocation, bodyLength);
	if (bodyRange.location != NSNotFound && bodyRange.length > 0) {
		[self applyBodyAttributesInRange:bodyRange];
	}
}


- (void)highlightLink:(NSString *)link text:(NSString *)text rangeOfFirstLine:(NSRange)rangeOfFirstLine {
	
	NSRange searchRange = NSMakeRange(0, [text length]);
	
	while (true) {
		
		NSRange range = [text rangeOfString:link options:NSCaseInsensitiveSearch range:searchRange];
		if (range.length < 1)
			break;
		
		NSDictionary *attributesToUse = self.bodyLinkAttributes;
		if (range.location < NSMaxRange(rangeOfFirstLine))
			attributesToUse = self.titleLinkAttributes;
		
		[self setAttributes:attributesToUse range:range];
		searchRange.location = NSMaxRange(range);
		searchRange.length = [text length] - searchRange.location;
	}
}


- (void)highlightLinks:(NSArray *)links {
	
	NSString *text = [self string];
	NSRange rangeOfFirstLine = [self rangeOfFirstLine];
	
	for (NSString *oneLink in links)
		[self highlightLink:oneLink text:text rangeOfFirstLine:rangeOfFirstLine];
}


- (void)unhighlightLinks {
	
	NSRange rangeOfFirstLine = [self rangeOfFirstLine];
	NSRange rangeOfBody = [self rangeOfBody];
	
	[self setAttributes:self.titleAttributes range:rangeOfFirstLine];
	[self setAttributes:self.bodyAttributes range:rangeOfBody];
}


@end
