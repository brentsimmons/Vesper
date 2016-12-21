//
//  VSTypographyFontSizeCell.m
//  Vesper
//
//  Created by Brent Simmons on 8/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTypographyFontSizeCell.h"
#import "VSTickMarksView.h"


@interface VSTypographyFontSizeCell ()

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *smallALabel;
@property (nonatomic, strong) UILabel *bigALabel;
@property (nonatomic, strong) VSTickMarksView *tickMarksView;

@end


@implementation VSTypographyFontSizeCell


#pragma mark - Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self == nil)
		return nil;
	
	self.contentMode = UIViewContentModeRedraw;
	self.opaque = YES;
	
	_slider = [[UISlider alloc] initWithFrame:CGRectZero];
	_slider.minimumValue = 0.0f;
	_slider.backgroundColor = [UIColor clearColor];
	_slider.opaque = NO;
	_slider.continuous = YES;
	_slider.userInteractionEnabled = YES;
	_slider.minimumTrackTintColor = [UIColor clearColor];
	_slider.maximumTrackTintColor = [UIColor clearColor];
	
	/*Set the minimumTrackImage to a transparent image. Otherwise it gets a weird ghost image.*/
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(1.0f, 1.0f), NO, 0.0f);
	UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	[_slider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
	
	//	_slider.minimumTrackTintColor = [app_delegate.theme colorForKey:@"typographyScreen.sliderTrackColor"];
	//	_slider.maximumTrackTintColor = [app_delegate.theme colorForKey:@"typographyScreen.sliderTrackColor"];
	[_slider sizeToFit];
	[_slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
	
	_tickMarksView = [[VSTickMarksView alloc] initWithSlider:_slider];
	
	_smallALabel = [self addLabelWithFontKey:@"typographyScreen.sliderSmallAFont"];
	_bigALabel = [self addLabelWithFontKey:@"typographyScreen.sliderLargeAFont"];
	
	[self.contentView addSubview:_slider];
	[self.contentView insertSubview:_tickMarksView belowSubview:_slider];
	
	self.contentView.backgroundColor = [app_delegate.theme colorForKey:@"typographyScreen.cellBackgroundColor"];
	self.contentView.opaque = YES;
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = self.contentView.backgroundColor;
	self.backgroundView.opaque = YES;
	
	self.userInteractionEnabled = YES;
	
	[self setNeedsLayout];
	
	[self updateUI];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UI

- (UILabel *)addLabelWithFontKey:(NSString *)fontKey {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.text = @"A";
	label.textColor = [app_delegate.theme colorForKey:@"typographyScreen.cellTextColor"];
	label.font = [app_delegate.theme fontForKey:fontKey];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	[label sizeToFit];
	[self.contentView addSubview:label];
	
	return label;
}


- (void)updateUI {
	
	NSUInteger fontLevel = VSDefaultsFontLevel();
	NSUInteger sliderLevel = (NSUInteger)self.slider.value;
	NSUInteger maxFontLevel = VSDefaultsFontLevelMaximum();
	self.slider.maximumValue = maxFontLevel;
	
	if (fontLevel != sliderLevel)
		self.slider.value = (float)fontLevel;
	
	[self.tickMarksView refresh];
}


#pragma mark - Notifications

- (void)userDefaultsDidChange:(NSNotification *)note {
	[self updateUI];
}


#pragma mark -

- (void)prepareForReuse {
	[super prepareForReuse];
	
	[self updateUI];
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	//	CGRect rBounds = self.bounds;
	
	CGRect rSlider = self.slider.frame;
	rSlider.origin = [app_delegate.theme pointForKey:@"typographyScreen.sliderOrigin"];
	//	CGFloat sliderMarginRight = [app_delegate.theme floatForKey:@"typographyScreen.sliderMarginRight"];
	//	CGFloat sliderWidth = CGRectGetWidth(rBounds) - (CGRectGetMinX(rSlider) + sliderMarginRight);
	static const CGFloat sliderWidth = 300.0f; /*It needs to be the same for every screen width, so tickmarks match up.*/
	rSlider.size.width = sliderWidth;
	CGSize sliderSize = rSlider.size;
	rSlider = CGRectCenteredHorizontallyInRect(rSlider, self.bounds);
	rSlider = CGRectIntegral(rSlider);
	rSlider.size = sliderSize;
	[self.slider qs_setFrameIfNotEqual:rSlider];
	
	CGRect rSmallALabel = self.smallALabel.frame;
	rSmallALabel.origin = [app_delegate.theme pointForKey:@"typographyScreen.sliderSmallAOrigin"];
	rSmallALabel.origin.x = CGRectGetMinX(rSlider) + 8.0f;
	[self.smallALabel qs_setFrameIfNotEqual:rSmallALabel];
	
	CGRect rBigALabel = self.bigALabel.frame;
	rBigALabel.origin.y = [app_delegate.theme floatForKey:@"typographyScreen.sliderLargeAOriginY"];
	rBigALabel.origin.x = CGRectGetMaxX(rSlider) - 25.0f;
	//	CGFloat bigALabelMarginRight = [app_delegate.theme floatForKey:@"typographyScreen.sliderLargeAMarginRight"];
	//	rBigALabel.origin.x = CGRectGetWidth(rBounds) - (CGRectGetWidth(rBigALabel) + bigALabelMarginRight);
	[self.bigALabel qs_setFrameIfNotEqual:rBigALabel];
	
	CGRect rTickmarks = CGRectZero;
	rTickmarks.size.height = [app_delegate.theme floatForKey:@"typographyScreen.sliderTickMarkHeight"];
	rTickmarks.size.width = CGRectGetWidth(rSlider);
	rTickmarks.origin.x = CGRectGetMinX(rSlider);
	rTickmarks.origin.y = CGRectGetMinY(rSlider) + [app_delegate.theme floatForKey:@"typographyScreen.sliderTickMarkVerticalFudge"];
	if (!CGRectEqualToRect(rTickmarks, self.tickMarksView.frame)) {
		self.tickMarksView.frame = rTickmarks;
		[self.tickMarksView setNeedsDisplay];
	}
}


#pragma mark - Actions

- (void)sliderChanged:(id)sender {
	
	CGFloat value = ((UISlider *)sender).value;
#if __LP64__
	CGFloat roundedValue = round(value);
#else
	CGFloat roundedValue = roundf(value);
#endif
	((UISlider *)sender).value = (float)roundedValue;
	
	NSUInteger currentFontLevel = VSDefaultsFontLevel();
	NSUInteger fontLevel = (NSUInteger)roundedValue;
	if (currentFontLevel != fontLevel) {
		VSDefaultsSetFontLevel(fontLevel);
	}
}


- (void)contentSizeCategoryDidChange:(NSNotification *)notification {
	[self updateUI];
}


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
	return YES;
}


- (UIAccessibilityTraits)accessibilityTraits {
	return [super accessibilityTraits] | UIAccessibilityTraitAdjustable;
}


- (void)accessibilityIncrement {
	self.slider.value += 1;
	[self.slider sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void)accessibilityDecrement {
	self.slider.value -= 1;
	[self.slider sendActionsForControlEvents:UIControlEventValueChanged];
}


- (NSString *)accessibilityLabel {
	return NSLocalizedString(@"Font size", nil);
}


- (NSString *)accessibilityValue {
	return [NSString stringWithFormat:NSLocalizedString(@"%d percent", nil), (int)(100.0 * (CGFloat)VSDefaultsFontLevel() / VSDefaultsFontLevelMaximum())];
}


@end
