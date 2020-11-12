
import Foundation


func anyNSError() -> NSError {
    NSError(domain: "any error", code: NSPersistentStoreOperationError, userInfo: nil)
}
