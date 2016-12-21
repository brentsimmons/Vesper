//
//  VSTagDetailScrollView.m
//  Vesper
//
//  Created by Brent Simmons on 4/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagDetailScrollView.h"
#import "VSTagButton.h"
#import "VSEditableTagView.h"
#import "VSTagTextFieldContainerView.h"
#import "VSGhostTagButton.h"
#import "VSTagProxy.h"
#import "VSTag.h"


NSString *VSNewTagShouldStartNotification = @"VSNewTagShouldStartNotification";


typedef struct {
	CGFloat height;
	CGFloat insetTop;
	CGFloat insetLeft;
	CGFloat insetRight;
	CGFloat viewMarginRight;
} VSTagDetailScrollViewLayoutBits;


@interface VSTagDetailScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) VSTagDetailScrollViewLayoutBits layoutBits;
@property (nonatomic, strong) VSGhostTagButton *ghostTagButton;
@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, strong) UIGestureRecognizer *tapGestureRecognizer;
@end


@implementation VSTagDetailScrollView


#pragma mark - Class Methods

+ (VSTagDetailScrollViewLayoutBits)layoutBits {
	
	VSTagDetailScrollViewLayoutBits layoutBits;
	
	layoutBits.height = [app_delegate.theme floatForKey:@"tagDetailScrollViewHeight"];
	layoutBits.insetTop = [app_delegate.theme floatForKey:@"tagDetailScrollViewInsetTop"];
	layoutBits.insetLeft = [app_delegate.theme floatForKey:@"tagDetailScrollViewInsetLeft"];
	layoutBits.insetRight = [app_delegate.theme floatForKey:@"tagDetailScrollViewInsetRight"];
	layoutBits.viewMarginRight = [app_delegate.theme floatForKey:@"tagBubbleMarginRight"];
	
	return layoutBits;
}


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame tagProxies:(NSArray *)tagProxies {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = [[self class] layoutBits];
	_ghostTagButton = [VSGhostTagButton button];
	_views = [NSMutableArray array];
	
	self.backgroundColor = [UIColor clearColor]; /*Can't be opaque because of text view scrollbar*/
	self.opaque = NO;
	
	self.alwaysBounceHorizontal = YES;
	self.showsHorizontalScrollIndicator = NO;
	self.showsVerticalScrollIndicator = NO;
	self.scrollsToTop = NO;
	self.contentMode = UIViewContentModeRedraw;
	self.clipsToBounds = NO;
	
	_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
	[self addGestureRecognizer:_tapGestureRecognizer];
	_tapGestureRecognizer.delegate = self;
	
	[self createViewsForTagProxies:tagProxies];
	
	[self addObserver:self forKeyPath:@"readonly" options:NSKeyValueObservingOptionInitial context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstResponderDidChange:) name:VSDidBecomeFirstResponderNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowTagPopover:) name:VSWillShowTagPopoverNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startNewTag:) name:VSNewTagShouldStartNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"readonly"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"readonly"]) {
		self.ghostTagButton.hidden = self.readonly;
		if (self.readonly)
			[self endEditing];
	}
}


#pragma mark - Notifications

- (void)firstResponderDidChange:(NSNotification *)note {
	
	;
}


- (void)willShowTagPopover:(NSNotification *)note {
	[self endEditing];
}


#pragma mark - Layout

NSString *VSEditingTagViewOriginXDidChangeNotification = @"VSEditingTagViewOriginXDidChangeNotification";
NSString *VSEditingTagViewOriginXKey = @"VSEditingTagViewOriginXKey";

- (void)postEditingViewOriginXDidChangeNotification:(CGFloat)originX {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:VSEditingTagViewOriginXDidChangeNotification object:self userInfo:@{VSEditingTagViewOriginXKey : @(originX)}];
	});
}


- (void)layoutViews {
	
	VSTagDetailScrollViewLayoutBits layoutBits = self.layoutBits;
	
	UIView *previousView = nil;
	
	for (UIView *oneView in self.views) {
		
		BOOL viewIsTextFieldView = [self viewIsTextFieldView:oneView];
		
		CGRect r = oneView.frame;
		r.size = [oneView sizeThatFits:CGSizeZero];
		
		r.origin.x = 0.0f;
		r.origin.y = self.layoutBits.insetTop;
		
		if (previousView == nil)
			r.origin.x = layoutBits.insetLeft;
		
		if (previousView != nil) {
			CGRect rPrevious = previousView.frame;
			r.origin.x = CGRectGetMaxX(rPrevious) + layoutBits.viewMarginRight;
		}
		
		if (viewIsTextFieldView) {
			r.origin.y -= 0.5f;
			r.size.height += 1.0f;
		}
		
		[oneView qs_setFrameIfNotEqual:r];
		
		previousView = oneView;
		
		[oneView setNeedsDisplay];
		
		if (viewIsTextFieldView) {
			
			CGPoint textFieldViewOrigin = r.origin;
			textFieldViewOrigin = [self convertPoint:textFieldViewOrigin fromView:nil];
			CGFloat originX = textFieldViewOrigin.x;
			[self postEditingViewOriginXDidChangeNotification:originX];
		}
	}
	
	CGFloat width = CGRectGetMaxX(((UIView *)[self.views lastObject]).frame) + layoutBits.insetRight;
	CGFloat height = layoutBits.height;
	
	CGSize updatedContentSize = CGSizeMake(width, height);
	if (!CGSizeEqualToSize(self.contentSize, updatedContentSize))
		self.contentSize = updatedContentSize;
}


