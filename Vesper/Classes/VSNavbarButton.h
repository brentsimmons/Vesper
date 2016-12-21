//
//  VSNavbarButton.h
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VSNavbarButton : UIButton


/*Image must not be nil. Any or both of the other images may be nil -- image is used in their place.*/

+ (UIButton *)navbarButtonWithImage:(UIImage *)image selectedImage:(UIImage *)selectedImage highlightedImage:(UIImage *)highlightedImage;

+ (UIButton *)toolbarButtonWithImage:(UIImage *)image selectedImage:(UIImage *)selectedImage highlightedImage:(UIImage *)highlightedImage; /*Different tint color for toolbar buttons.*/

+ (NSDictionary *)attributedTextAttributes:(BOOL)pressed;

@end



@interface VSNavbarTextButton : VSNavbarButton

+ (CGSize)sizeWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title;

+ (UIImage *)backgroundImageNormal;
+ (UIImage *)backgroundImagePressed;


@end


@interface VSNavbarBackButton : VSNavbarTextButton

@end


@interface VSToolbarTextButton : VSNavbarTextButton

@end


@interface VSSearchBarCancelButton : VSToolbarTextButton

@end


@interface VSBrowserTextButton : VSNavbarTextButton

@end


@interface VSPhotoTextButton : VSNavbarTextButton

@end

