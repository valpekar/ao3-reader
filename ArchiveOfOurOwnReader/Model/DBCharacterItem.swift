//
//  DBCharacterItem.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/2/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

class DBCharacterItem: NSManagedObject {

    @NSManaged var characterName: String
    @NSManaged var characterUrl: String
    @NSManaged var id: NSNumber
    @NSManaged var workItems: NSSet

}
