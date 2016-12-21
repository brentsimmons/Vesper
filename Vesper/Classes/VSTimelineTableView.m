//
//  VSTimelineTableView.m
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTimelineTableView.h"


@interface VSTimelineTableView ()

@property (nonatomic, assign) CGSize actualContentSize;
@property (nonatomic, assign) BOOL userHasScrolled;


@end


@implementation VSTimelineTableView


- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [self initWithFrame:frame style:UITableViewStylePlain];
	if (self == nil)
		return self;
	
	self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	self.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.opaque = YES;
	self.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.showsHorizontalScrollIndicator = NO;
	
	[self.panGestureRecognizer addTarget:self action:@selector(didScroll:)];
	
	return self;
}

- (void)didScroll:(UIPanGestureRecognizer *)panGestureRecognizer {
	self.userHasScrolled = YES;
}

/*This is a hack.
 When there are too few rows to fill the screen, pulling down the search bar is jerky.
 The work-around is to make sure the tableview thinks it's larger than the screen.
 The scroll indicator is hidden when necessary*/

static CGFloat hack_contentSizeFudge = 0.0f;

- (CGFloat)hack_contentSizeFudge {
	if (hack_contentSizeFudge == 0.0f) {
		hack_contentSizeFudge = [app_delegate.theme floatForKey:@"searchBarContainerViewHeight"];
	}
	return hack_contentSizeFudge;
}

- (CGFloat)totalHeightOfCells {
	NSInteger numberOfSections = [self numberOfSections];
	NSInteger numberOfRowsInLastSection = [self numberOfRowsInSection:numberOfSections-1];
	if (numberOfSections == 0 || numberOfRowsInLastSection == 0) {
		return 0.0f;
	}
	NSIndexPath *indexPathOfLastItem = [NSIndexPath indexPathForRow:numberOfRowsInLastSection-1 inSection:numberOfSections-1];
	CGRect rectForLastItem = [self rectForRowAtIndexPath:indexPathOfLastItem];
	CGFloat totalHeight = CGRectGetMaxY(rectForLastItem);
	return totalHeight;
}

- (void)hideSearchBarIfUserHasntScrolled {
	if (!self.userHasScrolled) {
		self.contentOffset = CGPointMake(0, [self hack_contentSizeFudge]);
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat totalHeight = [self totalHeightOfCells];
	CGRect rBounds = self.bounds;
	
	if (CGRectGetHeight(rBounds) > totalHeight) {
		CGSize contentSize = self.contentSize;
		contentSize.height = CGRectGetHeight(rBounds) + [self hack_contentSizeFudge];
		self.contentSize = contentSize;
		self.showsHorizontalScrollIndicator = NO;
	} else {
		self.showsHorizontalScrollIndicator = YES;
	}
	
	[self hideSearchBarIfUserHasntScrolled];
}

@end
