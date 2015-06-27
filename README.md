ContextObserver
======
This is a small library to manage CoreData notifications in order to update the user interface when a NSManagedObject is either inserted, deleted or updated.

ContextObserver works a bit like NSFetchedResultsController, that is by observing the managed object context's NSManagedObjectContextObjectsDidChangeNotification.

Whenever a change event occurs, a block is called that allows you to update your user interface accordingly.

## Installation via CocoaPods
The preferred way to use ContextObserver is via CocoaPods. Just add the following line to your Podfile.
```
pod 'ContextObserver', '~> 2.0.0'
```

## Manual installation
Just drag all the files from the Classes subdirectory into your project and make sure all Swift source code files are added to your target.

## Examples
### Basic usage
```swift
let observer = ContextObserver(context: myManagedObjectContext)
observer.add().block { [weak self] (object: NSManagedObject, type: EventType, keys: [String]) in
	self?.configureView()
}
```
This creates an instance of ContextObserver and registers a single handler whose closure will be called whenever an object from the given NSManagedObjectContext is changed, inserted or deleted. The type argument indicates whether there was an update, an insert or a deletion. For update events the affected keypaths are passed as the keys argument. The keys array is empty for inserts and deletions.
