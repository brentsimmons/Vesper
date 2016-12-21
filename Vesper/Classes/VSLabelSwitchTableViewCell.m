//
//  VSLabelSwitchTableViewCell.m
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSLabelSwitchTableViewCell.h"
#import "VSUI.h"


@interface VSLabelSwitchTableViewCell ()

@property (nonatomic, readwrite) UISwitch *switchView;
@property (nonatomic, assign) CGFloat labelWidth;
@property (nonatomic, assign) CGFloat switchMarginRight;

@end


@implementation VSLabelSwitchTableViewCell

- (instancetype)initWithLabel:(NSString *)label {

	self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	if (!self) {
		return nil;
	}

	[VSUI configureGroupedTableCell:self];

	[VSUI configureGroupedTableLabel:self.textLabel labelText:label];

	 _labelWidth = 200.0;

	_switchMarginRight = [app_delegate.theme floatForKey:@"groupedTable.switchMarginRight"];

	_switchView = [[UISwitch alloc] initWithFrame:CGRectZero]; /*control enforces size*/
	[self.contentView insertSubview:_switchView aboveSubview:self.textLabel];

	return self;
}


#pragma mark - UIView

- (void)layoutSubviews {

	[super layoutSubviews];

	[VSUI layoutGroupedTableLabel:self.textLabel labelWidth:self.labelWidth contentView:self.contentView];

	[VSUI layoutGroupedTableSwitch:self.switchView marginRight:self.switchMarginRight contentView:self.contentView];
}


@end
