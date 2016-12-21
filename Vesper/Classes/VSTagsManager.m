//
//  VSTagsManager.m
//  Vesper
//
//  Created by Brent Simmons on 2/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTagsManager.h"
#import "VSTag.h"


@interface VSTagsManager ()

@property (nonatomic, strong, readwrite) NSSet *tags;
@property (nonatomic, strong, readwrite) NSSet *tagNames;
@end


@implementation VSTagsManager


#pragma mark Init

//- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
//
//    self = [super init];
//    if (self == nil)
//        return nil;
//
//    _managedObjectContext = moc;
//
//    NSArray *tagsArray = [VSTag tags:_managedObjectContext];
//    if (tagsArray != nil)
//        _tags = [NSSet setWithArray:[VSTag tags:_managedObjectContext]];
//
//    [self addObserver:self forKeyPath:@"tags" options:NSKeyValueObservingOptionInitial context:nil];
//    
//    if (!RSIsEmpty(_tags))
//        _tagNames = [_tags valueForKeyPath:@"name"];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagWasAdded:) name:VSTagDidAddTagNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagWasDeleted:) name:VSTagDidDeleteTagNotification object:nil];
//
//    return self;
//}
//
//
//#pragma mark Dealloc
//
//- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"tags" context:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
//
//#pragma mark KVO
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//
//    if ([keyPath isEqualToString:@"tags"] && object == self) {
//        if (RSIsEmpty(self.tags))
//            self.tagNames = nil;
//        else
//            self.tagNames = [self.tags valueForKeyPath:@"name"];
//    }
//}
//
//
//#pragma mark Tags
//
//- (VSTag *)existingTagWithName:(NSString *)tagName {
//
//    if (RSStringIsEmpty(tagName))
//        return nil;
//    
//    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"name ==[c] %@", tagName];
//    NSSet *filteredTags = [self.tags filteredSetUsingPredicate:namePredicate];
//
//    return [filteredTags anyObject];
//}
//
//
//- (void)addTagWithName:(NSString *)tagName {
//
//    if (RSStringIsEmpty(tagName))
//        return;
//    
//    NSMutableSet *mutableTags = [self.tags mutableCopy];
//    VSTag *createdTag = [VSTag existingTagWithName:tagName managedObjectContext:self.managedObjectContext];
//    
//    [mutableTags rs_addObject:createdTag];
//    self.tags = mutableTags;
//}
//
//
//- (void)removeTagWithName:(NSString *)tagName {
//
//    VSTag *tagToRemove = [self existingTagWithName:tagName];
//    if (tagToRemove == nil)
//        return;
//
//    NSMutableSet *mutableTags = [self.tags mutableCopy];
//    if ([mutableTags containsObject:tagToRemove]) {
//        [mutableTags removeObject:tagToRemove];
//        self.tags = [mutableTags copy];
//    }
//}
//
//
//#pragma mark Notifications
//
//- (void)tagWasAdded:(NSNotification *)note {
//
//    NSString *tagName = note.userInfo[VSTagNameKey];
//    if ([NSThread isMainThread])
//        [self addTagWithName:tagName];
//    else
//        [self performSelectorOnMainThread:@selector(addTagWithName:) withObject:tagName waitUntilDone:NO];
//}
//
//
//- (void)tagWasDeleted:(NSNotification *)note {
//    
//    NSString *tagName = note.userInfo[VSTagNameKey];
//    if ([NSThread isMainThread])
//        [self removeTagWithName:tagName];
//    else
//        [self performSelectorOnMainThread:@selector(removeTagWithName:) withObject:tagName waitUntilDone:NO];
//}


@end

