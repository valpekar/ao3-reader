//
//  PublishChapter+CoreDataProperties.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/22/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//
//

import Foundation
import CoreData


extension PublishChapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublishChapter> {
        return NSFetchRequest<PublishChapter>(entityName: "PublishChapter")
    }

    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var publishWork: PublishWork?

}
