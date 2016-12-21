//
//  RSCoreDataUtilities.m
//  Vesper
//
//  Created by Brent Simmons on 12/6/12.
//  Copyright (c) 2012 Ranchero Software. All rights reserved.
//

#import "RSCoreDataUtilities.h"


static NSCache *gPredicateCache = nil;
static NSString *RSDataEqualityFormat = @"%@ == $VALUE";
//static NSString *RSDataInequalityFormat = @"%@ == $VALUE"; /*unused?*/
static NSString *RSDataGenericSubstitionKey = @"VALUE";


@implementation RSCoreDataUtilities


+ (void)initialize {
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		gPredicateCache = [NSCache new];
	});
}


+ (NSPredicate *)predicateWithEquality:(NSString *)key {
	NSPredicate *predicate = [gPredicateCache objectForKey:key];
	if (predicate != nil)
		return predicate;
	predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:RSDataEqualityFormat, key]];
	[gPredicateCache setObject:predicate forKey:key];
	return predicate;
}


+ (NSManagedObject *)fetchManagedObjectWithPredicate:(NSPredicate *)predicate entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	[request setFetchLimit:1];
	[request setPredicate:predicate];
	NSError *error = nil;
	return [[moc executeFetchRequest:request error:&error] rs_safeObjectAtIndex:0];
}


+ (NSArray *)fetchAllObjectsWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	NSError *error = nil;
	return [moc executeFetchRequest:request error:&error];
}


+ (NSArray *)fetchAllObjectsWithEntityName:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)sortDescriptor managedObjectContext:(NSManagedObjectContext *)moc {

    NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
    [request setSortDescriptors:@[sortDescriptor]];
	NSError *error = nil;
	return [moc executeFetchRequest:request error:&error];
}


+ (NSManagedObject *)fetchManagedObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	NSPredicate *localPredicate = [[self predicateWithEquality:key] predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:value forKey:RSDataGenericSubstitionKey]];
	return [self fetchManagedObjectWithPredicate:localPredicate entityName:entityName managedObjectContext:moc];
}


+ (NSManagedObject *)insertObjectWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
}


+ (NSManagedObject *)insertObjectWithDictionary:(NSDictionary *)matches entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	/*Assumes it doesn't exist already.*/
	NSManagedObject *insertedObject = [self insertObjectWithEntityName:entityName managedObjectContext:moc];
	for (NSString *oneKey in matches)
		[insertedObject setValue:[matches objectForKey:oneKey] forKey:oneKey];
	return insertedObject;
}


+ (NSManagedObject *)insertObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc {
	return [self insertObjectWithDictionary:[NSDictionary dictionaryWithObject:value forKey:key] entityName:entityName managedObjectContext:moc];
}


+ (NSManagedObject *)fetchOrInsertObjectWithValue:(id)value forKey:(NSString *)key entityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate {
	NSManagedObject *foundObject = [self fetchManagedObjectWithValue:value forKey:key entityName:entityName managedObjectContext:moc];
	if (foundObject != nil) {
		*didCreate = NO;
		return foundObject;
	}
	*didCreate = YES;
	return [self insertObjectWithValue:value forKey:key entityName:entityName managedObjectContext:moc];
}


@end
