//
//  VSSmokescreenView.m
//  Vesper
//
//  Created by Brent Simmons on 4/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSmokescreenView.h"


@interface VSSmokescreenView ()

@property (nonatomic, assign, readwrite) NSUInteger useCount;
@end


@implementation VSSmokescreenView


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.backgroundColor = backgroundColor;
	self.opaque = YES;
	
	return self;
}


#pragma mark - Use Count

- (void)incrementUseCount {
	self.useCount = self.useCount + 1;
}


- (void)decrementUseCount {
	self.useCount = self.useCount - 1;
}


@end
