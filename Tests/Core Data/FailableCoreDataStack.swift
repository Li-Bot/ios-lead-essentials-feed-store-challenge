
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
        var coordinator = FailablePersistentStoreCoordinator(managedObjectModel: managedObjectModel)
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
    
    init(storeURL: URL) {
        self.storeURL = storeURL
        allowFetch = false
    }
    
    init(storeURL: URL, allowFetch: Bool) {
        self.storeURL = storeURL
        self.allowFetch = allowFetch
    }
    
    func deleteAll(of entityName: String, context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try persistentStoreCoordinator.execute(deleteRequest, with: context)
    }
    
    @discardableResult
    func saveContext(context: NSManagedObjectContext) -> Error? {
        if !context.hasChanges {
            return nil
        }
        do {
            try context.save()
            return nil
        } catch {
            return error
        }
    }
    
}
