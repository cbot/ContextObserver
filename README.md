ContextObserver
======
This is a small library to manage CoreData notifications in order to update the user interface when a NSManagedObject is either inserted, deleted or updated.

ContextObserver works a bit like NSFetchedResultsController, that is by observing the managed object context's NSManagedObjectContextObjectsDidChangeNotification.

Whenever a change event occurs, a block is called that allows you to update your user interface accordingly.

## Requirements
ContextObserver supports iOS 7.0 and higher. However, in order to use the CocoaPods version of this library, iOS 8.0 is required. ContextObserver is also compatible with Mac OS X 10.9 or higher.

## Installation via CocoaPods
The preferred way to use ContextObserver is via CocoaPods. Just add the following line to your Podfile.
```
pod 'ContextObserver', '~> 3.0.1'
```

## Manual installation
Just drag all the files from the Classes subdirectory into your project and make sure all Swift source code files are added to your target.

## Examples
### Basic usage
```swift
let observer = ContextObserver(context: myManagedObjectContext)
observer.add().block { [weak self] (object: NSManagedObject, type: EventType, keys: [String]) in
	self?.updateUI()
}
```
This creates an instance of ContextObserver and registers a single handler whose closure will be called whenever an object from the given NSManagedObjectContext is changed, inserted or deleted. The type argument indicates whether there was an update, an insert or a deletion. For update events the affected keypaths are passed as the keys argument. The keys array is empty for inserts and deletions.

### Filters
In most cases the basic usage example is not exactly what you want. Real world applications typically contain quite a few different CoreData entities and potentially large amounts of NSManagedObject instances. In the example given above every single change in your NSManagedObjectContext triggers the handler's closure which in turn updates your UI. This is where filtering comes in.

#### Event type filters
```swift
observer.add().filter(.Inserted | .Deleted).block { [weak self] object, type, keys in
	self?.updateUI()
}
```
Pass EventType.Inserted, EventType.Deleted an/or EventType.Updated to the filter method in order to only have the closure called for desired event types.

#### Entity filters
```swift
observer.add().filter(Profile.self).block { [weak self] object, type, keys in
	self?.updateUI()
}

observer.add().filter(Profile.self, predicate: NSPredicate(format: "accountId = 1")).block { [weak self] object, type, keys in
	self?.updateUI()
}

observer.add().filter([Account.self, Event.self]).block { [weak self] object, type, keys in
	self?.updateUI()
}
```
You can pass an entity class or an array of entity classes to the filter method to only have the closure called for changes to objects from any of the given classes. It's also possible to specify a predicate in order to do additional filtering.

#### Instance filters
```swift
observer.add().filter(user).block { [weak self] object, type, keys in
	self?.updateUI()
}

observer.add().filter([user1, user2]).block { [weak self] object, type, keys in
	self?.updateUI()
}
```
You can call the filter method with instances of NSManagedObject to only have the closure called for changes to the given objects.

### Ignored properties
Often you want to exclude specific properties from observation, i.e. changes to a given group of properties should not trigger the observer. There are two ways to achieve this behavior:

#### Entity based ignored properties
You can mark an arbitrary set of properties as unobserved by making your NSManagedObject subclass conform to the Observable protocol.
```swift
class User: NSManagedObject, Observable {
	var ignoredKeysForObservation = ["lastUpdated"]

	@NSManaged var username: String
	@NSManaged var email: String
	@NSManaged var lastUpdated: Date
}
```

#### Per observer ignored properties
Call the ignoredKeys method with an array of ignored properties to prevent your closure from being called for changes to the given properties.
```swift
observer.add().filter(User.self).ignoredKeys(["lastUpdated"]).block { [weak self] object, type, keys in
	self?.updateUI()
}
```
