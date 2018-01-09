//
//  WorkItem.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 8/26/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation

class WorkItem : NSObject {
    
    var id: Int64 = 0
    var workId = ""
    var ratingTags = ""
    var archiveWarnings = ""
    var freeform = ""
    var category = ""
    var language = ""
    var published = ""
    var updated = ""
    var words = ""
    var chaptersCount = ""
    var kudos = ""
    var hits = ""
    var bookmarks = ""
    var comments = ""
    var workTitle = ""
    var author = ""
    var stats = ""
    var complete = ""
    var workContent = ""
    var nextChapter = ""
    var topic = ""
    var topicPreview = ""
    var tags = ""
    var datetime = ""
    var currentChapter = ""
    var serieUrl = ""
    var serieName = ""
    
    var chapters: NSSet = []
    var relationshipIds: NSSet = []
    var characterIds: NSSet = []
    var fandomIds: NSSet = []
}
