//
//  KSCoreDataManagedObjectObserver.h
//  Pods
//
//  Created by Kai Straßmann on 24.06.14.
//
//

#import <Foundation/Foundation.h>
#import "KSCoreDataObserver.h"

@interface KSCoreDataManagedObjectObserver : KSCoreDataFilteredObserver
+ (instancetype)observerWithObject:(NSManagedObject*)object changeBlock:(ChangeBlock)changeBlock;
+ (instancetype)observerWithObjecsInSet:(NSSet*)objects changeBlock:(ChangeBlock)changeBlock;
+ (instancetype)observerWithObjecsInArray:(NSArray*)objects changeBlock:(ChangeBlock)changeBlock;
@end
