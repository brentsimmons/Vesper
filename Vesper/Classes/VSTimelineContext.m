//
//  VSTimelineContext.m
//  Vesper
//
//  Created by Brent Simmons on 3/15/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSTimelineContext.h"

@implementation VSTimelineContext


- (QS_IMAGE *)noNotesImage {

	return [QS_IMAGE
			imageNamed:self.noNotesImageName];
}


@end
