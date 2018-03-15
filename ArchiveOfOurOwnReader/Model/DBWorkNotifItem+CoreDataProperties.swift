//
//  DBWorkNotifItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/15/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData


extension DBWorkNotifItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBWorkNotifItem> {
        return NSFetchRequest<DBWorkNotifItem>(entityName: "DBWorkNotifItem")
    }

    @NSManaged public var workId: String?
    @NSManaged public var isItemDeleted: NSNumber?

}
