
import Foundation
import CoreData
import FeedStoreChallenge


final class FailableCoreDataStack: CoreDataStack {
    
    lazy var managedContext: NSManagedObjectContext = {
        var managedObjectContext = FailableManagedObjectContext(concurrencyType: .privateQueueConcurrencyType, allowFetch: allowFetch)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let storeOptions = [NSMigratePersistentStoresAutomaticallyOption : true,
                            NSInferMappingModelAutomaticallyOption : true
        ]

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: storeOptions)
        } catch {
            print("Unresolved error \(error)")
            abort()
        }
        return coordinator
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        return NSManagedObjectModel.mergedModel(from: [Bundle(for: ProductionCoreDataStack.self)])!
    }()
    
    private let storeURL: URL
    private let allowFetch: Bool
    
    init(storeURL: URL, allowFetch: Bool) {
        self.storeURL = storeURL
        self.allowFetch = allowFetch
    }
    
    func deleteAll(of entityName: String, context: NSManagedObjectContext) throws {
        throw anyNSError()
    }
    
    func saveContext(context: NSManagedObjectContext) throws {
        throw anyNSError()
    }
    
}
