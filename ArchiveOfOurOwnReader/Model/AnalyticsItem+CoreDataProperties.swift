//
//  AnalyticsItem+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/11/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AnalyticsItem {

    @NSManaged var character: String?
    @NSManaged var fandom: String?
    @NSManaged var relationship: String?
    @NSManaged var author: String?
    @NSManaged var category: String?
    @NSManaged var tags: String?
    @NSManaged var tags_excl: String?

}
