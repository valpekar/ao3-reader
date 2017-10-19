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
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: ""))
        self.refreshControl.addTarget(self, action: #selector(HistoryViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
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
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.collectionView.backgroundColor = AppDelegate.redDarkColor
        }
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
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        let urlStr: String = "https://archiveofourown.org/users/" + username + "/readings"
        
        Alamofire.request(urlStr) //default is .get
            .response(completionHandler: { response in
                #if DEBUG
                //print(request)
                print(response.error ?? "")
                    #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.boomarksAddedStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "reading work")
                    //self.parseHistory(d)
                    self.refreshControl.endRefreshing()
                    self.showHistory()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
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
        
        if (tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        collectionView.flashScrollIndicators()
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
        
        var cell: PageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PageCollectionViewCell
        
        if (pages[indexPath.row].url.isEmpty) {
            cell = fillCollCell(cell: cell, isCurrent: true)
        } else {
            cell = fillCollCell(cell: cell, isCurrent: false)
        }
        
        cell.titleLabel.text = pages[indexPath.row].name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: "")) \(page.name)")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                
                #if DEBUG
                print(response.error ?? "")
                    #endif
                if let data = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.boomarksAddedStr) = WorksParser.parseWorks(data, itemsCountHeading: "h2", worksElement: "reading work")
                    //self.parseHistory(data)
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
        if(segue.identifier == "workDetail") {
            if let row = tableView.indexPathForSelectedRow?.row {
                if (row < works.count) {
                    selectedWorkDetail(segue: segue, row: row, modalDelegate: self, newsItem: works[row])
                    
                }
            }
            
        } else if (segue.identifier == "serieDetail" ) {
            if let row = tableView.indexPathForSelectedRow?.row {
                
                if (row < works.count) {
                    selectedSerieDetail(segue: segue, row: row, newsItem: works[row])
                }
            }
        }
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView(msg: "\(NSLocalizedString("DwnloadingWrk", comment: "")) \(curWork.title)")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let urlStr: String = "https://archiveofourown.org/works/" + curWork.workId
        
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
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
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
        
        let urlStr: String = "https://archiveofourown.org/users/" + pseuds[currentPseud]! + "/readings/" + curWork.readingId
        
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
        
        var noticediv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement]
        if(noticediv?.count ?? 0 > 0) {
            if let index = self.works.index( where: {$0.workId == curWork.workId}) {
                self.works.remove(at: index)
            }
            TSMessage.showNotification(in: self, title: NSLocalizedString("DeletingFromHistory", comment: ""), subtitle: noticediv?[0].content ?? "", type: .success)
        } else {
            if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") as? [TFHppleElement] {
            
                if(sorrydiv.count>0 && sorrydiv[0].text().range(of: "Sorry") != nil) {
                    TSMessage.showNotification(in: self, title: NSLocalizedString("DeletingFromHistory", comment: ""), subtitle: sorrydiv[0].content, type: .error)
                    return
                }
            }
        }
    }
    
}
