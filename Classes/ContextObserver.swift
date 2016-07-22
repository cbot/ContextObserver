import Foundation
import CoreData

public class ContextObserver: NSObject {
    public static var debugOutput = false
    
    private(set) public var observedContext: NSManagedObjectContext
    private var registeredHandlers = [Handler]()
    public var active = true
    
    public init(context: NSManagedObjectContext) {
        observedContext = context

        super.init()
        
        // register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(ContextObserver.managedObjectDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
        
    public func add() -> Handler {
        let blockHandler = Handler(context: observedContext)
        registeredHandlers.append(blockHandler)
        return blockHandler
    }
    
    public func clear() {
        registeredHandlers.removeAll()
    }
    
    // MARK: - Notifications
    func managedObjectDidChange(_ notification: Notification) {
        if !active { // observer disabled
            return
        }
        
        if let context = notification.object as? NSManagedObjectContext, let userInfo = (notification as NSNotification).userInfo, context == observedContext {
            let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
            
            for handler in registeredHandlers {
                handler.handle(insertedObjects: insertedObjects, deletedObjects: deletedObjects, updatedObjects: updatedObjects)
            }
        }
    }
    
    // MARK: - Memory
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
