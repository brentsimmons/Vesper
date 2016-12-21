//
//  VSGroupedTableButtonViewCell.m
//  Vesper
//
//  Created by Brent Simmons on 5/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSGroupedTableButtonViewCell.h"
#import "VSProgressView.h"


@interface VSGroupedTableButtonViewCell ()

@property (nonatomic) VSProgressView *progressView;
@property (nonatomic) UILabel *labelToAnimate;
@property (nonatomic) UIImageView *successFailureImageView;
@property (nonatomic, assign) BOOL showingProgressOrImage;

@end


@implementation VSGroupedTableButtonViewCell


#pragma mark - Class Methods

+ (UIFont *)groupedTableButtonFont {
	
	UIFont *font = [app_delegate.theme fontForKey:@"groupedTable.buttonFont"];
	if (VSDefaultsUsingLightText()) {
		font = [app_delegate.theme fontForKey:@"groupedTable.buttonFontLight"];
	}
	
	return font;
}


#pragma mark - Init

- (instancetype)initWithLabelText:(NSString *)labelText destructive:(BOOL)destructive textAlignment:(NSTextAlignment)textAlignment {
	
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	if (!self) {
		return nil;
	}
	
	self.contentMode = UIViewContentModeRedraw;
	self.opaque = YES;
	self.contentView.backgroundColor = [app_delegate.theme colorForKey:@"groupedTable.cellBackgroundColor"];
	self.backgroundColor = self.contentView.backgroundColor;
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.backgroundView.backgroundColor = self.contentView.backgroundColor;
	self.backgroundView.opaque = YES;
	
	self.textLabel.textAlignment = textAlignment;
	self.textLabel.font = [[self class] groupedTableButtonFont];
	self.textLabel.textColor = [app_delegate.theme colorForKey:@"groupedTable.buttonFontColor"];
	if (destructive) {
		self.textLabel.textColor = [app_delegate.theme colorForKey:@"groupedTable.buttonDestructiveFontColor"];
	}
	
	NSAttributedString *attString = [NSAttributedString qs_attributedStringWithText:labelText font:self.textLabel.font color:self.textLabel.textColor kerning:YES];
	self.textLabel.attributedText = attString;
	
	return self;
}


#pragma mark - Subviews

- (void)removeAllExtraViews {
	
	[self.progressView removeFromSuperview];
	[self.labelToAnimate removeFromSuperview];
	[self.successFailureImageView removeFromSuperview];
	
	self.progressView = nil;
	self.labelToAnimate = nil;
	self.successFailureImageView = nil;
}


- (void)addLabelToAnimate {
	
	CGRect r = self.textLabel.frame;
	self.labelToAnimate = [[UILabel alloc] initWithFrame:r];
	[self.contentView addSubview:self.labelToAnimate];
	
	self.labelToAnimate.opaque = self.textLabel.opaque;
	self.labelToAnimate.backgroundColor = self.textLabel.backgroundColor;
	self.labelToAnimate.attributedText = self.textLabel.attributedText;
	self.labelToAnimate.textColor = self.textLabel.textColor;
	self.labelToAnimate.textAlignment = self.textLabel.textAlignment;
}


- (void)addProgressView {
	
	self.progressView = [VSProgressView new];
	[self.contentView addSubview:self.progressView];
	
	CGRect r = CGRectZero;
	r.size = [self.progressView sizeThatFits:self.contentView.bounds.size];
	self.progressView.frame = r;
	self.progressView.center = self.textLabel.center;
}


- (void)addImageView:(BOOL)success {
	
	UIImage *image = [app_delegate.theme imageForKey:@"circleProgress.successImageName"];
	if (!success) {
		image = [app_delegate.theme imageForKey:@"circleProgress.failureImageName"];
	}
	
	image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	self.successFailureImageView = [[UIImageView alloc] initWithImage:image];
	UIColor *color = [app_delegate.theme colorForKey:@"circleProgress.successImageColor"];
	if (!success) {
		color = [app_delegate.theme colorForKey:@"circleProgress.failureImageColor"];
	}
	self.successFailureImageView.tintColor = color;
	
	[self.contentView addSubview:self.successFailureImageView];
	self.successFailureImageView.center = self.textLabel.center;
}


#pragma mark - API

- (void)startProgress {
	
	self.showingProgressOrImage = YES;
	[self removeAllExtraViews];
	
	CGRect r = self.textLabel.frame;
	r.origin.x -= r.size.width;
	
	self.textLabel.hidden = YES;
	
	[self addLabelToAnimate];
	
	__weak VSGroupedTableButtonViewCell *weakself = self;
	
	[UIView animateWithDuration:[app_delegate.theme timeIntervalForKey:@"circleProgress.labelSlideLeftDuration"] delay:0.0 options:[app_delegate.theme curveForKey:@"circleProgress.labelSlideLeftCurve"] animations:^{
		
		weakself.labelToAnimate.alpha = 0.0f;
		weakself.labelToAnimate.frame = r;
		
	} completion:^(BOOL finished) {
		
		[weakself.labelToAnimate removeFromSuperview];
		weakself.labelToAnimate = nil;
		
		[weakself addProgressView];
		[weakself.progressView startAnimating];
	}];
}


