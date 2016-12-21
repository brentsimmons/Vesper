//
//  VSSearchBarContainerView.m
//  Vesper
//
//  Created by Brent Simmons on 3/20/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSearchBarContainerView.h"
#import "UIView+RSExtras.h"
#import "VSNavbarButton.h"


@interface VSSearchBarContainerView ()

@property (nonatomic, strong, readwrite) UISearchBar *searchBar;
@property (nonatomic, strong, readwrite) UIImageView *shadowImageView;
@end


@implementation VSSearchBarContainerView


#pragma mark - Class Methods

+ (BOOL)requiresConstraintBasedLayout {
	return YES;
}


+ (UIImage *)searchBarBackgroundImage {
	
	static UIImage *searchBarBackgroundImage = nil;
	if (searchBarBackgroundImage != nil)
		return searchBarBackgroundImage;
	
	CGRect rImage = CGRectMake(0.0f, 0.0f, 1.0f, 64.0f);
	
	UIGraphicsBeginImageContextWithOptions(rImage.size, NO, [UIScreen mainScreen].scale);
	
	searchBarBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return searchBarBackgroundImage;
}


+ (UIImage *)searchFieldBackgroundImage {
	
	static UIImage *searchFieldBackgroundImage = nil;
	if (searchFieldBackgroundImage != nil)
		return searchFieldBackgroundImage;
	
	CGFloat height = [app_delegate.theme floatForKey:@"searchFieldHeight"];
	CGRect rImage = CGRectMake(0.0f, 0.0f, 64.0f, height);
	
	UIGraphicsBeginImageContextWithOptions(rImage.size, NO, [UIScreen mainScreen].scale);
	
	CGRect rPath = rImage;
	rPath.origin.x += 0.5f;
	rPath.origin.y += 0.5f;
	rPath.size.width -= 1.0f;
	rPath.size.height -= 1.0f;
	
	CGFloat cornerRadius = [app_delegate.theme floatForKey:@"searchFieldCornerRadius"];
	UIBezierPath *roundRectPath = [UIBezierPath bezierPathWithRoundedRect:rPath cornerRadius:cornerRadius];
	
	UIColor *searchFieldColor = [app_delegate.theme colorForKey:@"searchFieldColor"];
	[searchFieldColor set];
	[roundRectPath fill];
	
	searchFieldBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	searchFieldBackgroundImage = [searchFieldBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(height / 2.0f, 16.0f, height / 2.0f, 16.0f)];
	
	return searchFieldBackgroundImage;
}


+ (void)setupAppearanceForCancelButton {
	
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		
		UIImage *backgroundNormalImage = [VSSearchBarCancelButton backgroundImageNormal];
		UIImage *backgroundHighlightedImage = [VSSearchBarCancelButton backgroundImagePressed];
		
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setBackgroundImage:backgroundNormalImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setBackgroundImage:backgroundHighlightedImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
		
		NSDictionary *titleAttributes = [VSSearchBarCancelButton attributedTextAttributes:NO];
		UIFont *font = titleAttributes[NSFontAttributeName];
		UIColor *color = titleAttributes[NSForegroundColorAttributeName];
		NSShadow *emptyShadow = [NSShadow new];
		emptyShadow.shadowColor = [UIColor clearColor];
		emptyShadow.shadowOffset = CGSizeZero;
		emptyShadow.shadowBlurRadius = 0.0f;
		
		NSDictionary *barAttributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color, NSShadowAttributeName : emptyShadow};
		
		NSDictionary *titlePressedAttributes = [VSSearchBarCancelButton attributedTextAttributes:YES];
		font = titlePressedAttributes[NSFontAttributeName];
		color = titlePressedAttributes[NSForegroundColorAttributeName];
		NSDictionary *barPressedAttributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color, NSShadowAttributeName : emptyShadow};
		
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTitleTextAttributes:barAttributes forState:UIControlStateNormal];
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTitleTextAttributes:barAttributes forState:UIControlStateDisabled];
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTitleTextAttributes:barPressedAttributes forState:UIControlStateHighlighted];
		
		[[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTitlePositionAdjustment:UIOffsetMake(0.0f, 0.0f) forBarMetrics:UIBarMetricsDefault];
		
	});
}


#pragma mark - Init

