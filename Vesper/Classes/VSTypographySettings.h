//
//  VSTypographySettings.h
//  Vesper
//
//  Created by Brent Simmons on 9/1/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *VSTypographySettingsDidChangeNotification;

@class VSTheme;


@interface VSTypographySettings : NSObject

- (instancetype)initWithTheme:(VSTheme *)theme;

/*These are all observable, but it's best to watch for VSTypographySettingsDidChangeNotification instead.*/

@property (nonatomic, strong, readonly) QS_FONT *titleFont;
@property (nonatomic, strong, readonly) QS_FONT *titleFontArchived;
@property (nonatomic, strong, readonly) QS_FONT *titleLinkFont;
@property (nonatomic, strong, readonly) QS_FONT *titleLinkFontArchived;
@property (nonatomic, strong, readonly) QS_FONT *bodyFont;
@property (nonatomic, strong, readonly) QS_FONT *bodyFontArchived;
@property (nonatomic, strong, readonly) QS_FONT *bodyLinkFont;
@property (nonatomic, strong, readonly) QS_FONT *bodyLinkFontArchived;
@property (nonatomic, assign, readonly) BOOL useSmallCaps; /*For titles only*/


@end
