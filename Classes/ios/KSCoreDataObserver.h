//
//  KSCoreDataObserver.h
//
//  Created by Kai Straßmann on 21.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, KSObserverType) {
	KSObserverTypeUpdated = 1,
	KSObserverTypeInserted = 2,
	KSObserverTypeDeleted = 4,
	KSObserverTypeAll = 7
};

typedef void (^ChangeBlock)(KSObserverType type, NSManagedObject *object, NSArray* attributes);
typedef void (^ObjectsDidChangeBlock)(NSSet *updated, NSSet *inserted, NSSet* deleted);

@interface KSCoreDataFilteredObserver : NSObject
@property (nonatomic, assign) KSObserverType mask;
@property (nonatomic, strong) ChangeBlock changeBlock;
- (BOOL)execute:(NSSet*)updated inserted:(NSSet*)inserted deleted:(NSSet*)deleted;
@end

@interface KSCoreDataObserver : NSObject
@property (nonatomic, weak) NSManagedObjectContext *requiredContext;
@property (nonatomic, strong) ObjectsDidChangeBlock objectsDidChangeBlock;
@property (nonatomic, assign) KSObserverType mask;

- (void)addFilteredObserver:(KSCoreDataFilteredObserver*)observer;
@end

#import "KSCoreDataManagedObjectObserver.h"