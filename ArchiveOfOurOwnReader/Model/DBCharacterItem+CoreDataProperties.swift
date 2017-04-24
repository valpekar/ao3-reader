//
//  DBCharacterItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/5/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

extension DBCharacterItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBCharacterItem> {
        return NSFetchRequest<DBCharacterItem>(entityName: "DBCharacterItem");
    }

    @NSManaged public var characterName: String?
    @NSManaged public var characterUrl: String?
    @NSManaged public var id: NSNumber?
    @NSManaged public var workItems: NSSet?

}

// MARK: Generated accessors for workItems
extension DBCharacterItem {

    @objc(addWorkItemsObject:)
    @NSManaged public func addToWorkItems(_ value: DBWorkItem)

    @objc(removeWorkItemsObject:)
    @NSManaged public func removeFromWorkItems(_ value: DBWorkItem)

    @objc(addWorkItems:)
    @NSManaged public func addToWorkItems(_ values: NSSet)

    @objc(removeWorkItems:)
    @NSManaged public func removeFromWorkItems(_ values: NSSet)

}
