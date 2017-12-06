//
//  DBWorkItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 12/6/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData
import ArchiveOfOurOwnReader

extension DBWorkItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBWorkItem> {
        return NSFetchRequest<DBWorkItem>(entityName: "DBWorkItem")
    }

    @NSManaged public var archiveWarnings: String?
    @NSManaged public var author: String?
    @NSManaged public var bookmarks: String?
    @NSManaged public var category: String?
    @NSManaged public var chaptersCount: String?
    @NSManaged public var comments: String?
    @NSManaged public var complete: String?
    @NSManaged public var currentChapter: NSNumber?
    @NSManaged public var dateAdded: NSDate?
    @NSManaged public var datetime: String?
    @NSManaged public var hits: String?
    @NSManaged public var id: NSNumber?
    @NSManaged public var kudos: String?
    @NSManaged public var language: String?
    @NSManaged public var nextChapter: String?
    @NSManaged public var published: String?
    @NSManaged public var ratingTags: String?
    @NSManaged public var scrollProgress: String?
    @NSManaged public var stats: String?
    @NSManaged public var tags: String?
    @NSManaged public var topic: String?
    @NSManaged public var topicPreview: String?
    @NSManaged public var updatedStr: String?
    @NSManaged public var words: String?
    @NSManaged public var workContent: String?
    @NSManaged public var workId: String?
    @NSManaged public var workTitle: String?
    @NSManaged public var serieName: String?
    @NSManaged public var serieUrl: String?
    @NSManaged public var chapters: NSSet?
    @NSManaged public var characters: NSSet?
    @NSManaged public var fandoms: NSSet?
    @NSManaged public var folder: Folder?
    @NSManaged public var relationships: NSSet?
    @NSManaged public var series: Serie?

}

// MARK: Generated accessors for chapters
extension DBWorkItem {

    @objc(addChaptersObject:)
    @NSManaged public func addToChapters(_ value: DBChapter)

    @objc(removeChaptersObject:)
    @NSManaged public func removeFromChapters(_ value: DBChapter)

    @objc(addChapters:)
    @NSManaged public func addToChapters(_ values: NSSet)

    @objc(removeChapters:)
    @NSManaged public func removeFromChapters(_ values: NSSet)

}

// MARK: Generated accessors for characters
extension DBWorkItem {

    @objc(addCharactersObject:)
    @NSManaged public func addToCharacters(_ value: DBCharacterItem)

    @objc(removeCharactersObject:)
    @NSManaged public func removeFromCharacters(_ value: DBCharacterItem)

    @objc(addCharacters:)
    @NSManaged public func addToCharacters(_ values: NSSet)

    @objc(removeCharacters:)
    @NSManaged public func removeFromCharacters(_ values: NSSet)

}

// MARK: Generated accessors for fandoms
extension DBWorkItem {

    @objc(addFandomsObject:)
    @NSManaged public func addToFandoms(_ value: DBFandom)

    @objc(removeFandomsObject:)
    @NSManaged public func removeFromFandoms(_ value: DBFandom)

    @objc(addFandoms:)
    @NSManaged public func addToFandoms(_ values: NSSet)

    @objc(removeFandoms:)
    @NSManaged public func removeFromFandoms(_ values: NSSet)

}

// MARK: Generated accessors for relationships
extension DBWorkItem {

    @objc(addRelationshipsObject:)
    @NSManaged public func addToRelationships(_ value: DBRelationship)

    @objc(removeRelationshipsObject:)
    @NSManaged public func removeFromRelationships(_ value: DBRelationship)

    @objc(addRelationships:)
    @NSManaged public func addToRelationships(_ values: NSSet)

    @objc(removeRelationships:)
    @NSManaged public func removeFromRelationships(_ values: NSSet)

}
