//
//  VSTagSuggestionButtonsContainerView.m
//  Vesper
//
//  Created by Brent Simmons on 4/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagSuggestionButtonsContainerView.h"
#import "VSTagSuggestionButton.h"
#import "VSTagDetailScrollView.h"
#import "VSTagTextFieldContainerView.h"


typedef struct {
	CGFloat bubbleCornerRadius;
	CGFloat bubbleHeight;
	CGFloat pipeHeight;
	CGFloat pipeWidth;
	CGFloat paddingLeft;
	CGFloat paddingRight;
	CGFloat marginLeft;
	CGFloat marginRight;
	CGFloat shadowOffsetY;
	CGFloat shadowBlurRadius;
	CGFloat shadowAlpha;
	CGSize chevronSize;
	CGFloat chevronOriginX;
	CGFloat borderWidth;
} VSTagSuggestionButtonsContainerViewLayoutBits;


static VSTagSuggestionButtonsContainerViewLayoutBits containerViewLayoutBits(VSTheme *theme) {
	
	VSTagSuggestionButtonsContainerViewLayoutBits layoutBits;
	
	layoutBits.bubbleCornerRadius = [theme floatForKey:@"autoCompleteBubbleCornerRadius"];
	layoutBits.bubbleHeight = [theme floatForKey:@"autoCompleteBubbleHeight"];
	layoutBits.pipeHeight = [theme floatForKey:@"autoCompletePipeHeight"];
	layoutBits.pipeWidth = [theme floatForKey:@"autoCompletePipeWidth"];
	layoutBits.paddingLeft = [theme floatForKey:@"autoCompletePaddingLeft"];
	layoutBits.paddingRight = [theme floatForKey:@"autoCompletePaddingRight"];
	layoutBits.marginLeft = [theme floatForKey:@"autoCompleteMarginLeft"];
	layoutBits.marginRight = [theme floatForKey:@"autoCompleteMarginRight"];
	layoutBits.shadowOffsetY = [theme floatForKey:@"autoCompleteBubbleShadowYOffset"];
	layoutBits.shadowBlurRadius = [theme floatForKey:@"autoCompleteBubbleShadowRadius"];
	layoutBits.shadowAlpha = [theme floatForKey:@"autoCompleteBubbleShadowAlpha"];
	layoutBits.chevronSize = [theme sizeForKey:@"autoCompleteChevron"];
	layoutBits.chevronOriginX = [theme floatForKey:@"autoCompleteChevronOriginX"];
	layoutBits.borderWidth = [theme floatForKey:@"autoCompleteBubbleBorderThickness"];
	
	return layoutBits;
}


@interface VSButtonsContainerView : UIView

@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat editingViewOriginX;
@end


@interface VSTagSuggestionButtonsContainerView ()

@property (nonatomic, assign) VSTagSuggestionButtonsContainerViewLayoutBits layoutBits;
@property (nonatomic, assign, readwrite) CGFloat width;
@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, strong) UIColor *pipeColor;
@property (nonatomic, strong) VSButtonsContainerView *buttonsContainerView;
@property (nonatomic, assign) CGFloat editingViewOriginX;
@end


@implementation VSTagSuggestionButtonsContainerView


+ (UIColor *)pipeColor {
	return [app_delegate.theme colorForKey:@"autoCompletePipeColor"];
}