- (void)stopProgress:(BOOL)success imageViewAnimationBlock:(QSVoidBlock)imageViewAnimationBlock {
	
	self.showingProgressOrImage = YES;
	[self.progressView stopAnimating];
	
	if (success) {
		
		[self addImageView:success];
		
		self.successFailureImageView.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
		self.successFailureImageView.alpha = 0.0f;
		
		NSTimeInterval progressFadeOutDuration = [app_delegate.theme timeIntervalForKey:@"circleProgress.fadeOutDuration"];
		NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"circleProgress.successFailureFadeInDuration"];
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		
		__weak VSGroupedTableButtonViewCell *weakself = self;
		
		[UIView animateWithDuration:progressFadeOutDuration delay:0.0 options:0 animations:^{
			
			weakself.progressView.alpha = 0.0f;
			
		} completion:^(BOOL finished) {
			
			[UIView animateWithDuration:duration delay:0.0 options:0 animations:^{
				
				weakself.successFailureImageView.transform = CGAffineTransformIdentity;
				weakself.successFailureImageView.alpha = 1.0f;
				
				if (imageViewAnimationBlock) {
					imageViewAnimationBlock();
				}
				
			} completion:^(BOOL finished2) {
				
				[weakself.progressView removeFromSuperview];
				weakself.progressView = nil;
				
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			}];
		}];
	}
	
	else {
		
		[self addLabelToAnimate];
		CGRect r = self.labelToAnimate.frame;
		r.origin.x -= r.size.width;
		self.labelToAnimate.frame = r;
		
		NSTimeInterval progressFadeOutDuration = [app_delegate.theme timeIntervalForKey:@"circleProgress.fadeOutDuration"];
		
		__weak VSGroupedTableButtonViewCell *weakself = self;
		
		[UIView animateWithDuration:progressFadeOutDuration delay:0.0 options:0 animations:^{
			
			weakself.progressView.alpha = 0.0f;
			
		} completion:^(BOOL finished) {
			
			/*Animate back the label*/
			
			NSTimeInterval duration2 = [app_delegate.theme timeIntervalForKey:@"circleProgress.labelSlideRightDuration"];
			UIViewAnimationOptions options = [app_delegate.theme curveForKey:@"circleProgress.labelSlideRightCurve"];
			
			[UIView animateWithDuration:duration2 delay:0.0 options:options animations:^{
				
				weakself.labelToAnimate.alpha = 1.0f;
				weakself.labelToAnimate.frame = self.textLabel.frame;
				
				if (imageViewAnimationBlock) {
					imageViewAnimationBlock();
				}
				
			} completion:^(BOOL finished2) {
				
				[weakself removeAllExtraViews];
				weakself.textLabel.hidden = NO;
			}];
		}];
		
	}
}


- (void)clearProgressViews:(BOOL)animated {
	
	//	if (!self.showingProgressOrImage) {
	//		return;
	//	}
	
	self.showingProgressOrImage = NO;
	
	//	if (!animated) {
	[self removeAllExtraViews];
	self.textLabel.hidden = NO;
	return;
	//	}
	
	//	[self addLabelToAnimate];
	//	CGRect r = self.labelToAnimate.frame;
	//	r.origin.x -= r.size.width;
	//	self.labelToAnimate.frame = r;
	//
	//	/*Don't block UI, since this animation can run when a user is typing.*/
	//
	//	NSTimeInterval duration = [app_delegate.theme timeIntervalForKey:@"circleProgress.successFailureFadeOutDuration"];
	//
	//	__weak VSGroupedTableButtonViewCell *weakself = self;
	//
	//	[UIView animateWithDuration:duration delay:0.0f options:0 animations:^{
	//
	//		weakself.successFailureImageView.transform = CGAffineTransformMakeScale(0.0f, 0.0f);
	//		weakself.successFailureImageView.alpha = 0.0f;
	//
	//	} completion:^(BOOL finished) {
	//
	//		[weakself.successFailureImageView removeFromSuperview];
	//		weakself.successFailureImageView = nil;
	//
	//		/*Animate back the label*/
	//
	//		NSTimeInterval duration2 = [app_delegate.theme timeIntervalForKey:@"circleProgress.labelSlideRightDuration"];
	//		UIViewAnimationOptions options = [app_delegate.theme curveForKey:@"circleProgress.labelSlideRightCurve"];
	//
	//		[UIView animateWithDuration:duration2 delay:0.0 options:options animations:^{
	//
	//			weakself.labelToAnimate.alpha = 1.0f;
	//			weakself.labelToAnimate.frame = self.textLabel.frame;
	//
	//		} completion:^(BOOL finished2) {
	//
	//			[weakself removeAllExtraViews];
	//			weakself.textLabel.hidden = NO;
	//		}];
	//	}];
	
}

@end
