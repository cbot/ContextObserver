//
//  KSCoreDataObserver.m
//
//  Created by Kai Straßmann on 21.06.14.
//
//

#import "KSCoreDataObserver.h"

@interface KSCoreDataObserver ()
@property (nonatomic, strong) NSArray *observedObjectIDs; // this holds the (optional!) array of observed managed object IDs
@end

@implementation KSCoreDataObserver

- (instancetype)init {
    self = [super init];
    if (self) {
		self.observedObjectIDs = [NSMutableArray array]; // empty array: ALL nsmanagedobjects are observed
		self.mask = KSObserverTypeAll; // default: observe all change types, insert, delete, update
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }
    return self;
}

- (void)managedObjectDidChange:(NSNotification*)notification {
	NSManagedObjectContext *context = notification.object;
	
	if (self.requiredContext && self.requiredContext != context) return; // if a special context ist set for this observer: make sure we got the notification from the right one
	
	// get inserted objects
	NSSet *insertedObjects;
	if (self.mask & KSObserverTypeInserted) {
		insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	} else {
		insertedObjects = [NSSet set];
	}
	
	// get deleted objects
	NSSet *deletedObjects;
	if (self.mask & KSObserverTypeDeleted) {
		deletedObjects = notification.userInfo[NSDeletedObjectsKey];
	} else {
		deletedObjects = [NSSet set];
	}
	
	// get updated objects
	NSSet *updatedObjects;
	if (self.mask & KSObserverTypeUpdated) {
		updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	} else {
		updatedObjects = [NSSet set];
	}
	
	// call the objectsDidChange block for all inserted/deleted/updated objects
	if (self.objectDidChangeBlock) {
		for (NSManagedObject *object in insertedObjects) {
			if (self.observedObjectIDs.count == 0 || [self.observedObjectIDs containsObject:object.objectID]) self.objectDidChangeBlock(KSObserverTypeInserted, object, nil);
		}
		
		for (NSManagedObject *object in deletedObjects) {
			if (self.observedObjectIDs.count == 0 || [self.observedObjectIDs containsObject:object.objectID]) self.objectDidChangeBlock(KSObserverTypeDeleted, object, nil);
		}
		
		for (NSManagedObject *object in updatedObjects) {
			if (self.observedObjectIDs.count == 0 || [self.observedObjectIDs containsObject:object.objectID]) self.objectDidChangeBlock(KSObserverTypeUpdated, object, [[object changedValuesForCurrentEvent] allKeys]);
		}
	}
}

- (void)setObservedObject:(NSManagedObject*)managedObject {
	if (managedObject.objectID == nil) {
		self.observedObjectIDs = @[]; // reset
	} else {
		self.observedObjectIDs = @[managedObject.objectID];
	}
}

- (void)setObservedObjects:(NSArray*)managedObjects {
	self.observedObjectIDs = [managedObjects valueForKeyPath:@"objectID"];
}

- (void)dealloc {
	// make sure we remove ourself from the list of NSManagedObjectContextObjectsDidChangeNotification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end