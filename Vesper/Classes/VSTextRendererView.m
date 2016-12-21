//
//  VSTextRendererView.m
//  Vesper
//
//  Created by Brent Simmons on 5/21/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTextRendererView.h"
#import "VSNoteTextRenderer.h"


@implementation VSTextRendererView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.backgroundColor = [UIColor clearColor];
	
	self.contentMode = UIViewContentModeTopLeft;
	self.autoresizingMask = UIViewAutoresizingNone;
	
	[self addObserver:self forKeyPath:@"highlightingLink" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"highlightedLinkID" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"textRenderer" options:0 context:NULL];
	
	self.userInteractionEnabled = NO;
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"highlightingLink"];
	[self removeObserver:self forKeyPath:@"highlightedLinkID"];
	[self removeObserver:self forKeyPath:@"textRenderer"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"highlightingLink"] || [keyPath isEqualToString:@"highlightedLinkID"] || [keyPath isEqualToString:@"textRenderer"])
		
		[self setNeedsDisplay];
}


#pragma mark - Drawing

- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(CGRect)rect {
	
	[super drawRect:rect];
	
	CGRect textRect = self.bounds;
	
	if (self.highlightingLink && !QSIsEmpty(self.highlightedLinkID))
		[self.textRenderer renderTextInRect:textRect highlightedLinkID:self.highlightedLinkID];
	else
		[self.textRenderer renderTextInRect:textRect];
}


@end
