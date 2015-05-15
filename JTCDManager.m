//
//  JTCDManager.m
//  John TSai
//
//  Created by John TSai on 15/4/23.
//  Copyright (c) 2015年 John TSai. All rights reserved.
//

#import "JTCDManager.h"
#import <objc/runtime.h>

/**
 *  the resouce name of core data model
 */
static NSString *CDResource = @"soure short name";
static NSString *CDResourceName = @"you source full name";

@interface JTCDManager ()
{
    @private
    NSFetchRequest *_fetchRequest;
}

@end

@implementation JTCDManager

+ (instancetype)sharedManager {
    static JTCDManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _isCreated = YES;
        
        _priviteObjectContent = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _priviteObjectContent.undoManager = nil;
        
        _mainObjectContent = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainObjectContent.undoManager = nil;
        
        // init fetch request
        _fetchRequest = [[NSFetchRequest alloc] init];
        
        // create model
        [self createManagerObjectModel];
        
        // create persistentStoreCoordinator
        [self __persistentStoreCoordinator];
        
        // assign value to context
        _priviteObjectContent.persistentStoreCoordinator = _persistentStoreCoordinator;
        _mainObjectContent.parentContext = _priviteObjectContent;
        
        // add kvo
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    _fetchRequest = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSPersistentStoreCoordinator *)__persistentStoreCoordinator {
    
    // set path of persistentStore
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    NSURL *storeUrl = [NSURL fileURLWithPath: [cachePath stringByAppendingPathComponent:CDResourceName]];
    
    // create persistentStore
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        DLog(@"%@",error);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark -
#pragma mark FetchData
- (void)fetchData:(NSString *)entityName
     predicate:(NSPredicate *)predicate
   sortDescriptor:(NSSortDescriptor *)sortDesc
      resultBlock:(void (^)(NSError *error, NSArray *data))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAssert(entityName, @"the entity name is not nil");
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:_mainObjectContent];
        [_fetchRequest setEntity:entity];
        
        if (predicate) {
            [self fetchData:predicate
             sortDescriptor:sortDesc
                resultBlock:block];
            return ;
        }
        
        [self fetchData:sortDesc
            resultBlock:block];
    });
}

- (void)fetchData:(NSPredicate *)predicate
   sortDescriptor:(NSSortDescriptor *)sortDesc
      resultBlock:(void (^)(NSError *error, NSArray *data))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_fetchRequest setPredicate:predicate];
        
        if (sortDesc) {
            [self fetchData:sortDesc
                resultBlock:block];
            return ;
        }
        
        [self fetchData:block];
       
    });
}

- (void)fetchData:(NSSortDescriptor *)sortDesc
      resultBlock:(void (^)(NSError *error, NSArray *data))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDesc, nil]];
        
        [self fetchData:block];
    });
}

- (void)fetchData:(void (^)(NSError *error, NSArray *data))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        NSArray *fetchedObjects = [_mainObjectContent executeFetchRequest:_fetchRequest error:&error];
        if (fetchedObjects == nil) {
            
        }
        block(error,fetchedObjects);
    });
}

#pragma mark -
#pragma mark InitManagedObjectModel
- (void)createManagerObjectModel {
    // get the url of resource
    NSString *path = [[NSBundle mainBundle] pathForResource:CDResource ofType:@"momd"];
    NSAssert(path, @"can not found the datamodel path");
    NSURL *url = [NSURL fileURLWithPath:path];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    
    NSAssert(managedObjectModel, @"managerObjectModel is nil");
    _managedObjectModel = managedObjectModel;
}


#pragma mark -
#pragma mark Notification
- (void)contextDidSave:(NSNotification *)notification {
    if ([_mainObjectContent hasChanges])
        [_priviteObjectContent mergeChangesFromContextDidSaveNotification:notification];
    [_mainObjectContent mergeChangesFromContextDidSaveNotification:notification];
}

- (void)contextDidChange:(NSNotification *)notification {
    
}

#pragma mark -
#pragma mark Save
- (void)save:(NSError *__autoreleasing *)error {
    if ([_priviteObjectContent hasChanges]) {
        [_priviteObjectContent save:error];
    }
}


- (void)deleteObject:(NSManagedObject *)object {
    NSError *error;
    NSManagedObject *managedObject = [_priviteObjectContent objectWithID:[object objectID]];
    if (managedObject) {
        [_priviteObjectContent deleteObject:managedObject];
        [self save:&error];
    }
}


@end
