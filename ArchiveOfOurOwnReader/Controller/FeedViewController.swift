//
//  FeedViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import StoreKit
import CoreLocation
import TSMessages
import Alamofire
import Crashlytics

protocol SearchControllerDelegate {
    func searchApplied(_ searchQuery:SearchQuery, shouldAddKeyword: Bool)
}

protocol DownloadButtonDelegate {
    func downloadTouched(rowIndex: Int)
    func deleteTouched(rowIndex: Int)
}

class FeedViewController: ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SearchControllerDelegate, UIWebViewDelegate, ChoosePrefProtocol {
    

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    @IBOutlet weak var checkStatusButton:UIButton!
    
    var resultSearchController = UISearchController()
    
    var query: SearchQuery = SearchQuery()
    
    var i = 0 //counts page transitions, display ads every 3rd time
    var adsShown = 0
    var triedToLogin = 0
    
    var refreshControl: UIRefreshControl!
    
    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.foundItems = "0 Found"
        self.worksElement = "work"
        self.itemsCountHeading = "h3"
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(FeedViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [String : AnyObject]
        
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.tintColor = AppDelegate.purpleLightColor
            controller.searchBar.backgroundImage = UIImage()
            controller.searchBar.delegate = self
            
            if let tf = controller.searchBar.value(forKey: "_searchField") as? UITextField {
                addDoneButtonOnKeyboardTf(tf)
                
                if (theme == DefaultsManager.THEME_DAY) {
                    tf.textColor = AppDelegate.redColor
                    tf.backgroundColor = UIColor.white
                    
                } else {
                    tf.textColor = AppDelegate.textLightColor
                    tf.backgroundColor = AppDelegate.greyBg
                }
            }
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        
        //Load query
        loadQueryFromDefaults()
        
       // let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        #if DEBUG
        print((UIApplication.shared.delegate as! AppDelegate).cookies)
            #endif
        
       /* if (purchased /*&& !pseud_id.isEmpty*/ && (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0) {
            openLoginController()
        } else {
            
            searchApplied(self.query, shouldAddKeyword: true)
        }*/
        
        if ( !DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: WorkDetailViewController = storyboard.instantiateViewController(withIdentifier: "WorkDetailViewController") as! WorkDetailViewController
            let item: WorkItem = WorkItem()
            item.workId = DefaultsManager.getString(DefaultsManager.LASTWRKID)
            vc.workItem = item
            vc.modalDelegate = self
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        tryAgainButton.layer.borderWidth = 1.0
        tryAgainButton.layer.borderColor = AppDelegate.redColor.cgColor
        tryAgainButton.layer.cornerRadius = 5.0
        
        checkStatusButton.layer.borderWidth = 1.0
        checkStatusButton.layer.borderColor = AppDelegate.redColor.cgColor
        checkStatusButton.layer.cornerRadius = 5.0
        
//        let shown: Bool = DefaultsManager.getBool(DefaultsManager.CONTENT_SHOWSN) ?? false
//        if (shown == false) {
//            showContentAlert()
//        }
      
        checkAuth()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let navVC = self.navigationController else {
            return
        }
        navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = false
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        
        //
        
        if (!purchased && !donated) {
            print("not purchased")
            //self.setupAdPlacer()
            if (adsShown % 3 == 0) {
                loadAdMobInterstitial()
                adsShown += 1
            }
        }
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
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
    
    deinit {
        #if DEBUG
        print ("Feed View Controller deinit")
        #endif
    }
    
    override func authFinished(success: Bool) {
        if (success == true) {
            refresh(tableView)
        }
    }
    
    override func loadAfterAuth() {
        if (query.isEmpty()) {
            self.performSegue(withIdentifier: "choosePref", sender: self)
        } else {
            refresh(tableView)
        }
    }
    
    @IBAction func tryAgainTouched(_ sender: AnyObject) {
        refresh(tableView)
    }
    
    func refresh(_ sender:AnyObject) {
        searchApplied(self.query, shouldAddKeyword: true)
        
        if (Reachability.isConnectedToNetwork()) {
            if (!DefaultsManager.getString(DefaultsManager.PSEUD_ID).isEmpty &&  (/*(UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 ||*/ (UIApplication.shared.delegate as! AppDelegate).token.isEmpty)) {
                
                if (triedToLogin < 2) {
                    openLoginController()
                    triedToLogin += 1
                }
            } else if (query.isEmpty()) {
                self.performSegue(withIdentifier: "choosePref", sender: self)
            } else {
                
                searchApplied(self.query, shouldAddKeyword: true)
            }
        } else {
            TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
        }
    }
   
    
    //MARK: - feed
    
    @IBAction func checkStatusTouched(_ sender: AnyObject) {
        UIApplication.shared.openURL(URL(string: "https://twitter.com/ao3_status")!)
    }
    
    override func showWorks() {
        
        tableView.reloadData()
        collectionView.reloadData()
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        self.title = foundItems
        
        //tableView.setContentOffset(CGPoint(x: 0, y: 0 - tableView.contentInset.top), animated:true)
        
        if (works.count == 0) {
            tryAgainButton.isHidden = false
            checkStatusButton.isHidden = false
        } else {
            tryAgainButton.isHidden = true
            checkStatusButton.isHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                if (self.tableView.numberOfSections > 0 && self.tableView.numberOfRows(inSection: 0) > 0) {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
                self.collectionView.flashScrollIndicators()
            }
        }
    }
    
    
    func loadQueryFromDefaults() {
        if let sq = DefaultsManager.getObject(DefaultsManager.SEARCH_Q) as? SearchQuery {
            self.query = sq
        }
    }
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell: FeedTableViewCell! = nil
        if let c:FeedTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FeedTableViewCell {
            cell = c
        } else {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        if (works.count <= indexPath.row) {
            return cell
        }
        
        let curWork:NewsFeedItem = works[indexPath.row]
        
        cell = fillCellXib(cell: cell, curWork: curWork, needsDelete: false, index: indexPath.row)
        
        cell.workCellView.tag = indexPath.row
        cell.workCellView.downloadButtonDelegate = self
        
        return cell
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        var cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
       // let cell: PageCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PageCollectionViewCell
        
    //    switch (indexPath.row) {
        
        if (pages.count <= indexPath.row) {
            return cell
        }
   
        cell = fillCollCell(cell: cell as! PageCollectionViewCell, page: pages[indexPath.row])
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCollCell(indexPath: indexPath, sender: self.collectionView)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCell(row: indexPath.row, works: works)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        switch (indexPath.row) {
//        case 0, self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) - 1:
//            return CGSize(width: AppDelegate.bigCollCellWidth, height: 28)
//        default:
            return CGSize(width: AppDelegate.smallCollCellWidth, height: 28)
//        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "workDetail") {
            
            if let row = tableView.indexPathForSelectedRow?.row {
                if (row < works.count) {
                    selectedWorkDetail(segue: segue, row: row, modalDelegate: self, newsItem: works[row])
                }
            }
            
        } else if (segue.identifier == "serieDetail") {
            if let row = tableView.indexPathForSelectedRow?.row {
                
                if (row < works.count) {
                    selectedSerieDetail(segue: segue, row: row, newsItem: works[row])
                }
            }
        } else if(segue.identifier == "searchSegue") {
            if let searchController: SearchViewController = segue.destination as? SearchViewController {
                searchController.delegate = self
                searchController.modalDelegate = self
                
                Answers.logCustomEvent(withName: "Search: Extended Opened",
                                       customAttributes: [:])
            }
        } else if (segue.identifier == "choosePref") {
            if let choosePref: UINavigationController = segue.destination as? UINavigationController {
                (choosePref.topViewController as! ChoosePrefController).chosenDelegate = self
            }
        } 
    }

    
    func searchApplied(_ searchQuery:SearchQuery, shouldAddKeyword: Bool) {
        
        pages = [PageItem]()
        works = [NewsFeedItem]()
        self.foundItems = ""

        if (searchQuery.isEmpty() && shouldAddKeyword) {
            searchQuery.include_tags = "popular"
            DefaultsManager.putObject(searchQuery, key: DefaultsManager.SEARCH_Q)
        }
       
        query = searchQuery
        
        let queryResult = query.formQuery()
        let encodableURLRequest = URLRequest(url: URL( string: "https://archiveofourown.org/works/search" )!)
        var encodedURLRequest: URLRequest? = nil
        do {
            encodedURLRequest = try URLEncoding.queryString.encode(encodableURLRequest, with: queryResult)
        } catch {
            print(error.localizedDescription)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
       
        showLoadingView(msg: NSLocalizedString("Searching", comment: ""))
        
        guard let url = URL( string: (encodedURLRequest?.url?.absoluteString)!) else {
            return
        }
        let mutableURLRequest = NSMutableURLRequest(url: url)
        mutableURLRequest.httpMethod = "GET"
        
        request("https://archiveofourown.org/works/search", method: .get, parameters: queryResult, encoding: URLEncoding.queryString)
            .response(completionHandler: onFeedLoaded(_:))
        
    }
    
    func onFeedLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        //print(response)
        print(response.error ?? "")
            #endif
        
        if let d = response.data {
            self.parseCookies(response)
            let checkItems = self.getDownloadedStats()
            (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: self.worksElement, downloadedCheckItems: checkItems)
            //self.getFeed(d)
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
        }
        
        self.refreshControl.endRefreshing()
        
        self.showWorks()
    }
    
    override func doneButtonAction() {
        super.doneButtonAction()
        self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
    override func drawerClicked(_ sender: AnyObject) {
        
        doneButtonAction()
        super.drawerClicked(sender)
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableViewRowAnimation.automatic)
    }
    
    
    //MARK: - SAVE WORK TO DB
    

    
    func saveWork() {
        hideLoadingView()
    }
    
    override func controllerDidClosed() {
       // if (!purchased && i%2 == 0) {
       //     showWvInterstitial()
       // }
        
        if (i % 5 == 0 && (!purchased && !donated)) {
            showAdMobInterstitial()
            adsShown += 1
        }
        
        i += 1
    }
    
    func controllerDidClosedWithLogin() {
        if (self.query.isEmpty()) {
            loadQueryFromDefaults()
        }
        self.searchApplied(self.query, shouldAddKeyword: true)
    }
    
    func controllerDidClosedWithChange() {
        
    }
    
    func showContestAlert() {
        let refreshAlert = UIAlertController(title: "Contest Announcement!", message: "Hi! I want to share great news! If you post your fanfics to http://indiefics.com from Jun 1 till June 30, you can take part in fanfics contest! The best chosen fanfic will be shown in this app as the first item on the main screen! For more details please check http://indiefics.com !", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Don't show again", style: .default, handler: { (action: UIAlertAction!) in
            DefaultsManager.putObject(false as AnyObject, key: DefaultsManager.DONTSHOW_CONTEST)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "More Details", style: .default, handler: { (action: UIAlertAction!) in
            UIApplication.shared.openURL(URL(string: "http://www.indiefics.com")!)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        //presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    func showContentAlert() {
        let refreshAlert = UIAlertController(title: NSLocalizedString("Attention", comment: ""), message: NSLocalizedString("SensitiveAttention", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: NSLocalizedString("MoreDetails", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
            if let url: URL = URL(string: "https://www.tumblr.com/blog/unofficialao3app") {
                UIApplication.shared.open(url, options: [ : ], completionHandler: { (result) in
                    print("Tumblr opened")
                })
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
             DefaultsManager.putBool(true, key: DefaultsManager.CONTENT_SHOWSN)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    //Mark: - ChoosePrefProtocol
    func prefChosen(pref: String) {
        query.fandom_names = pref
        DefaultsManager.putObject(query, key: DefaultsManager.SEARCH_Q)
        
        Answers.logCustomEvent(withName: "Fandom Chosen",
                               customAttributes: [
                                "pref": pref])
        
        self.searchApplied(self.query, shouldAddKeyword: true)
    }
    

}

extension FeedViewController : UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let txt = searchBar.text else {
            TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotBeEmpty", comment: ""), type: .error, duration: 2.0)
            return
        }
        
        if (!txt.isEmpty && query.include_tags != txt) {
            query = SearchQuery()
            
            query.include_tags = txt
            DefaultsManager.putObject(query, key: DefaultsManager.SEARCH_Q)
            
            Answers.logCustomEvent(withName: "Search: Quick",
                                   customAttributes: [
                                    "txt": txt])
            
            searchApplied(query, shouldAddKeyword: false)
            
            resultSearchController.isActive = false
        }
    }
    
    //MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
}



