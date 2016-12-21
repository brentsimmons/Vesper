//
//  RSCoreDataUtilities.h
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Ranchero Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSCoreDataUtilities : NSObject


+ (NSManagedObject *)fetchManagedObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc;

+ (NSManagedObject *)fetchOrInsertObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate;

+ (NSArray *)fetchAllObjectsWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc;
+ (NSArray *)fetchAllObjectsWithEntityName:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)sortDescriptor managedObjectContext:(NSManagedObjectContext *)moc;

+ (NSManagedObject *)insertObjectWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc;
+ (NSManagedObject *)insertObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc;


@end
