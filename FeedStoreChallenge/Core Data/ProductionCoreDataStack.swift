
import Foundation
import CoreData


public final class ProductionCoreDataStack: CoreDataStack {
    
    enum CoreDataStackError: Error {
        case wrongModelURL
    }
    
    public lazy var managedContext: NSManagedObjectContext = {
        container.newBackgroundContext()
    }()
    
    private let container: NSPersistentContainer
    
    public init(modelURL: URL, storeURL: URL) throws {
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw CoreDataStackError.wrongModelURL
        }
        
        let modelName = modelURL.deletingPathExtension().lastPathComponent
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        var receivedError: Error?
        container.loadPersistentStores { (stores, error) in
            receivedError = error
        }
        if let error = receivedError {
            throw error
        }
    }
    
    public func deleteAll(of entityName: String, context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try container.persistentStoreCoordinator.execute(deleteRequest, with: context)
    }
    
    public func saveContext(context: NSManagedObjectContext) throws {
        if !managedContext.hasChanges {
            return
        }
        try context.save()
    }
    
}
