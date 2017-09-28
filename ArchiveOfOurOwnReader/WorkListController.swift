//
//  WorkListController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/9/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import TSMessages
import Alamofire

class WorkListController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var worksStr = NSLocalizedString("WorkList", comment: "")
    var tagUrl = ""
    var tagName = NSLocalizedString("WorkList", comment: "")
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: ""))
        self.refreshControl.addTarget(self, action: #selector(FavoritesSiteController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        if (!tagUrl.contains("archiveofourown.org")) {
            tagUrl = "http://archiveofourown.org\(tagUrl)"
        }
        
        #if DEBUG
        print(tagUrl)
            #endif
        
        requestWorks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func refresh(_ sender:AnyObject) {
        requestWorks()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestWorks()
    }
    
    func requestWorks() {
        
        self.pages.removeAll()
        self.works.removeAll()
        self.worksStr = ""
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
        }
        
        showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
        
        let urlStr = tagUrl
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.worksStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "work")
                    //self.parseWorks(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
                self.refreshControl.endRefreshing()
            })
    }
    
    func showWorks() {
        if (works.count > 0) {
            tableView.isHidden = false
            tryAgainButton.isHidden = true
        } else {
            tableView.isHidden = true
            tryAgainButton.isHidden = false
        }
        
        tableView.reloadData()
        collectionView.reloadData()
        
        hideLoadingView()
        self.navigationItem.title = worksStr
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
        cell?.chaptersLabel.text = "Chapters: " + curWork.chapters
       
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
            
            showLoadingView(msg: "Loading page \(page.name)")
            
            self.worksStr = NSLocalizedString("0Found", comment: "")
            
            Alamofire.request("http://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let data: Data = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.worksStr) = WorksParser.parseWorks(data, itemsCountHeading: "h2", worksElement: "work")
                    //self.parseWorks(data)
                    self.showWorks()
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
        if(segue.identifier == "workDetail") {
            let workDetail: WorkDetailViewController = segue.destination as! WorkDetailViewController
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
            
            workDetail.workItem = currentWorkItem
            workDetail.modalDelegate = self
            
        }
    }
    
    func controllerDidClosedWithChange() {
        
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
                #if DEBUG
                print(response.request ?? "")
                //  println(response ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let _ = self.downloadWork(d, curWork: curWork)
                    //self.saveWork()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
}
