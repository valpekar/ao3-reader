//
//  ListViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/3/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import Foundation
import Alamofire
import TSMessages
import Crashlytics

class ListViewController: LoadingViewController, PageSelectDelegate, UIPopoverPresentationControllerDelegate {
    
    var foundItems = ""
    
    var worksElement = "work"
    var liWorksElement = "work"
    var itemsCountHeading = "h3"
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    func fillCell(cell: FeedTableViewCell, curWork: NewsFeedItem) -> FeedTableViewCell {
        cell.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell.fandomsLabel.text = curWork.fandoms
        
        cell.wordsLabel.text = curWork.words
        
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
            cell.wordsLabel.textColor = AppDelegate.redColor
            
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
            cell.wordsLabel.textColor = AppDelegate.darkerGreyColor
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
    
    func fillCollCell(cell: PageCollectionViewCell, page: PageItem) -> PageCollectionViewCell {
        
        cell.setNeedsDisplay()
        
        if (theme == DefaultsManager.THEME_DAY) {
            if (page.isCurrent && page.name != "…") {
                cell.titleLabel.textColor = UIColor(red: 169/255, green: 164/255, blue: 164/255, alpha: 1)
            } else {
                cell.titleLabel.textColor = UIColor.black
            }
            cell.backgroundColor = AppDelegate.greyLightBg
        } else {
            if (page.isCurrent && page.name != "…") {
                cell.titleLabel.textColor = AppDelegate.greyColor
            } else {
                cell.titleLabel.textColor = UIColor.white
            }
            cell.backgroundColor = AppDelegate.redDarkColor
        }
        
        cell.titleLabel.text = page.name
        
        return cell
    }
    
    func selectedSerieDetail(segue: UIStoryboardSegue, row: Int, newsItem:NewsFeedItem) {
        if let navController: SerieViewController = segue.destination as? SerieViewController {
            navController.serieId = newsItem.workId
            
        }
    }
    
    func showWorks() {
        
    }
    
    func showPagesPopup(page: PageItem, sender: UIView) {
        
        let baseUrl = page.url
        
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Main",
            bundle: nil)
        guard let pagesViewController: PagesController = storyboard.instantiateViewController(withIdentifier: "pagesController") as? PagesController else {
            return
        }
        
        pagesViewController.modalDelegate = self
        pagesViewController.modalPresentationStyle = .popover
        pagesViewController.baseUrl = baseUrl
        pagesViewController.theme = theme
        
        let screenSize: CGRect = UIScreen.main.bounds
        
        pagesViewController.preferredContentSize = CGSize(width: screenSize.width * 0.3, height: 10 * 44.0)
        
        let popoverMenuViewController = pagesViewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .any
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = self.view
        popoverMenuViewController?.sourceRect = sender.frame
//        popoverMenuViewController?.sourceRect = CGRect(
//            x: 0,
//            y: sender.frame.maxY,
//            width: sender.frame.width,
//            height: sender.frame.height)
        
        Answers.logCustomEvent(withName: "ListVC: open pages popup", customAttributes: ["baseUrl" : baseUrl])
        
        present(
            pagesViewController,
            animated: true,
            completion: nil)
    
    }

    func adaptivePresentationStyle(
        for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func selectCollCell(indexPath: IndexPath, sender: UIView) {
        if (pages.count > indexPath.row) {
            let page: PageItem = pages[indexPath.row]
            
            if (!page.url.isEmpty) {
                
                goToPage(pageUrl: page.url, name: page.name)
                
            } else if (pages[indexPath.row].name == AppDelegate.gapString) {
                if (pages.count > 1) {
                    if let page = pages.filter({ (pageItem) -> Bool in
                        return (pageItem.url.isEmpty == false && pageItem.isCurrent == false && pageItem.name != "→")
                    }).last {
                    
                        showPagesPopup(page: page, sender:  sender)
                    }
                }
            }
        }
    }


    func pageSelected(pageUrl: String) {
        Answers.logCustomEvent(withName: "ListVC: selected from pages popup", customAttributes: ["pageUrl" : pageUrl])
        
        goToPage(pageUrl: pageUrl, name: "")
    }

    func goToPage(pageUrl: String, name: String) {
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            
            guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage
                else {
                    return
            }
            cStorage.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        
        let urlStr = AppDelegate.ao3SiteUrl + pageUrl
        
        showLoadingView(msg: ("\(NSLocalizedString("LoadingPage", comment: "")) \(name)"))
        
        Alamofire.request(urlStr)
            .response(completionHandler: { response in
                #if DEBUG
                    //  print(request)
                    //  println(response)
                    print(response.error ?? "")
                #endif
                
                self.parseCookies(response)
                
                if let data = response.data {
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(data, itemsCountHeading: self.itemsCountHeading, worksElement: self.worksElement)
                    
                    self.showWorks()
                
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
}
