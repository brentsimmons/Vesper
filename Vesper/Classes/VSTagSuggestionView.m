//
//  VSTagSuggestionView.m
//  Vesper
//
//  Created by Brent Simmons on 4/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagSuggestionView.h"
#import "VSDataController.h"
#import "VSTag.h"
#import "VSTagSuggestionButton.h"
#import "VSTagSuggestionButtonsContainerView.h"
#import "VSTagDetailScrollView.h"
#import "VSDetailTextView.h"
#import "VSDetailView.h"
#import "VSTagSuggester.h"


typedef struct {
	CGSize chevronSize;
	CGFloat bubbleCornerRadius;
	CGFloat bubbleHeight;
	CGFloat pipeHeight;
	CGFloat pipeWidth;
	CGFloat hideDuration;
} VSTagSuggestionViewLayoutBits;


static VSTagSuggestionViewLayoutBits tagSuggestionViewLayoutBits(VSTheme *theme) {
	
	VSTagSuggestionViewLayoutBits layoutBits;
	
	layoutBits.bubbleCornerRadius = [app_delegate.theme floatForKey:@"autoCompleteBubbleCornerRadius"];
	layoutBits.chevronSize = [app_delegate.theme sizeForKey:@"autoCompleteChevron"];
	layoutBits.bubbleHeight = [app_delegate.theme floatForKey:@"autoCompleteBubbleHeight"];
	layoutBits.pipeHeight = [app_delegate.theme floatForKey:@"autoCompletePipeHeight"];
	layoutBits.pipeWidth = [app_delegate.theme floatForKey:@"autoCompletePipeWidth"];
	layoutBits.hideDuration = [app_delegate.theme floatForKey:@"autoCompleteAnimationHideDuration"];
	
	return layoutBits;
}


@interface VSTagSuggestionView ()

@property (nonatomic, weak) id<VSTagSuggestionViewDelegate> delegate;
@property (nonatomic, strong) VSTagSuggestionButtonsContainerView *buttonsContainerView;
@property (nonatomic, strong) NSArray *suggestedTagNames;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, assign) VSTagSuggestionViewLayoutBits layoutBits;
@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, strong) UIColor *pipeColor;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, assign) CGFloat editingViewOriginX;
@end


@implementation VSTagSuggestionView


+ (CGFloat)height {
	
	static CGFloat height = 0.0f;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		VSTagSuggestionViewLayoutBits layoutBits = tagSuggestionViewLayoutBits(app_delegate.theme);
		height = layoutBits.bubbleHeight + layoutBits.chevronSize.height;
	});
	
	return height;
}


+ (CGSize)size {
	
	CGSize size = CGSizeZero;
	size.width = [UIScreen mainScreen].applicationFrame.size.width;
	size.height = [self height];
	
	return size;
}


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame delegate:(id<VSTagSuggestionViewDelegate>)delegate {
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_delegate = delegate;
	self.backgroundColor = [UIColor clearColor];
	
	_layoutBits = tagSuggestionViewLayoutBits(app_delegate.theme);
	_bubbleColor = [app_delegate.theme colorForKey:@"autoCompleteBubbleColor"];
	_pipeColor = [app_delegate.theme colorForKey:@"autoCompletePipeColor"];
	
	_buttonsContainerView = [[VSTagSuggestionButtonsContainerView alloc] initWithFrame:[self rectOfButtonsContainerView]];
	_buttonsContainerView.hidden = YES;
	_buttonsContainerView.autoresizingMask = UIViewAutoresizingNone;
	[self addSubview:_buttonsContainerView];
	
	[self addObserver:self forKeyPath:@"width" options:0 context:nil];
	[self addObserver:self forKeyPath:@"userTypedTag" options:0 context:nil];
	[self addObserver:self forKeyPath:@"tagNamesForNote" options:0 context:nil];
	[self addObserver:self forKeyPath:@"suggestedTagNames" options:0 context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingOriginXDidChange:) name:VSEditingTagViewOriginXDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstResponderDidChange:) name:VSDidBecomeFirstResponderNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	_delegate = nil;
	
	[self removeObserver:self forKeyPath:@"width"];
	[self removeObserver:self forKeyPath:@"userTypedTag"];
	[self removeObserver:self forKeyPath:@"tagNamesForNote"];
	[self removeObserver:self forKeyPath:@"suggestedTagNames"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"width"]) {
		[self animateToShowOrHideIfNeeded];
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
	
	else if ([keyPath isEqualToString:@"userTypedTag"]) {
		[self calculateSuggestedTagNames];
	}
	
	else if ([keyPath isEqualToString:@"tagNamesForNote"]) {
		[self calculateSuggestedTagNames];
	}
	
	else if ([keyPath isEqualToString:@"suggestedTagNames"]) {
		[self layoutButtonsAndCalculateWidth];
	}
}


#pragma mark - Notifications

- (void)editingOriginXDidChange:(NSNotification *)note {
	
	CGFloat originX = [[note userInfo][VSEditingTagViewOriginXKey] floatValue];
	originX += 15.0f; /*TODO: figure this out properly.*/
	
	self.editingViewOriginX = originX;
	[self setNeedsLayout];
}


- (void)firstResponderDidChange:(NSNotification *)note {
	
	UIView *firstResponder = [note userInfo][VSResponderKey];
	if ([firstResponder isKindOfClass:[UITextView class]])
		[self animateToHide];
}


#pragma mark - Animation

- (BOOL)shouldShow {
	
	return !QSStringIsEmpty(self.userTypedTag) && !QSIsEmpty(self.suggestedTagNames);
}


