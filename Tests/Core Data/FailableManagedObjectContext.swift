
import Foundation
import CoreData


final class FailableManagedObjectContext: NSManagedObjectContext {
    
    private let allowFetch: Bool
    
    init(concurrencyType ct: NSManagedObjectContextConcurrencyType, allowFetch: Bool) {
        self.allowFetch = allowFetch
        super.init(concurrencyType: ct)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var hasChanges: Bool {
        true
    }
    
    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        if allowFetch {
            return []
        }
        throw anyNSError()
    }
    
}
