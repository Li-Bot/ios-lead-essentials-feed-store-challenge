
import Foundation
import CoreData


public final class CoreDataFeedStore: FeedStore {
    
    private var managedContext: NSManagedObjectContext {
        coreDataStack.managedContext
    }
    
    private let coreDataStack: CoreDataStack
    
    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        managedContext.perform { [unowned self] in
            let error = deleteCaches()
            completion(error)
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        managedContext.perform { [unowned self] in
            deleteCaches()
            let cdCache = createCache(timestamp: timestamp)
            
            let mapper = LocalToModelFeedMapper(feed: feed, cache: cdCache, context: managedContext)
            mapper.map()
            
            let error = coreDataStack.saveContext(context: managedContext)
            completion(error)
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        do {
            if let cache = try fetchCache() {
                let feed = ModelToLocalFeedMapper(feed: cache.feed).map()
                completion(.found(feed: feed, timestamp: cache.timestamp))
            } else {
                completion(.empty)
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func fetchCache() throws -> CDCache? {
        let fetchRequest: NSFetchRequest<CDCache> = CDCache.fetchRequest()
        let caches = try managedContext.fetch(fetchRequest)
        return caches.first
    }
    
    @discardableResult
    private func deleteCaches() -> Error? {
        coreDataStack.deleteAll(of: CDCache.entityName, context: managedContext)
    }
    
    private func createCache(timestamp: Date) -> CDCache {
        let cdCache = CDCache(managedContext: managedContext)
        cdCache.timestamp = timestamp
        return cdCache
    }
    
}
