//
//  VSTypographySettings.m
//  Vesper
//
//  Created by Brent Simmons on 9/1/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTypographySettings.h"
@import CoreText;

NSString *VSTypographySettingsDidChangeNotification = @"VSTypographySettingsDidChangeNotification";


@interface VSTypographySettings ()

@property (nonatomic, strong, readonly) VSTheme *theme;
@property (nonatomic, assign, readwrite) BOOL useSmallCaps;
@property (nonatomic, assign) VSTextWeight textWeight;
@property (nonatomic, assign) NSUInteger fontLevel;
@property (nonatomic, strong, readwrite) QS_FONT *titleFont;
@property (nonatomic, strong, readwrite) QS_FONT *titleFontArchived;
@property (nonatomic, strong, readwrite) QS_FONT *titleLinkFont;
@property (nonatomic, strong, readwrite) QS_FONT *titleLinkFontArchived;
@property (nonatomic, strong, readwrite) QS_FONT *bodyFont;
@property (nonatomic, strong, readwrite) QS_FONT *bodyFontArchived;
@property (nonatomic, strong, readwrite) QS_FONT *bodyLinkFont;
@property (nonatomic, strong, readwrite) QS_FONT *bodyLinkFontArchived;

@end


@implementation VSTypographySettings


#pragma mark - Init

- (instancetype)initWithTheme:(VSTheme *)theme {

	self = [self init];
	if (self == nil)
		return nil;

	_theme = theme;

	_useSmallCaps = [[NSUserDefaults standardUserDefaults] boolForKey:VSDefaultsUseSmallCapsKey];
	_textWeight = VSDefaultsTextWeight();
	_fontLevel = VSDefaultsFontLevel();

	[self setupFonts];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Notifications

- (void)userDefaultsDidChange:(NSNotification *)note {

	BOOL settingsDidChange = NO;

	VSTextWeight textWeight = VSDefaultsTextWeight();
	if (textWeight != self.textWeight) {
		self.textWeight = textWeight;
		settingsDidChange = YES;
	}

	BOOL useSmallCaps = [[NSUserDefaults standardUserDefaults] boolForKey:VSDefaultsUseSmallCapsKey];
	if (useSmallCaps != self.useSmallCaps) {
		self.useSmallCaps = useSmallCaps;
		settingsDidChange = YES;
	}

	NSUInteger fontLevel = VSDefaultsFontLevel();
	if (fontLevel != self.fontLevel) {
		self.fontLevel = fontLevel;
		settingsDidChange = YES;
	}

	if (settingsDidChange) {
		[self setupFonts];
		[[NSNotificationCenter defaultCenter] postNotificationName:VSTypographySettingsDidChangeNotification object:self];
	}
}


#pragma mark - Fonts

- (QS_FONT *)fontWithKey:(NSString *)fontKey fontSize:(CGFloat)fontSize italic:(BOOL)italic bold:(BOOL)bold smallCaps:(BOOL)smallCaps {

	if (italic)
		fontKey = [fontKey stringByAppendingString:@"Italic"];

	if (self.textWeight == VSTextWeightLight)
		fontKey = [fontKey stringByAppendingString:@"Light"];
	else
		fontKey = [fontKey stringByAppendingString:@"Regular"];

	fontKey = [NSString stringWithFormat:@"typography.%@", fontKey];

	NSString *fontName = [app_delegate.theme stringForKey:fontKey];
	if (smallCaps)
		fontName = [fontName stringByReplacingOccurrencesOfString:@"-" withString:@"SC-"];

	QS_FONT *font = [QS_FONT fontWithName:fontName size:fontSize];
	
	// 19 Dec. 2016: Since Ideal Sans has been removed, font will probably be nil, so use the system font instead of crashing later. The block of code below is new for the open source version.
	if (!font) {
		CGFloat weight = UIFontWeightRegular;
		if (self.textWeight == VSTextWeightLight) {
			weight = UIFontWeightLight;
		}
		if (bold) {
			weight = UIFontWeightBold;
		}
		font = [UIFont systemFontOfSize:fontSize weight:weight];
		if (italic) {
			UIFontDescriptorSymbolicTraits traits = UIFontDescriptorTraitItalic;
			if (bold) {
				traits = UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold;
			}
			font = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:traits] size:fontSize];
		}
		
		if (smallCaps) {
			font = [self smallCapsFontWithFont:font fontSize:fontSize];
		}
	}

	return font;
}

- (UIFont *)smallCapsFontWithFont:(UIFont *)font fontSize:(CGFloat)fontSize {
	
	UIFontDescriptor *smallCapsDescriptor = [font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @(kLowerCaseType), UIFontFeatureSelectorIdentifierKey: @(kLowerCaseSmallCapsSelector)}]}];
	return [UIFont fontWithDescriptor:smallCapsDescriptor size:fontSize];
}

- (QS_FONT *)fontWithKey:(NSString *)fontKey fontSize:(CGFloat)fontSize italic:(BOOL)italic smallCaps:(BOOL)smallCaps {
	
	return [self fontWithKey:fontKey fontSize:fontSize italic:italic bold:NO smallCaps:smallCaps];
}

- (CGFloat)fontSizeForKey:(NSString *)key {
	
	NSUInteger maxSize = VSDefaultsFontLevelMaximum();
	key = [NSString stringWithFormat:@"typography.%@.%ld", key, (long)maxSize];

	NSArray *fontSizes = [app_delegate.theme objectForKey:key];
	CGFloat fontSize = [fontSizes[self.fontLevel] floatValue];
	return fontSize;
}


- (void)setupFonts {

	CGFloat titleFontSize = [self fontSizeForKey:@"titleFontSizes"];
	self.titleFont = [self fontWithKey:@"noteTitleFont" fontSize:titleFontSize italic:NO bold:YES smallCaps:self.useSmallCaps];
	self.titleFontArchived = [self fontWithKey:@"noteTitleFont" fontSize:titleFontSize italic:YES bold:YES smallCaps:self.useSmallCaps];

	CGFloat titleLinkFontSize = [self fontSizeForKey:@"titleLinkFontSizes"];
	self.titleLinkFont = [self fontWithKey:@"noteTitleLinkFont" fontSize:titleLinkFontSize italic:NO smallCaps:self.useSmallCaps];
	self.titleLinkFontArchived = [self fontWithKey:@"noteTitleLinkFont" fontSize:titleLinkFontSize italic:YES smallCaps:self.useSmallCaps];

	CGFloat bodyFontSize = [self fontSizeForKey:@"bodyFontSizes"];
	self.bodyFont = [self fontWithKey:@"noteBodyFont" fontSize:bodyFontSize italic:NO smallCaps:NO];
	self.bodyFontArchived = [self fontWithKey:@"noteBodyFont" fontSize:bodyFontSize italic:YES smallCaps:NO];

	CGFloat bodyLinkFontSize = [self fontSizeForKey:@"bodyLinkFontSizes"];
	self.bodyLinkFont = [self fontWithKey:@"noteBodyLinkFont" fontSize:bodyLinkFontSize italic:NO smallCaps:NO];
	self.bodyLinkFontArchived = [self fontWithKey:@"noteBodyLinkFont" fontSize:bodyLinkFontSize italic:YES smallCaps:NO];
}


@end
