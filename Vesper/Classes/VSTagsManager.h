//
//  VSTagsManager.h
//  Vesper
//
//  Created by Brent Simmons on 2/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Main thread only.*/

@class VSTag;

@interface VSTagsManager : NSObject


//- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;

/*Both of these are observable.*/

@property (nonatomic, strong, readonly) NSSet *tags;
@property (nonatomic, strong, readonly) NSSet *tagNames;

//- (VSTag *)existingTagWithName:(NSString *)tagName;

@end
