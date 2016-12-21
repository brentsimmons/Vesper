//
//  VSSidebarTableViewCell.m
//  Vesper
//
//  Created by Brent Simmons on 2/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSidebarTableViewCell.h"
#import "UIView+RSExtras.h"
#import "RSGeometry.h"


@implementation VSSidebarTableViewCell


#pragma mark - Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self == nil)
		return nil;
	
	[self addObserver:self forKeyPath:@"selected" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"highlighted" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"showIcon" options:0 context:NULL];
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = [UIColor clearColor];//[app_delegate.theme colorForKey:@"sidebarBackgroundColor"];
	self.backgroundView.opaque = NO;
	
	self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	UIColor *selectionColor = [app_delegate.theme colorForKey:@"sidebarSelectionColor"];
	selectionColor = [selectionColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"sidebarSelectionColorAlpha"]];
	self.selectedBackgroundView.backgroundColor = selectionColor;
	
	self.textLabel.backgroundColor = [UIColor clearColor];
	self.textLabel.opaque = NO;
	
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"selected"];
	[self removeObserver:self forKeyPath:@"highlighted"];
	[self removeObserver:self forKeyPath:@"showIcon"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"selected"] || [keyPath isEqualToString:@"highlighted"])
		[self updateText];
	
	else if ([keyPath isEqualToString:@"showIcon"]) {
		[self setNeedsLayout];
		self.imageView.hidden = !self.showIcon;
	}
}


#pragma mark - Attributed Text

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	
	[super setSelected:selected animated:animated];
	
	[self updateText];
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	
	[super setHighlighted:highlighted animated:animated];
	
	[self updateText];
}


- (void)updateTextWithColor:(UIColor *)color {
	
	NSAttributedString *attributedText = self.textLabel.attributedText;
	if ([attributedText length] < 1)
		return;
	
	NSDictionary *attributes = [attributedText attributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0, 1)];
	NSMutableDictionary *attributesCopy = [attributes mutableCopy];
	
	attributesCopy[NSForegroundColorAttributeName] = color;
	
	NSAttributedString *updatedAttributedText = [[NSAttributedString alloc] initWithString:attributedText.string attributes:attributesCopy];
	
	self.textLabel.attributedText = updatedAttributedText;
}


- (void)makeTextHighlighted {
	
	[self updateTextWithColor:[app_delegate.theme colorForKey:@"sidebarSelectedTextColor"]];
}


- (void)makeTextNonHighlighted {
	
	[self updateTextWithColor:[app_delegate.theme colorForKey:@"sidebarTextColor"]];
	[self updateTextWithColor:[app_delegate.theme colorForKey:@"sidebarSelectedTextColor"]];
}


- (void)updateText {
	if (self.selected || self.highlighted)
		[self makeTextHighlighted];
	else
		[self makeTextNonHighlighted];
}


#pragma mark - UITableViewCell

- (void)prepareForReuse {
	[super prepareForReuse];
	[self makeTextNonHighlighted];
	self.imageView.hidden = NO;
	self.showIcon = YES;
}


#pragma mark Layout

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect rBounds = self.bounds;
	[self.contentView qs_setFrameIfNotEqual:rBounds];
	
	[self.backgroundView qs_setFrameIfNotEqual:rBounds];
	[self.selectedBackgroundView qs_setFrameIfNotEqual:rBounds];
	
	CGFloat iconLeftMargin = [app_delegate.theme floatForKey:@"sidebarIconOriginX"];
	CGRect rIcon = self.imageView.frame;
	rIcon.size = self.imageView.image.size;
	rIcon = CGRectCenteredVerticallyInRect(rIcon, rBounds);
	rIcon.size = self.imageView.image.size;
	rIcon.origin.x = iconLeftMargin;
	[self.imageView qs_setFrameIfNotEqual:rIcon];
	
	CGFloat sidebarTextOriginX = [app_delegate.theme floatForKey:@"sidebarTextOriginX"];
	if (!self.showIcon)
		sidebarTextOriginX = [app_delegate.theme floatForKey:@"sidebarTextHiddenIconOriginX"];
	CGRect rText = CGRectZero;
	rText.origin.x = sidebarTextOriginX;
	CGFloat sidebarWidth = [app_delegate.theme floatForKey:@"sidebarWidth"];
	rText.size.width = sidebarWidth - rText.origin.x;
	rText.origin.y = 0.0f;
	rText.size.height = rBounds.size.height - 0.0f;
	[self.textLabel qs_setFrameIfNotEqual:rText];
}


@end
