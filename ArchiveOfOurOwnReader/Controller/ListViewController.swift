//
//  ListViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/3/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation

class ListViewController: UIViewController {
    
    var theme: Int = DefaultsManager.THEME_DAY
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    func fillCell(cell: FeedTableViewCell, curWork: NewsFeedItem) -> FeedTableViewCell {
        cell.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell.fandomsLabel.text = curWork.fandoms
        
        if (curWork.topicPreview != nil) {
            cell.topicPreviewLabel.text = curWork.topicPreview
        }
        else {
            cell.topicPreviewLabel.text = ""
        }
        
        cell.datetimeLabel.text = curWork.dateTime
        
        if (curWork.language.isEmpty) {
            cell.languageLabel.text = "-"
        } else {
            cell.languageLabel.text = curWork.language
        }
        
        if (!curWork.chapters.isEmpty) {
            cell.chaptersLabel.text = NSLocalizedString("Chapters_", comment: "") + curWork.chapters
        } else {
            cell.chaptersLabel.text = ""
        }
        
        if let commentsNum: Float = Float(curWork.comments) {
            cell.commentsLabel.text =  commentsNum.formatUsingAbbrevation()
        } else {
            cell.commentsLabel.text = curWork.comments
        }
        
        if let kudosNum: Float = Float(curWork.kudos) {
            cell.kudosLabel.text =  kudosNum.formatUsingAbbrevation()
        } else {
            cell.kudosLabel.text = curWork.kudos
        }
        
        if let bookmarksNum: Float = Float(curWork.bookmarks) {
            cell.bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
        } else {
            cell.bookmarksLabel.text = curWork.bookmarks
        }
        
        if let hitsNum: Float = Float(curWork.hits) {
            cell.hitsLabel.text =  hitsNum.formatUsingAbbrevation()
        } else {
            cell.hitsLabel.text = curWork.hits
        }
        // cell?.completeLabel.text = curWork.complete
        // cell?.categoryLabel.text = curWork.category
         cell.ratingLabel.text = curWork.rating
        
        
        var tagsString = ""
        if (curWork.tags.count > 0) {
            tagsString = curWork.tags.joined(separator: ", ")
        }
        cell.tagsLabel.text = tagsString
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.bgView.backgroundColor = UIColor.white
            cell.topicLabel.textColor = AppDelegate.redColor
            cell.languageLabel.textColor = AppDelegate.redColor
            cell.datetimeLabel.textColor = AppDelegate.redColor
            cell.chaptersLabel.textColor = AppDelegate.redColor
            cell.topicPreviewLabel.textColor = UIColor.black
            cell.tagsLabel.textColor = AppDelegate.darkerGreyColor
            cell.kudosLabel.textColor = AppDelegate.redColor
            cell.commentsLabel.textColor = AppDelegate.redColor
            cell.bookmarksLabel.textColor = AppDelegate.redColor
            cell.hitsLabel.textColor = AppDelegate.redColor
            
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.bgView.backgroundColor = AppDelegate.greyBg
            cell.topicLabel.textColor = AppDelegate.textLightColor
            cell.languageLabel.textColor = AppDelegate.greyLightColor
            cell.datetimeLabel.textColor = AppDelegate.greyLightColor
            cell.chaptersLabel.textColor = AppDelegate.greyLightColor
            cell.topicPreviewLabel.textColor = AppDelegate.textLightColor
            cell.tagsLabel.textColor = AppDelegate.redTextColor
            cell.tagsLabel.textColor = AppDelegate.greyLightColor
            cell.kudosLabel.textColor = AppDelegate.darkerGreyColor
            cell.commentsLabel.textColor = AppDelegate.darkerGreyColor
            cell.bookmarksLabel.textColor = AppDelegate.darkerGreyColor
            cell.hitsLabel.textColor = AppDelegate.darkerGreyColor
        }
        
        cell.fandomsLabel.textColor = AppDelegate.greenColor
        
        return cell
    }
    
    func selectCell(row: Int, works: [NewsFeedItem]) {
        if (row >= works.count) {
            return
        }
        
        let newsItem:NewsFeedItem = works[row]
        if (newsItem.workId.contains("serie")) {
            self.performSegue(withIdentifier: "serieDetail", sender: self)
        } else {
            self.performSegue(withIdentifier: "workDetail", sender: self)
        }
    }
    
    func selectedWorkDetail(segue: UIStoryboardSegue, row: Int, modalDelegate: ModalControllerDelegate, newsItem:NewsFeedItem) {
        if let workDetail: WorkDetailViewController = segue.destination as? WorkDetailViewController {
            
            guard let work_id = Int(newsItem.workId) else {
                return
            }
            
            let currentWorkItem = WorkItem()
            
            currentWorkItem.id = Int64(work_id)
            
            currentWorkItem.archiveWarnings = newsItem.warning
            currentWorkItem.workTitle = newsItem.title
            currentWorkItem.topic = newsItem.topic
            
            if (newsItem.topicPreview != nil) {
                currentWorkItem.topicPreview = newsItem.topicPreview!
            }
            
            let tagsString = newsItem.tags.joined(separator: ", ")
            currentWorkItem.tags = tagsString
            
            currentWorkItem.datetime = newsItem.dateTime
            currentWorkItem.language = newsItem.language
            currentWorkItem.words = newsItem.words
            currentWorkItem.comments = newsItem.comments
            currentWorkItem.kudos = newsItem.kudos
            currentWorkItem.chaptersCount = newsItem.chapters
            currentWorkItem.bookmarks = newsItem.bookmarks
            currentWorkItem.hits = newsItem.hits
            currentWorkItem.ratingTags = newsItem.rating
            currentWorkItem.category = newsItem.category
            currentWorkItem.complete = newsItem.complete
            currentWorkItem.workId = newsItem.workId
        
            
            workDetail.workItem = currentWorkItem
            workDetail.modalDelegate = modalDelegate
        }
    }
    
    func fillCollCell(cell: PageCollectionViewCell, isCurrent: Bool) -> PageCollectionViewCell {
        
        if (theme == DefaultsManager.THEME_DAY) {
            if (isCurrent) {
                cell.titleLabel.textColor = UIColor(red: 169/255, green: 164/255, blue: 164/255, alpha: 1)
            } else {
                cell.titleLabel.textColor = UIColor.black
            }
            cell.backgroundColor = AppDelegate.greyLightBg
        } else {
            if (isCurrent) {
                cell.titleLabel.textColor = AppDelegate.greyColor
            } else {
                cell.titleLabel.textColor = UIColor.white
            }
            cell.backgroundColor = AppDelegate.redDarkColor
        }
        
        return cell
    }
    
    func selectedSerieDetail(segue: UIStoryboardSegue, row: Int, newsItem:NewsFeedItem) {
        if let navController: SerieViewController = segue.destination as? SerieViewController {
            navController.serieId = newsItem.workId
            
        }
    }
}
