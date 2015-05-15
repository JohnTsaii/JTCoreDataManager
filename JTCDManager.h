//
//  JTCDManager.h
//  John TSai
//
//  Created by John TSai on 15/4/23.
//  Copyright (c) 2015年 John TSai. All rights reserved.
//
//  TODO: add a start sdk method
//  TODO: migrate FMDB Data to CoreData

#import <Foundation/Foundation.h>
@import CoreData;

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

@interface JTCDManager : NSObject

/**
 *  return a single instance and init
 *  setting
 *  @return JTCDManger instance
 */
+ (instancetype)sharedManager;

/**
 *  the readonly priviteObjectContent that use to save data
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *priviteObjectContent;

/**
 *  the readonly mainObjectContent that use get data
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *mainObjectContent;

/**
 *  the global managedObjectModel
 */
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;

/**
 *  the global persistentStoreCoordinator
 */
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 *  judge the sdk is create,default is NO
 */
@property (nonatomic, assign, readonly) BOOL isCreated;

//////////////////////////////////////////////////////////////////////
////////////////    Methods that for manager  ////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

/**
 *  fetch data from core data
 *
 *  @param entityName the entity name
 *  @param predicate  fetch request predicate
 *  @param sortDesc   fetch request sortDescriptor
 *  @param block      result block return fetch data
 *  if fetch failed the error will not be nil. otherwise,
 *  the error is nil
 */
- (void)fetchData:(NSString *)entityName
        predicate:(NSPredicate *)predicate
   sortDescriptor:(NSSortDescriptor *)sortDesc
      resultBlock:(void (^)(NSError *error, NSArray *data))block;

/**
 *  save context to persistent store
 *
 *  @param error if save failed the error will not be nil
 */
- (void)save:(NSError * __autoreleasing *)error;

/**
 *  delete object
 *  @param object that you want to delete
 *
 */
- (void)deleteObject:(NSManagedObject *)object;


@end
