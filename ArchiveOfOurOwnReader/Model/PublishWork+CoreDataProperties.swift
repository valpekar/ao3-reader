//
//  PublishWork+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/22/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData


extension PublishWork {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublishWork> {
        return NSFetchRequest<PublishWork>(entityName: "PublishWork")
    }

    @NSManaged public var pseud_id: String?
    @NSManaged public var title: String?
    @NSManaged public var ratingTags: String?
    @NSManaged public var freeformTags: String?
    @NSManaged public var isPublished: NSNumber?
    @NSManaged public var publishChapters: NSOrderedSet?

}

// MARK: Generated accessors for publishChapters
extension PublishWork {

    @objc(insertObject:inPublishChaptersAtIndex:)
    @NSManaged public func insertIntoPublishChapters(_ value: PublishChapter, at idx: Int)

    @objc(removeObjectFromPublishChaptersAtIndex:)
    @NSManaged public func removeFromPublishChapters(at idx: Int)

    @objc(insertPublishChapters:atIndexes:)
    @NSManaged public func insertIntoPublishChapters(_ values: [PublishChapter], at indexes: NSIndexSet)

    @objc(removePublishChaptersAtIndexes:)
    @NSManaged public func removeFromPublishChapters(at indexes: NSIndexSet)

    @objc(replaceObjectInPublishChaptersAtIndex:withObject:)
    @NSManaged public func replacePublishChapters(at idx: Int, with value: PublishChapter)

    @objc(replacePublishChaptersAtIndexes:withPublishChapters:)
    @NSManaged public func replacePublishChapters(at indexes: NSIndexSet, with values: [PublishChapter])

    @objc(addPublishChaptersObject:)
    @NSManaged public func addToPublishChapters(_ value: PublishChapter)

    @objc(removePublishChaptersObject:)
    @NSManaged public func removeFromPublishChapters(_ value: PublishChapter)

    @objc(addPublishChapters:)
    @NSManaged public func addToPublishChapters(_ values: NSOrderedSet)

    @objc(removePublishChapters:)
    @NSManaged public func removeFromPublishChapters(_ values: NSOrderedSet)

}
