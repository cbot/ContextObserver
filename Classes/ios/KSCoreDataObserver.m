//
//  KSCoreDataObserver.m
//
//  Created by Kai Straßmann on 21.06.14.
//
//

#import "KSCoreDataObserver.h"

@interface KSCoreDataObserver ()
@property (nonatomic, strong) NSMutableArray *filteredObservers;
@end

@implementation KSCoreDataObserver

- (instancetype)init {
    self = [super init];
    if (self) {
		self.filteredObservers = [NSMutableArray array];
		self.mask = KSObserverTypeAll;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }
    return self;
}

- (void)managedObjectDidChange:(NSNotification*)notification {
	NSManagedObjectContext *context = notification.object;
	
	if (self.requiredContext && self.requiredContext != context) return;
	
	NSSet *updatedObjects;
	if (self.mask & KSObserverTypeUpdated) {
		updatedObjects = notification.userInfo[NSUpdatedObjectsKey];
	} else {
		updatedObjects = [NSSet set];
	}
	
	NSSet *insertedObjects;
	if (self.mask & KSObserverTypeInserted) {
		insertedObjects = notification.userInfo[NSInsertedObjectsKey];
	} else {
		insertedObjects = [NSSet set];
	}
	
	NSSet *deletedObjects;
	if (self.mask & KSObserverTypeDeleted) {
		deletedObjects = notification.userInfo[NSDeletedObjectsKey];
	} else {
		deletedObjects = [NSSet set];
	}
	
	if (insertedObjects.count > 0 || updatedObjects.count > 0 || deletedObjects.count > 0) {
		if (self.objectsDidChangeBlock) {
			self.objectsDidChangeBlock(updatedObjects, insertedObjects, deletedObjects);
		}
		for (KSCoreDataFilteredObserver *filteredObserver in self.filteredObservers) {
			[filteredObserver execute:updatedObjects inserted:insertedObjects deleted:deletedObjects];
		}
	}
}

- (void)addFilteredObserver:(KSCoreDataFilteredObserver *)observer {
	if (![self.filteredObservers containsObject:observer]) {
		[self.filteredObservers addObject:observer];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

@implementation KSCoreDataFilteredObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mask = KSObserverTypeAll;
    }
    return self;
}

- (BOOL)execute:(NSSet*)updated inserted:(NSSet*)inserted deleted:(NSSet*)deleted {
	// empty
	return NO;
}

@end
