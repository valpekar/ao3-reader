//
//  AnalyticsItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/12/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension AnalyticsItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnalyticsItem> {
        return NSFetchRequest<AnalyticsItem>(entityName: "AnalyticsItem");
    }

    @NSManaged public var author: String?
    @NSManaged public var category: String?
    @NSManaged public var character: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var fandom: String?
    @NSManaged public var relationship: String?
    @NSManaged public var tags: String?
    @NSManaged public var tags_excl: String?

}
