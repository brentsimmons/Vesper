//
//  VSArchiveIndicatorView.m
//  Vesper
//
//  Created by Brent Simmons on 4/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSArchiveIndicatorView.h"


@interface VSArchiveIndicatorView ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic, strong) UIImage *arrowImageOn;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, assign) CGSize labelSize;
@end


@implementation VSArchiveIndicatorView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_label = [[UILabel alloc] initWithFrame:CGRectZero];
	_label.opaque = NO;
	_label.backgroundColor = [UIColor clearColor];
	_label.font = [app_delegate.theme fontForKey:@"archiveIndicatorFont"];
	_label.textColor = [app_delegate.theme colorForKey:@"archiveIndicatorTextColor"];
	_label.textAlignment = NSTextAlignmentLeft;
	[self addSubview:_label];
	
	UIColor *tintColor = [app_delegate.theme colorForKey:@"archiveIndicatorArrowTintColor"];
	_arrowImage = [UIImage qs_imageNamed:@"arrow-left" tintedWithColor:tintColor];
	
	tintColor = [app_delegate.theme colorForKey:@"archiveIndicatorArrowOnTintColor"];
	_arrowImageOn = [UIImage qs_imageNamed:@"arrow-left" tintedWithColor:tintColor];
	
	_arrowImageView = [[UIImageView alloc] initWithImage:_arrowImage];
	[self addSubview:_arrowImageView];
	
	self.contentMode = UIViewContentModeRedraw;
	self.backgroundColor = [UIColor clearColor];//[app_delegate.theme colorForKey:@"timelineArchiveDelete.backgroundColor"];
	
	[self setNeedsLayout];
	
	[self addObserver:self forKeyPath:@"archiveIndicatorState" options:0 context:nil];
	[self addObserver:self forKeyPath:@"text" options:0 context:nil];
	[self addObserver:self forKeyPath:@"font" options:0 context:nil];
	[self addObserver:self forKeyPath:@"arrowTranslationX" options:0 context:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"archiveIndicatorState"];
	[self removeObserver:self forKeyPath:@"text"];
	[self removeObserver:self forKeyPath:@"font"];
	[self removeObserver:self forKeyPath:@"arrowTranslationX"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"archiveIndicatorState"]) {
		
		if (self.archiveIndicatorState == VSArchiveIndicatorStateHinting) {
			if (self.arrowImageView.image != self.arrowImage)
				self.arrowImageView.image = self.arrowImage;
			self.label.textColor = [app_delegate.theme colorForKey:@"archiveIndicatorTextColor"];
			self.arrowImageView.alpha = 1.0f;
			//            self.arrowImageView.hidden = NO;
		}
		else if (self.archiveIndicatorState == VSArchiveIndicatorStateIndicating) {
			self.label.textColor = [app_delegate.theme colorForKey:@"archiveIndicatorOnTextColor"];
			if (self.arrowImageView.image != self.arrowImageOn)
				self.arrowImageView.image = self.arrowImageOn;
			//            self.arrowImageView.alpha = 1.0f;
			
			//            [UIView animateWithDuration:[app_delegate.theme floatForKey:@"archiveIndicatorArrowFadeDuration"] animations:^{
			//                self.arrowImageView.alpha = 0.0f;
			//            }];
			
			//            self.arrowImageView.hidden = YES;
		}
	}
	
	else if ([keyPath isEqualToString:@"text"]) {
		
		self.label.text = self.text;
		self.labelSize = [self.text sizeWithAttributes:@{NSFontAttributeName : self.label.font}];
		//        self.labelSize = [self.text sizeWithFont:self.label.font];
	}
	
	else if ([keyPath isEqualToString:@"font"]) {
		self.label.font = self.font;
	}
	
	[self setNeedsLayout];
}


//#pragma mark - Animations
//
//- (void)animateImageViewHidden:(BOOL)hidden {
//
//    [UIView animateWithDuration:0.25f animations:^{
//        self.arrowImageView.alpha = (hidden ? 0.0f : 1.0f);
//    } completion:^(BOOL finished) {
//        self.arrowImageView.hidden = hidden;
//    }];
//}


#pragma mark - Layout

- (void)layoutSubviews {
	
	CGRect rArrow = self.arrowImageView.frame;
	rArrow.origin.x = 0.0f;//self.bounds.size.width - rArrow.size.width;
	
	CGRect rLabel = self.label.frame;
	rLabel.size = self.labelSize;
	CGFloat labelMarginLeft = [app_delegate.theme floatForKey:@"archiveIndicatorTextMarginLeft"];
	rLabel.origin.x = rArrow.origin.x + rArrow.size.width + labelMarginLeft;
	
	rArrow = CGRectCenteredVerticallyInRect(rArrow, self.bounds);
	rLabel = CGRectCenteredVerticallyInRect(rLabel, self.bounds);
	rLabel.origin.y -= 1.0f;
	
	rArrow.origin.x += self.arrowTranslationX;
	
	[self.arrowImageView qs_setFrameIfNotEqual:rArrow];
	[self.label qs_setFrameIfNotEqual:rLabel];
}


- (CGSize)sizeThatFits:(CGSize)size {
	
	CGSize sizeThatFits = CGSizeZero;
	CGFloat textMarginRight = [app_delegate.theme floatForKey:@"archiveIndicatorTextMarginRight"];
	
	sizeThatFits.height = MAX(self.arrowImageView.bounds.size.height, self.labelSize.height);
	sizeThatFits.width = self.arrowImageView.bounds.size.width + textMarginRight + self.labelSize.width;
	
	return sizeThatFits;
}


#pragma mark - Drawing

- (BOOL)isOpaque {
	return NO;
}


@end

