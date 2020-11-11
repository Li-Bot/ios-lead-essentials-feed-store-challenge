
import Foundation
import CoreData


public protocol CoreDataStack {
    
    var managedContext: NSManagedObjectContext { get }
    
    init(storeURL: URL)

    func deleteAll(of entityName: String, context: NSManagedObjectContext) -> Error?
    func saveContext(context: NSManagedObjectContext) -> Error?
    
}
