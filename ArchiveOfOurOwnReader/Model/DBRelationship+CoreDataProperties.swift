//
//  DBRelationship+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/5/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

extension DBRelationship {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBRelationship> {
        return NSFetchRequest<DBRelationship>(entityName: "DBRelationship");
    }

    @NSManaged public var id: NSNumber?
    @NSManaged public var relationshipName: String?
    @NSManaged public var relationshipUrl: String?
    @NSManaged public var workItems: NSSet?

}

// MARK: Generated accessors for workItems
extension DBRelationship {

    @objc(addWorkItemsObject:)
    @NSManaged public func addToWorkItems(_ value: DBWorkItem)

    @objc(removeWorkItemsObject:)
    @NSManaged public func removeFromWorkItems(_ value: DBWorkItem)

    @objc(addWorkItems:)
    @NSManaged public func addToWorkItems(_ values: NSSet)

    @objc(removeWorkItems:)
    @NSManaged public func removeFromWorkItems(_ values: NSSet)

}
