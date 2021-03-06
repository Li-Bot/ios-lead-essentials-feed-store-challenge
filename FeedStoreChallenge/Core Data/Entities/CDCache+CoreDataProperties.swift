
import Foundation
import CoreData


extension CDCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCache> {
        return NSFetchRequest<CDCache>(entityName: "CDCache")
    }

    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
    
    var genericFeed: [CDFeedImage] {
        feed.array as! [CDFeedImage]
    }

}

// MARK: Generated accessors for feed
extension CDCache {

    @objc(addFeedObject:)
    @NSManaged public func addToFeed(_ value: CDFeedImage)

    @objc(removeFeedObject:)
    @NSManaged public func removeFromFeed(_ value: CDFeedImage)

    @objc(addFeed:)
    @NSManaged public func addToFeed(_ values: NSOrderedSet)

    @objc(removeFeed:)
    @NSManaged public func removeFromFeed(_ values: NSOrderedSet)

}

extension CDCache : Identifiable {

}
