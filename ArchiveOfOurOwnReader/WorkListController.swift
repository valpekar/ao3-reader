//
//  WorkListController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/9/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import Crashlytics

class WorkListController: ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    @IBOutlet weak var notFoundLabel:UILabel!
    
    var worksStr = Localization("WorkList")
    var tagUrl = ""
    var tagName = Localization("WorkList")
    
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var searchBar: UISearchBar!
    var searched = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: Localization("PullToRefresh"))
        self.refreshControl.addTarget(self, action: #selector(WorkListController.refresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        if (self.worksElement.isEmpty == true) {
            self.worksElement = "work"
        }
        self.itemsCountHeading = "h2"
        
        if (liWorksElement.isEmpty == true) {
            liWorksElement = worksElement
        }
        
       // if (tagUrl.contains("/pseuds/") == false && tagUrl.contains("/users/") == false) {
        
//            searchController = UISearchController(searchResultsController: nil)
//            searchController.searchResultsUpdater = self
//            searchController.searchBar.delegate = self
//            searchController.searchBar.tintColor = AppDelegate.purpleLightColor
//            searchController.searchBar.backgroundImage = UIImage()
//            searchController.dimsBackgroundDuringPresentation = false
//            definesPresentationContext = true
        
            if let tf = self.searchBar.value(forKey: "_searchField") as? UITextField {
                addDoneButtonOnKeyboardTf(tf)
                
                if (theme == DefaultsManager.THEME_DAY) {
                    tf.textColor = AppDelegate.redColor
                    tf.backgroundColor = UIColor.white
                    
                } else {
                    tf.textColor = AppDelegate.textLightColor
                    tf.backgroundColor = AppDelegate.greyBg
                }
            }
        
       //     self.tableView.tableHeaderView = searchController.searchBar
      //  }
        
        self.searchBar.delegate = self
        
        if (!tagUrl.contains("archiveofourown.org")) {
            tagUrl = "https://archiveofourown.org\(tagUrl)"
        }
        
        #if DEBUG
        print(tagUrl)
            #endif
        
        Answers.logCustomEvent(withName: "Work List Open", customAttributes: ["link" : tagUrl])
        
        requestWorks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showNav()
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
            self.tryAgainButton.setTitleColor(AppDelegate.redColor, for: UIControl.State.normal)
            self.notFoundLabel.textColor = AppDelegate.redColor
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.collectionView.backgroundColor = AppDelegate.redDarkColor
            self.tryAgainButton.setTitleColor(AppDelegate.purpleLightColor, for: UIControl.State.normal)
            self.notFoundLabel.textColor = AppDelegate.nightTextColor
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        requestWorks()
    }
    
    @IBAction func tryAgainTouched(_ sender: AnyObject) {
        if (self.searchBar != nil) {
            self.searchBar.text = ""
            self.searchBar.endEditing(true)
        }
        
        requestWorks()
    }
    
    func requestWorks() {
        
        searched = false
        
        self.pages.removeAll()
        self.works.removeAll()
        self.worksStr = ""
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            }
        }
        
        showLoadingView(msg: Localization("GettingWorks"))
        
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
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.worksStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: self.worksElement, liWorksElement: self.liWorksElement, downloadedCheckItems: checkItems)
                    //self.parseWorks(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
                self.refreshControl.endRefreshing()
            })
    }
    
    override func reload(row: Int) {
        if self.works.count > row {
            self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableView.RowAnimation.automatic)
        }
    }
    
    override func showWorks() {
        if (works.count > 0) {
            tableView.isHidden = false
            tryAgainButton.isHidden = true
            notFoundLabel.isHidden = true
        } else {
            tableView.isHidden = true
            tryAgainButton.isHidden = false
            notFoundLabel.isHidden = false
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
        
        if (works.count > indexPath.row) {
        
        let curWork:NewsFeedItem = works[indexPath.row]
        
            cell = fillCellXib(cell: cell!, curWork: curWork, needsDelete: false, index: indexPath.row)
            
            cell?.workCellView.tag = indexPath.row
            cell?.workCellView.downloadButtonDelegate = self
        }
        
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
        
        cell = fillCollCell(cell: cell , page: pages[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCollCell(indexPath: indexPath, sender: self.collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: AppDelegate.smallCollCellWidth, height: 28)
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
        
        hideBackTitle()
    }
    
    func controllerDidClosedWithChange() {
        
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView(msg: "\(Localization("DwnloadingWrk")) \(curWork.title)")
        
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
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
    }
    
    override func doneButtonAction() {
        super.doneButtonAction()
        self.searchBar.endEditing(true)
        
//        self.searchBarSearchButtonClicked(self.searchController.searchBar)
//        self.searchController.dismiss(animated: true, completion: nil)
    }
}


extension WorkListController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
//        if let txt = searchController.searchBar.text {
//            if (txt.isEmpty) {
//                showNotification(in: self, title:  Localization("Error"), subtitle: Localization("CannotBeEmpty"), type: .error, duration: 2.0)
//            } else {
//                searchAndFilter(txt)
//            }
//        }
        
        if (searchBar.text != nil && searchBar.text?.isEmpty == false) {
            searchAndFilter(searchBar.text!)
        } else {
            requestWorks()
        }
        searchBar.endEditing(true)
    }
    
    
    func searchAndFilter(_ text: String) {
        
        Answers.logCustomEvent(withName: "Work list: select", customAttributes: ["text": text])
        
        searched = true
        
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
        
        showLoadingView(msg: Localization("GettingWorks"))
        
        //http://archiveofourown.org/works?utf8=%E2%9C%93&work_search%5Bsort_column%5D=revised_at&work_search%5Bother_tag_names%5D=&work_search%5Bquery%5D=tian&work_search%5Blanguage_id%5D=&work_search%5Bcomplete%5D=0&commit=Sort+and+Filter&tag_id=19%E5%A4%A9+-+Old%E5%85%88+%7C+19+Days+-+Old+Xian

        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject
        params["work_search"] = ["sort_column": "",
                                 "query": text,
                                 "revised_at": "",
                                 "other_tag_names": "",
                                 "excluded_tag_names": "",
                                 "language_id": "",
                                 "date_from": "",
                                 "date_to": "",
                                 "words_from": "",
                                 "words_to": "",
                                 "complete": "0"
                                 ]
        let strArr = tagUrl.components(separatedBy: "/")
        if (strArr.count > strArr.count - 2) {
            params["tag_id"] = strArr[strArr.count - 2].removingPercentEncoding  //tag id goes before /works
        }
        params["commit"] = "Sort and Filter"
        
        Answers.logCustomEvent(withName: "WorkList_search",
                               customAttributes: [
                                "txt": text])
        
        Alamofire.request("https://archiveofourown.org/works", method: .get, parameters: params) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.worksStr) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: self.worksElement, liWorksElement: self.worksElement, downloadedCheckItems: checkItems)
                    //self.parseWorks(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                    
                }
                self.refreshControl.endRefreshing()
            })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if (searchBar.text != nil && searchBar.text?.isEmpty == false) {
            searchAndFilter(searchBar.text!)

            searchBar.endEditing(true)
        } else {
            self.showError(title: Localization("Error"), message: Localization("CannotBeEmpty"))
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)

        if (searched == true) {
            requestWorks()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if (searchBar.text != nil && searchBar.text?.isEmpty == false && searchBar.text?.count ?? 0 > 2) {
            searchAndFilter(searchBar.text!)
        } else {
            requestWorks()
        }
        searchBar.endEditing(true)
    }
}
