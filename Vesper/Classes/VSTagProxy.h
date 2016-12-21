//
//  VSTagProxy.h
//  Vesper
//
//  Created by Brent Simmons on 4/11/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Used by VSDetailViewController. Probably not useful elsewhere.*/

@class VSTag;


@interface VSTagProxy : NSObject


@property (nonatomic, strong) VSTag *tag; /*May be nil.*/
@property (nonatomic, strong, readonly) VSTag *initialTag; /*May be nil; tag may change; this won't*/
@property (nonatomic, strong) NSString *name; /*May be nil.*/
@property (nonatomic, strong, readonly) NSString *normalizedName; /*May be nil; calculated on demand*/
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign, readonly) BOOL isGhostTag;

+ (instancetype)tagProxyWithTag:(VSTag *)tag;
+ (NSArray *)tagProxiesWithTags:(NSArray *)tags;

+ (instancetype)tagProxyWithName:(NSString *)name;

- (void)createTagIfNeeded;

@end


@interface VSGhostTagProxy : VSTagProxy

+ (instancetype)ghostTagProxy;

@end

