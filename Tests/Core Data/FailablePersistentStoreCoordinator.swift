
import Foundation
import CoreData


final class FailablePersistentStoreCoordinator: NSPersistentStoreCoordinator {
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext) throws -> Any {
        throw anyNSError()
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: NSPersistentStoreOperationError, userInfo: nil)
    }
    
}
