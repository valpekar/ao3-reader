//
//  HistoryItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 7/12/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData


extension HistoryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HistoryItem> {
        return NSFetchRequest<HistoryItem>(entityName: "HistoryItem")
    }

    @NSManaged public var lastChapter: String?
    @NSManaged public var scrollProgress: String?
    @NSManaged public var timeStamp: NSDate?
    @NSManaged public var workId: String?
    @NSManaged public var lastChapterIdx: NSNumber?

}
