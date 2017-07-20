//
//  Folder+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 7/20/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData
import ArchiveOfOurOwnReader

extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var name: String?
    @NSManaged public var works: NSSet?

}

// MARK: Generated accessors for works
extension Folder {

    @objc(addWorksObject:)
    @NSManaged public func addToWorks(_ value: DBWorkItem)

    @objc(removeWorksObject:)
    @NSManaged public func removeFromWorks(_ value: DBWorkItem)

    @objc(addWorks:)
    @NSManaged public func addToWorks(_ values: NSSet)

    @objc(removeWorks:)
    @NSManaged public func removeFromWorks(_ values: NSSet)

}
