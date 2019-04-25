//
//  WorksParser.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 8/8/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation


class WorksParser {
    
    class func parseWorks(_ data: Data, itemsCountHeading: String, worksElement: String, liWorksElement: String? = "", downloadedCheckItems: [CheckDownloadItem]? = nil) -> ([PageItem], [NewsFeedItem], String) {
        var pages : [PageItem] = [PageItem]()
        var works : [NewsFeedItem] = [NewsFeedItem]()
        var worksCountStr = ""
        
        guard let _ = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return (pages, works, worksCountStr)
        }
       /* #if DEBUG
            print(dta)
        #endif*/
        guard let doc : TFHpple = TFHpple(htmlData: data) else {
            return (pages, works, worksCountStr)
        }
        
        var liEl = worksElement
        if let l = liWorksElement {
            if (l.isEmpty == false) {
                liEl = l
            }
        }
        
        var olLiteral = "ol"
        
        if (worksElement == "series" && liWorksElement == "series") {
            olLiteral = "ul"
        }
        
        if let itemsCount: [TFHppleElement] = doc.search(withXPathQuery: "//\(itemsCountHeading)[@class='heading']") as? [TFHppleElement] {
            if (itemsCount.count > 0) {
                worksCountStr = itemsCount[0].content.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines
                )
                worksCountStr = worksCountStr.replacingOccurrences(of: "?", with: "")
//                if let idx = worksCountStr.index(of: "d") {
//                    worksCountStr = String(worksCountStr[..<worksCountStr.index(after: idx)])
//                }
            }
        }
        if let workGroup = doc.search(withXPathQuery: "//\(olLiteral)[@class='\(worksElement) index group']") as? [TFHppleElement] {
            if (workGroup.count > 0) {
                
                var worksList : [TFHppleElement]? = nil
                if let wList = workGroup[0].search(withXPathQuery: "//li[@class='\(liEl) blurb group']") as? [TFHppleElement],
                    wList.count > 0 {
                    worksList = wList
                } else if let ownList = workGroup[0].search(withXPathQuery: "//li[@class='own \(liEl) blurb group']") as? [TFHppleElement],
                    ownList.count > 0 {
                    worksList = ownList
                }
                if let worksList : [TFHppleElement] = worksList {
                
                    //sometimes they have extra space " " after group ("group ") >.<
                    if (worksList.count == 0) {
                        if let newList: [TFHppleElement] = workGroup[0].search(withXPathQuery: "//li[@class='\(liEl) blurb group ']") as? [TFHppleElement] {
                           
                            for workListItem in newList {
                                autoreleasepool { [unowned workListItem] in
                                    
                                    let item: NewsFeedItem = parseWorkItem(workListItem: workListItem, downloadedCheckItems:  downloadedCheckItems)
                                    works.append(item)
                                }
                            }
                        }
                    } else {
                    
                        for workListItem in worksList {
                            autoreleasepool { [unowned workListItem] in
                            
                                let item: NewsFeedItem = parseWorkItem(workListItem: workListItem, downloadedCheckItems:  downloadedCheckItems)
                                works.append(item)
                            }
                        }
                    }
                    
                    //parse pages
                    if let paginationActions: [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='pagination actions']") as? [TFHppleElement] {
                        if((paginationActions.count) > 0) {
                            guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") as? [TFHppleElement] else {
                                return (pages, works, worksCountStr)
                            }
                            
                            pages = parsePages(paginationArr: paginationArr)
                        }
                    }
                }
            }
        } else {
            worksCountStr = Localization("0Found")
        }
        
        return (pages, works, worksCountStr)
    }
    
    class func parseSerie(_ data: Data, downloadedCheckItems: [CheckDownloadItem]? = nil) -> ([PageItem], [NewsFeedItem], SerieItem) {
        var pages : [PageItem] = [PageItem]()
        var works : [NewsFeedItem] = [NewsFeedItem]()
        var serieItem: SerieItem = SerieItem()
        
        guard let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return (pages, works, serieItem)
        }
        #if DEBUG
            print(dta)
        #endif
        guard let doc : TFHpple = TFHpple(htmlData: data) else {
            return (pages, works, serieItem)
        }
        
        if let itemsCount: [TFHppleElement] = doc.search(withXPathQuery: "//h2[@class='heading']") as? [TFHppleElement] {
            if (itemsCount.count > 0) {
                serieItem.title = itemsCount[0].content.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines)
            }
        }
        
        if let subscribeEls = doc.search(withXPathQuery: "//form[@class='ajax-create-destroy']") as? [TFHppleElement] {
            if (subscribeEls.count > 0) {
                if let attributes : NSDictionary = subscribeEls[0].attributes as NSDictionary?  {
                    let subscAction = (attributes["action"] as? String ?? "")
                    serieItem.subscribeActionUrl = subscAction
                }
                if let inputTokenEls = subscribeEls[0].search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement],
                    inputTokenEls.count > 0 {
                    if let attrs : NSDictionary = inputTokenEls[0].attributes as NSDictionary?  {
                        serieItem.subscribeAuthToken = (attrs["value"] as? String ?? "")
                    }
                }
                
                if let inputTokenElsSId = subscribeEls[0].search(withXPathQuery: "//input[@id='subscription_subscribable_id']") as? [TFHppleElement],
                    inputTokenElsSId.count > 0 {
                    if let attrs : NSDictionary = inputTokenElsSId[0].attributes as NSDictionary?  {
                        serieItem.subscribableId = (attrs["value"] as? String ?? "")
                    }
                }
                
                if let inputTokenElsSType = subscribeEls[0].search(withXPathQuery: "//input[@id='subscription_subscribable_type']") as? [TFHppleElement],
                    inputTokenElsSType.count > 0 {
                    if let attrs : NSDictionary = inputTokenElsSType[0].attributes as NSDictionary?  {
                        serieItem.subscribableType = (attrs["value"] as? String ?? "")
                    }
                }
                
                if let inputTokenElsSubmtType = subscribeEls[0].search(withXPathQuery: "//input[@type='submit']") as? [TFHppleElement],
                    inputTokenElsSubmtType.count > 0 {
                    if let attrs : NSDictionary = inputTokenElsSubmtType[0].attributes as NSDictionary?  {
                        let val = (attrs["value"] as? String ?? "")
                        if (val.contains("Unsubscribe")) {
                            serieItem.subscribed = true
                        }
                    }
                }
            }
        }
        
        if let seriesMeta: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='series meta group']//dd") as? [TFHppleElement],
            let seriesMetaDt: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='series meta group']//dt") as? [TFHppleElement] {
            if (seriesMeta.count > 0) {
                serieItem.author = seriesMeta[0].content.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines)
                
                if (seriesMeta.count > 1) {
                    serieItem.serieBegun = seriesMeta[1].content.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines)
                }
                
                if (seriesMeta.count > 2) {
                    serieItem.serieUpdated = seriesMeta[2].content.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines)
                }
                
                if (seriesMeta.count > 3 && seriesMetaDt.count > 3) {
                    if (seriesMetaDt[3].content.contains("Description")) {
                        serieItem.desc = seriesMeta[3].content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                }
                
                if (seriesMeta.count > 4 && seriesMetaDt.count > 4) { //beacuse stats item is number 4
                    if (seriesMetaDt[4].content.contains("Notes")) {
                        serieItem.notes = seriesMeta[4].content.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines)
                    }
                }
                
                if (seriesMeta.count > 5 && seriesMetaDt.count > 5) { //beacuse stats item is number 4
                    if (seriesMetaDt[5].content.contains("Notes")) {
                        serieItem.notes = seriesMeta[5].content.trimmingCharacters(
                            in: CharacterSet.whitespacesAndNewlines)
                    }
                }
            }
        }
        
        if let seriesStats: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='series meta group']//dd[@class='stats']") as? [TFHppleElement] {
            if (seriesStats.count > 0) {
                let txt: String = seriesStats[0].content.replacingOccurrences(of: "\n  ", with: "")
                serieItem.stats = txt.trimmingCharacters(
                    in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            }
        }
        
        if let workGroup = doc.search(withXPathQuery: "//ul[@class='series work index group']") as? [TFHppleElement] {
            if (workGroup.count > 0) {
                
                var worksList : [TFHppleElement]? = nil
                if let wList = workGroup[0].search(withXPathQuery: "//li[@class='work blurb group']") as? [TFHppleElement],
                    wList.count > 0 {
                    worksList = wList
                } else if let ownList = workGroup[0].search(withXPathQuery: "//li[@class='own work blurb group']") as? [TFHppleElement],
                    ownList.count > 0 {
                    worksList = ownList
                }
                if let worksList : [TFHppleElement] = worksList {
                    
                    for workListItem in worksList {
                        
                        autoreleasepool { [unowned workListItem] in
                            
                            let item: NewsFeedItem = parseWorkItem(workListItem: workListItem, downloadedCheckItems: downloadedCheckItems)
                            works.append(item)
                        }
                    }
                    
                    if let paginationActions: [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='pagination actions']") as? [TFHppleElement] {
                        if((paginationActions.count) > 0) {
                            guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") as? [TFHppleElement] else {
                                return (pages, works, serieItem)
                            }
                            pages = parsePages(paginationArr: paginationArr)
                        }
                    }
                }
            }
        }
        
        return (pages, works, serieItem)
    }
    
    class func parseWorkItem(workListItem: TFHppleElement, downloadedCheckItems: [CheckDownloadItem]? = nil) -> NewsFeedItem {
        var item : NewsFeedItem = NewsFeedItem()
        
        if let header : [TFHppleElement] = workListItem.search(withXPathQuery: "//div[@class='header module']") as? [TFHppleElement] {
            
            if (header.count > 0) {
                if let topicEl: [TFHppleElement] = header[0].search(withXPathQuery: "//h4[@class='heading']") as? [TFHppleElement] {
                    if (topicEl.count > 0) {
                        let topic : TFHppleElement? = topicEl[0]
                        if let titleEl = topic?.search(withXPathQuery: "//a") as? [TFHppleElement],
                            titleEl.count > 0 {
                            
                            item.topic = titleEl[0].content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                            item.title = item.topic
                            
                        }
                        
                        item.author = ""
                        if let authorEl = topic?.search(withXPathQuery: "//a[@rel='author']") as? [TFHppleElement],
                            authorEl.count > 0 {
                            for i in 0..<authorEl.count {
                                item.author += authorEl[i].content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                                if (i < authorEl.count - 1) {
                                    item.author += ", "
                                }
                            }
                        }
                        
                       // item.topic = topic?.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                       //     .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil) ?? ""
                    }
                }
            }
        }
        
        var stats : TFHppleElement? = nil
        let statsEl: [TFHppleElement]? = workListItem.search(withXPathQuery: "//dl[@class='stats']") as? [TFHppleElement]
        if (statsEl?.count ?? 0 > 0) {
            stats = statsEl?[0]
        }
        
        if let userstuffArr = workListItem.search(withXPathQuery: "//blockquote[@class='userstuff summary']/p"), userstuffArr.count > 0  {
                if let userstuff : TFHppleElement = userstuffArr[0] as? TFHppleElement {
                    var isBanner = false
                    if (userstuff.attributes?.count ?? 0 > 0) {
                        if (userstuff.attributes["id"] as? String ?? "" == "admin-banner") {
                            isBanner = true
                        }
                    }
                    if (isBanner == false) {
                        item.topicPreview = userstuff.content
                    } else {
                        if userstuffArr.count > 1,
                            let userstuff1 : TFHppleElement = userstuffArr[1] as? TFHppleElement {
                            item.topicPreview = userstuff1.content
                        }
                    }
                }
        }
        
        if let seriesNum: [TFHppleElement] = workListItem.search(withXPathQuery: "//ul[@class='series']") as? [TFHppleElement] {
            if (seriesNum.count > 0) {
                let sNum: String = seriesNum[0].content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                item.topicPreview = "\(sNum) \n\n\(item.topicPreview)"
            }
        }
        
        if let fandomsArr = workListItem.search(withXPathQuery: "//h5[@class='fandoms heading']") {
            if(fandomsArr.count > 0) {
                if let fandoms  = fandomsArr[0] as? TFHppleElement {
                    item.fandoms = fandoms.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                    item.fandoms = item.fandoms.replacingOccurrences(of: "Fandoms:", with: "")
                }
            }
        }
        
        if let tagsUl : [TFHppleElement] = workListItem.search(withXPathQuery: "//ul[@class='tags commas']/li") as? [TFHppleElement] {
            for tagUl in tagsUl {
                if var tagStr = tagUl.content {
                    if (tagStr.contains("Underage")) {
                        tagStr = tagStr.replacingOccurrences(of: "Underage", with: "Archive Warnings")
                    }
                    if (tagStr.contains("Rape")) {
                        tagStr = tagStr.replacingOccurrences(of: "Rape", with: "Warning: Violence")
                    }
                    item.tags.append(tagStr)
                }
            }
        }
        
        if let dateTimeVar = workListItem.search(withXPathQuery: "//p[@class='datetime']") {
            if(dateTimeVar.count > 0) {
                item.dateTime = (dateTimeVar[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        //parse stats
        if let langVar = stats?.search(withXPathQuery: "//dd[@class='language']") {
            if(langVar.count > 0) {
                item.language = (langVar[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        if let wordsVar = stats?.search(withXPathQuery: "//dd[@class='words']") {
            if(wordsVar.count > 0) {
                if let wordsNum: TFHppleElement = wordsVar[0] as? TFHppleElement {
                    if (wordsNum.text() != nil) {
                        item.words = wordsNum.text()
                    }
                }
            }
        }
        
        if let chaptersVar = stats?.search(withXPathQuery: "//dd[@class='chapters']") {
            if(chaptersVar.count > 0) {
                item.chapters = (chaptersVar[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        if let commentsVar = stats?.search(withXPathQuery: "//dd[@class='comments']") {
            if(commentsVar.count > 0) {
                item.comments = ((commentsVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        if let kudosVar = stats?.search(withXPathQuery: "//dd[@class='kudos']") {
            if(kudosVar.count > 0) {
                item.kudos = ((kudosVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        if let bookmarksVar = stats?.search(withXPathQuery: "//dd[@class='bookmarks']") {
            if(bookmarksVar.count > 0) {
                item.bookmarks = ((bookmarksVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        if let hitsVar = stats?.search(withXPathQuery: "//dd[@class='hits']") {
            if(hitsVar.count > 0) {
                item.hits = (hitsVar[0] as? TFHppleElement)?.text() ?? ""
            }
        }
        
        //parse tags
        if let requiredTagsList = workListItem.search(withXPathQuery: "//ul[@class='required-tags']") as? [TFHppleElement] {
            if(requiredTagsList.count > 0) {
                if let requiredTags: [TFHppleElement] = (requiredTagsList[0] ).search(withXPathQuery: "//li") as? [TFHppleElement] {
                    
                    for i in 0..<requiredTags.count {
                        switch (i) {
                        case 0:
                            item.rating = requiredTags[i].content
                        case 1:
                            item.warning = requiredTags[i].content
                        case 2:
                            item.category = requiredTags[i].content
                        case 3:
                            item.complete = requiredTags[i].content
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        if (item.complete.isEmpty) {
            item.complete = "Work In Progress"
        }
        
        //MARK: - remove underage and rape ratings!!
        if (item.warning.contains("Underage")) {
            item.warning = item.warning.replacingOccurrences(of: "Underage", with: "Archive Warnings")
        }
        if (item.warning.contains("Rape")) {
            item.warning = item.warning.replacingOccurrences(of: "Rape", with: "Warning: Violence")
        }
        
        if (item.complete.isEmpty ) {
            if (item.chapters.contains("?")) {
                item.complete = "Work In Progress"
            }
        }
        
        //parse work ID
        if let attributes : NSDictionary = workListItem.attributes as NSDictionary? {
            item.workId = (attributes["id"] as? String)?.replacingOccurrences(of: "work_", with: "") ?? ""
        }
        
        if let _ = item.workId.rangeOfCharacter(from: CharacterSet.letters) {
            if let headingH4 = workListItem.search(withXPathQuery: "//h4[@class='heading']//a") as? [TFHppleElement] {
                if (headingH4.count > 0) {
                    let attributes : NSDictionary = headingH4[0].attributes as NSDictionary
                    item.workId = (attributes["href"] as? String)?.replacingOccurrences(of: "/works/", with: "") ?? ""
                }
            }
        }
        
        if let downloadedItems = downloadedCheckItems {
            for downloadedItem in downloadedItems {
                if (downloadedItem.workId == item.workId) {
                    item.isDownloaded = true
                    
                    if (downloadedItem.date != item.dateTime) {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd MMM yyyy"
                        if let oldDate = dateFormatter.date(from: downloadedItem.date),
                            let newDate = dateFormatter.date(from: item.dateTime),
                            oldDate <= newDate {
                            item.needReload = true
                        }
                    }
                }
            }
        }
        
        if let readingIdGroup = workListItem.search(withXPathQuery: "//ul[@class='actions']//li") as? [TFHppleElement] {
            if (readingIdGroup.count > 0) {
                if let readingIdInput = readingIdGroup[0].search(withXPathQuery: "//input[@id='reading']") as? [TFHppleElement] {
                    if (readingIdInput.count > 0) {
                        let attributes : NSDictionary = readingIdInput[0].attributes as NSDictionary
                        item.readingId = (attributes["value"] as? String) ?? "" //.replacingOccurrences(of: "/confirm_delete", with: "") ?? ""
                    }
                }
            }
        }
        
        if (item.readingId.isEmpty) {
            if let readingIdGroup = workListItem.search(withXPathQuery: "//ul[@class='actions']//li") as? [TFHppleElement] {
                if (readingIdGroup.count > 1) {
                    if let readingIdInput = readingIdGroup[1].search(withXPathQuery: "//a") as? [TFHppleElement] {
                        if (readingIdInput.count > 0) {
                            let attributes : NSDictionary = readingIdInput[0].attributes as NSDictionary
                            item.readingId = (attributes["href"] as? String)?.replacingOccurrences(of: "/confirm_delete", with: "") ?? ""
                        }
                    }
                }
            }
        }
        
        return item
    }
    
    class func parsePages(paginationArr: [TFHppleElement]) -> [PageItem] {
        //parse pages
        
        var pages: [PageItem] = [PageItem]()
        var idxGap1 = -1
        var idxGap2 = -1
        var idxCurrent = -1
        
                for i in 0..<paginationArr.count {
                    let page: TFHppleElement = paginationArr[i]
                    var pageItem = PageItem()
                    
                    if (page.content.contains("Previous")) {
                        pageItem.name = "←"
                    } else if (page.content.contains("Next")) {
                        pageItem.name = "→"
                    } else {
                        pageItem.name = page.content
                    }
                    
                    if (pageItem.name.contains(AppDelegate.gapString)) {
                        if (idxGap1 < 0) {
                            idxGap1 = i
                        } else {
                            idxGap2 = i
                        }
                    }
                    
                    if let attrs = page.search(withXPathQuery: "//a") as? [TFHppleElement] {
                        if (attrs.count > 0) {
                            
                            let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                            if (attributesh != nil) {
                                pageItem.url = attributesh!["href"] as? String ?? ""
                            }
                        }
                    }
                    
                    if let current: [TFHppleElement] = page.search(withXPathQuery: "//span") as? [TFHppleElement] {
                        if (current.count > 0) {
                            pageItem.isCurrent = true
                            
                            idxCurrent = i
                        }
                    }
                    
                    pages.append(pageItem)
                }
        
        
        if (idxGap1 > 0 && idxGap2 < 0 && idxCurrent < idxGap1) {
            let size = idxGap1
            //for j in (idxCurrent + 2)..<size {
                pages.removeSubrange((idxCurrent + 2)..<size) //remove(at: j)
            
            if (idxCurrent > 3) {
                pages[2...(idxCurrent - 2)] = [PageItem(name: "…")]
            }
           // }
        } else
            if (idxGap1 > 0 && idxGap2 < 0 && idxCurrent > idxGap1) {
                let idxInverse = pages.count - idxCurrent
                
                let size = idxCurrent == pages.count - 1 ? idxCurrent - 2 : idxCurrent - 1
                pages.removeSubrange((idxGap1 + 1)..<size)
                
                if (idxInverse > 4) {
                    pages[pages.count - idxInverse + 2..<pages.count - 2] = [PageItem(name: "…")]
                }
            } else
                if (idxGap1 > 0 && idxGap2 > 0 && idxCurrent < idxGap2 && idxCurrent > idxGap1) {
                    
                    let size2 = idxGap2 - 1
                    pages.removeSubrange((idxCurrent + 2)...size2)
                    
                    let size1 = idxCurrent - 1
                    pages.removeSubrange((idxGap1 + 1)..<size1)
                    
                   
        }
        
        
        return pages
    }
    
}
