//
//  VSBrowserLoadingView.m
//  Vesper
//
//  Created by Brent Simmons on 3/3/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSBrowserLoadingView.h"
#import "VSTheme.h"
#import "UIView+RSExtras.h"
#import "RSGeometry.h"
#import "UIImage+RSExtras.h"
#import "VSBrowserLockURLView.h"


@interface VSBrowserLoadingView ()

@property (nonatomic, strong) VSBrowserLockURLView *lockURLView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIImageView *refreshIconImageView;
@property (nonatomic, strong) UIImageView *spinnerView;
@property (nonatomic, strong) UILabel *statusLabel;
@end




@implementation VSBrowserLoadingView


#pragma mark Class Methods

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}


#pragma mark Init

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    if (self == nil)
        return nil;

    UIColor *color = [app_delegate.theme colorForKey:@"browserLoadingOverlayColor"];
    color = [color colorWithAlphaComponent:[app_delegate.theme floatForKey:@"browserLoadingOverlayColorAlpha"]];
    self.backgroundColor = color;

    _arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"webview-downarrow"]];
    [_arrowImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_arrowImageView];

    static UIImage *refreshIconImage = nil;
    if (refreshIconImage == nil) {
        refreshIconImage = [[UIImage imageNamed:@"refresh"] rs_imageTintedWithColor:[app_delegate.theme colorForKey:@"browserLoadingOverlayRefreshIconColor"]];
    }
    _refreshIconImageView = [[UIImageView alloc] initWithImage:refreshIconImage];
    [_refreshIconImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_refreshIconImageView];

    _spinnerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spin0"]];
    
    NSMutableArray *spinnerImages = [NSMutableArray new];
    NSUInteger i = 0;
    static const NSUInteger kNumberOfSpinnerImages = 12;
    for (i = 0; i < kNumberOfSpinnerImages; i++) {
        NSString *oneImageName = [NSString stringWithFormat:@"spin%d", i];
        UIImage *oneImage = [UIImage imageNamed:oneImageName];
        [spinnerImages addObject:oneImage];
    }
    _spinnerView.animationImages = [spinnerImages copy];
    _spinnerView.animationDuration = [app_delegate.theme floatForKey:@"browserLoadingOverlaySpinnerAnimationDuration"];
    
    [_spinnerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    _spinnerView.hidden = YES;
    [self addSubview:_spinnerView];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.opaque = NO;
    _statusLabel.font = [app_delegate.theme fontForKey:@"browserLoadingOverlayFont"];
    _statusLabel.numberOfLines = 1;
    _statusLabel.textColor = [app_delegate.theme colorForKey:@"browserLoadingOverlayFontColor"];
    _statusLabel.text = NSLocalizedString(@"Refresh", @"Refresh");
    [_statusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_statusLabel];

    _lockURLView = [[VSBrowserLockURLView alloc] initWithFrame:CGRectZero];
    _lockURLView.backgroundColor = [UIColor clearColor];
    [_lockURLView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_lockURLView];
    
    self.userInteractionEnabled = NO;

    [self addObserver:self forKeyPath:@"url" options:0 context:nil];
    [self addObserver:self forKeyPath:@"loading" options:0 context:nil];
    
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"url"];
    [self removeObserver:self forKeyPath:@"loading"];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString:@"url"] && object == self) {
        self.lockURLView.url = self.url;
    }

    else if ([keyPath isEqualToString:@"loading"] && object == self) {

        if (self.isLoading) {
            self.arrowImageView.hidden = YES;
            self.refreshIconImageView.hidden = YES;
            self.spinnerView.hidden = NO;
            [self.spinnerView startAnimating];
            self.statusLabel.text = NSLocalizedString(@"Loading", @"Loading");
        }
        else {
            self.arrowImageView.hidden = NO;
            self.refreshIconImageView.hidden = YES;
            self.spinnerView.hidden = YES;
            [self.spinnerView stopAnimating];
            self.statusLabel.text = NSLocalizedString(@"Refresh", @"Refresh");
        }

        [self setNeedsLayout];
    }
}


#pragma mark Accessors

- (void)setUrl:(NSURL *)url {
    if (url == nil || RSStringIsEmpty([url absoluteString]))
        return;

    [self willChangeValueForKey:@"url"];
    _url = url;
    [self didChangeValueForKey:@"url"];
}


#pragma mark - UIView

- (BOOL)isOpaque {
    return NO;
}


//@property (nonatomic, strong) UIImageView *spinnerView;

//- (void)addConstraintsWithThemeKey:(NSString *)themeKey viewName:(NSString *)viewName view:(UIView *)view {
//
//    NSString *horizontalKey = [NSString stringWithFormat:@"%@Horizontal", themeKey];
//    NSString *layoutString = [app_delegate.theme stringForKey:horizontalKey];
//    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutString options:0 metrics:nil views:@{viewName : view}];
//    [self addConstraints:constraints];
//
//    NSString *verticalKey = [NSString stringWithFormat:@"%@Vertical", themeKey];
//    layoutString = [app_delegate.theme stringForKey:verticalKey];
//    constraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutString options:0 metrics:nil views:@{viewName : view}];
//    [self addConstraints:constraints];
//}


- (void)updateConstraints {

    [super updateConstraints];

    [self rs_addConstraintsWithThemeKey:@"browserLoadingOverlayArrowLayout" viewName:@"arrow" view:self.arrowImageView];
    [self rs_addConstraintsWithThemeKey:@"browserLoadingOverlayRefreshIconLayout" viewName:@"refreshIcon" view:self.refreshIconImageView];
    [self rs_addConstraintsWithThemeKey:@"browserLoadingOverlaySpinnerLayout" viewName:@"spinner" view:self.spinnerView];
    [self rs_addConstraintsWithThemeKey:@"browserLoadingOverlayLockURLLayout" viewName:@"lockURL" view:self.lockURLView];
    [self rs_addConstraintsWithThemeKey:@"browserLoadingOverlayStatusLayout" viewName:@"status" view:self.statusLabel];
}


@end



