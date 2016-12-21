//
//  VSDetailToolbar.m
//  Vesper
//
//  Created by Brent Simmons on 9/3/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDetailToolbar.h"
#import "VSNavbarButton.h"
#import "UIImageView+RSExtras.h"
#import "VSDetailStatusView.h"


@interface VSDetailToolbar ()

@property (nonatomic, readwrite) UIBarButtonItem *deleteButton;
@property (nonatomic, readwrite) UIBarButtonItem *archiveButton;
@property (nonatomic, readwrite) UIBarButtonItem *restoreButton;
@property (nonatomic) UIBarButtonItem *flexibleSpaceItemLeft;
@property (nonatomic) UIBarButtonItem *flexibleSpaceItemRight;
@property (nonatomic, readwrite) VSDetailStatusView *statusView;
@property (nonatomic) UIBarButtonItem *statusItem;

@end


@implementation VSDetailToolbar


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.clipsToBounds = YES;
	self.translucent = YES;
	self.opaque = NO;
	self.barStyle = UIBarStyleDefault;
	self.backgroundColor = [UIColor clearColor];
	
	[self setupControls];
	[self setNeedsLayout];
	self.items = @[_deleteButton, _flexibleSpaceItemLeft, _statusItem, _flexibleSpaceItemRight, _archiveButton];
	
	return self;
}


#pragma mark - Buttons

- (void)setupControls {
	
	UIColor *buttonTintColor = [app_delegate.theme colorForKey:@"toolbarButtonColor"];
	
	self.deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed:)];
	self.deleteButton.tintColor = buttonTintColor;
	
	self.archiveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"archive"] style:UIBarButtonItemStylePlain target:self action:@selector(archiveButtonPressed:)];
	self.archiveButton.tintColor = buttonTintColor;
	self.archiveButton.imageInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 13.0f);
	
	self.restoreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"restore"] style:UIBarButtonItemStylePlain target:self action:@selector(restoreButtonPressed:)];
	self.restoreButton.tintColor = buttonTintColor;
	
	self.flexibleSpaceItemLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.flexibleSpaceItemRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	CGRect rStatus = self.frame;
	rStatus.size.width = 190.0f;
	rStatus.origin = CGPointZero;
	self.statusView = [[VSDetailStatusView alloc] initWithFrame:rStatus];
	self.statusItem = [[UIBarButtonItem alloc] initWithCustomView:self.statusView];
	self.statusItem.width = CGRectGetWidth(rStatus);
}


#pragma mark - Accessors

- (void)setShowRestoreButton:(BOOL)showRestoreButton {
	
	_showRestoreButton = showRestoreButton;
	
	if (showRestoreButton) {
		self.items = @[self.deleteButton, self.flexibleSpaceItemLeft, self.statusItem, self.flexibleSpaceItemRight, self.restoreButton];
	}
	else {
		self.items = @[self.deleteButton, self.flexibleSpaceItemLeft, self.statusItem, self.flexibleSpaceItemRight, self.archiveButton];
	}
}


#pragma mark - Actions

- (void)deleteButtonPressed:(id)sender {
	[self qs_performSelectorViaResponderChain:@selector(confirmDeleteNote:) withObject:sender];
}


- (void)archiveButtonPressed:(id)sender {
	[self qs_performSelectorViaResponderChain:@selector(archiveNote:) withObject:sender];
}


- (void)restoreButtonPressed:(id)sender {
	[self qs_performSelectorViaResponderChain:@selector(restoreNote:) withObject:sender];
}


#pragma mark - Animation

- (UIImageView *)imageViewForAnimation {
	
	self.opaque = YES;
	self.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	UIImageView *imageView = (UIImageView *)[self snapshotViewAfterScreenUpdates:YES];
	self.opaque = NO;
	self.backgroundColor = [UIColor clearColor];
	
	return imageView;
}


@end

