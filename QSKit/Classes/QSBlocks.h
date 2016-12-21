//
//  QSBlocks.h
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/22/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

@import Foundation;
#import "QSPlatform.h"


typedef void (^QSVoidBlock)(void);

typedef QSVoidBlock QSVoidCompletionBlock;

typedef BOOL (^QSBoolBlock)(void);

typedef void (^QSFetchResultsBlock)(NSArray *fetchedObjects);

typedef void (^QSDataResultBlock)(NSData *d);

typedef void (^QSObjectResultBlock)(id obj);

typedef void (^QSBoolResultBlock)(BOOL flag);


/*Images*/

typedef void (^QSImageResultBlock)(QS_IMAGE *image);

typedef QS_IMAGE *(^QSImageRenderBlock)(QS_IMAGE *imageToRender);


/*Calls on main thread. Ignores if nil.*/

void QSCallCompletionBlock(QSVoidCompletionBlock completion);

void QSCallBlockWithParameter(QSObjectResultBlock block, id obj);

void QSCallFetchResultsBlock(QSFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects);
