//
//  SearchQuery.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 7/21/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit

class SearchQuery : NSObject, NSCoding {
    
    var include_tags = ""
    var exclude_tags = ""
    var tag = ""
    var title = "" 
    var creator = "" 
    var revised_at = "" 
    var complete = "0" 
    var single_chapter = "0" 
    var word_count = "" 
    var fandom_names = ""  /*{didSet{
        NSLog("fandom_names=" + String(fandom_names))
        }}*/
    var language_id = "" 
    var rating_ids = "" 
    var character_names = "" 
    var relationship_names = "" 
    var freeform_names = "" 
    var hits = "" 
    var kudos_count = "" /*{didSet{
        NSLog("kudoscount=" + String(kudos_count))
        }}*/
    var comments_count = "" 
    var bookmarks_count = "" 
    var sort_column = "" 
    var sort_direction = "desc" 
    var warnings = [String]()
    var categories = [String]()
    
  /*  func formQuery1() -> String {
        
        var result:String = String()
        
        result += tag
        result += "&work_search[title]="
        result += title
        result += "&work_search[creator]="
        result += creator
        result += "&work_search[revised_at]="
        result += revised_at
        result += "&work_search[complete]="
        result += complete
        result += "&work_search[single_chapter]="
        result += single_chapter
        result += "&work_search[word_count]="
        result += word_count
        result += "&work_search[language_id]="
        result += language_id
        result += "&work_search[fandom_names]="
        result += fandom_names
        result += "&work_search[rating_ids]="
        result += rating_ids
        
        for warning in warnings {
             result += "&work_search[warning_ids][]=" + warning
        }
        
        for category in categories {
             result += "&work_search[category_ids][]=" + category
        }
        
        result += "&work_search[character_names]="
        result += character_names
        result += "&work_search[relationship_names]="
        result += relationship_names
        result += "&work_search[freeform_names]="
        result += freeform_names
        result += "&work_search[hits]="
        result += hits
        result += "&work_search[kudos_count]="
        result += kudos_count
        result += "&work_search[comments_count]="
        result += comments_count
        result += "&work_search[bookmarks_count]="
        result += bookmarks_count
        result += "&work_search[sort_column]="
        result += sort_column
        result += "&work_search[sort_direction]="
        result += sort_direction
        result += "&commit=Search"
        
        return result
    } */
    
    func isEmpty() -> Bool {
        var res = true
        
        if !single_chapter.isEmpty && single_chapter != "0"  {
            res = false
        }
        
        if !complete.isEmpty && complete != "0" {
            res = false
        }
        
        if(!language_id.isEmpty &&  language_id != "0") {
            res = false
        }
        
        if (!exclude_tags.isEmpty) {
            res = false
        }
        
        let incl = include_tags.replacingOccurrences(of: "-\"Rape\" -\"Underage\"", with: "")
        if (!incl.isEmpty) {
            res = false
        }
        
        if (!creator.isEmpty) {
            res = false
        }
        
        if (!title.isEmpty) {
            res = false
        }
        
        if (!revised_at.isEmpty) {
            res = false
        }
        
        if (!word_count.isEmpty) {
            res = false
        }
        
        if (!fandom_names.isEmpty) {
            res = false
        }
        
        if (!rating_ids.isEmpty) {
            res = false
        }
        
        if (!warnings.isEmpty) {
            res = false
        }
        
        if (!categories.isEmpty) {
            res = false
        }
        
        if (!character_names.isEmpty) {
            res = false
        }
        
        if (!relationship_names.isEmpty) {
            res = false
        }
        
        if (!freeform_names.isEmpty) {
            res = false
        }
        
        if (!hits.isEmpty) {
            res = false
        }
        
        if (!kudos_count.isEmpty) {
            res = false
        }
        
        if (!comments_count.isEmpty) {
            res = false
        }
        
        if (!bookmarks_count.isEmpty) {
            res = false
        }
        
        return res
    }
    
