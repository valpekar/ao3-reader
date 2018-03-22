//
//  DBHighlightItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData


extension DBHighlightItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBHighlightItem> {
        return NSFetchRequest<DBHighlightItem>(entityName: "DBHighlightItem")
    }

    @NSManaged public var workId: String?
    @NSManaged public var author: String?
    @NSManaged public var content: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var workName: String?

}