- (void)animateLayout:(void (^)(BOOL finished))completion {
	
	[UIView animateWithDuration:0.25f animations:^{
		
		[self layoutViews];
		
	} completion:completion];
}


- (BOOL)viewIsTextFieldView:(UIView *)view {
	return [view isKindOfClass:[VSTagTextFieldContainerView class]];
}


- (BOOL)tagNames:(NSMutableSet *)tagNames containsTagName:(NSString *)tagName {
	
	NSString *normalizedTagName = [VSTag normalizedTagName:tagName];
	
	for (NSString *oneTagName in tagNames) {
		
		NSString *oneNormalizedTagName = [VSTag normalizedTagName:oneTagName];
		if ([oneNormalizedTagName localizedCaseInsensitiveCompare:normalizedTagName] == NSOrderedSame)
			return YES;
	}
	
	return NO;
}


NSString *VSTagsDidEndEditingNotification = @"VSTagsDidEndEditingNotification";

- (void)endEditing {
	
	[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:VSTagsDidEndEditingNotification object:self userInfo:nil];
	
	NSMutableArray *editingTagViews = [NSMutableArray new];
	NSMutableSet *tagNames = [NSMutableSet set]; /*For checking for duplicates*/
	
	for (UIView *oneView in self.views) {
		if ([self viewIsTextFieldView:oneView]) {
			[editingTagViews addObject:oneView];
			[(VSTagTextFieldContainerView *)oneView updateTextForTagProxy];
		}
		
		else if ([oneView respondsToSelector:@selector(tagProxy)]) {
			NSString *oneTagName = ((id<VSEditableTagView>)oneView).tagProxy.name;
			if (!QSStringIsEmpty(oneTagName))
				[tagNames addObject:oneTagName];
		}
	}
	
	if (QSIsEmpty(editingTagViews))
		return;
	
	for (id<VSEditableTagView> oneTagView in editingTagViews) {
		
		NSUInteger ix = [self.views indexOfObjectIdenticalTo:oneTagView];
		if (ix == NSNotFound)
			continue;
		
		VSTagProxy *oneTagProxy = oneTagView.tagProxy;
		
		NSString *oneTagName = oneTagProxy.name;
		
		BOOL shouldRemove = QSStringIsEmpty(oneTagName);
		if (!shouldRemove)
			shouldRemove = ![oneTagName rs_hasNonWhitespaceAndNewlineCharacters];
		if (!shouldRemove)
			shouldRemove = [self tagNames:tagNames containsTagName:oneTagName];
		
		if (!shouldRemove) {
			VSTagButton *replacementButton = [VSTagButton buttonWithTagProxy:oneTagProxy];
			[self.views replaceObjectAtIndex:ix withObject:replacementButton];
			[self addSubview:replacementButton];
		}
		else
			[self.views removeObjectAtIndex:ix];
		
		[(UIView *)oneTagView removeFromSuperview];
	}
	
	/*Make sure ghost tag is at end and exists in just one place.*/
	if ([self.views containsObject:self.ghostTagButton])
		[self.views removeObject:self.ghostTagButton];
	[self.views addObject:self.ghostTagButton];
	[self addSubview:self.ghostTagButton];
	
	[self layoutViews];
}


- (VSTagTextFieldContainerView *)textFieldContainerViewWithTagProxy:(VSTagProxy *)tagProxy {
	
	if (tagProxy == nil)
		tagProxy = [VSTagProxy new];
	VSTagTextFieldContainerView *textFieldView = [VSTagTextFieldContainerView tagTextFieldContainerViewWithTagProxy:tagProxy];
	return textFieldView;
}


#pragma mark - Editing

- (VSTagTextFieldContainerView *)tagViewBeingEdited {
	
	for (id<VSEditableTagView> oneTagView in self.views) {
		if ([self viewIsTextFieldView:(UIView *)oneTagView])
			return (VSTagTextFieldContainerView *)oneTagView;
	}
	
	return nil;
}


