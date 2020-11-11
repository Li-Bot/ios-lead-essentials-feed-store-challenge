//
//  CDCache+CoreDataProperties.swift
//  Tests
//
//  Created by Libor Polehna on 10/11/2020.
//  Copyright © 2020 Essential Developer. All rights reserved.
//
//

import Foundation
import CoreData


extension CDCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCache> {
        return NSFetchRequest<CDCache>(entityName: "CDCache")
    }

    @NSManaged public var timestamp: Date
    @NSManaged public var feed: Set<CDFeedImage>

}

// MARK: Generated accessors for feed
extension CDCache {

    @objc(addFeedObject:)
    @NSManaged public func addToFeed(_ value: CDFeedImage)

    @objc(removeFeedObject:)
    @NSManaged public func removeFromFeed(_ value: CDFeedImage)

    @objc(addFeed:)
    @NSManaged public func addToFeed(_ values: NSSet)

    @objc(removeFeed:)
    @NSManaged public func removeFromFeed(_ values: NSSet)

}

extension CDCache : Identifiable {

}
