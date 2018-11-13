//
//  DBFavAuthor+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 11/13/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData


extension DBFavAuthor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBFavAuthor> {
        return NSFetchRequest<DBFavAuthor>(entityName: "DBFavAuthor")
    }

    @NSManaged public var name: String?
    @NSManaged public var authorId: String?
    @NSManaged public var priority: NSNumber?

}
