//
//  VSSearchBarContainerView.h
//  Vesper
//
//  Created by Brent Simmons on 3/20/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VSSearchBarContainerView : UIView

@property (nonatomic, strong, readonly) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL hasShadow;
@property (nonatomic, strong, readonly) UIImageView *shadowImageView;
@property (nonatomic, assign) BOOL inSearchMode;

- (void)enableCancelButton; /*A hack, unfortunately. The system disables it once the keyboard disappears.*/

@end
