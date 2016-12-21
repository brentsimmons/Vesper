//
//  VSBrowserToolbarView.m
//  Vesper
//
//  Created by Brent Simmons on 4/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBrowserToolbarView.h"
#import "VSNavbarButton.h"


@implementation VSBrowserToolbarView

#pragma mark Init

- (void)commonInit {
	
	[self setupControls];
	
	[self setNeedsLayout];
	
	self.translucent = YES;
	self.backgroundColor = [UIColor clearColor];
	
	self.clipsToBounds = YES; /*Removes the top border that UIToolbar draws.*/
	
	CGFloat toolbarBorderWidth = [app_delegate.theme floatForKey:@"browserToolbarBorderWidth"];
	if (toolbarBorderWidth > 0.1f) {
		
		CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
		UIView *toolbarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenWidth, toolbarBorderWidth)];
		toolbarBorder.opaque = YES;
		toolbarBorder.backgroundColor = [app_delegate.theme colorForKey:@"browserToolbarBorderColor"];
		[self addSubview:toolbarBorder];
	}
}


- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	[self commonInit];
	return self;
}


- (BOOL)isOpaque {
	return NO;
}


+ (BOOL)requiresConstraintBasedLayout {
	return YES;
}


- (void)addConstraintsWithFormat:(NSString *)format viewsDictionary:(NSDictionary *)viewsDictionary {
	NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:viewsDictionary];
	[self addConstraints:constraints];
}


- (void)setupControls {
	
	self.doneButton = [VSBrowserTextButton buttonWithTitle:NSLocalizedString(@"Done", @"Done")];
	[self.doneButton addTarget:nil action:@selector(browserDone:) forControlEvents:UIControlEventTouchUpInside];
	self.doneButton.accessibilityLabel = NSLocalizedString(@"Done", nil);
	[self addSubview:self.doneButton];
	
	self.backButton = [VSNavbarButton toolbarButtonWithImage:[UIImage imageNamed:@"webview-back"] selectedImage:nil highlightedImage:[UIImage imageNamed:@"webview-back"]];
	[self.backButton addTarget:nil action:@selector(browserBack:) forControlEvents:UIControlEventTouchUpInside];
	self.backButton.accessibilityLabel = NSLocalizedString(@"Back", nil);
	[self addSubview:self.backButton];
	
	self.forwardButton = [VSNavbarButton toolbarButtonWithImage:[UIImage imageNamed:@"webview-forward"] selectedImage:nil highlightedImage:[UIImage imageNamed:@"webview-forward"]];
	[self.forwardButton addTarget:nil action:@selector(browserForward:) forControlEvents:UIControlEventTouchUpInside];
	self.forwardButton.accessibilityLabel = NSLocalizedString(@"Forward", nil);
	[self addSubview:self.forwardButton];
	
	self.activityButton = [VSNavbarButton toolbarButtonWithImage:[UIImage imageNamed:@"activity"] selectedImage:nil highlightedImage:[UIImage imageNamed:@"activity"]];
	self.activityButton.accessibilityLabel = NSLocalizedString(@"Share", nil);
	[self.activityButton addTarget:nil action:@selector(activityButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:self.activityButton];
}


- (void)updateConstraints {
	
	[super updateConstraints];
	
	[self.doneButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.backButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.forwardButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.activityButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	CGSize doneButtonSize = [VSBrowserTextButton sizeWithTitle:NSLocalizedString(@"Done", @"Done")];
	NSInteger doneButtonWidth = (NSInteger)(doneButtonSize.width);
	NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[doneButton(doneButtonWidth)]-0-|" options:0 metrics:@{@"doneButtonWidth": @(doneButtonWidth)} views:@{@"doneButton": self.doneButton}];
	[self addConstraints:constraints];
	
	NSInteger backButtonWidth = [app_delegate.theme integerForKey:@"browserToolbarBackButtonWidth"];
	constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[backButton(backButtonWidth)]" options:0 metrics:@{@"backButtonWidth": @(backButtonWidth)} views:@{@"backButton": self.backButton}];
	[self addConstraints:constraints];
	
	NSInteger forwardButtonWidth = [app_delegate.theme integerForKey:@"browserToolbarForwardButtonWidth"];
	NSInteger forwardButtonOriginX = [app_delegate.theme integerForKey:@"browserToolbarForwardButtonOriginX"];
	constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-forwardButtonOriginX-[forwardButton(forwardButtonWidth)]" options:0 metrics:@{@"forwardButtonWidth": @(forwardButtonWidth), @"forwardButtonOriginX": @(forwardButtonOriginX)} views:@{@"forwardButton": self.forwardButton}];
	[self addConstraints:constraints];
	
	NSInteger activityButtonWidth = [app_delegate.theme integerForKey:@"browserToolbarActivityButtonWidth"];
	NSInteger activityButtonOriginX = [app_delegate.theme integerForKey:@"browserToolbarActivityButtonOriginX"];
	constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-activityButtonOriginX-[activityButton(activityButtonWidth)]" options:0 metrics:@{@"activityButtonWidth": @(activityButtonWidth), @"activityButtonOriginX": @(activityButtonOriginX)} views:@{@"activityButton": self.activityButton}];
	[self addConstraints:constraints];
	
	[self addConstraintsWithFormat:@"V:|-0-[doneButton]-0-|" viewsDictionary:@{@"doneButton": self.doneButton}];
	[self addConstraintsWithFormat:@"V:|-0-[backButton]-0-|" viewsDictionary:@{@"backButton": self.backButton}];
	[self addConstraintsWithFormat:@"V:|-0-[forwardButton]-0-|" viewsDictionary:@{@"forwardButton": self.forwardButton}];
	
	
	NSInteger activityButtonOriginY = [app_delegate.theme integerForKey:@"browserToolbarActivityButtonOriginY"];
	NSString *activityButtonVerticalFormat = [NSString stringWithFormat:@"V:|-%ld-[activityButton]", (long)activityButtonOriginY];
	[self addConstraintsWithFormat:activityButtonVerticalFormat viewsDictionary:@{@"activityButton": self.activityButton}];
}




@end
