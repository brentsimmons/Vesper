//
//  VSSyncUtilities.h
//  Vesper
//
//  Created by Brent Simmons on 11/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


BOOL VSSyncObjectHasLaterDate(NSDate *syncObjectDate, NSDate *existingObjectDate);


/*Returns YES if existingObject got updated.*/

BOOL VSSyncProperty(id existingObject, id syncObject, NSString *propertyName);
