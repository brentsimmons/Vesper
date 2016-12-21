//
//  VSSidebarView.m
//  Vesper
//
//  Created by Brent Simmons on 5/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSidebarView.h"


@interface VSSidebarStatusBarBackgroundView : UIView
@end

@interface VSSidebarView ()

@property (nonatomic, strong) UIImageView *sidebarImageView;
@property (nonatomic, assign) CGFloat parallaxWidth;
@property (nonatomic, strong) VSSidebarStatusBarBackgroundView *statusBarBackgroundView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, assign) CGRect statusBarBackgroundFrame;

@end


@implementation VSSidebarView


#pragma mark - Init


- (instancetype)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	
	UIColor *backgroundColor = [app_delegate.theme colorForKey:@"sidebarBackgroundColor"];
	backgroundColor = [backgroundColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"sidebarBackgroundColorAlpha"]];
	self.backgroundColor = backgroundColor;
	
	self.backgroundColor = [UIColor blackColor];
	_overlayView = [[UIView alloc] initWithFrame:frame];
	_overlayView.backgroundColor = backgroundColor;
	
	UIImage *image = [UIImage imageNamed:@"wallpaper"];
	_sidebarImageView = [[UIImageView alloc] initWithImage:image];
	_sidebarImageView.contentMode = UIViewContentModeCenter;
	
	CGFloat wallpaperParallaxX = [app_delegate.theme floatForKey:@"sidebarWallpaperParallaxX"];
	CGFloat wallpaperParallaxY = [app_delegate.theme floatForKey:@"sidebarWallpaperParallaxY"];
	CGRect rImageView = CGRectZero;
	rImageView.origin.x = -(wallpaperParallaxX);
	rImageView.origin.y = -(wallpaperParallaxY);
	rImageView.size = image.size;
	_sidebarImageView.frame = rImageView;
	
	[_sidebarImageView qs_addParallaxMotionEffectWithOffset:CGSizeMake(wallpaperParallaxX, wallpaperParallaxY)];
	[self addSubview:_sidebarImageView];
	
	[self addSubview:_overlayView];
	
	CGRect rStatusBarBackground = CGRectMake(0.0f, 0.0f, frame.size.width, [app_delegate.theme floatForKey:@"sidebarStatusBarGradient.height"]);
	
	if (![app_delegate.theme boolForKey:@"statusBarHidden"]) {
		_statusBarBackgroundView = [[VSSidebarStatusBarBackgroundView alloc] initWithFrame:rStatusBarBackground];
		_statusBarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
		_statusBarBackgroundFrame = rStatusBarBackground;
		[self addSubview:_statusBarBackgroundView];
	}
	
	_parallaxWidth = [app_delegate.theme floatForKey:@"sidebarParallaxWidth"];
	_originX = -(_parallaxWidth);
	
	[self setNeedsLayout];
	
	[self addObserver:self forKeyPath:@"originX" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"backgroundView" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"tableView" options:0 context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPanSidebar:) name:VSDataViewDidPanToRevealSidebarNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"originX"];
	[self removeObserver:self forKeyPath:@"backgroundView"];
	[self removeObserver:self forKeyPath:@"tableView"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"originX"])
		[self setNeedsLayout];
	
	else if ([keyPath isEqualToString:@"backgroundView"]) {
		
		
		[self setNeedsLayout];
	}
	
	else if ([keyPath isEqualToString:@"tableView"]) {
		
		[self setNeedsLayout];
	}
	
	[self bringSubviewToFront:self.statusBarBackgroundView];
}


#pragma mark - Notifications

- (void)didPanSidebar:(NSNotification *)note {
	
	CGFloat percentageMoved = [[note userInfo][VSPercentMovedKey] floatValue];
	CGFloat originX = -(self.parallaxWidth);
	originX += (self.parallaxWidth * percentageMoved);
	
	if (originX > 0.0f)
		originX = 0.0f;
	
	self.originX = originX;
}


#pragma mark - Layout

- (void)layout {
	
	CGRect rBounds = self.bounds;
	
	rBounds.origin.x = self.originX;
	
	CGRect rBackground = rBounds;
	rBackground.origin.y = 0.0f;
	rBackground.size.height = [UIScreen mainScreen].bounds.size.height;
	
	[self.backgroundView qs_setFrameIfNotEqual:rBackground];
	
	[self.overlayView qs_setFrameIfNotEqual:self.bounds];
	
	CGRect rTable = rBackground;
	rTable.origin = CGPointZero;
	CGFloat statusBarHeight = CGRectGetHeight(RSStatusBarFrame());
	if (statusBarHeight > 21.0f) { /*Extended status bar*/
		rTable.origin.y = VSNormalStatusBarHeight();
		rTable.size.height = CGRectGetHeight(rBackground) - statusBarHeight;
		self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
	}
	else {
		self.tableView.contentInset = UIEdgeInsetsMake(VSNormalStatusBarHeight(), 0.0f, 0.0f, 0.0f);
	}
	
	[self.tableView qs_setFrameIfNotEqual:rTable];
	[self.statusBarBackgroundView qs_setFrameIfNotEqual:self.statusBarBackgroundFrame];
}


- (void)moveToSidebarOpenPosition {
	_originX = 0; /*Direct access: don't want to trigger layoutSubviews*/
	[self layout];
}


- (void)moveToSidebarClosedPosition {
	_originX = -(self.parallaxWidth);
	[self layout];
}



#pragma mark - UIView

- (void)layoutSubviews {
	
	[self layout];
}


@end


@implementation VSSidebarStatusBarBackgroundView

- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(CGRect)rect {
	
	static CGGradientRef gradient = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		UIColor *topColor = [app_delegate.theme colorForKey:@"sidebarStatusBarGradient.topColor"];
		topColor = [topColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"sidebarStatusBarGradient.topColorAlpha"]];
		UIColor *bottomColor = [app_delegate.theme colorForKey:@"sidebarStatusBarGradient.bottomColor"];
		bottomColor = [bottomColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"sidebarStatusBarGradient.bottomColorAlpha"]];
		NSArray *colors = @[(__bridge id)topColor.CGColor, (__bridge id)bottomColor.CGColor];
		
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
		CGFloat locations[2] = {0.0f, 1.0f};
		gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, locations);
		
		CGColorSpaceRelease(colorspace);
	});
	
	CGRect rBounds = self.bounds;
	CGRect rDrawing = rBounds;
	rDrawing.size.height -= 1.0f;
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), gradient, CGPointZero, CGPointMake(0.0f, CGRectGetMaxY(self.bounds)), 0);
}

@end