+ (UIColor *)bubbleColor {
	return [app_delegate.theme colorForKey:@"autoCompleteBubbleColor"];
}


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = containerViewLayoutBits(app_delegate.theme);
	_bubbleColor = [app_delegate.theme colorForKey:@"autoCompleteBubbleColor"];
	_pipeColor = [app_delegate.theme colorForKey:@"autoCompletePipeColor"];
	
	CGRect rContainer = frame;
	rContainer.origin.x = _layoutBits.marginLeft;
	rContainer.size.width = frame.size.width - (_layoutBits.marginLeft + _layoutBits.marginRight);
	if (rContainer.size.width < 0.0f)
		rContainer.size.width = 0.0f;
	_buttonsContainerView = [[VSButtonsContainerView alloc] initWithFrame:rContainer];
	_buttonsContainerView.autoresizingMask = UIViewAutoresizingNone;
	_buttonsContainerView.contentMode = UIViewContentModeRedraw;
	[self addSubview:_buttonsContainerView];
	
	//    self.backgroundColor = [UIColor greenColor];
	
	[self addObserver:self forKeyPath:@"buttons" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"width" options:0 context:NULL];
	
	self.layer.shadowOffset = CGSizeMake(0, _layoutBits.shadowOffsetY);
	self.layer.shadowRadius = _layoutBits.shadowBlurRadius;
	self.layer.shadowColor = [app_delegate.theme colorForKey:@"autoCompleteBubbleShadowColor"].CGColor;
	self.layer.shadowOpacity = (float)_layoutBits.shadowAlpha;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingOriginXDidChange:) name:VSEditingTagViewOriginXDidChangeNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"buttons"];
	[self removeObserver:self forKeyPath:@"width"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"buttons"]) {
		self.buttonsContainerView.buttons = self.buttons;
		[self updateUI];
	}
	
	else if ([keyPath isEqualToString:@"width"]) {
		self.buttonsContainerView.width = self.width;
	}
}


#pragma mark - Notifications

- (void)editingOriginXDidChange:(NSNotification *)note {
	
	CGFloat originX = [[note userInfo][VSEditingTagViewOriginXKey] floatValue];
	self.editingViewOriginX = originX;
	[self setNeedsLayout];
	
	CGPoint pt = CGPointMake(originX, 0.0f);
	pt = [self convertPoint:pt toView:self.buttonsContainerView];
	self.buttonsContainerView.editingViewOriginX = pt.x;
}


#pragma mark - UI

- (void)updateUI {
	
	[self removeButtons];
	[self addButtons];
	[self setNeedsLayout];
	[self.buttonsContainerView setNeedsLayout];
	[self.buttonsContainerView setNeedsDisplay];
}


- (void)removeButtons {
	
	for (UIView *oneView in self.buttonsContainerView.subviews)
		[oneView removeFromSuperview];
}


- (void)addButtons {
	
	for (UIView *oneView in self.buttons)
		[self.buttonsContainerView addSubview:oneView];
}


- (void)hideAllButtons {
	for (UIView *oneView in self.buttons)
		oneView.hidden = YES;
}


#pragma mark - Layout

- (CGFloat)maximumWidthOfSuggestionBubble {
	return self.bounds.size.width - (self.layoutBits.marginLeft + self.layoutBits.marginRight);
}


- (CGFloat)maximumWidthOfSuggestionBubbleMinusPadding {
	CGFloat maxWidth = [self maximumWidthOfSuggestionBubble];
	maxWidth -= (self.layoutBits.paddingLeft + self.layoutBits.paddingRight);
	return maxWidth;
}


- (CGFloat)buttonsWidth {
	
	/*Includes padding on first and last button. Calculates width of the bubble.*/
	
	[self hideAllButtons];
	
	CGFloat currentWidth = 0.0f;
	CGFloat totalWidthAvailable = [self maximumWidthOfSuggestionBubbleMinusPadding];
	NSUInteger ix = 0;
	
	for (VSTagSuggestionButton *oneButton in self.buttons) {
		
		CGRect rButton = oneButton.frame;
		CGSize buttonSize = rButton.size;
		CGFloat proposedWidth = currentWidth + buttonSize.width;
		if (ix > 0)
			proposedWidth += self.layoutBits.pipeWidth;
		
		BOOL proposedWidthIsTooWide = proposedWidth > totalWidthAvailable;
		if (proposedWidthIsTooWide)
			break;
		
		oneButton.hidden = NO;
		currentWidth = proposedWidth;
		
		ix++;
	}
	
	return currentWidth;
}


- (CGFloat)bubbleWidth {
	
	CGFloat bubbleWidth = self.buttonsWidth + self.layoutBits.paddingLeft + self.layoutBits.paddingRight;
	return bubbleWidth;
}


