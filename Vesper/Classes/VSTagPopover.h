//
//  VSTagPopover.h
//  Vesper
//
//  Created by Brent Simmons on 5/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSIconGridPopover.h"


@class VSTagProxy;

@interface VSTagPopover : VSIconGridPopover

@property (nonatomic, strong) VSTagProxy *tagProxy;

@end
