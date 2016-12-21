//
//  VSTagProxy.m
//  Vesper
//
//  Created by Brent Simmons on 4/11/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagProxy.h"
#import "VSTag.h"
#import "VSDataController.h"


@interface VSTagProxy ()

@property (nonatomic, strong, readwrite) VSTag *initialTag;
@end


@implementation VSTagProxy

#pragma mark - Class Methods

+ (instancetype)tagProxyWithTag:(VSTag *)tag {
	
	VSTagProxy *tagProxy = [self new];
	tagProxy.tag = tag;
	tagProxy.initialTag = tag;
	tagProxy.name = tag.name;
	return tagProxy;
}


+ (NSArray *)tagProxiesWithTags:(NSArray *)tags {
	
	NSMutableArray *tagProxies = [NSMutableArray new];
	
	for (VSTag *oneTag in tags) {
		VSTagProxy *oneTagProxy = [self tagProxyWithTag:oneTag];
		[tagProxies addObject:oneTagProxy];
	}
	
	return [tagProxies copy];
}


+ (instancetype)tagProxyWithName:(NSString *)name {
	
	VSTagProxy *tagProxy = [self new];
	tagProxy.name = name;
	return tagProxy;
}


#pragma mark - Init

- (instancetype)init {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	[self addObserver:self forKeyPath:@"tag" options:0 context:nil];
	[self addObserver:self forKeyPath:@"name" options:0 context:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"tag"];
	[self removeObserver:self forKeyPath:@"name"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"tag"])
		[self updateNameBasedOnTag];
	
	else if ([keyPath isEqualToString:@"name"])
		[self updateTagBasedOnName];
}


#pragma mark - Accessors

- (NSString *)normalizedName {
	
	if (self.name == nil)
		return nil;
	
	return [VSTag normalizedTagName:self.name];
}


#pragma mark - Updating

- (void)updateNameBasedOnTag {
	
	if (self.tag == nil)
		return; /*It's okay to have a name without a tag.*/
	
	NSString *tagName = self.tag.name;
	if (!QSStringIsEmpty(tagName) && ![self.name isEqualToString:tagName])
		self.name = self.tag.name;
}


- (void)updateTagBasedOnName {
	
	NSString *normalizedName = self.normalizedName;
	
	if (QSStringIsEmpty(normalizedName)) {
		self.tag = nil;
		return;
	}
	
	VSTag *existingTag = [[VSDataController sharedController] existingTagWithName:normalizedName];
	if (existingTag != self.tag) {
		self.tag = existingTag;
	}
}


- (void)createTagIfNeeded {
	
	NSString *normalizedName = self.normalizedName;
	if (!QSStringIsEmpty(normalizedName)) {
		VSTag *tag = [[VSDataController sharedController] tagWithName:normalizedName];
		self.tag = tag;
	}
}


- (BOOL)isGhostTag {
	return NO;
}


@end


@implementation VSGhostTagProxy

+ (instancetype)ghostTagProxy {
	
	static VSGhostTagProxy *ghostTagProxy = nil;
	if (ghostTagProxy == nil)
		ghostTagProxy = [VSGhostTagProxy new];
	return ghostTagProxy;
}


- (BOOL)isGhostTag {
	return YES;
}

@end
