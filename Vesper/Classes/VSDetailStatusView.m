//
//  VSDetailStatusView.m
//  Vesper
//
//  Created by Brent Simmons on 7/17/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSDetailStatusView.h"


@interface VSDetailStatusView ()

@property (nonatomic) UILabel *label;
@property (nonatomic) UILabel *animatingOutLabel;
@property (nonatomic) UITapGestureRecognizer *gestureRecognizer;

@end


typedef NS_ENUM(NSUInteger, VSDetailStatusViewState) {
	VSDetailStatusViewStateBlank,
	VSDetailStatusViewStateCreationDate,
	VSDetailStatusViewStateModificationDate,
	VSDetailStatusViewCount
};

static NSUInteger VSDetailStatusViewStateMinimum = VSDetailStatusViewStateBlank;
static NSUInteger VSDetailStatusViewStateMaximum = VSDetailStatusViewCount;


@implementation VSDetailStatusView


#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (!self) {
		return nil;
	}
	
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	_label = [[UILabel alloc] initWithFrame:frame];
	_label.opaque = NO;
	_label.backgroundColor = [UIColor clearColor];
	_label.textAlignment = NSTextAlignmentCenter;
	_label.textColor = [app_delegate.theme colorForKey:@"detailToolbar.statusTextColor"];
	_label.font = [app_delegate.theme fontForKey:@"detailToolbar.statusFont"];
	_label.userInteractionEnabled = YES;
	_label.adjustsFontSizeToFitWidth = YES;
	
	[self addSubview:_label];
	
	_animatingOutLabel = [[UILabel alloc] initWithFrame:frame];
	_animatingOutLabel.opaque = NO;
	_animatingOutLabel.backgroundColor = [UIColor clearColor];
	_animatingOutLabel.textAlignment = NSTextAlignmentCenter;
	_animatingOutLabel.textColor = [app_delegate.theme colorForKey:@"detailToolbar.statusTextColor"];
	_animatingOutLabel.font = [app_delegate.theme fontForKey:@"detailToolbar.statusFont"];
	_animatingOutLabel.userInteractionEnabled = YES;
	_animatingOutLabel.adjustsFontSizeToFitWidth = YES;
	
	_gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToNextState:)];
	[self addGestureRecognizer:_gestureRecognizer];
	
	[self updateUI];
	
	return self;
}


#pragma mark - Accessors

- (void)setCharacterCount:(NSUInteger)characterCount {
	
	if (characterCount == _characterCount) {
		return;
	}
	_characterCount = characterCount;
	
	if (self.state == VSDetailStatusViewCount) {
		[self updateUI];
	}
}


- (void)setWordCount:(NSUInteger)wordCount {
	
	if (wordCount == _wordCount) {
		return;
	}
	
	_wordCount = wordCount;
	
	if (self.state == VSDetailStatusViewCount) {
		[self updateUI];
	}
}


- (void)setCreationDate:(NSDate *)creationDate {
	
	if ([creationDate isEqual:_creationDate]) {
		return;
	}
	
	_creationDate = creationDate;
	
	if (self.state == VSDetailStatusViewStateCreationDate) {
		[self updateUI];
	}
}


- (void)setModificationDate:(NSDate *)modificationDate {
	
	if ([modificationDate isEqual:_modificationDate]) {
		return;
	}
	
	_modificationDate = modificationDate;
	[self updateUI];
	
	if (self.state == VSDetailStatusViewStateModificationDate) {
		[self updateUI];
	}
}


#pragma mark - UIView

- (void)layoutSubviews {
	
	CGRect r = self.bounds;
	[self.label qs_setFrameIfNotEqual:r];
}


#pragma mark - States

- (VSDetailStatusViewState)constrainedStateWithInteger:(NSInteger)state {
	
	if (state < (NSInteger)VSDetailStatusViewStateMinimum) {
		state = (NSInteger)VSDetailStatusViewStateMinimum;
	}
	if (state > (NSInteger)VSDetailStatusViewStateMaximum) {
		state = (NSInteger)VSDetailStatusViewStateMaximum;
	}
	
	return (VSDetailStatusViewState)state;
}


static NSString *VSDetailStatusViewStateKey = @"detailStatusState";

