//
//  VSTypographySmallCapsCell.m
//  Vesper
//
//  Created by Brent Simmons on 8/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTypographySmallCapsCell.h"


@interface VSTypographySmallCapsCell ()

@property (nonatomic, strong) UISwitch *yesNoSwitch;
@property (nonatomic, assign) CGSize textLabelSize;
@end


@implementation VSTypographySmallCapsCell


#pragma mark - Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self == nil)
		return nil;
	
	self.contentMode = UIViewContentModeRedraw;
	self.opaque = YES;
	
	_yesNoSwitch = [[UISwitch alloc] initWithFrame:CGRectZero]; /*control enforces size*/
	_yesNoSwitch.onTintColor = [app_delegate.theme colorForKey:@"typographyScreen.smallCapsSwitchOnColor"];
	[self.contentView insertSubview:_yesNoSwitch aboveSubview:self.textLabel];
	[_yesNoSwitch addTarget:self action:@selector(yesNoSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	
	self.textLabel.backgroundColor = [UIColor clearColor];
	self.textLabel.opaque = NO;
	
	UIFont *font = [app_delegate.theme fontForKey:@"typographyScreen.cellFont"];
	NSString *text = NSLocalizedString(@"Small Caps", @"Small Caps");
	//	UIColor *color = [app_delegate.theme colorForKey:@"typographyScreen.cellTextColor"];
	UIColor *color = [UIColor blackColor];
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:text font:font color:color kerning:YES];
	self.textLabel.attributedText = attString;
	
	_textLabelSize = [self.textLabel sizeThatFits:CGSizeMake(200.0f, 30.0f)]; /*200, 30 -- big enough*/
	
	self.contentView.backgroundColor = [app_delegate.theme colorForKey:@"typographyScreen.cellBackgroundColor"];
	self.contentView.opaque = YES;
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = self.contentView.backgroundColor;
	self.backgroundView.opaque = YES;
	
	[self setNeedsLayout];
	
	[self updateUI];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGFloat textOriginX = [app_delegate.theme floatForKey:@"typographyScreen.cellTextOriginX"];
	CGFloat textOriginY = [app_delegate.theme floatForKey:@"typographyScreen.smallCapsTextOriginY"];
	CGFloat textWidth = self.textLabelSize.width;
	CGFloat textHeight = self.textLabelSize.height;
	
	CGRect r = CGRectMake(textOriginX, textOriginY, textWidth, textHeight);
	[self.textLabel qs_setFrameIfNotEqual:r];
	
	CGRect rSwitch = self.yesNoSwitch.frame;
	rSwitch.origin.x = CGRectGetMaxX(self.bounds) - (CGRectGetWidth(rSwitch) + [app_delegate.theme floatForKey:@"typographyScreen.smallCapsSwitchMarginRight"]);
	rSwitch.origin.y = [app_delegate.theme floatForKey:@"typographyScreen.smallCapsSwitchOriginY"];
	[self.yesNoSwitch qs_setFrameIfNotEqual:rSwitch];
}


#pragma mark - UI

- (void)updateUI {
	
	BOOL switchIsOn = self.yesNoSwitch.on;
	BOOL useSmallCaps = [[NSUserDefaults standardUserDefaults] boolForKey:VSDefaultsUseSmallCapsKey];
	if (switchIsOn != useSmallCaps)
		self.yesNoSwitch.on = useSmallCaps;
}


#pragma mark - Actions

- (void)yesNoSwitchChanged:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:self.yesNoSwitch.on forKey:VSDefaultsUseSmallCapsKey];
	//	[[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Notifications

- (void)userDefaultsDidChange:(NSNotification *)note {
	[self updateUI];
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement
{
	return YES;
}


- (NSString *)accessibilityValue
{
	return [self.yesNoSwitch isOn] ? NSLocalizedString(@"On", nil) : NSLocalizedString(@"Off", nil);
}


- (CGPoint)accessibilityActivationPoint
{
	return [self.yesNoSwitch accessibilityActivationPoint];
}


@end
