
import Foundation


internal final class ModelToLocalFeedMapper {
    
    private let feed: [CDFeedImage]
    
    init(feed: [CDFeedImage]) {
        self.feed = feed
    }
    
    func map() -> [LocalFeedImage] {
        mapModelsToLocals(feed)
    }
    
    private func mapModelsToLocals(_ feed: [CDFeedImage]) -> [LocalFeedImage] {
        feed.map { feedImage -> LocalFeedImage in
            LocalFeedImage(id: feedImage.id,
                           description: feedImage.desc,
                           location: feedImage.location,
                           url: feedImage.url
            )
        }
    }
    
}
