import Foundation
import CoreData

public struct EventType : OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {self.rawValue = rawValue}
    
    public static let All = EventType(rawValue: 15)
    public static let Deleted = EventType(rawValue: 1)
    public static let Inserted = EventType(rawValue: 2)
    public static let Updated = EventType(rawValue: 4)
    public static let Refreshed = EventType(rawValue: 8)
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
    private var block: ((_ object: NSManagedObject, _ type: EventType, _ keys: [String]) -> Void)?
    
    /// A dictionary that is used as a cache for the entityForClass method. The dictionary maps fully qualified core data model class names (Module.ClassName) to the associated NSEntityDescription instance
    private(set) var entityDescriptionsMap = [String: NSEntityDescription]()
    
    init(context: NSManagedObjectContext) {
        observedContext = context
    }
    
    func handle(insertedObjects: Set<NSManagedObject>, deletedObjects: Set<NSManagedObject>, updatedObjects: Set<NSManagedObject>, refreshedObjects: Set<NSManagedObject>) {
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
                    block?(object, EventType.Updated, updatedKeys)
                }
            }
        }

        if filterMask.contains(.Refreshed) {
            let emptyArray = [String]()
            for object in refreshedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { print("R \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object, EventType.Refreshed, emptyArray)
                }
            }
        }

        if filterMask.contains(.Deleted) {
            let emptyArray = [String]()
            for object in deletedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { print("D \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object, EventType.Deleted, emptyArray)
                }
            }
        }
        
        if filterMask.contains(.Inserted) {
            let emptyArray = [String]()
            for object in insertedObjects {
                if isObserved(object) {
                    if ContextObserver.debugOutput { print("I \(object.entity.name != nil ? object.entity.name! : String())") }
                    block?(object, EventType.Inserted, emptyArray)
                }
            }
        }
    }
    
    public func block(_ block: @escaping ((_ object: NSManagedObject, _ type: EventType, _ keys: [String]) -> Void)) {
        self.block = block
    }
    
    @discardableResult
    public func handleUpdatesWithoutChanges(_ handle: Bool = true) -> Self {
        handleUpdatesWithoutChanges = handle
        return self
    }
    
    @discardableResult
    public func filter(_ type: EventType) -> Self {
        filterMask = type
        return self
    }
    
    @discardableResult
    public func filter(_ predicate: NSPredicate) -> Self {
        filterGlobalPredicate = predicate
        return self
    }
    
    @discardableResult
    public func filter(_ filterClasses: [NSManagedObject.Type], predicates: [NSPredicate]? = nil) -> Self {
        if let predicates = predicates, predicates.count != filterClasses.count {
            print("filterClasses count differs predicates count - filtering won't work as expected!")
            return self
        }
        
        for (index, filterClass) in filterClasses.enumerated() {
            filter(filterClass, predicate: predicates?[index])
        }
        return self
    }
    
    @discardableResult
    public func filter(_ objects: [NSManagedObject]) -> Self {
        for object in objects {
            filter(object)
        }
        return self
    }
    
    @discardableResult
    public func filter(_ object: NSManagedObject?) -> Self {
        if let object = object {
            filter(NSPredicate(format: "objectID = %@", object.objectID))
        }
        return self
    }
    
    @discardableResult
    public func filter(_ filterClass: NSManagedObject.Type, predicate: NSPredicate? = nil) -> Self {
        if let description = entityForClass(filterClass) {
            filterEntityDescriptions.append(description)
            filterPredicates.append(predicate)
        }
        return self
    }
    
    @discardableResult
    public func ignoreKeys(_ keys: [String]) -> Self {
        filterIgnoredKeys = keys
        return self
    }
    
    func isObserved(_ object: NSManagedObject) -> Bool {
        if let filterGlobalPredicate = filterGlobalPredicate {
            if !filterGlobalPredicate.evaluate(with: object) {
                return false
            }
        }
        
        if !filterEntityDescriptions.isEmpty {
            var contains = false
            
            for (index, description) in filterEntityDescriptions.enumerated() {
                if object.entity.isKindOf(entity: description) {
                    if let predicate = filterPredicates[index] {
                        if predicate.evaluate(with: object) {
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
    func entityForClass<T: NSManagedObject>(_ classType: T.Type) -> NSEntityDescription? {
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
