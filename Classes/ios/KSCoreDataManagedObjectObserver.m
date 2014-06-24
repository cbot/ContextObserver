//
//  KSCoreDataManagedObjectObserver.m
//  Pods
//
//  Created by Kai Straßmann on 24.06.14.
//
//

#import "KSCoreDataManagedObjectObserver.h"

@interface KSCoreDataManagedObjectObserver ()
@property (nonatomic, strong) NSSet *observedObjectIDs;
@end

@implementation KSCoreDataManagedObjectObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (instancetype)observerWithObject:(NSManagedObject*)object changeBlock:(ChangeBlock)changeBlock {
	KSCoreDataManagedObjectObserver *observer = [[self alloc] init];
	observer.observedObjectIDs = [NSSet setWithObject:object.objectID];
	observer.changeBlock = changeBlock;
	return observer;
}

+ (instancetype)observerWithObjecsInSet:(NSSet*)objects changeBlock:(ChangeBlock)changeBlock {
	KSCoreDataManagedObjectObserver *observer = [[self alloc] init];
	observer.changeBlock = changeBlock;
	
	NSMutableSet *objectIDs = [NSMutableSet set];
	for (NSManagedObject *object in objects) {
		[objectIDs addObject:object.objectID];
	}
	
	observer.observedObjectIDs = objectIDs;
	
	return observer;
}

+ (instancetype)observerWithObjecsInArray:(NSArray*)objects changeBlock:(ChangeBlock)changeBlock {
	return [self observerWithObjecsInSet:[NSSet setWithArray:objects] changeBlock:changeBlock];
}

- (BOOL)execute:(NSSet *)updated inserted:(NSSet *)inserted deleted:(NSSet *)deleted {
	BOOL executed = NO;
	
	for (NSManagedObjectID *objectID in self.observedObjectIDs) {
		
		if (self.mask & KSObserverTypeUpdated) for (NSManagedObject *object in updated) {
			if ([objectID isEqual:object.objectID]) {
				executed = YES;
				if (self.changeBlock) self.changeBlock(KSObserverTypeUpdated, object, [[object changedValuesForCurrentEvent] allKeys]);
			}
		}
		
		if (self.mask & KSObserverTypeInserted) for (NSManagedObject *object in inserted) {
			if ([objectID isEqual:object.objectID]) {
				executed = YES;
				if (self.changeBlock) self.changeBlock(KSObserverTypeInserted, object, nil);
			}
		}
		
		if (self.mask & KSObserverTypeDeleted) for (NSManagedObject *object in deleted) {
			if ([objectID isEqual:object.objectID]) {
				executed = YES;
				if (self.changeBlock) self.changeBlock(KSObserverTypeDeleted, object, nil);
			}
		}
		
	}
	
	return executed;
}

@end
