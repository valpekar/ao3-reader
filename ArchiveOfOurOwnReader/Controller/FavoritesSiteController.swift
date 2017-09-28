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


class FavoritesSiteController : LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var boomarksAddedStr = NSLocalizedString("Bookmarks", comment: "")
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(FavoritesSiteController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.title = NSLocalizedString("Bookmarks", comment: "")
        
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
        
        showLoadingView(msg: NSLocalizedString("GettingBmks", comment: ""))
        
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            } else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("LoginToViewBmks", comment: ""), type: .error)
                showBookmarks()
                return
            }
        }
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        guard let curPs = pseuds[currentPseud] else {
            return
        }
        let urlStr = "http://archiveofourown.org/users/\(login)/pseuds/\(curPs)/bookmarks" // + pseuds[currentPseud]! + "/bookmarks"
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.boomarksAddedStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "bookmark")
                    //self.parseBookmarks(d)
                    self.showBookmarks()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
                self.refreshControl.endRefreshing()
            })
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
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if (self.tableView.numberOfSections > 0 && self.tableView.numberOfRows(inSection: 0) > 0) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        collectionView.flashScrollIndicators()
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
        cell?.chaptersLabel.text = NSLocalizedString("Chapters_", comment: "") + curWork.chapters
        
        if let commentsNum: Float = Float(curWork.comments) {
            (cell as! FeedTableViewCell).commentsLabel.text =  commentsNum.formatUsingAbbrevation()
        } else {
            (cell as! FeedTableViewCell).commentsLabel.text = curWork.comments
        }
        
        if let kudosNum: Float = Float(curWork.kudos) {
            (cell as! FeedTableViewCell).kudosLabel.text =  kudosNum.formatUsingAbbrevation()
        } else {
            (cell as! FeedTableViewCell).kudosLabel.text = curWork.kudos
        }
        
        if let bookmarksNum: Float = Float(curWork.bookmarks) {
            (cell as! FeedTableViewCell).bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
        } else {
            (cell as! FeedTableViewCell).bookmarksLabel.text = curWork.bookmarks
        }
        
        if let hitsNum: Float = Float(curWork.hits) {
            (cell as! FeedTableViewCell).hitsLabel.text =  hitsNum.formatUsingAbbrevation()
        } else {
            (cell as! FeedTableViewCell).hitsLabel.text = curWork.hits
        }
        
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
            
            showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: "")) \(page.name)")
            
            Alamofire.request("http://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let data: Data = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.boomarksAddedStr) = WorksParser.parseWorks(data, itemsCountHeading: "h2", worksElement: "bookmark")
                    //self.parseBookmarks(data)
                    self.showBookmarks()
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
            currentWorkItem.id = Int64(workIdStr) ?? 0
            
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
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }

    //MARK: - delete work from bookmarks
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
        
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteWrkFromBmks", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[sender.tag]
            self.deleteItemFromBookmarks(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromBookmarks(_ curWork: NewsFeedItem) {
        showLoadingView(msg: NSLocalizedString("DeletingFromBmks", comment: ""))
        
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
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
    
    func parseDeleteResponse(_ data: Data, curWork: NewsFeedItem) {
        // let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        // print("the string is: \(dta)")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        let noticediv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement]
        if(noticediv != nil && (noticediv?.count)! > 0) {
            if let index = self.works.index( where: {$0.workId == curWork.workId}) {
                self.works.remove(at: index)
            }
            self.view.makeToast(message: noticediv?[0].content ?? "", duration: 3.0, position: "center" as AnyObject, title: NSLocalizedString("DeleteFromBmk", comment: ""))
        } else {
            if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
                if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
                    self.view.makeToast(message: (sorrydiv[0] as AnyObject).content, duration: 4.0, position: "center" as AnyObject, title: NSLocalizedString("DeleteFromBmk", comment: ""))
                    return
                }
            }
        }
    }

}