- (void)makeAllViewsHidden:(BOOL)hidden {
	
	self.buttonsContainerView.hidden = hidden;
	self.hidden = hidden;
}


- (void)setAlphaForAllViews:(CGFloat)alpha {
	
	self.buttonsContainerView.alpha = alpha;
}


- (void)animateToHide {
	
	if (!self.showing)
		return;
	
	self.showing = NO;
	
	[UIView animateWithDuration:self.layoutBits.hideDuration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[self setAlphaForAllViews:0.0f];
	} completion:^(BOOL finished) {
		
		[self makeAllViewsHidden:YES];
	}];
}

- (void)hide {
	[self setAlphaForAllViews:0.0f];
	[self makeAllViewsHidden:YES];
}


- (void)animateToShow {
	
	if (self.showing)
		return;
	
	self.showing = YES;
	[self makeAllViewsHidden:NO];
	[self setAlphaForAllViews:0.0f];
	
	[UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		//        self.bottomCircleView.alpha = 1.0f;
		
	} completion:^(BOOL finished) {
		
		[UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			//            self.middleCircleView.alpha = 1.0f;
			
		} completion:^(BOOL finished2) {
			
			[UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
				self.buttonsContainerView.alpha = 1.0f;
				
			} completion:^(BOOL finished3) {
				;
			}];
		}];
	}];
}


- (void)animateToShowOrHideIfNeeded {
	
	BOOL shouldShow = [self shouldShow];
	if (shouldShow == self.showing)
		return;
	
	if (shouldShow)
		[self animateToShow];
	else
		[self animateToHide];
}


#pragma mark - Suggested Tags

- (BOOL)tag:(VSTag *)tag isRepresentedInTagNames:(NSSet *)tagNames {
	
	NSString *lowerTagName = [tag.name lowercaseString];
	if (QSStringIsEmpty(lowerTagName))
		return NO;
	
	for (NSString *oneTagName in tagNames) {
		
		if ([[oneTagName lowercaseString] isEqualToString:lowerTagName])
			return YES;
	}
	
	return NO;
}


- (NSArray *)tagsMatchingSearchString:(NSString *)searchString {
	
	return [VSTagSuggester tags:[VSDataController sharedController].tagsWithAtLeastOneNote matchingSearchString:searchString];
}


- (void)calculateSuggestedTagNames {
	
	if (QSIsEmpty(self.userTypedTag)) {
		self.suggestedTagNames = nil;
		return;
	}
	
	NSArray *matchingTags = [self tagsMatchingSearchString:self.userTypedTag];
	
	NSMutableArray *suggestedTags = [matchingTags mutableCopy];
	NSInteger i = 0;
	for (i = (NSInteger)[matchingTags count] - 1; i >= 0; i--) {
		
		VSTag *oneTag = [matchingTags objectAtIndex:(NSUInteger)i];
		if ([self tag:oneTag isRepresentedInTagNames:self.tagNamesForNote])
			[suggestedTags removeObjectAtIndex:(NSUInteger)i];
	}
	
	self.suggestedTagNames = [suggestedTags valueForKey:@"name"];
}


#pragma mark - Layout

- (void)removeCurrentButtons {
	
	//    for (UIButton *oneButton in self.buttons) {
	//        [oneButton removeFromSuperview];
	//    }
	
	self.buttons = nil;
}


- (void)layoutButtonsAndCalculateWidth {
	
	[self removeCurrentButtons];
	
	if (QSIsEmpty(self.suggestedTagNames)) {
		self.width = 0.0f;
		return;
	}
	
	NSMutableArray *buttons = [NSMutableArray new];
	
	for (NSString *oneTagName in self.suggestedTagNames) {
		
		VSTagSuggestionButton *tagSuggestionButton = [VSTagSuggestionButton buttonWithTitle:oneTagName];
		[tagSuggestionButton addTarget:self action:@selector(tagSuggestionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		[buttons addObject:tagSuggestionButton];
	}
	
	self.buttonsContainerView.buttons = [buttons copy];
	self.width = self.buttonsContainerView.bubbleWidth;
	self.buttons = [buttons copy];
	
	if (self.width < 13.0f)
		[self hide];
}


- (void)layoutSubviews {
	
	//    CGRect rBottomCircle = [self rectOfBottomCircle];
	//    [self.bottomCircleView qs_setFrameIfNotEqual:rBottomCircle];
	//
	//    CGRect rMiddleCircle = [self rectOfMiddleCircle];
	//    [self.middleCircleView qs_setFrameIfNotEqual:rMiddleCircle];
	
	CGRect rButtons = [self rectOfButtonsContainerView];
	[self.buttonsContainerView qs_setFrameIfNotEqual:rButtons];
}


- (CGSize)sizeThatFits:(CGSize)constrainingSize {
	
	/*constrainingSize is ignored*/
	
	CGSize size;
	size.height = [[self class] height];
	size.width = self.superview.bounds.size.width;
	
	return size;
}


- (CGRect)rectOfButtonsContainerView {
	CGRect r = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height);
	return r;
}


#pragma mark - Actions

- (void)tagSuggestionButtonTapped:(VSTagSuggestionButton *)tagSuggestionButton {
	//    VSDoContentOffsetHack();
	[[NSNotificationCenter defaultCenter] postNotificationName:VSFastSwitchFirstResponderNotification object:self userInfo:nil];
	
	[self.delegate tagSuggestionView:self didChooseTagName:tagSuggestionButton.tagName];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSNewTagShouldStartNotification object:self userInfo:nil];
}


@end
