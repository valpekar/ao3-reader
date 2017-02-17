//
//  DBWorkItem.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/13/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation
import CoreData

class DBWorkItem: NSManagedObject {

    @NSManaged var archiveWarnings: String
    @NSManaged var author: String
    @NSManaged var bookmarks: String
    @NSManaged var category: String
    @NSManaged var chaptersCount: String
    @NSManaged var comments: String
    @NSManaged var complete: String
    @NSManaged var currentChapter: NSNumber
    @NSManaged var datetime: String
    @NSManaged var hits: String
    @NSManaged var id: NSNumber
    @NSManaged var kudos: String
    @NSManaged var language: String
    @NSManaged var nextChapter: String
    @NSManaged var published: String
    @NSManaged var ratingTags: String
    @NSManaged var stats: String
    @NSManaged var tags: String
    @NSManaged var topic: String
    @NSManaged var topicPreview: String
    @NSManaged var updatedStr: String
    @NSManaged var words: String
    @NSManaged var workContent: String
    @NSManaged var workId: String
    @NSManaged var workTitle: String
    @NSManaged var scrollProgress: String
    @NSManaged var chapters: NSSet
    @NSManaged var characters: NSSet
    @NSManaged var fandoms: NSSet
    @NSManaged var relationships: NSSet

}
