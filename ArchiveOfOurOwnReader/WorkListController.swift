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
import Crashlytics

class WorkListController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var worksStr = NSLocalizedString("WorkList", comment: "")
    var tagUrl = ""
    var tagName = NSLocalizedString("WorkList", comment: "")
    var worksElement = "work"
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: ""))
        self.refreshControl.addTarget(self, action: #selector(FavoritesSiteController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        if (!tagUrl.contains("archiveofourown.org")) {
            tagUrl = "https://archiveofourown.org\(tagUrl)"
        }
        
        #if DEBUG
        print(tagUrl)
            #endif
        
        requestWorks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
        }
        
        showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
        
        let urlStr = tagUrl
        
        Answers.logCustomEvent(withName: "WorkList_opened",
                               customAttributes: [
                                "urlStr": urlStr])
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.worksStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "work", liWorksElement: self.worksElement)
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
        return works.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:FeedTableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? FeedTableViewCell
        
        if (cell == nil) {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        let curWork:NewsFeedItem = works[indexPath.row]
        
        cell = fillCell(cell: cell!, curWork: curWork)
        cell?.downloadButton.tag = indexPath.row
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCell(row: indexPath.row, works: works)
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
            
            showLoadingView(msg: "Loading page \(page.name)")
            
            self.worksStr = NSLocalizedString("0Found", comment: "")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
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
    
    func controllerDidClosedWithChange() {
        
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
        
        let urlStr =  "https://archiveofourown.org/works/" + curWork.workId
        
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