- (void)addEditingTagView {
	
	[self endEditing];
	
	VSTagTextFieldContainerView *editingView = [self textFieldContainerViewWithTagProxy:nil];
	editingView.hidden = YES;
	
	[self.views removeObject:self.ghostTagButton];
	[self.ghostTagButton removeFromSuperview];
	
	[self.views addObject:editingView];
	[self addSubview:editingView];
	
	[self layoutViews];
	[editingView beginEditing];
	editingView.hidden = NO;
	
	
	//    [self animateLayout:^(BOOL finished) {
	//
	//        editingView.hidden = NO;
	//        editingView.alpha = 0.0f;
	//
	//        [UIView animateWithDuration:0.25f animations:^{
	//            editingView.alpha = 1.0f;
	//        } completion:^(BOOL finished2) {
	//            [editingView beginEditing];
	//        }];
	//     }];
}


- (BOOL)isEditing {
	return [self tagViewBeingEdited] != nil;
}


- (BOOL)editingViewIsEmpty {
	
	VSTagTextFieldContainerView *editingView = [self tagViewBeingEdited];
	if (editingView == nil)
		return YES;
	
	NSString *text = editingView.text;
	return QSStringIsEmpty(text);
}


- (void)userChoseSuggestedTagName:(NSString *)tagName {
	
	if (self.readonly)
		return;
	
	VSTagTextFieldContainerView *tagViewBeingEdited = [self tagViewBeingEdited];
	if (tagViewBeingEdited == nil)
		return;
	
	tagViewBeingEdited.userAcceptedSuggestedTag = tagName;
	[self endEditing];
}


#pragma mark - Tag Proxies

- (void)createViewsForTagProxies:(NSArray *)tagProxies {
	
	/*No views yet.*/
	
	for (VSTagProxy *oneTagProxy in tagProxies) {
		
		VSTagButton *oneTagButton = [VSTagButton buttonWithTagProxy:oneTagProxy];
		[self.views addObject:oneTagButton];
		[self addSubview:oneTagButton];
	}
	
	[self.views addObject:self.ghostTagButton];
	[self addSubview:self.ghostTagButton];
	
	[self layoutViews];
}


- (NSArray *)tagProxies {
	
	NSMutableArray *tagProxies = [NSMutableArray new];
	
	for (id<VSEditableTagView> oneTagView in self.views) {
		VSTagProxy *oneTagProxy = oneTagView.tagProxy;
		[tagProxies addObject:oneTagProxy];
	}
	
	return [tagProxies copy];
}


- (NSArray *)nonEditingTagProxies {
	
	NSMutableArray *tagProxies = [NSMutableArray new];
	
	for (id<VSEditableTagView> oneTagView in self.views) {
		if ([self viewIsTextFieldView:(UIView *)oneTagView])
			continue;
		VSTagProxy *oneTagProxy = oneTagView.tagProxy;
		if (!oneTagProxy.isGhostTag)
			[tagProxies addObject:oneTagProxy];
	}
	
	return [tagProxies copy];
}


#pragma mark - Actions

- (void)ghostTagButtonTapped:(id)sender {
	
	if (self.readonly) {
		return;
	}
	if ([self isEditing] && [self editingViewIsEmpty]) {
		return;
	}
	
	[self endEditing];
	[self addEditingTagView];
}


- (void)startNewTag:(id)sender {
	[self ghostTagButtonTapped:sender];
}


- (void)deleteTagButton:(VSTagButton *)tagButton {
	
	NSUInteger ix = [self.views indexOfObjectIdenticalTo:tagButton];
	if (ix == NSNotFound)
		return;
	
	[tagButton removeFromSuperview];
	[self.views removeObjectAtIndex:ix];
	
	[self animateLayout:NULL];
}


- (void)updateSizeForView:(UIView *)view {
	
	[self layoutViews];
}


- (void)tagTextFieldDidEndEditing:(UIView *)view {
	[self endEditing];
}


#pragma mark - Gesture Recognizers

- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)tapGestureRecognizer {
	
	[self qs_performSelectorViaResponderChain:@selector(editTextViewIfNotEditing:) withObject:self];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	if (gestureRecognizer != self.tapGestureRecognizer)
		return YES;
	
	CGPoint touchLocation = [gestureRecognizer locationInView:self];
	for (UIView *oneSubview in self.subviews) {
		if (CGRectContainsPoint(oneSubview.frame, touchLocation))
			return NO;
	}
	
	return YES;
}


#pragma mark - Updating

- (void)updateWithTagProxies:(NSArray *)tagProxies {
	
	[self endEditing];
	
	[self.views makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.views removeAllObjects];
	
	[self createViewsForTagProxies:tagProxies];
}

@end


