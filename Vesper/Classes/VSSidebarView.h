//
//  VSSidebarView.h
//  Vesper
//
//  Created by Brent Simmons on 5/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import UIKit;

@interface VSSidebarView : UIToolbar


@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, assign) CGFloat originX;

/*Call from within animation blocks.*/

- (void)moveToSidebarOpenPosition;
- (void)moveToSidebarClosedPosition;


@end
