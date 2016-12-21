//
//  VSThumbnailRotation.m
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSThumbnailRotation.h"
#import "VSNote.h"
#import "VSTheme.h"
#import "VSAttachment.h"


static NSMutableDictionary *thumbnailRotationCache = nil;


static void startup(void) {

    static dispatch_once_t pred;
	dispatch_once(&pred, ^{
         thumbnailRotationCache = [NSMutableDictionary new];
	});
}


#pragma mark - Thumbnail Rotation Cache

static NSInteger cachedThumbnailRotationForNoteID(NSString *noteID, BOOL *wasCached) {

    assert(noteID != nil);

    startup();

    NSNumber *cachedRotation = thumbnailRotationCache[noteID];
    *wasCached = (cachedRotation != nil);

    if (cachedRotation == nil)
        return 0xbad;
    return [cachedRotation integerValue];

}


static void cacheThumbnailRotationForNoteID(NSString *noteID, NSInteger rotation) {

    assert(noteID != nil);

    startup();

    thumbnailRotationCache[noteID] = [NSNumber numberWithInteger:rotation];
}


static NSInteger randomRotation(void) {

    NSInteger rotationMin = [app_delegate.theme integerForKey:@"thumbnailRotationDegreesMinimum"];
    NSInteger rotationMax = [app_delegate.theme integerForKey:@"thumbnailRotationDegreesMaximum"];
    NSInteger rotationLock = [app_delegate.theme integerForKey:@"thumbnailRotationDegreesLock"];

    NSInteger rotationRangeSize = rotationMax + (-rotationMin);
    NSInteger randomRotation = (NSInteger)arc4random_uniform((u_int32_t)rotationRangeSize);
    randomRotation += rotationMin;

    if (abs(randomRotation) <= rotationLock)
        randomRotation = 0;

    return randomRotation;
}


#pragma mark - API

NSInteger thumbnailRotationForNote(VSNote *note) {

    if (note.attachment == nil || !note.attachment.isImage || RSStringIsEmpty(note.uniqueID))
        return 0;

    BOOL wasCached = NO;
    NSInteger rotation = cachedThumbnailRotationForNoteID(note.uniqueID, &wasCached);
    if (wasCached)
        return rotation;

    rotation = randomRotation();
    cacheThumbnailRotationForNoteID(note.uniqueID, rotation);
    
    return rotation;
}