- (void)layoutContainerView {
	
	CGRect r = self.bounds;
	r.size.height = r.size.height;
	r.size.width = self.bubbleWidth;
	//    r.origin.x = self.layoutBits.marginLeft;
	r.origin.x = self.editingViewOriginX;
	
	CGFloat maxBounds = CGRectGetMaxX(self.bounds);
	CGFloat maxR = CGRectGetMaxX(r);
	
	if (maxR > maxBounds) {
		CGFloat extraSpace = maxR - maxBounds;
		r.origin.x -= extraSpace;
		r.origin.x -= self.layoutBits.marginRight;
	}
	
	if (!CGRectEqualToRect(r, self.buttonsContainerView.frame)) {
		[self.buttonsContainerView qs_setFrameIfNotEqual:r];
		[self.buttonsContainerView setNeedsDisplay];
		[self.buttonsContainerView setNeedsLayout];
	}
}


- (void)layoutSubviews {
	
	//    [self layoutButtons];
	[self layoutContainerView];
}


@end


#pragma mark -

@interface VSButtonsContainerView ()

@property (nonatomic, assign) VSTagSuggestionButtonsContainerViewLayoutBits layoutBits;
@property (nonatomic, assign) CGRect tagViewFrame;
@end

@implementation VSButtonsContainerView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	_layoutBits = containerViewLayoutBits(app_delegate.theme);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagDidBeginEditing:) name:VSTagDidBeginEditingNotification object:nil];
	
	return self;
}

#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


#pragma mark - Notifications

- (void)tagDidBeginEditing:(NSNotification *)note {
	
	VSTagTextFieldContainerView *tagView = [note userInfo][VSTagKey];
	CGRect rTagView = tagView.frame;
	rTagView.origin.x += 15.0f;
	self.tagViewFrame = rTagView;
	//    [self setNeedsLayout];
	[self setNeedsDisplay];
}


#pragma mark - Layout

- (void)layoutSubviews {
	
	//    CGRect rBounds = self.bounds;
	//    NSLog(@"layoutSubviews %f %f %f %f", rBounds.origin.x, rBounds.origin.y, rBounds.size.width, rBounds.size.height);
	NSUInteger ix = 0;
	
	for (VSTagSuggestionButton *oneButton in self.buttons) {
		
		CGRect rButton = oneButton.frame;
		rButton.origin.x = self.layoutBits.paddingLeft;
		//        rButton.origin.y += 0.5f;
		
		if (ix > 0) {
			VSTagSuggestionButton *previousButton = [self.buttons objectAtIndex:ix - 1];
			CGRect rPrevious = previousButton.frame;
			rButton.origin.x = CGRectGetMaxX(rPrevious) + self.layoutBits.pipeWidth;
		}
		
		[oneButton qs_setFrameIfNotEqual:rButton];
		
		ix++;
	}
}


#pragma mark - Drawing

- (void)setWidth:(CGFloat)width {
	_width = width;
	[self setNeedsDisplay];
}


- (BOOL)isOpaque {
	return NO;
}


- (void)drawPipeAfterButton:(UIButton *)oneButton {
	
	CGRect rPipe = CGRectZero;
	rPipe.size.width = 1.0f;
	rPipe.size.height = self.layoutBits.pipeHeight;
	rPipe.origin.x = CGRectGetMaxX(oneButton.frame);
	rPipe.origin.y = 0.0f;
	
	CGRect rPipeContainer = rPipe;
	rPipeContainer.size.height = self.layoutBits.bubbleHeight;
	rPipeContainer.size.width = self.layoutBits.pipeWidth;
	
	rPipe = CGRectCenteredHorizontallyInRect(rPipe, rPipeContainer);
	rPipe = CGRectCenteredVerticallyInRect(rPipe, rPipeContainer);
	
	[[VSTagSuggestionButtonsContainerView pipeColor] set];
	UIRectFill(rPipe);
}


- (CGRect)bubbleRect {
	
	VSTagSuggestionButtonsContainerViewLayoutBits layoutBits = self.layoutBits;
	
	CGRect rBubble = self.bounds;
	
	if (CGRectGetWidth(rBubble) < (layoutBits.bubbleCornerRadius * 2)) {
		rBubble.size.width = layoutBits.bubbleCornerRadius * 2;
	}
	
	rBubble.size.height = layoutBits.bubbleHeight;
	
	rBubble = CGRectInset(rBubble, layoutBits.bubbleCornerRadius, layoutBits.bubbleCornerRadius);
	
	rBubble.origin.x += 0.5f;
	rBubble.size.width -= 3.0f;
	rBubble.origin.y += 0.5f;
	rBubble.size.height -= 1.0f;
	
	return rBubble;
}


