
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
        managedContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                try self.deleteCaches()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        managedContext.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.deleteCaches()
                _ = self.createCache(feed: feed, timestamp: timestamp)
                
                try self.coreDataStack.saveContext(context: self.managedContext)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        managedContext.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                if let cache = try self.fetchCache() {
                    let feed = ModelToLocalFeedMapper(feed: cache.genericFeed).map()
                    completion(.found(feed: feed, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func fetchCache() throws -> CDCache? {
        let fetchRequest: NSFetchRequest<CDCache> = CDCache.fetchRequest()
        let caches = try managedContext.fetch(fetchRequest)
        return caches.first
    }
    
    private func deleteCaches() throws {
        try coreDataStack.deleteAll(of: CDCache.entityName, context: managedContext)
    }
    
    private func createCache(feed: [LocalFeedImage], timestamp: Date) -> CDCache {
        let cache = CDCache(managedContext: managedContext)
        cache.timestamp = timestamp
        
        for localFeedImage in feed {
            let modelFeedImage = createFeedImage(from: localFeedImage)
            cache.addToFeed(modelFeedImage)
        }
        
        return cache
    }
    
    private func createFeedImage(from localFeedImage: LocalFeedImage) -> CDFeedImage {
        let feedImage = CDFeedImage(managedContext: managedContext)
        feedImage.id = localFeedImage.id
        feedImage.desc = localFeedImage.description
        feedImage.location = localFeedImage.location
        feedImage.url = localFeedImage.url
        return feedImage
    }
    
}
