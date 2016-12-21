//
//  FMDatabase+QSKit.h
//  Vesper
//
//  Created by Brent Simmons on 3/3/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;
#import "FMDatabase.h"
#import "FMResultSet.h"


typedef enum _QSDatabaseInsertType {
    QSDatabaseInsert,
    QSDatabaseInsertOrReplace,
	QSDatabaseInsertOrIgnore
} QSDatabaseInsertType;


@interface FMDatabase (QSKit)


/*Keys and table names are assumed to be trusted. Values are not.*/


/*delete from tableName where key in (?, ?, ?)*/

- (BOOL)qs_deleteRowsWhereKey:(NSString *)key inValues:(NSArray *)values tableName:(NSString *)tableName;

/*delete from tableName where key=?*/

- (BOOL)qs_deleteRowsWhereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName;


/*select * from tableName where key in (?, ?, ?)*/

- (FMResultSet *)qs_selectRowsWhereKey:(NSString *)key inValues:(NSArray *)values tableName:(NSString *)tableName;

/*select * from tableName where key = ? limit 1*/

- (FMResultSet *)qs_selectSingleRowWhereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName;

/*select * from tableName*/

- (FMResultSet *)qs_selectAllRows:(NSString *)tableName;

/*select key from tableName;*/

- (FMResultSet *)qs_selectColumnWithKey:(NSString *)key tableName:(NSString *)tableName;

/*select 1 from tableName where key = value limit 1;*/

- (BOOL)qs_rowExistsWithValue:(id)value forKey:(NSString *)key tableName:(NSString *)tableName;

/*select 1 from tableName limit 1;*/

- (BOOL)qs_tableIsEmpty:(NSString *)tableName;


/*update tableName set key1=?, key2=? where key = value*/

- (BOOL)qs_updateRowsWithDictionary:(NSDictionary *)d whereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName;

/*update tableName set key1=?, key2=? where key in (?, ?, ?)*/

- (BOOL)qs_updateRowsWithDictionary:(NSDictionary *)d whereKey:(NSString *)key inValues:(NSArray *)keyValues tableName:(NSString *)tableName;


/*insert (or replace, or ignore) into tablename (key1, key2) values (val1, val2)*/

- (BOOL)qs_insertRowWithDictionary:(NSDictionary *)d insertType:(QSDatabaseInsertType)insertType tableName:(NSString *)tableName;


@end


@interface FMResultSet (QSKit)

- (NSArray *)qs_arrayForSingleColumnResultSet; /*Doesn't handle dates.*/

@end

