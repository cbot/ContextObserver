import Foundation
import CoreData

public struct EventType : OptionSetType {
    public let rawValue: UInt
    public init(rawValue: UInt) {self.rawValue = rawValue}
    
    public static let All = EventType(rawValue: 7)
    public static let Deleted = EventType(rawValue: 1)
    public static let Inserted = EventType(rawValue: 2)
    public static let Updated = EventType(rawValue: 4)
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
    
    /// A dictionary that is used as a cache for the entityForClass method. The dictionary maps fully qualified core data model class names (Module.ClassName) to the associated NSEntityDescription instance
    private(set) var entityDescriptionsMap = [String: NSEntityDescription]()
    
    init(context: NSManagedObjectContext) {
        observedContext = context
    }
    
    func handle(insertedObjects insertedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>) {
        if !active {
            return
        }
        
        if filterMask.contains(.Updated) {
            for object in updatedObjects {
                var updatedKeys = Array(object.changedValuesForCurrentEvent().keys)
                
                var objectIgnoredKeys = filterIgnoredKeys ?? [String]()
                if let object = object as? Observable {
                    objectIgnoredKeys = objectIgnoredKeys + object.ignoredKeysForObservation
                }
                
                updatedKeys = updatedKeys.filter { key in
                    !objectIgnoredKeys.contains(key)
                }
                
                if (!updatedKeys.isEmpty || handleUpdatesWithoutChanges) && isObserved(object) {
                    if ContextObserver.debugOutput { print("U \(object.entity.name != nil ? object.entity.name! : String()) - \(updatedKeys.debugDescription)") }
                    block?(object: object, type: EventType.Updated, keys: updatedKeys)
                }
            }
        }
        
        if filterMask.contains(.Deleted) {
            let emptyArray = [String]()
            for object in deletedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { print("D \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object: object, type: EventType.Deleted, keys: emptyArray)
                }
            }
        }
        
        if filterMask.contains(.Inserted) {
            let emptyArray = [String]()
            for object in insertedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { print("I \(object.entity.name != nil ? object.entity.name! : String())") }
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
            print("filterClasses count differs predicates count - filtering won't work as expected!")
            return self
        }
        
        for (index, filterClass) in filterClasses.enumerate() {
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
            filter(NSPredicate(format: "objectID = %@", object.objectID))
        }
        return self
    }
    
    public func filter(filterClass: NSManagedObject.Type, predicate: NSPredicate? = nil) -> Self {
        if let description = entityForClass(filterClass) {
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
            
            for (index, description) in filterEntityDescriptions.enumerate() {
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
    
    
    /**
     Method that tries to find the associated NSEntityDescription for a given NSManagedObject subclass.
     
     - parameter classType: the class to find the NSEntityDescription for
     
     - returns: the NSEntityDescription for the given class or nil
     */
    func entityForClass<T: NSManagedObject>(classType: T.Type) -> NSEntityDescription? {
        guard let model = observedContext.persistentStoreCoordinator?.managedObjectModel else {
            print("Unable to find EntityDescription for type \(classType.debugDescription()) - filtering won't work as expected!")
            return nil
        }
        
        let fullClassName = NSStringFromClass(classType) as String // get the Module.ClassName representation
        
        // let's see if we have a NSEntityDescription in our cache
        if let entity = entityDescriptionsMap[fullClassName] {
            return entity
        }
        
        // reduce entities to a fitting NSEntityDescription
        let entity = model.entities.reduce(nil as NSEntityDescription?) { current, entity in
            if current != nil {
                return current
            } else if entity.managedObjectClassName == fullClassName {
                return entity
            } else {
                return nil
            }
        }
        
        if entity == nil {
            print("Unable to find EntityDescription for type \(classType.debugDescription()) - filtering won't work as expected!")
        }
        
        // update cache
        entityDescriptionsMap[fullClassName] = entity
        
        return entity
    }
}
