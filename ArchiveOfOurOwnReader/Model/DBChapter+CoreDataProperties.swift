//
//  DBChapter+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/12/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

extension DBChapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBChapter> {
        return NSFetchRequest<DBChapter>(entityName: "DBChapter");
    }

    @NSManaged public var chapterContent: String?
    @NSManaged public var chapterIndex: NSNumber?
    @NSManaged public var chapterName: String?
    @NSManaged public var id: NSNumber?
    @NSManaged public var workItem: DBWorkItem?

}
