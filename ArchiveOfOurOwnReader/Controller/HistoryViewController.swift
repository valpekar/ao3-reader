//
//  HistoryViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/2/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import Foundation
import Alamofire
import TSMessages

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


class HistoryViewController : LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var boomarksAddedStr = NSLocalizedString("History", comment: "")
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.title = NSLocalizedString("History", comment: "")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: ""))
        self.refreshControl.addTarget(self, action: #selector(HistoryViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            requestFavs()
        } else if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            openLoginController()
            //requestFavs() //openLoginController()
        }
    }
    
    func refresh(_ sender:AnyObject) {
        requestFavs()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestFavs()
    }
    
    //MARK: - login
    
    
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        openLoginController()
    }
    
    //MARK: - request
    
    func requestFavs() {
        
        let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        showLoadingView(msg: NSLocalizedString("GettingHistory", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        let urlStr: String = "http://archiveofourown.org/users/" + username + "/readings"
        
        Alamofire.request(urlStr) //default is .get
            .response(completionHandler: { response in
                #if DEBUG
                //print(request)
                print(response.error ?? "")
                    #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseHistory(d)
                    self.refreshControl.endRefreshing()
                    self.showHistory()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)

                }
                
            })
        
    }
    
    func parseHistory(_ data: Data) {
        works.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        #if DEBUG
        let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print(string1 ?? "")
            #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        let historylist : [TFHppleElement]? = doc.search(withXPathQuery: "//ol[@class='reading work index group']") as? [TFHppleElement]
        if let workGroup = historylist {
            
            if (workGroup.count > 0) {
                let worksList : [TFHppleElement]? = workGroup[0].search(withXPathQuery: "//li[@class='reading work blurb group']") as? [TFHppleElement]
                if let worksList = worksList {
                    
                    for workListItem in worksList {
                        
                        autoreleasepool { [unowned self, unowned workListItem] in
                            
                            var item : NewsFeedItem = NewsFeedItem()
                        
                        let statsEls : [TFHppleElement]? = workListItem.search(withXPathQuery: "//dl[@class='stats']") as? [TFHppleElement]
                        
                        if (statsEls?.count ?? 0 > 0) {
                            let stats = statsEls?[0]
                            
                            //parse stats
                            var langVar = stats?.search(withXPathQuery: "//dd[@class='language']")
                            if(langVar?.count > 0) {
                                item.language = (langVar?[0] as? TFHppleElement)?.text() ?? ""
                            }
                            
                            var wordsVar = stats?.search(withXPathQuery: "//dd[@class='words']")
                            if(wordsVar?.count > 0) {
                                if let wordsNum: TFHppleElement = wordsVar?[0] as? TFHppleElement {
                                    if (wordsNum.text() != nil) {
                                        item.words = wordsNum.text()
                                    }
                                }
                            }
                            
                            var chaptersVar = stats?.search(withXPathQuery: "//dd[@class='chapters']")
                            if(chaptersVar?.count > 0) {
                                item.chapters = (chaptersVar?[0] as! TFHppleElement).text()
                            }
                            
                            var commentsVar = stats?.search(withXPathQuery: "//dd[@class='comments']")
                            if(commentsVar?.count > 0) {
                                item.comments = ((commentsVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var kudosVar = stats?.search(withXPathQuery: "//dd[@class='kudos']")
                            if(kudosVar?.count > 0) {
                                item.kudos = ((kudosVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var bookmarksVar = stats?.search(withXPathQuery: "//dd[@class='bookmarks']")
                            if(bookmarksVar?.count > 0) {
                                item.bookmarks = ((bookmarksVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
                            }
                            
                            var hitsVar = stats?.search(withXPathQuery: "//dd[@class='hits']")
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
                            
                            self.works.append(item)
                            }
                        }
                            }
                        
                        //parse pages
                        var paginationActions = doc.search(withXPathQuery: "//ol[@class='pagination actions']")
                        if(paginationActions?.count > 0) {
                            guard let paginationArr = (paginationActions?[0] as AnyObject).search(withXPathQuery: "//li") else {
                                return
                            }
                            
                            for i in 0..<paginationArr.count {
                                let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                                var pageItem = PageItem()
                                
                                pageItem.name = page.content
                                
                                let attrs: [TFHppleElement]? = page.search(withXPathQuery: "//a") as? [TFHppleElement]
                                
                                if (attrs?.count ?? 0 > 0) {
                                    
                                    if let attributesh : NSDictionary? = attrs?[0].attributes as? NSDictionary {
                                        pageItem.url = attributesh?["href"] as? String ?? ""
                                    }
                                }
                                
                                let current = page.search(withXPathQuery: "//span") as? [TFHppleElement]
                                if (current?.count ?? 0 > 0) {
                                    pageItem.isCurrent = true
                                }
                                
                                self.pages.append(pageItem)
                            }
                        }
                }
            }
        }
    }
    
    func showHistory() {
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
        
        tableView.setContentOffset(CGPoint.zero, animated:true)
    }
    
    override func controllerDidClosed() {}
    
    func controllerDidClosedWithLogin() {
        requestFavs()
    }
    
    func controllerDidClosedWithChange() {
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
        cell?.chaptersLabel.text = NSLocalizedString("Chapters_", comment: "") + curWork.chapters
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
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: "")) \(indexPath.row)")
            
            Alamofire.request("http://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                
                #if DEBUG
                print(response.error ?? "")
                    #endif
                if let data = response.data {
                    self.parseCookies(response)
                    self.parseHistory(data)
                    self.showHistory()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
        if(segue.identifier == "HistoryDetail") {
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
            
            currentWorkItem.id = Int64(Int(newsItem.workId)!)
            
            (workDetail.viewControllers[0] as! WorkDetailViewController).workItem = currentWorkItem
            (workDetail.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
            
        }
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView(msg: "\(NSLocalizedString("DwnloadingWrk", comment: "")) \(curWork.title)")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let urlStr: String = "http://archiveofourown.org/works/" + curWork.workId
        
        Alamofire.request(urlStr, parameters: params) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let _ = self.downloadWork(d, curWork: curWork)
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
        
    }

    //MARK: - delete work from history
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
        
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteFromHistory", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            #if DEBUG
            print("Cancel")
            #endif
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[sender.tag]
            self.deleteItemFromHistory(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromHistory(_ curWork: NewsFeedItem) {
        showLoadingView(msg: NSLocalizedString("DeletingFromHistory", comment: ""))
        
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
        params["reading"] = curWork.readingId as AnyObject?
        
        let urlStr: String = "http://archiveofourown.org/users/" + pseuds[currentPseud]! + "/readings/" + curWork.readingId
        
        Alamofire.request(urlStr, method: .post, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d, curWork: curWork)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
            self.view.makeToast(message: noticediv[0].content, duration: 3.0, position: "center" as AnyObject, title: "Delete from History")
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && sorrydiv?.count>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.view.makeToast(message: (sorrydiv![0] as AnyObject).content, duration: 4.0, position: "center" as AnyObject, title: NSLocalizedString("DeletingFromHistory", comment: ""))
                return
            }
        }
    }
    
}
