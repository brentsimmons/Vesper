//
//  VSExporter.h
//  Vesper
//
//  Created by Brent Simmons on 7/4/16.
//  Copyright © 2016 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *VSExportDidCompleteNotification;

@interface VSExporter : NSObject

- (void)exportNotesAndPictures;

@property (nonatomic, readonly) NSString *folder;

@property (nonatomic, readonly) NSError *exportError;

@end
