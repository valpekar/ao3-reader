//
//  DBRelationship.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/2/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

class DBRelationship: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var relationshipName: String
    @NSManaged var relationshipUrl: String
    @NSManaged var workItems: NSSet

}
