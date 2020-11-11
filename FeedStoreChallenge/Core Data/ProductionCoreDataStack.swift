
import Foundation
import CoreData


public final class ProductionCoreDataStack: CoreDataStack {
    
    public lazy var managedContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
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
        NSManagedObjectModel.mergedModel(from: [Bundle(for: ProductionCoreDataStack.self)])!
    }()
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func deleteAll(of entityName: String, context: NSManagedObjectContext) -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentStoreCoordinator.execute(deleteRequest, with: context)
            return nil
        } catch {
            return error
        }
    }
    
    @discardableResult
    public func saveContext(context: NSManagedObjectContext) -> Error? {
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
