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
import CoreData

class ListViewController: LoadingViewController, PageSelectDelegate, UIPopoverPresentationControllerDelegate {
    
    var foundItems = ""
    
    var worksElement = "work"
    var liWorksElement = "work"
    var itemsCountHeading = "h3"
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var curWork:NewsFeedItem?
    var curRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    func reload(row: Int) {
        
    }
    
    func fillCell(cell: FeedTableViewCell, curWork: NewsFeedItem) -> FeedTableViewCell {
        cell.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell.fandomsLabel.text = curWork.fandoms
        
        cell.wordsLabel.text = curWork.words
        
        cell.topicPreviewLabel.text = curWork.topicPreview
        
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
    
    func fillCellXib(cell: FeedTableViewCell, curWork: NewsFeedItem, needsDelete: Bool, index: Int) -> FeedTableViewCell {
        cell.workCellView.rowIndex = index
        
        cell.workCellView.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell.workCellView.fandomsLabel.text = curWork.fandoms
        cell.workCellView.authorLabel.text = curWork.author
        
        cell.workCellView.wordsLabel.text = curWork.words
        
        cell.workCellView.topicPreviewLabel.text = curWork.topicPreview
        
        cell.workCellView.datetimeLabel.text = curWork.dateTime
        
        if (curWork.language.isEmpty == true) {
            cell.workCellView.languageLabel.text = "-"
        } else {
            cell.workCellView.languageLabel.text = curWork.language
        }
        
        if (curWork.chapters.isEmpty == false) {
            cell.workCellView.chaptersLabel.text = curWork.chapters
        } else {
            cell.workCellView.chaptersLabel.text = "-"
        }
        
//        if let commentsNum: Float = Float(curWork.comments) {
//            cell.workCellView.commentsLabel.text =  commentsNum.formatUsingAbbrevation()
//        } else {
//            cell.workCellView.commentsLabel.text = curWork.comments
//        }
        
        if let kudosNum: Float = Float(curWork.kudos) {
            cell.workCellView.kudosLabel.text =  kudosNum.formatUsingAbbrevation()
        } else {
            cell.workCellView.kudosLabel.text = curWork.kudos
        }
        
        if let bookmarksNum: Float = Float(curWork.bookmarks) {
            cell.workCellView.bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
        } else {
            cell.workCellView.bookmarksLabel.text = curWork.bookmarks
        }
        
        if let hitsNum: Float = Float(curWork.hits) {
            cell.workCellView.hitsLabel.text =  hitsNum.formatUsingAbbrevation()
        } else {
            cell.workCellView.hitsLabel.text = curWork.hits
        }
        // cell?.completeLabel.text = curWork.complete
        // cell?.categoryLabel.text = curWork.category
        switch curWork.rating.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            cell.workCellView.ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            cell.workCellView.ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            cell.workCellView.ratingImg.image = UIImage(named: "NC17")
        case "Explicit":
            cell.workCellView.ratingImg.image = UIImage(named: "R")
        default:
            cell.workCellView.ratingImg.image = UIImage(named: "NotRated")
        }
        
        var tagsString = ""
        if (curWork.tags.count > 0) {
            tagsString = curWork.tags.joined(separator: ", ")
        }
        cell.workCellView.tagsLabel.text = tagsString
        
        
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.contentView.backgroundColor = AppDelegate.greyLightBg
            cell.workCellView.backgroundColor = AppDelegate.greyLightBg
            cell.workCellView.bgView.backgroundColor = UIColor.white
            cell.workCellView.topicLabel.textColor = AppDelegate.redColor
            cell.workCellView.languageLabel.textColor = AppDelegate.redColor
            cell.workCellView.datetimeLabel.textColor = AppDelegate.redColor
            cell.workCellView.chaptersLabel.textColor = AppDelegate.redColor
            cell.workCellView.authorLabel.textColor = AppDelegate.redColor
            cell.workCellView.topicPreviewLabel.textColor = UIColor.black
            cell.workCellView.tagsLabel.textColor = AppDelegate.darkerGreyColor
            cell.workCellView.kudosLabel.textColor = AppDelegate.redColor
            cell.workCellView.chaptersLabel.textColor = AppDelegate.redColor
            cell.workCellView.bookmarksLabel.textColor = AppDelegate.redColor
            cell.workCellView.hitsLabel.textColor = AppDelegate.redColor
            cell.workCellView.wordsLabel.textColor = AppDelegate.redColor
            
            cell.workCellView.wordImg.image = UIImage(named: "word")
            cell.workCellView.chaptersImg.image = UIImage(named: "chapters")
            cell.workCellView.kudosImg.image = UIImage(named: "likes")
            cell.workCellView.bmkImg.image = UIImage(named: "bookmark")
            cell.workCellView.hitsImg.image = UIImage(named: "hits")
            
            if (curWork.isDownloaded == true) {
                if (curWork.needReload == true) {
                    cell.workCellView.downloadButton.setImage(UIImage(named: "ic_refresh"), for: .normal)
                } else {
                    cell.workCellView.downloadButton.setImage(UIImage(named: "ic_yes"), for: .normal)
                }
            } else {
                cell.workCellView.downloadButton.setImage(UIImage(named: "download-100"), for: .normal)
            }
            
        } else {
            cell.contentView.backgroundColor = AppDelegate.greyDarkBg
            cell.workCellView.backgroundColor = AppDelegate.greyDarkBg
            cell.workCellView.bgView.backgroundColor = AppDelegate.greyBg
            cell.workCellView.topicLabel.textColor = AppDelegate.textLightColor
            cell.workCellView.languageLabel.textColor = AppDelegate.greyLightColor
            cell.workCellView.datetimeLabel.textColor = AppDelegate.greyLightColor
            cell.workCellView.chaptersLabel.textColor = AppDelegate.greyLightColor
            cell.workCellView.authorLabel.textColor = AppDelegate.greyLightColor
            cell.workCellView.topicPreviewLabel.textColor = AppDelegate.textLightColor
            cell.workCellView.tagsLabel.textColor = AppDelegate.redTextColor
            cell.workCellView.tagsLabel.textColor = AppDelegate.greyLightColor
            cell.workCellView.kudosLabel.textColor = AppDelegate.darkerGreyColor
            cell.workCellView.chaptersLabel.textColor = AppDelegate.darkerGreyColor
            cell.workCellView.bookmarksLabel.textColor = AppDelegate.darkerGreyColor
            cell.workCellView.hitsLabel.textColor = AppDelegate.darkerGreyColor
            cell.workCellView.wordsLabel.textColor = AppDelegate.darkerGreyColor
            
            cell.workCellView.wordImg.image = UIImage(named: "word_light")
            cell.workCellView.chaptersImg.image = UIImage(named: "chapters_light")
            cell.workCellView.kudosImg.image = UIImage(named: "likes_light")
            cell.workCellView.bmkImg.image = UIImage(named: "bookmark_light")
            cell.workCellView.hitsImg.image = UIImage(named: "hits_light")
            
            if (curWork.isDownloaded == true) {
                if (curWork.needReload == true) {
                    cell.workCellView.downloadButton.setImage(UIImage(named: "ic_refresh_light"), for: .normal)
                } else {
                    cell.workCellView.downloadButton.setImage(UIImage(named: "ic_yes_light"), for: .normal)
                }
            } else {
                cell.workCellView.downloadButton.setImage(UIImage(named: "download-100_light"), for: .normal)
            }
        }
        
