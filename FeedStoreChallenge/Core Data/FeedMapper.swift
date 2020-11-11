
import Foundation


internal final class FeedMapper {
    
    private let feed: Set<CDFeedImage>
    
    init(feed: Set<CDFeedImage>) {
        self.feed = feed
    }
    
    func map() -> [LocalFeedImage] {
        mapLocalsToModels(sort(feed))
    }
    
    private func sort(_ feed: Set<CDFeedImage>) -> [CDFeedImage] {
        feed.sorted { (firstFeedImage, secondFeedImage) -> Bool in
            firstFeedImage.position < secondFeedImage.position
        }
    }
    
    private func mapLocalsToModels(_ feed: [CDFeedImage]) -> [LocalFeedImage] {
        feed.map { cdFeedImage -> LocalFeedImage in
            LocalFeedImage(id: cdFeedImage.id,
                           description: cdFeedImage.desc,
                           location: cdFeedImage.location,
                           url: cdFeedImage.url
            )
        }
    }
    
}