- (VSDetailStatusViewState)state {
	
	NSInteger state = [[NSUserDefaults standardUserDefaults] integerForKey:VSDetailStatusViewStateKey];
	return [self constrainedStateWithInteger:state];
}


- (void)setState:(VSDetailStatusViewState)state {
	
	state = [self constrainedStateWithInteger:(NSInteger)state];
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)state forKey:VSDetailStatusViewStateKey];
}


- (VSDetailStatusViewState)nextStateWithState:(VSDetailStatusViewState)initialState {
	
	NSInteger state = initialState;
	state = state + 1;
	if (state > (NSInteger)VSDetailStatusViewStateMaximum) {
		state = (NSInteger)VSDetailStatusViewStateMinimum; /*Wrap around*/
	}
	
	return [self constrainedStateWithInteger:state];
}


#pragma mark - Actions

- (void)switchToNextState:(id)sender {
	
	self.animatingOutLabel.text = self.label.text;
	self.animatingOutLabel.frame = self.label.frame;
	[self addSubview:self.animatingOutLabel];
	
	CGRect rLabel = self.label.frame;
	CGRect rLabelInitial = rLabel;
	rLabelInitial.origin.y = CGRectGetHeight(self.frame);
	self.label.frame = rLabelInitial;
	
	VSDetailStatusViewState state = [self nextStateWithState:self.state];
	self.state = state;
	
	self.label.text = [self currentText];
	
	self.label.alpha = 0.0f;
	self.animatingOutLabel.alpha = 1.0f;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[app_delegate.theme animateWithAnimationSpecifierKey:@"detailToolbar.statusAnimation" animations:^{
		
		CGRect rAnimatingOutlabel = self.animatingOutLabel.frame;
		rAnimatingOutlabel.origin.y = -(CGRectGetHeight(rAnimatingOutlabel));
		self.animatingOutLabel.frame = rAnimatingOutlabel;
		self.animatingOutLabel.alpha = 0.0f;
		
		self.label.frame = rLabel;
		self.label.alpha = 1.0f;
		
	} completion:^(BOOL finished) {
		
		[self.animatingOutLabel removeFromSuperview];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}


#pragma mark - UI

- (NSDateFormatter *)dateFormatter {
	
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDoesRelativeDateFormatting:YES];
	}
	
	return dateFormatter;
}


- (NSString *)stringWithDate:(NSDate *)d {
	
	NSMutableString *s = [[[self dateFormatter] stringFromDate:d] mutableCopy];
	
	[s replaceOccurrencesOfString:@"Yesterday" withString:@"yesterday" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
	[s replaceOccurrencesOfString:@"Today" withString:@"today" options:NSLiteralSearch range:NSMakeRange(0, s.length)];
	
	return [s copy];
}


- (NSString *)creationDateString {
	
	if (!self.creationDate) {
		return @"";
	}
	
	NSString *dateString = [self stringWithDate:self.creationDate];
	NSString *s = NSLocalizedString(@"Created", nil);
	return [NSString stringWithFormat:@"%@ %@", s, dateString];
}


- (NSString *)modificationDateString {
	
	if (!self.modificationDate) {
		return @"";
	}
	
	NSString *dateString = [self stringWithDate:self.modificationDate];
	NSString *s = NSLocalizedString(@"Modified", nil);
	return [NSString stringWithFormat:@"%@ %@", s, dateString];
}


- (NSString *)countString {
	
	if (self.characterCount <= 200) {
		return [NSString stringWithFormat:@"%ld characters", (long)self.characterCount];
	}
	
	return [NSString stringWithFormat:@"%ld words", (long)self.wordCount];
}


- (NSString *)currentText {
	
	NSString *s = nil;
	
	switch (self.state) {
			
		case VSDetailStatusViewStateBlank:
			s = @"";
			break;
			
		case VSDetailStatusViewStateCreationDate:
			s = [self creationDateString];
			break;
			
		case VSDetailStatusViewStateModificationDate:
			s = [self modificationDateString];
			break;
			
		case VSDetailStatusViewCount:
			s = [self countString];
			break;
			
		default:
			s = @""; /*Shouldn't get here*/
			break;
	}
	
	return s;
}


- (void)updateUI {
	
	NSString *updatedText = [self currentText];
	
	if (![updatedText isEqualToString:self.label.text]) {
		self.label.text = updatedText;
	}
}


@end

