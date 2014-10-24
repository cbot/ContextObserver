//
//  KSCoreDataObserver.m
//
//  Created by Kai Straßmann on 21.06.14.
//
//

#import "KSCoreDataObserver.h"

@interface KSCoreDataObserver ()
@property (nonatomic, strong) NSArray *observedObjectIDs; // this holds the (optional!) array of observed managed object IDs
@property (nonatomic, strong) NSArray *observedEntityNames; // this holds the (optional!) array of observed entity names
@property (nonatomic, strong) NSPredicate *fullPredicate; // this is the predicate that is actually used to filter objects, see updateFullPredicate
@end

@implementation KSCoreDataObserver

- (instancetype)init {
    self = [super init];
    if (self) {
		self.observedObjectIDs = [NSArray array]; // empty array: ALL NSManagedObjects are observed
		self.observedEntityNames = [NSArray array]; // empty array: ALL entities are observed
		
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
			if ([self isObservedObject:object]) {
				self.objectDidChangeBlock(KSObserverTypeInserted, object, nil);
			}
		}
		
		for (NSManagedObject *object in deletedObjects) {
			if ([self isObservedObject:object]) {
				self.objectDidChangeBlock(KSObserverTypeDeleted, object, nil);
			}
		}
		
		for (NSManagedObject *object in updatedObjects) {
			NSArray *updatedKeys = [[object changedValuesForCurrentEvent] allKeys];
			if ((updatedKeys.count > 0 || self.reportUpdatesWithoutChanges) && [self isObservedObject:object]) {
				self.objectDidChangeBlock(KSObserverTypeUpdated, object, updatedKeys);
			}
		}
	}
}

- (BOOL)isObservedObject:(NSManagedObject*)object {
	return (self.fullPredicate == nil || [self.fullPredicate evaluateWithObject:object]);
}

#pragma mark - Observed Objects
- (void)setObservedObject:(NSManagedObject*)managedObject {
	if (managedObject.objectID == nil) {
		[self setObservedObjects:@[]]; // reset
	} else {
		[self setObservedObjects:@[managedObject]];
	}
}

- (void)setObservedObjects:(NSArray*)managedObjects {
	self.observedObjectIDs = [managedObjects valueForKeyPath:@"objectID"];
	[self updateFullPredicate];
}

#pragma mark - Observed Entities
- (void)setObservedEntityName:(NSString*)entityName {
	if (entityName == nil) {
		[self setObservedEntityNames:@[]]; // reset
	} else {
		[self setObservedEntityNames:@[entityName]];
	}
}

- (void)setObservedEntityNames:(NSArray*)entityNames {
	_observedEntityNames = entityNames;
	[self updateFullPredicate];
}

#pragma mark - User Predicate
- (void)setPredicate:(NSPredicate *)predicate {
	_predicate = predicate;
	[self updateFullPredicate];
}

#pragma mark - Filter predicate creation
- (void)updateFullPredicate {
	NSMutableArray *subPredicates = [NSMutableArray array];
	
	if (self.observedEntityNames.count > 0) {
		NSMutableArray *entityPredicates = [NSMutableArray array];
		for (NSString *entityName in self.observedEntityNames) {
			[entityPredicates addObject:[NSPredicate predicateWithFormat:@"entity.name = %@", entityName]];
		}
		[subPredicates addObject:[[NSCompoundPredicate alloc] initWithType:NSOrPredicateType subpredicates:entityPredicates]];
	}
	
	if (self.observedObjectIDs.count > 0) {
		NSMutableArray *objectIDPredicates = [NSMutableArray array];
		for (NSString *objectID in self.observedObjectIDs) {
			[objectIDPredicates addObject:[NSPredicate predicateWithFormat:@"objectID = %@", objectID]];
		}
		[subPredicates addObject:[[NSCompoundPredicate alloc] initWithType:NSOrPredicateType subpredicates:objectIDPredicates]];
	}
	
	if (self.predicate) {
		[subPredicates addObject:[NSPredicate predicateWithFormat:@"managedObjectContext != %@", nil]];
		[subPredicates addObject:self.predicate];
	}
	
	self.fullPredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:subPredicates];
}

#pragma mark - Memory
- (void)dealloc {
	// make sure we remove ourself from the list of NSManagedObjectContextObjectsDidChangeNotification observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end