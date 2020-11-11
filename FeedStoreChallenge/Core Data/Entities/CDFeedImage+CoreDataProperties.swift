
import Foundation
import CoreData


extension CDFeedImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFeedImage> {
        return NSFetchRequest<CDFeedImage>(entityName: "CDFeedImage")
    }

    @NSManaged public var id: UUID
    @NSManaged public var desc: String?
    @NSManaged public var location: String?
    @NSManaged public var url: URL
    @NSManaged public var position: Int16

}

extension CDFeedImage : Identifiable {

}
