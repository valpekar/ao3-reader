//
//  Serie+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/10/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData

extension Serie {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Serie> {
        return NSFetchRequest<Serie>(entityName: "Serie")
    }

    @NSManaged public var title: String?
    @NSManaged public var serieId: String?
    @NSManaged public var author: String?
    @NSManaged public var authorlink: String?
    @NSManaged public var serieBegun: String?
    @NSManaged public var serieEnded: String?
    @NSManaged public var desc: String?
    @NSManaged public var works: NSSet?

}

// MARK: Generated accessors for works
extension Serie {

    @objc(addWorksObject:)
    @NSManaged public func addToWorks(_ value: DBWorkItem)

    @objc(removeWorksObject:)
    @NSManaged public func removeFromWorks(_ value: DBWorkItem)

    @objc(addWorks:)
    @NSManaged public func addToWorks(_ values: NSSet)

    @objc(removeWorks:)
    @NSManaged public func removeFromWorks(_ values: NSSet)

}