        cell.workCellView.fandomsLabel.textColor = AppDelegate.greenColor
        
        if (needsDelete == false) {
            cell.workCellView.deleteButtonWidth.constant = 0.0
        }
        
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
            currentWorkItem.workTitle = newsItem.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            currentWorkItem.topic = newsItem.topic
            
            currentWorkItem.topicPreview = newsItem.topicPreview
            
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
            currentWorkItem.isDownloaded = newsItem.isDownloaded
            currentWorkItem.needReload = newsItem.needReload
            
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
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(data, itemsCountHeading: self.itemsCountHeading, worksElement: self.worksElement, downloadedCheckItems: checkItems)
                    
                    self.showWorks()
                
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
}

//MARK: - DownloadButtonDelegate

extension ListViewController: DownloadButtonDelegate {
    
    func downloadTouched(rowIndex: Int) {
        if (rowIndex >= works.count) {
            return
        }
        
        curWork = works[rowIndex]
        self.curRow = rowIndex
        
        if (curWork?.isDownloaded == true) {
            let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("WrkOptions", comment: ""), preferredStyle: .actionSheet)
            optionMenu.view.tintColor = AppDelegate.redColor
            
            let deleteAction = UIAlertAction(title: NSLocalizedString("DeleteWrk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.doDeleteWork()
                self.reload(row: rowIndex)
            })
            optionMenu.addAction(deleteAction)
            
            let reloadAction = UIAlertAction(title: NSLocalizedString("ReloadWrk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.doDownloadWork()
            })
            optionMenu.addAction(reloadAction)
            
            optionMenu.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
                print("Cancel")
            }))
            
            optionMenu.popoverPresentationController?.sourceView =  self.view
            optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
            
            optionMenu.view.tintColor = AppDelegate.redColor
            
            self.present(optionMenu, animated: true, completion: nil)
        } else {
        
            if (purchased || donated) {
                #if DEBUG
                    print("premium")
                #endif
            } else {
                if (countWroksFromDB() > 29) {
                    TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Only30Stroies", comment: ""), type: .error, duration: 2.0)
                
                    return
                }
            }
        
            doDownloadWork()
        }
    }
    
    func deleteTouched(rowIndex: Int) {
        
    }
    
    func doDownloadWork() {
        curWork?.isDownloaded = true
        
        showLoadingView(msg: "\(NSLocalizedString("DwnloadingWrk", comment: "")) \(curWork?.title ?? "")")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        request("https://archiveofourown.org/works/" + (curWork?.workId ?? ""), method: .get, parameters: params)
            .response(completionHandler: onSavedWorkDownloaded(_:))
    }
    
    func onSavedWorkDownloaded(_ response: DefaultDataResponse) {
        #if DEBUG
            print(response.request ?? "")
            //  println(response)
            print(response.error ?? "")
        #endif
        self.parseCookies(response)
        if let d = response.data {
            let _ = self.downloadWork(d, curWork: curWork)
            self.hideLoadingView()
            if (self.works.count > curRow) {
                self.works[curRow].isDownloaded = true
                self.works[curRow].needReload = false
            }
            self.reload(row: curRow)
        } else {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotDwnldWrk", comment: ""), type: .error, duration: 2.0)
            self.hideLoadingView()
        }
        
        curWork = nil
    }
    
    func doDeleteWork() {
        var res: DBWorkItem?
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        fetchRequest.fetchLimit = 1
        let searchPredicate: NSPredicate = NSPredicate(format: "workId = %@", curWork?.workId ?? "")
        
        fetchRequest.predicate = searchPredicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let results = fetchedResults {
                res = results.first
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        if let res = res {
            managedContext.delete(res)
            do {
                try managedContext.save()
            } catch _ {
                NSLog("Cannot delete saved work")
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotDeleteWrk", comment: ""), type: .error)
            }
            
            curWork?.isDownloaded = false
            curWork?.needReload = false
            
            if (self.works.count > curRow) {
                self.works[curRow].isDownloaded = false
                self.works[curRow].needReload = false
            }
            
            TSMessage.showNotification(in: self, title: NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("WorkDeletedFromDownloads", comment: ""), type: .success)
        
        } else {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotFindWrk", comment: ""), type: .error)
        }
    }
    
}

