//
//  VSTimelineSectionHeaderView.m
//  Vesper
//
//  Created by Brent Simmons on 5/22/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTimelineSectionHeaderView.h"


@interface VSTimelineSectionHeaderView ()

@property (nonatomic, strong) UILabel *label;
@end


@implementation VSTimelineSectionHeaderView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame title:(NSString *)title {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.backgroundColor = [app_delegate.theme colorForKey:@"timelineSectionHeaderBackgroundColor"];
	
	CGRect rLabel = [self rectOfStatusLabel];
	UILabel *label = [[UILabel alloc] initWithFrame:rLabel];
	label.opaque = NO;
	label.backgroundColor = [UIColor clearColor];
	[self addSubview:label];
	
	label.textColor = [app_delegate.theme colorForKey:@"timelineSectionHeaderFontColor"];
	label.font = [app_delegate.theme fontForKey:@"timelineSectionHeaderFont"];
	label.text = title;
	
	[self setNeedsLayout];
	
	return self;
}


- (CGRect)rectOfStatusLabel {
	
	CGFloat labelOriginX = [app_delegate.theme floatForKey:@"timelineSectionHeaderTextOriginX"]; /*Also used as right margin*/
	CGFloat viewHeight = [app_delegate.theme floatForKey:@"timelineSectionHeaderHeight"];
	CGRect r = CGRectMake(labelOriginX, 0.0f, self.bounds.size.width - (labelOriginX + labelOriginX), viewHeight);
	
	return r;
}


- (void)layoutSubviews {
	[self.label qs_setFrameIfNotEqual:[self rectOfStatusLabel]];
}


@end
