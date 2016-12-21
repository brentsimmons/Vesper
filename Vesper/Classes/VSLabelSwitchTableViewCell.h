//
//  VSLabelSwitchTableViewCell.h
//  Vesper
//
//  Created by Brent Simmons on 4/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@interface VSLabelSwitchTableViewCell : UITableViewCell

- (instancetype)initWithLabel:(NSString *)label;

@property (nonatomic, readonly) UISwitch *switchView;

@end