    func formQuery() -> [String:AnyObject]{
        var params:[String:Any] = [String:Any]()
        
        if single_chapter.isEmpty {
            single_chapter = "0"
        }
        if complete.isEmpty {
            complete = "0"
        }
        if(language_id == "0") {
            language_id = ""
        }
        
        var tagStr: String = ""
        var excludeTags: [String] = exclude_tags.components(separatedBy:  ",").map { String($0) }
        for i in 0..<excludeTags.count {
            tagStr += "-\"" + excludeTags[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + "\""
            if (i < excludeTags.count - 1) {
                tagStr += " "
            }
        }
        
        if (tagStr.count > 0) {
            tagStr += " "
        }
        
 //       var safe = true
//        if let s = DefaultsManager.getBool(DefaultsManager.SAFE) {
//            safe = s
//        }
//        if (safe == true) {
            tagStr += "-\"Rape\" "
            tagStr += "-\"Underage\" "
 //       }
        
        var includeTags: [String] = include_tags.characters.split {$0 == ","}.map { String($0) }
        for i in 0..<includeTags.count {
            tagStr += "\"" + includeTags[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) + "\""
            if (i < includeTags.count - 1) {
                tagStr += " "
            }
        }
        
        /*var fandomStr: String = ""
        var fandomTags: [String] = fandom_names.characters.split {$0 == ","}.map { String($0) }
        for i in 0..<fandomTags.count {
            fandomStr += fandomTags[i].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if (i < includeTags.count - 1) {
                fandomStr += " && "
            }
        }*/
        
        if (tagStr.count > 0) {
            tagStr += " "
        }
        tagStr += tag
        
        params["utf8"] = "✓" as AnyObject?//"%E2%9C%93"//"✓"
        
        params["work_search"] = ["query": tagStr,
        "title": title,
        "creator": creator,
        "revised_at": revised_at,
        "complete": complete,
        "single_chapter": single_chapter,
        "word_count": word_count,
        "language_id": language_id,
        "fandom_names": fandom_names,
        "rating_ids": rating_ids,
        "warning_ids": warnings,
        "category_ids": categories,
        "character_names": character_names,
        "relationship_names": relationship_names,
        "freeform_names": freeform_names,
        "hits": hits,
        "kudos_count": kudos_count,
        "comments_count": comments_count,
        "bookmarks_count": bookmarks_count,
        "sort_column": sort_column,
        "sort_direction": sort_direction]
        
        params["commit"] = "Search" as AnyObject?
        
        return params as [String : AnyObject]
    }
    
    /*func formQuery2() -> [String:AnyObject]{
        var params:[String:AnyObject] = [String:AnyObject]()
        
        params["utf8"] = "✓" as AnyObject?
        params["work_search[query]"] = tag as AnyObject?
        params["work_search[title]"] = title as AnyObject?
        params["work_search[creator]"] = creator as AnyObject?
        params["work_search[revised_at]"] = revised_at as AnyObject?
        params["work_search[complete]"] = complete as AnyObject?
        params["work_search[single_chapter]"] = single_chapter as AnyObject?
        params["work_search[word_count]"] = word_count as AnyObject?
        params["work_search[language_id]"] = language_id as AnyObject?
        params["work_search[fandom_names]"] = fandom_names as AnyObject?
        params["work_search[rating_ids]"] = rating_ids as AnyObject?
        params["work_search[warning_ids]"] = warnings as AnyObject?
        params["work_search[category_ids]"] = categories as AnyObject?
        params["work_search[character_names]"] = character_names as AnyObject?
        params["work_search[relationship_names]"] = relationship_names as AnyObject?
        params["work_search[freeform_names]"] = freeform_names as AnyObject?
        params["work_search[hits]"] = hits as AnyObject?
        params["work_search[kudos_count]"] = kudos_count as AnyObject?
        params["work_search[comments_count]"] = comments_count as AnyObject?
        params["work_search[bookmarks_count]"] = bookmarks_count as AnyObject?
        params["work_search[sort_column]"] = sort_column as AnyObject?
        params["work_search[sort_direction]"] = sort_direction as AnyObject?
        params["commit"] = "Search" as AnyObject?
        
        return params
    }*/
    
    //https://archiveofourown.org/works/search?utf8=%E2%9C%93&work_search[query]=cheese&work_search[title]=&work_search[creator]=&work_search[revised_at]=&work_search[complete]=0&work_search[single_chapter]=0&work_search[word_count]=&work_search[language_id]=&work_search[fandom_names]=&work_search[rating_ids]=&work_search[warning_ids][]=14&work_search[warning_ids][]=18&work_search[warning_ids][]=19&work_search[character_names]=&work_search[relationship_names]=&work_search[freeform_names]=&work_search[hits]=&work_search[kudos_count]=&work_search[comments_count]=&work_search[bookmarks_count]=&work_search[sort_column]=&work_search[sort_direction]=&commit=Search
   
    // MARK: NSCoding
    
    @objc required convenience init?(coder decoder: NSCoder) {
        
        self.init()
        
        self.include_tags = (decoder.decodeObject(forKey: "include_tags") as? String)!
        self.exclude_tags = (decoder.decodeObject(forKey: "exclude_tags") as? String)!
        self.tag = (decoder.decodeObject(forKey: "tag") as? String)!
        self.title = (decoder.decodeObject(forKey: "title") as? String)!
        self.creator = (decoder.decodeObject(forKey: "creator") as? String)!
        self.revised_at = (decoder.decodeObject(forKey: "revised_at") as? String)!
        self.complete = (decoder.decodeObject(forKey: "complete") as? String)!
        self.single_chapter = (decoder.decodeObject(forKey: "single_chapter") as? String)!
        self.word_count = (decoder.decodeObject(forKey: "word_count") as? String)!
        self.fandom_names = (decoder.decodeObject(forKey: "fandom_names") as? String)!
        self.language_id = (decoder.decodeObject(forKey: "language_id") as? String)!
        self.rating_ids = (decoder.decodeObject(forKey: "rating_ids") as? String)!
        self.character_names = (decoder.decodeObject(forKey: "character_names") as? String)!
        self.relationship_names = (decoder.decodeObject(forKey: "relationship_names") as? String)!
        self.freeform_names = (decoder.decodeObject(forKey: "freeform_names") as? String)!
        self.hits = (decoder.decodeObject(forKey: "hits") as? String)!
        self.kudos_count = (decoder.decodeObject(forKey: "kudos_count") as? String)!
        self.comments_count = (decoder.decodeObject(forKey: "comments_count") as? String)!
        self.bookmarks_count = (decoder.decodeObject(forKey: "bookmarks_count") as? String)!
        self.sort_column = (decoder.decodeObject(forKey: "sort_column") as? String)!
        self.sort_direction = (decoder.decodeObject(forKey: "sort_direction") as? String)!
        self.warnings = (decoder.decodeObject(forKey: "warnings") as? [String])!
        self.categories = (decoder.decodeObject(forKey: "categories") as? [String])!
        
    }
    
    @objc func encode(with coder: NSCoder) {
        coder.encode(self.include_tags, forKey: "include_tags")
        coder.encode(self.exclude_tags, forKey: "exclude_tags")
        coder.encode(self.tag, forKey: "tag")
        coder.encode(self.title, forKey: "title")
        coder.encode(self.creator, forKey: "creator")
        coder.encode(self.revised_at, forKey: "revised_at")
        coder.encode(self.complete, forKey: "complete")
        coder.encode(self.single_chapter, forKey: "single_chapter")
        coder.encode(self.word_count, forKey: "word_count")
        coder.encode(self.fandom_names, forKey: "fandom_names")
        coder.encode(self.language_id, forKey: "language_id")
        coder.encode(self.rating_ids, forKey: "rating_ids")
        coder.encode(self.character_names, forKey: "character_names")
        coder.encode(self.relationship_names, forKey: "relationship_names")
        coder.encode(self.freeform_names, forKey: "freeform_names")
        coder.encode(self.hits, forKey: "hits")
        coder.encode(self.kudos_count, forKey: "kudos_count")
        coder.encode(self.comments_count, forKey: "comments_count")
        coder.encode(self.bookmarks_count, forKey: "bookmarks_count")
        coder.encode(self.sort_column, forKey: "sort_column")
        coder.encode(self.sort_direction, forKey: "sort_direction")
        coder.encode(self.warnings, forKey: "warnings")
        coder.encode(self.categories, forKey: "categories")
    }
}
