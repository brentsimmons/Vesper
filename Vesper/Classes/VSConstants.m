//
//  VSConstants.m
//  Vesper
//
//  Created by Brent Simmons on 3/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSConstants.h"
#import "QSDateParser.h"
#import "VSDateManager.h"


NSString *VSUniqueIDsKey = @"uniqueIDs";
NSString *VSUniqueIDKey = @"uniqueID";
NSString *UniqueIDKey = @"uniqueID";

NSString *VSImageKey = @"VSImage";
NSString *VSNoteKey = @"VSNote";
NSString *VSNotesKey = @"notes";

NSString *VSDidBecomeFirstResponderNotification = @"VSDidBecomeFirstResponderNotification";
NSString *VSDidResignFirstResponderNotification = @"VSDidResignFirstResponderNotification";
NSString *VSResponderKey = @"VSResponder";

NSString *VSAppShouldShowStatusBarNotification = @"VSAppShouldShowStatusBarNotification";
NSString *VSAppShouldHideStatusBarNotification = @"VSAppShouldHideStatusBarNotification";

NSString *VSBrowserViewDidOpenNotification = @"VSBrowserViewDidOpenNotification";
NSString *VSBrowserViewDidCloseNotification = @"VSBrowserViewDidCloseNotification";

NSString *VSSidebarDidChangeDisplayStateNotification = @"VSSidebarDidChangeDisplayStateNotification";
NSString *VSSidebarShowingKey = @"sidebarShowing";

NSString *VSWillShowTagPopoverNotification = @"VSWillShowTagPopoverNotification";
NSString *VSButtonKey = @"VSButton";

NSString *VSRightSideViewFrameDidChangeNotification = @"VSRightSideViewFrameDidChangeNotification";
NSString *VSFrameKey = @"VSFrame";
NSString *VSViewControllerKey = @"VSViewController";

NSString *VSTimelineSelectionDidChangeNotification = @"VSTimelineSelectionDidChangeNotification";
NSString *VSSourceListSelectionDidChangeNotification = @"VSSourceListSelectionDidChangeNotification";
NSString *VSSourceListItemKey = @"VSSourceListItem";

NSString *VSHTTPCallDidBeginNotification = @"VSHTTPCallDidBeginNotification";
NSString *VSHTTPCallDidEndNotification = @"VSHTTPCallDidEndNotification";

NSString *VSSyncDidBeginNotification = @"VSSyncDidBeginNotification";
NSString *VSSyncDidCompleteNotification = @"VSSyncDidCompleteNotification";

NSString *VSSidebarTagsDidChangeNotification = @"VSSidebarTagsDidChangeNotification";
NSString *VSTagsKey = @"tags";

NSString *VSDataMigrationDidBeginNotification = @"VSDataMigrationDidBeginNotification";
NSString *VSDataMigrationDidCompleteNotification = @"VSDataMigrationDidCompleteNotification";

NSString *VSDidCopyNoteNotification = @"VSDidCopyNoteNotification";
NSString *VSSyncNoteTagsDidChangeNotification = @"VSSyncNoteTagsDidChangeNotification";
NSString *VSSyncNotesDidChangeNotification = @"VSSyncNotesDidChangeNotification";


const CGFloat VSNavbarHeight = 44.0f;

const int64_t VSTutorialNoteMaxID = 999;
const int64_t VSNoteMaxID = 9007199254740992;

CGFloat VSNormalStatusBarHeight(void) {
	
	static CGFloat height = 20.0f;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if ([app_delegate.theme boolForKey:@"statusBarHidden"]) {
			height = 0.0f;
		}
	});
	
	return height;
}


NSString *VSDataViewDidPanToRevealSidebarNotification = @"VSDataViewDidPanToRevealSidebarNotification";
NSString *VSPercentMovedKey = @"VSPercentMovedKey";


NSString *VSUIEventHappenedNotification = @"VSUIEventHappenedNotification";


void VSSendUIEventHappenedNotification(void) {
	[[NSNotificationCenter defaultCenter] postNotificationName:VSUIEventHappenedNotification object:nil];
}

NSString *VSShouldCloseSidebarNotification = @"VSShouldCloseSidebarNotification";


void VSCloseSidebar(void) {
	[[NSNotificationCenter defaultCenter] postNotificationName:VSShouldCloseSidebarNotification object:nil];
}

