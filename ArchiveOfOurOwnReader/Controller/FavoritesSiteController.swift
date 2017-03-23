//
//  FavoritesSiteController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/25/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import TSMessages
import Alamofire

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class FavoritesSiteController : LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var boomarksAddedStr = "Bookmarks"
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(FavoritesSiteController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.title = "Bookmarks"
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            requestFavs()
        } else {
            openLoginController() //openLoginController()
        }
        
    }
    
    func refresh(_ sender:AnyObject) {
        requestFavs()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestFavs()
    }
    
    //MARK: - login
    
    override func openLoginController() {
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
        (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        openLoginController()
    }
    
    //MARK: - request
    
    func requestFavs() {
        
        //let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
        if (del.cookies.count > 0) {
            guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                return
            }
            cStorage.setCookies(del.cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        }
        
        showLoadingView()
        
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            } else {
                TSMessage.showNotification(in: self, title: "Error", subtitle: "Log in to view your bookmarks!", type: .error)
                showBookmarks()
                return
            }
        }
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        let urlStr = "http://archiveofourown.org/users/\(login)/pseuds/\(pseuds[currentPseud]!)/bookmarks" // + pseuds[currentPseud]! + "/bookmarks"
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseBookmarks(d)
                    self.showBookmarks()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
                self.refreshControl.endRefreshing()
            })
        }
    
    func parseBookmarks(_ data: Data) {
        works.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        let doc : TFHpple = TFHpple(htmlData: data)
        if let bookmarksCount: [TFHppleElement] = doc.search(withXPathQuery: "//h2[@class='heading']") as? [TFHppleElement] {
        if (bookmarksCount.count > 0) {
            boomarksAddedStr = bookmarksCount[0].content.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines
            )
        }
        }
        let bookmarkslist : [TFHppleElement]? = doc.search(withXPathQuery: "//ol[@class='bookmark index group']") as? [TFHppleElement]
        if let workGroup = bookmarkslist {
            
            if (workGroup.count > 0) {
                let worksList : [TFHppleElement]? = workGroup[0].search(withXPathQuery: "//li[@class='bookmark blurb group']") as? [TFHppleElement]
                if let worksList = worksList {
                    
                    for workListItem in worksList {
                        
                        let item : NewsFeedItem = NewsFeedItem()
                        
                        let statsEls : [TFHppleElement] = workListItem.search(withXPathQuery: "//dl[@class='stats']") as! [TFHppleElement]
                        
                        if (statsEls.count > 0) {
                        let stats = statsEls[0]
                        
                            //parse stats
                            var langVar = stats.search(withXPathQuery: "//dd[@class='language']")
                            if(langVar?.count > 0) {
                                item.language = (langVar?[0] as! TFHppleElement).text()
                            }
                            
                            var wordsVar = stats.search(withXPathQuery: "//dd[@class='words']")
                            if(wordsVar?.count > 0) {
                                if let wordsNum: TFHppleElement = wordsVar?[0] as? TFHppleElement {
                                    if (wordsNum.text() != nil) {
                                        item.words = wordsNum.text()
                                    }
                                }
                            }
                            
                            var chaptersVar = stats.search(withXPathQuery: "//dd[@class='chapters']")
                            if(chaptersVar?.count > 0) {
                                item.chapters = (chaptersVar?[0] as! TFHppleElement).text()
                            }
                            
                            var commentsVar = stats.search(withXPathQuery: "//dd[@class='comments']")
                            if(commentsVar?.count > 0) {
                                item.comments = ((commentsVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var kudosVar = stats.search(withXPathQuery: "//dd[@class='kudos']")
                            if(kudosVar?.count > 0) {
                                item.kudos = ((kudosVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var bookmarksVar = stats.search(withXPathQuery: "//dd[@class='bookmarks']")
                            if(bookmarksVar?.count > 0) {
                                item.bookmarks = ((bookmarksVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var hitsVar = stats.search(withXPathQuery: "//dd[@class='hits']")
                            if(hitsVar?.count > 0) {
                                item.hits = (hitsVar?[0] as! TFHppleElement).text()
                            }
                        }
                        
                        if let headerEl: [TFHppleElement] = workListItem.search(withXPathQuery: "//div[@class='header module']") as? [TFHppleElement] {
                        
                        if (headerEl.count > 0) {
                        let header : TFHppleElement = headerEl[0] 
                        
                        let topic : TFHppleElement = header.search(withXPathQuery: "//h4[@class='heading']")[0] as! TFHppleElement
                        
                        item.topic = topic.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                            
                            }
                        
                        var userstuffArr = workListItem.search(withXPathQuery: "//blockquote[@class='userstuff summary']/p");
                        if(userstuffArr?.count > 0) {
                            let userstuff : TFHppleElement = userstuffArr![0] as! TFHppleElement
                            item.topicPreview = userstuff.content
                        }
                        
                        var fandomsArr = workListItem.search(withXPathQuery: "//h5[@class='fandoms heading']");
                        if(fandomsArr?.count > 0) {
                            let fandoms  = fandomsArr?[0] as! TFHppleElement
                            item.fandoms = fandoms.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                        }
                        
                        let tagsUl : [TFHppleElement] = workListItem.search(withXPathQuery: "//ul[@class='tags commas']/li") as! [TFHppleElement]
                        for tagUl in tagsUl {
                            item.tags.append(tagUl.content);
                        }
                        
                        var dateTimeVar = workListItem.search(withXPathQuery: "//p[@class='datetime']")
                        if(dateTimeVar?.count > 0) {
                            item.dateTime = (dateTimeVar?[0] as! TFHppleElement).text()
                        }
                        
                        
                        //parse tags
                        var requiredTagsList = workListItem.search(withXPathQuery: "//ul[@class='required-tags']")
                        if(requiredTagsList?.count > 0) {
                            var requiredTags = (requiredTagsList?[0] as AnyObject).search(withXPathQuery: "//li") as! [TFHppleElement]
                            
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
                        
                        //parse work ID
                        let headingH4 = workListItem.search(withXPathQuery: "//h4[@class='heading']//a") as? [TFHppleElement]
                        if (headingH4?.count > 0) {
                            let attributes : NSDictionary = headingH4![0].attributes as NSDictionary
                            item.workId = (attributes["href"] as! String).replacingOccurrences(of: "/works/", with: "")
                        }
                            
                            let readingIdGroup = workListItem.search(withXPathQuery: "//ul[@class='actions']//li") as! [TFHppleElement]
                            if (readingIdGroup.count > 1) {
                                var readingIdInput = readingIdGroup[1].search(withXPathQuery: "//a") as! [TFHppleElement]
                                if (readingIdInput.count > 0) {
                                    let attributes : NSDictionary = readingIdInput[0].attributes as NSDictionary
                                    item.readingId = (attributes["href"] as! String).replacingOccurrences(of: "/confirm_delete", with: "")
                                }
                            }
                        
                        works.append(item)
                        
                        //parse pages
                        var paginationActions = doc.search(withXPathQuery: "//ol[@class='pagination actions']")
                        if(paginationActions?.count > 0) {
                            guard let paginationArr = (paginationActions?[0] as AnyObject).search(withXPathQuery: "//li") else {
                                return
                            }
                            
                            for i in 0..<paginationArr.count {
                                let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                                let pageItem = PageItem()
                                
                                pageItem.name = page.content
                                
                                var attrs = page.search(withXPathQuery: "//a") as! [TFHppleElement]
                                
                                if (attrs.count > 0) {
                                    
                                    let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                                    if (attributesh != nil) {
                                        pageItem.url = attributesh!["href"] as! String
                                    }
                                }
                                
                                let current = page.search(withXPathQuery: "//span") as! [TFHppleElement]
                                if (current.count > 0) {
                                    pageItem.isCurrent = true
                                }
                                
                                pages.append(pageItem)
                            }
                        }
                    }
                    }
                }
            }
        }
    }
    
    func showBookmarks() {
        if (works.count > 0) {
            tableView.isHidden = false
            errView.isHidden = true
        } else {
            tableView.isHidden = true
            errView.isHidden = false
        }
        
        tableView.reloadData()
        collectionView.reloadData()
        
        hideLoadingView()
        self.navigationItem.title = boomarksAddedStr
    }
    
    override func controllerDidClosed() {}
    
    func controllerDidClosedWithLogin() {
        requestFavs()
    }
    
    func controllerDidClosedWithChange() {
        refresh(tableView)
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:FeedTableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? FeedTableViewCell
        
        if (cell == nil) {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
        
        cell?.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell?.fandomsLabel.text = curWork.fandoms
        
        if (curWork.topicPreview != nil) {
            cell?.topicPreviewLabel.text = curWork.topicPreview
        }
        else {
            cell?.topicPreviewLabel.text = ""
        }
        
        cell?.datetimeLabel.text = curWork.dateTime
        cell?.languageLabel.text = curWork.language
        cell?.wordsLabel.text = curWork.words
        cell?.chaptersLabel.text = "Chapters: " + curWork.chapters
        cell?.commentsLabel.text = curWork.comments
        cell?.kudosLabel.text = curWork.kudos
        cell?.bookmarksLabel.text = curWork.bookmarks
        cell?.hitsLabel.text = curWork.hits
        /*cell?.completeLabel.text = curWork.complete
        cell?.categoryLabel.text = curWork.category
        cell?.ratingLabel.text = curWork.rating*/
        
        let tagsString:NSString = curWork.tags.joined(separator: ", ") as NSString
        cell?.tagsLabel.text = tagsString as String
        
        cell?.downloadButton.tag = (indexPath as NSIndexPath).row
        cell?.deleteButton.tag = (indexPath as NSIndexPath).row
        
        return cell!
    }
    
    
    //MARK: - collectionview
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        let cell: PageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PageCollectionViewCell
        
        cell.titleLabel.text = pages[(indexPath as NSIndexPath).row].name
        
        if (pages[(indexPath as NSIndexPath).row].url.isEmpty) {
            cell.titleLabel.textColor = UIColor(red: 169/255, green: 164/255, blue: 164/255, alpha: 1)
        } else {
            cell.titleLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[(indexPath as NSIndexPath).row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView()
            
            Alamofire.request("http://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let data: Data = response.data {
                    self.parseCookies(response)
                    self.parseBookmarks(data)
                    self.showBookmarks()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch ((indexPath as NSIndexPath).row) {
        case 0, self.collectionView(collectionView, numberOfItemsInSection: (indexPath as NSIndexPath).section) - 1:
            return CGSize(width: 100, height: 28)
        default:
            return CGSize(width: 50, height: 28)
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "BookmarkDetail") {
            let workDetail: UINavigationController = segue.destination as! UINavigationController
            let newsItem:NewsFeedItem = works[(tableView.indexPathForSelectedRow! as NSIndexPath).row]
            
            let currentWorkItem = WorkItem()
            
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
            
            let workIdStr = newsItem.workId.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            currentWorkItem.id = Int64(Int(workIdStr)!)
            
            (workDetail.viewControllers[0] as! WorkDetailViewController).workItem = currentWorkItem
            (workDetail.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
            
        }
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let urlStr =  "http://archiveofourown.org/works/" + curWork.workId
        
        Alamofire.request(urlStr, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                //  println(response ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    self.downloadWork(d, curWork: curWork)
                    //self.saveWork()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
    }

    //MARK: - delete work from bookmarks
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
        
        let deleteAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you would like to delete this work from bookmarks?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[sender.tag]
            self.deleteItemFromBookmarks(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromBookmarks(_ curWork: NewsFeedItem) {
        showLoadingView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        //let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            }
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        params["_method"] = "delete" as AnyObject?
        
        let urlStr = "http://archiveofourown.org" + curWork.readingId
        
        Alamofire.request(urlStr, method: .post, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d, curWork: curWork)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
    }
    
    func parseDeleteResponse(_ data: Data, curWork: NewsFeedItem) {
        // let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        // print("the string is: \(dta)")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as! [TFHppleElement]
        if(noticediv.count > 0) {
            if let index = self.works.index( where: {$0.workId == curWork.workId}) {
                self.works.remove(at: index)
            }
            self.view.makeToast(message: noticediv[0].content, duration: 3.0, position: "center" as AnyObject, title: "Delete from Bookmarks")
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && sorrydiv?.count>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.view.makeToast(message: (sorrydiv![0] as AnyObject).content, duration: 4.0, position: "center" as AnyObject, title: "Delete from Bookmarks")
                return
            }
        }
    }

}