- (id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	
	self.opaque = NO;
	//	self.translucent = YES;
	//	self.clipsToBounds = YES; /*Removes the top border that UIToolbar draws.*/
	self.backgroundColor = [UIColor clearColor]; /*Can't be opaque because of the tableview scroll indicator.*/
	
	[[self class] setupAppearanceForCancelButton];
	
	_searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
	[_searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
	_searchBar.backgroundImage = [[self class] searchBarBackgroundImage];
	
	UIImage *searchFieldBackgroundImage = [[self class] searchFieldBackgroundImage];
	[_searchBar setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
	[_searchBar setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateDisabled];
	
	UIColor *searchFieldIconColor = [app_delegate.theme colorForKey:@"searchFieldIconColor"];
	UIImage *searchFieldIcon = [UIImage qs_imageNamed:@"search-icon" tintedWithColor:searchFieldIconColor];
	[_searchBar setImage:searchFieldIcon forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
	[_searchBar setImage:searchFieldIcon forSearchBarIcon:UISearchBarIconSearch state:UIControlStateHighlighted];
	
	UIOffset searchIconOffset = UIOffsetMake(0.0f, 0.0f);
	[_searchBar setPositionAdjustment:searchIconOffset forSearchBarIcon:UISearchBarIconSearch];
	
	UIColor *searchFieldClearIconColor = [app_delegate.theme colorForKey:@"searchFieldClearIconColor"];
	UIImage *searchFieldClearIcon = [UIImage qs_imageNamed:@"search-clear" tintedWithColor:searchFieldClearIconColor];
	[_searchBar setImage:searchFieldClearIcon forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
	[_searchBar setImage:searchFieldClearIcon forSearchBarIcon:UISearchBarIconClear state:UIControlStateHighlighted];
	
	UIOffset clearIconOffset = UIOffsetMake(-2.0f, 0.0f);
	[_searchBar setPositionAdjustment:clearIconOffset forSearchBarIcon:UISearchBarIconClear];
	
	//	_searchBar.translucent = YES;
	//	_searchBar.opaque = NO;
	//	_searchBar.backgroundColor = [UIColor clearColor];
	[self addSubview:_searchBar];
	
	//    _shadowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navbar-shadow"]];
	//    [_shadowImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
	//    [self addSubview:_shadowImageView];
	
	
	UIFont *searchBarFont = [app_delegate.theme fontForKey:@"searchFieldFont"];
	UIColor *searchBarTextColor = [app_delegate.theme colorForKey:@"searchFieldFontColor"];
	VSMakeTextFieldSubviewUseFontAndColor(_searchBar, searchBarFont, searchBarTextColor);
	
	//    for (UIView *oneSubview in _searchBar.subviews) {
	//		NSLog(@"oneSubview: %@", oneSubview);
	//        if ([oneSubview isKindOfClass:[UITextField class]]) {
	//            UITextField *textField = (UITextField *)oneSubview;
	//            textField.font = [app_delegate.theme fontForKey:@"searchFieldFont"];
	//            textField.textColor = [app_delegate.theme colorForKey:@"searchFieldFontColor"];
	//        }
	//    }
	
	CGFloat searchBarTextFudge = [app_delegate.theme floatForKey:@"searchFieldTextPositionFudge"];
	CGFloat searchBarTextHorizontalFudge = [app_delegate.theme floatForKey:@"searchFieldTextPositionHorizontalFudge"];
	_searchBar.searchTextPositionAdjustment = UIOffsetMake(searchBarTextHorizontalFudge, searchBarTextFudge);
	
	[self addObserver:self forKeyPath:@"hasShadow" options:NSKeyValueObservingOptionInitial context:nil];
	[self addObserver:self forKeyPath:@"inSearchMode" options:NSKeyValueObservingOptionInitial context:nil];
	
	[self setNeedsLayout];
	
	
	return self;
}


static void VSMakeTextFieldSubviewUseFontAndColor(UIView *view, UIFont *font, UIColor *color) {
	
	if ([view isKindOfClass:[UITextField class]]) {
		UITextField *textField = (UITextField *)view;
		textField.font = [app_delegate.theme fontForKey:@"searchFieldFont"];
		textField.textColor = [app_delegate.theme colorForKey:@"searchFieldFontColor"];
	}
	
	for (UIView *oneSubview in view.subviews) {
		VSMakeTextFieldSubviewUseFontAndColor(oneSubview, font, color);
	}
}


#pragma mark - Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"hasShadow"];
	[self removeObserver:self forKeyPath:@"inSearchMode"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"hasShadow"] && object == self)
		self.shadowImageView.hidden = !self.hasShadow;
	else if ([keyPath isEqualToString:@"inSearchMode"])
		[self setNeedsDisplay];
}


#pragma mark - Constraints

- (void)updateConstraints {
	
	[super updateConstraints];
	
	[self rs_addConstraintsWithThemeKey:@"searchBarLayout" viewName:@"searchBar" view:self.searchBar];
}


#pragma mark - Layout

- (void)layoutSubviews {
	
	[super layoutSubviews];
	
	CGRect rShadow = self.bounds;
	CGSize imageSize = self.shadowImageView.image.size;
	rShadow.size.height = imageSize.height;
	rShadow.origin.y = CGRectGetMaxY(self.bounds);
	
	[self.shadowImageView qs_setFrameIfNotEqual:rShadow];
}


#pragma mark - Drawing

- (BOOL)isOpaque {
	return self.inSearchMode;
}


#pragma mark - Hack

- (void)enableCancelButton {
	
	for (UIView *oneSubview in self.searchBar.subviews) {
		if ([oneSubview isKindOfClass:[UIControl class]])
			((UIControl *)oneSubview).enabled = YES;
	}
}


@end

