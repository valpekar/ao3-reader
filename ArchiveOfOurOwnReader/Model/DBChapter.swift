//
//  DBChapter.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/2/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

class DBChapter: NSManagedObject {

    @NSManaged var chapterContent: String
    @NSManaged var chapterIndex: NSNumber
    @NSManaged var id: NSNumber
    @NSManaged var workItem: DBWorkItem

}