#if TARGET_OS_IPHONE

void VSSendRightSideViewFrameDidChangeNotification(UIViewController *viewController, CGRect frame) {
	[[NSNotificationCenter defaultCenter] postNotificationName:VSRightSideViewFrameDidChangeNotification object:viewController userInfo:@{VSFrameKey : [NSValue valueWithCGRect:frame]}];
}

#endif


NSString *VSDefaultsUseSmallCapsKey = @"useSmallCaps";
NSString *VSDefaultsFontLevelKey = @"fontLevel";
NSString *VSDefaultsTextWeightKey = @"textWeight";

VSTextWeight VSDefaultsTextWeight(void) {
	
	VSTextWeight textWeight = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:VSDefaultsTextWeightKey];
	if (textWeight < VSTextWeightRegular || textWeight > VSTextWeightLight)
		textWeight = VSTextWeightRegular;
	
	return textWeight;
}


BOOL VSDefaultsUsingLightText(void) {
	return VSDefaultsTextWeight() == VSTextWeightLight;
}


void VSDefaultsSetTextWeight(VSTextWeight textWeight) {
	
	if (textWeight < VSTextWeightRegular || textWeight > VSTextWeightLight)
		textWeight = VSTextWeightRegular;
	[[NSUserDefaults standardUserDefaults] setInteger:textWeight forKey:VSDefaultsTextWeightKey];
	//	[[NSUserDefaults standardUserDefaults] synchronize];
}

#if TARGET_OS_IPHONE

static BOOL VSIsAccessibilityLargerTextSizeEnabled(void) {
	static NSSet *accessibilityContentSizeCategories = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		accessibilityContentSizeCategories =
		[NSSet setWithArray:@[
							  UIContentSizeCategoryAccessibilityMedium,
							  UIContentSizeCategoryAccessibilityLarge,
							  UIContentSizeCategoryAccessibilityExtraLarge,
							  UIContentSizeCategoryAccessibilityExtraExtraLarge,
							  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge,
							  ]];
	});
	return [accessibilityContentSizeCategories containsObject:[UIApplication sharedApplication].preferredContentSizeCategory];
}

NSUInteger VSDefaultsFontLevelMaximum(void) {
	return VSIsAccessibilityLargerTextSizeEnabled() ? 8 : 4;
}

#else

NSUInteger VSDefaultsFontLevelMaximum(void) {
	return 4;
}

#endif


NSUInteger VSDefaultsFontLevel(void) {
	
	NSUInteger fontLevel = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:VSDefaultsFontLevelKey];
	NSUInteger max = VSDefaultsFontLevelMaximum();
	if (fontLevel > max)
		fontLevel = max;
	return fontLevel;
}

void VSDefaultsSetFontLevel(NSUInteger fontLevel) {
	
	NSUInteger max = VSDefaultsFontLevelMaximum();
	if (fontLevel > max)
		fontLevel = max;
	
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)fontLevel forKey:VSDefaultsFontLevelKey];
}


QS_COLOR *VSPressedColor(QS_COLOR *originalColor) {
	
	static CGFloat alpha = 0.0f;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		alpha = [app_delegate.theme floatForKey:@"buttonPressedStateAlpha"];
	});
	
	return [originalColor colorWithAlphaComponent:alpha];
}


NSDate *VSOldDate(void) {
	
	static NSDate *oldDate = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		oldDate = QSDateWithString(@"2012-12-12T12:00:00Z");
	});
	
	return oldDate;
}


NSDate *VSSyncEndDate(void) {
	
#if SYNC_TRANSITION
	static NSDate *endDate = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		endDate = QSDateWithString(@"2016-08-30T20:00:00PDT");
	});
	
	return endDate;
#else
	return [NSDate distantFuture];
#endif
}


BOOL VSSyncIsShutdown(void) {
	
#if TEST_SYNC_IS_OVER
	return YES;
#endif
	
#if SYNC_TRANSITION
	
	static BOOL isShutdown = NO;
	if (isShutdown) {
		return YES;
	}
	
	NSDate *shutdownDate = VSSyncEndDate();
	isShutdown = [[NSDate date] earlierDate:shutdownDate] == shutdownDate;
	return isShutdown;
#else
	return NO;
#endif
}

