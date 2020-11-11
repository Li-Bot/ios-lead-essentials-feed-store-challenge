
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
        feed.map { cdFeedImage -> LocalFeedImage in
            LocalFeedImage(id: cdFeedImage.id,
                           description: cdFeedImage.desc,
                           location: cdFeedImage.location,
                           url: cdFeedImage.url
            )
        }
    }
    
}
