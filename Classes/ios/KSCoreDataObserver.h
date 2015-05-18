//
//  KSCoreDataObserver.h
//
//  Created by Kai Straßmann on 21.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 *  The type of a NSManagedObject change event
 */
typedef NS_ENUM(NSUInteger, KSObserverType) {
	/**
	 *  An object's attributes were changed
	 */
	KSObserverTypeUpdated = 1,
	/**
	 *  A new object was inserted
	 */
	KSObserverTypeInserted = 2,
	/**
	 *  An object was deleted
	 */
	KSObserverTypeDeleted = 4,
	/**
	 *  All of the above
	 */
	KSObserverTypeAll = 7
};

/**
 *  A block of this type is called whenever the observer detects changes in the NSManagedObjectContext
 *
 *  @param type          A value of type KSObserverType that indicates the type of event for this call
 *  @param managedObject The NSManagedObject that was inserted, deleted or updated
 *  @param updatedKeys   Only for KSObserverTypeUpdated: an array of changed keys that were changed for the NSManagedObject
 */
typedef void (^ObjectDidChangeBlock)(KSObserverType type, NSManagedObject *managedObject, NSArray *updatedKeys);

/**
 *  KSCoreDataObserver makes it easy to observe a NSManagedObjectContext for inserted, deleted or updated objects.
 */
@interface KSCoreDataObserver : NSObject

/**
 *  The designated initializer for KSCoreDataObserver
 *
 *  @param context the context to observe. Pass nil to observer all contexts. Note: completion blocks will be called from the context's thread!
 */
- (instancetype)initWithContext:(NSManagedObjectContext*)context NS_DESIGNATED_INITIALIZER;

/**
 *  The block that is called to indicate changes in the NSMangedObjectContext
 */
@property (nonatomic, strong) ObjectDidChangeBlock objectDidChangeBlock;

/**
 *  Optional: set this property to only observe the given NSManagedObjectContext
 */
@property (nonatomic, weak) NSManagedObjectContext *requiredContext;

/**
 *  Optional: set this property to determine the type of changes to be observed
 */
@property (nonatomic, assign) KSObserverType mask;

/**
 *  Optional: set this property to YES in order to get notifications for KSObserverTypeUpdated events without actually changed values
 */
@property (nonatomic, assign) BOOL reportUpdatesWithoutChanges;

/**
 *  Optional: a user defined predicate to filter observed objects. Be very careful when setting this property to avoid key value coding related crashes.
 *  Always make sure to also set either an observed entity name or an observed object.
 */
@property (nonatomic, strong) NSPredicate *predicate;

/**
 *  Optional: set this to define keys that should not trigger a notification
 */
@property (nonatomic, strong) NSArray *ignoredKeys;

/**
 *  Optional: an array of NSManagedObjectID instances whose corresponding NSManagedObjects should be observed for changes
 */
@property (nonatomic, strong) NSArray *observedObjectIDs;

/**
 *  Optional: an array of entity names (as strings) that should be observed for changes
 */
@property (nonatomic, strong) NSArray *observedEntityNames;

/**
 *  Optional: call this method to set a specific NSManagedObject that should be observed
 *
 *  @param managedObject A NSManagedObject to be observed for changes
 */
- (void)setObservedObject:(NSManagedObject*)managedObject;

/**
 *  Optional: call this method to set an array of NSManagedObjects that should be observed
 *
 *  @param managedObjects An array of NSManagedObjects to be observed for changes
 */
- (void)setObservedObjects:(NSArray*)managedObjects;
@end