//
//  VSConstants.h
//  Vesper
//
//  Created by Brent Simmons on 3/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@import Foundation;
#import "QSPlatform.h"


extern NSString *VSUniqueIDsKey;
extern NSString *VSUniqueIDKey;
extern NSString *UniqueIDKey;

extern NSString *VSImageKey;
extern NSString *VSNoteKey;
extern NSString *VSNotesKey;

extern NSString *VSDidBecomeFirstResponderNotification;
extern NSString *VSDidResignFirstResponderNotification;
extern NSString *VSResponderKey;

extern NSString *VSAppShouldShowStatusBarNotification;
extern NSString *VSAppShouldHideStatusBarNotification;

extern NSString *VSBrowserViewDidOpenNotification;
extern NSString *VSBrowserViewDidCloseNotification;

extern NSString *VSSidebarDidChangeDisplayStateNotification;
extern NSString *VSSidebarShowingKey;

extern NSString *VSWillShowTagPopoverNotification;
extern NSString *VSButtonKey;

extern NSString *VSRightSideViewFrameDidChangeNotification;
extern NSString *VSFrameKey; /*NSValue of CGRect*/
extern NSString *VSViewControllerKey;

extern NSString *VSSourceListSelectionDidChangeNotification; /*userInfo @{VSSourceListItemKey : sourceListItem}, or empty if no selection*/
extern NSString *VSTimelineSelectionDidChangeNotification; /*userInfo: @{VSNoteKey : note}, or empty if no note*/

extern NSString *VSSourceListItemKey;

extern NSString *VSSidebarTagsDidChangeNotification;
extern NSString *VSTagsKey; /*userInfo - the sidebar tags*/

extern NSString *VSDataMigrationDidBeginNotification;
extern NSString *VSDataMigrationDidCompleteNotification;

extern NSString *VSDidCopyNoteNotification;
extern NSString *VSSyncNoteTagsDidChangeNotification;
extern NSString *VSSyncNotesDidChangeNotification;

/*Always sent on main thread.*/

extern NSString *VSHTTPCallDidBeginNotification;
extern NSString *VSHTTPCallDidEndNotification;

extern NSString *VSSyncDidBeginNotification;
extern NSString *VSSyncDidCompleteNotification;

extern const int64_t VSTutorialNoteMaxID; /*Tutorial note ID range is from 0 to VSTutorialNoteMaxID.*/
extern const int64_t VSNoteMaxID; /*JavaScript 2^53 integer max.*/

#if TARGET_OS_IPHONE

void VSSendRightSideViewFrameDidChangeNotification(UIViewController *viewController, CGRect frame);

#endif

extern const CGFloat VSNavbarHeight;
//extern const CGFloat VSNormalStatusBarHeight;

CGFloat VSNormalStatusBarHeight(void);

extern NSString *VSDataViewDidPanToRevealSidebarNotification;
extern NSString *VSPercentMovedKey; /*userInfo key for above*/


extern NSString *VSUIEventHappenedNotification; /*Popovers watch this to know to dismiss*/

void VSSendUIEventHappenedNotification(void); /*Call any time there might be a popover to dismiss*/

extern NSString *VSShouldCloseSidebarNotification;
void VSCloseSidebar(void); /*Closes without animation*/

typedef NS_ENUM(NSUInteger, VSPosition) {
	VSFirst,
	VSMiddle,
	VSLast,
	VSOnly
};

typedef NS_ENUM(NSUInteger, VSDirection) {
	VSUp,
	VSDown,
	VSLeft,
	VSRight
};


/*NSUserDefaults*/

extern NSString *VSDefaultsUseSmallCapsKey;
extern NSString *VSDefaultsFontLevelKey; /*number: 0 - 4*/
extern NSString *VSDefaultsTextWeightKey; /*VSTextWeightLight or VSTextWeightRegular*/

typedef NS_ENUM(NSUInteger, VSTextWeight) {
	/*Don't change these, since they're stored in NSUserDefaults*/
	VSTextWeightRegular = 1,
	VSTextWeightLight = 2
};

VSTextWeight VSDefaultsTextWeight(void);
void VSDefaultsSetTextWeight(VSTextWeight textWeight);

BOOL VSDefaultsUsingLightText(void);

NSUInteger VSDefaultsFontLevelMaximum(void);
NSUInteger VSDefaultsFontLevel(void);
void VSDefaultsSetFontLevel(NSUInteger fontLevel);

QS_COLOR *VSPressedColor(QS_COLOR *originalColor);


NSDate *VSOldDate(void);


@class VSAPIResult;

typedef void (^VSAPIResultBlock)(VSAPIResult *apiResult);


NSDate *VSSyncEndDate(void);
BOOL VSSyncIsShutdown(void);