#define degreesToRadians(x) ((x) * (CGFloat)M_PI / 180.0f)

- (UIBezierPath *)popoverPathWithBubbleRect:(CGRect)rBubble {
	
	VSTagSuggestionButtonsContainerViewLayoutBits layoutBits = self.layoutBits;
	
	UIBezierPath *path = [UIBezierPath bezierPath];
	path.lineWidth = layoutBits.borderWidth;
	
	[path addArcWithCenter:rBubble.origin radius:layoutBits.bubbleCornerRadius startAngle:degreesToRadians(180.0f) endAngle:degreesToRadians(270.0f) clockwise:YES];
	
	[path addArcWithCenter:CGPointMake(CGRectGetMaxX(rBubble), CGRectGetMinY(rBubble)) radius:layoutBits.bubbleCornerRadius startAngle:degreesToRadians(270.0f) endAngle:degreesToRadians(360.0f) clockwise:YES];
	
	[path addArcWithCenter:CGPointMake(CGRectGetMaxX(rBubble), CGRectGetMaxY(rBubble)) radius:layoutBits.bubbleCornerRadius startAngle:degreesToRadians(0.0f) endAngle:degreesToRadians(90.0f) clockwise:YES];
	
	CGPoint chevronPoint = CGPointZero;
	CGFloat tagX = CGRectGetMinX(self.tagViewFrame);
	tagX -= self.frame.origin.x;
	chevronPoint.x = tagX;
	if (chevronPoint.x < rBubble.origin.x + 5.0f)
		chevronPoint.x = rBubble.origin.x + 5.0f;
	if (chevronPoint.x > CGRectGetMaxX(rBubble))
		chevronPoint.x = CGRectGetMaxX(rBubble) - 5.0f;
	
#if __LP64__
	chevronPoint.y = floor(CGRectGetMaxY(rBubble));
#else
	chevronPoint.y = floorf(CGRectGetMaxY(rBubble));
#endif
	
	CGPoint arrowRight = chevronPoint;
	
	arrowRight.x = arrowRight.x + (layoutBits.chevronSize.width / 2.0f);
	arrowRight.y = CGRectGetMaxY(rBubble) + layoutBits.bubbleCornerRadius;
	
	CGPoint arrowMiddle = arrowRight;
	arrowMiddle.x = chevronPoint.x;
	arrowMiddle.y = arrowRight.y + layoutBits.chevronSize.height;
	
	CGPoint arrowLeft = arrowRight;
	arrowLeft.x = arrowLeft.x - layoutBits.chevronSize.width;
	
	[path addLineToPoint:arrowRight];
	[path addLineToPoint:arrowMiddle];
	[path addLineToPoint:arrowLeft];
	
	[path addArcWithCenter:CGPointMake(CGRectGetMinX(rBubble), CGRectGetMaxY(rBubble)) radius:layoutBits.bubbleCornerRadius startAngle:degreesToRadians(90.0f) endAngle:degreesToRadians(180.0f) clockwise:YES];
	
	[path closePath];
	
	return path;
}


- (void)drawRect:(CGRect)rect {
	
	VSTagSuggestionButtonsContainerViewLayoutBits layoutBits = self.layoutBits;
	
	CGRect rBubble = [self bubbleRect];
	
	UIBezierPath *bezierPath = [self popoverPathWithBubbleRect:rBubble];
	[[VSTagSuggestionButtonsContainerView bubbleColor] set];
	[bezierPath fill];
	
	if (layoutBits.borderWidth > 0.1f) {
		bezierPath.lineWidth = layoutBits.borderWidth;
		UIColor *borderColor = [app_delegate.theme colorForKey:@"autoCompleteBubbleBorderColor"];
		[borderColor set];
		[bezierPath stroke];
	}
	
	
	NSUInteger ix = 0;
	
	for (UIButton *oneButton in self.buttons) {
		
		if (oneButton.hidden)
			break;
		
		BOOL isLast = (oneButton == [self.buttons lastObject]);
		if (!isLast) {
			UIButton *nextButton = [self.buttons objectAtIndex:ix + 1];
			isLast = nextButton.hidden;
		}
		
		if (!isLast)
			[self drawPipeAfterButton:oneButton];
		
		ix++;
	}
}


@end

