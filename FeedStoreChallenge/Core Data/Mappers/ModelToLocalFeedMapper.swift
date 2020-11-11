
import Foundation


internal final class ModelToLocalFeedMapper {
    
    private let feed: Set<CDFeedImage>
    
    init(feed: Set<CDFeedImage>) {
        self.feed = feed
    }
    
    func map() -> [LocalFeedImage] {
        mapModelsToLocals(sort(feed))
    }
    
    private func sort(_ feed: Set<CDFeedImage>) -> [CDFeedImage] {
        feed.sorted { (firstFeedImage, secondFeedImage) -> Bool in
            firstFeedImage.position < secondFeedImage.position
        }
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
