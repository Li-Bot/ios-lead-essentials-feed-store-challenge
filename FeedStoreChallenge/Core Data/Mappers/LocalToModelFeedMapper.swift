
import Foundation
import CoreData


internal final class LocalToModelFeedMapper {
    
    private let feed: [LocalFeedImage]
    private let cache: CDCache
    private let context: NSManagedObjectContext
    
    init(feed: [LocalFeedImage], cache: CDCache, context: NSManagedObjectContext) {
        self.feed = feed
        self.cache = cache
        self.context = context
    }
    
    @discardableResult
    func map() -> [CDFeedImage] {
        var modelFeed = [CDFeedImage]()
        for (index, feedImage) in feed.enumerated() {
            let cdFeedImage = createFeedImage(from: feedImage, position: index)
            cache.addToFeed(cdFeedImage)
            modelFeed.append(cdFeedImage)
        }
        return modelFeed
    }
    
    private func createFeedImage(from localFeedImage: LocalFeedImage, position: Int) -> CDFeedImage {
        let feedImage = CDFeedImage(managedContext: context)
        feedImage.id = localFeedImage.id
        feedImage.desc = localFeedImage.description
        feedImage.location = localFeedImage.location
        feedImage.url = localFeedImage.url
        feedImage.position = Int16(position)
        return feedImage
    }
    
}
