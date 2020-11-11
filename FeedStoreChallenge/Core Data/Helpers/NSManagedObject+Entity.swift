
import Foundation
import CoreData


public extension NSManagedObject {
    
    static var entityName: String {
        String(describing: Self.self)
    }
    
    convenience init(managedContext: NSManagedObjectContext) {
        self.init(entity: Self.entity(), insertInto: managedContext)
    }
    
}
