import Foundation
import CoreData

public struct EventType : RawOptionSetType, BooleanType {
    typealias RawValue = UInt
    private var value: UInt = 7
    init(_ value: UInt) { self.value = value }
    public init(rawValue value: UInt) { self.value = value }
    public init(nilLiteral: ()) { self.value = 7 }
    public static var allZeros: EventType { return self(0) }
    static func fromMask(raw: UInt) -> EventType { return self(raw) }
    public var rawValue: UInt { return self.value }
    public var boolValue: Bool { return value != 0 }
    
    public static var All: EventType  { return self(7) }
    public static var Deleted: EventType { return self(1) }
    public static var Inserted: EventType   { return self(2) }
    public static var Updated: EventType  { return self(4) }
}

public class Handler {
    public var active = true
    private(set) public var filterMask: EventType = .All
    private(set) public var filterEntityDescriptions = [NSEntityDescription]()
    private(set) public var filterPredicates = [NSPredicate?]()
    private(set) public var filterGlobalPredicate: NSPredicate?
    private(set) public var observedContext: NSManagedObjectContext
    private(set) public var handleUpdatesWithoutChanges = false
    private(set) public var filterIgnoredKeys: [String]?
    private var block: ((object: NSManagedObject, type: EventType, keys: [String]) -> Void)?
    
    init(context: NSManagedObjectContext) {
        observedContext = context
    }
    
    func handle(#insertedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        if !active {
            return
        }
        
        if filterMask & .Updated {
            for object in updatedObjects {
                var updatedKeys = (object.changedValuesForCurrentEvent().keys.array as! [NSString]) as! [String]
                
                var objectIgnoredKeys = filterIgnoredKeys ?? [String]()
                if let object = object as? Observable {
                    objectIgnoredKeys = objectIgnoredKeys + object.ignoredKeysForObservation
                }
                
                updatedKeys = updatedKeys.filter { key in
                    !contains(objectIgnoredKeys, key)
                }
                
                if (!updatedKeys.isEmpty || handleUpdatesWithoutChanges) && isObserved(object) {
                    if ContextObserver.debugOutput { println("U \(object.entity.name != nil ? object.entity.name! : String()) - \(updatedKeys.debugDescription)") }
                    block?(object: object, type: EventType.Updated, keys: updatedKeys)
                }
            }
        }
        
        if filterMask & .Deleted {
            let emptyArray = [String]()
            for object in deletedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { println("D \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object: object, type: EventType.Deleted, keys: emptyArray)
                }
            }
        }
        
        if filterMask & .Inserted {
            let emptyArray = [String]()
            for object in insertedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { println("I \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object: object, type: EventType.Inserted, keys: emptyArray)
                }
            }
        }
    }
    
    public func block(block: (object: NSManagedObject, type: EventType, keys: [String]) -> Void) {
        self.block = block
    }
    
    public func handleUpdatesWithoutChanges(handle: Bool = true) -> Self {
        handleUpdatesWithoutChanges = handle
        return self
    }
    
    public func filter(type: EventType) -> Self {
        filterMask = type
        return self
    }
    
    public func filter(predicate: NSPredicate) -> Self {
        filterGlobalPredicate = predicate
        return self
    }
    
    public func filter(filterClasses: [NSManagedObject.Type], predicates: [NSPredicate]? = nil) -> Self {
        if let predicates = predicates where predicates.count != filterClasses.count {
            println("filterClasses count differs predicates count - filtering won't work as expected!")
            return self
        }
        
        for (index, filterClass) in enumerate(filterClasses) {
            filter(filterClass, predicate: predicates?[index])
        }
        return self
    }
    
    public func filter(objects: [NSManagedObject]) -> Self {
        for object in objects {
            filter(object)
        }
        return self
    }
    
    public func filter(object: NSManagedObject?) -> Self {
        if let object = object {
            filter(object.dynamicType, predicate: NSPredicate(format: "objectID = %@", object.objectID))
        }
        return self
    }
    
    public func filter(filterClass: NSManagedObject.Type, predicate: NSPredicate? = nil) -> Self {
        if let description = entityDescriptionForType(filterClass) {
            filterEntityDescriptions.append(description)
            filterPredicates.append(predicate)
        }
        return self
    }
    
    public func ignoreKeys(keys: [String]) -> Self {
        filterIgnoredKeys = keys
        return self
    }
    
    func isObserved(object: NSManagedObject) -> Bool {
        if let filterGlobalPredicate = filterGlobalPredicate {
            if !filterGlobalPredicate.evaluateWithObject(object) {
                return false
            }
        }
        
        if !filterEntityDescriptions.isEmpty {
            var contains = false
            
            for (index, description) in enumerate(filterEntityDescriptions) {
                if object.entity.isKindOfEntity(description) {
                    if let predicate = filterPredicates[index] {
                        if predicate.evaluateWithObject(object) {
                            contains = true
                            break
                        }
                    } else {
                        contains = true
                        break
                    }
                }
            }
            if !contains {
                return false
            }
        }
        
        return true
    }
    
    func entityDescriptionForType(type: NSManagedObject.Type) -> NSEntityDescription? {
        if let model = observedContext.persistentStoreCoordinator?.managedObjectModel, entities = model.entities as? [NSEntityDescription],
        description = entities.filter({ e in e.managedObjectClassName == toString(type.classForCoder()) }).first {
            return description
        }
        
        println("Unable to find EntityDescription for type \(type.debugDescription()) - filtering won't work as expected!")
        return nil
    }
}
