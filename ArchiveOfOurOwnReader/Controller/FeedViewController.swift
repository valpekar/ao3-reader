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
import Alamofire
import Crashlytics
import GoogleMobileAds
import Firebase

let NUMBER_OF_ELEMENTS_BETWEEN_ADS = 7

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
    
    @IBOutlet weak var extSearchItem: UIBarButtonItem!
    @IBOutlet weak var categoriesItem: UIBarButtonItem!
    
    var resultSearchController = UISearchController()
    
    var query: SearchQuery = SearchQuery()
    
    var i = 0 //counts page transitions, display ads every 3rd time
    var adsShown = 0
    var triedToLogin = 0
    
    var refreshControl: UIRefreshControl!
    
    var openingPrevWork = false
    
    
    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load query
        loadQueryFromDefaults()
        
        self.createDrawerButton()
        
        self.foundItems = "0 Found"
        self.worksElement = "work"
        self.itemsCountHeading = "h3"
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.tableView.register(UINib(nibName: "NativeAdTableViewCell", bundle: nil), forCellReuseIdentifier: "NativeAdTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(FeedViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        let titleDict: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict
        
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.tintColor = AppDelegate.purpleLightColor
            controller.searchBar.backgroundImage = UIImage()
            controller.searchBar.delegate = self
            
            if let tf = controller.searchBar.textField {
                addDoneButtonOnKeyboardTf(tf)
                
                if (theme == DefaultsManager.THEME_DAY) {
                    tf.textColor = UIColor(named: "global_tint")
                    tf.backgroundColor = UIColor.white
                    
                } else {
                    tf.textColor = AppDelegate.textLightColor
                    tf.backgroundColor = AppDelegate.greyBg
                }
            }
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
       // let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        #if DEBUG
            print((UIApplication.shared.delegate as? AppDelegate)?.cookies ?? "")
            #endif
        
       /* if (purchased /*&& !pseud_id.isEmpty*/ && (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0) {
            openLoginController()
        } else {
            
            searchApplied(self.query, shouldAddKeyword: true)
        }*/
        
        tryAgainButton.layer.borderWidth = 1.0
        tryAgainButton.layer.borderColor = UIColor(named: "global_tint")!.cgColor
        tryAgainButton.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        checkStatusButton.layer.borderWidth = 1.0
        checkStatusButton.layer.borderColor = UIColor(named: "global_tint")!.cgColor
        checkStatusButton.layer.cornerRadius = AppDelegate.smallCornerRadius
        
//        let shown: Bool = DefaultsManager.getBool(DefaultsManager.CONTENT_SHOWSN) ?? false
//        if (shown == false) {
//            showContentAlert()
//        }
      
        checkAuth()
        
        self.sendAllNotSentForNotif()
        self.sendAllNotSentForDelete()
        
        if ( !DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            openingPrevWork = true
            
            let mWorkId = DefaultsManager.getString(DefaultsManager.LASTWRKID)
            openWorkDetails(workId: mWorkId, fromNotif: false)
        }
        
         setupAccessibility()
    }
    
    var triedOpenDetails = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let navVC = self.navigationController else {
            return
        }
        navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = false
        
        
        //
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
        
        let worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        if (worksToReload.count > 0 && openingPrevWork == false && triedOpenDetails == 0) {
            triedOpenDetails = 1
            if (worksToReload[0].isEmpty == false) {
                openWorkDetails(workId: worksToReload[0], fromNotif: true)
            }
        }
        self.updateAppBadge()
    }
    
    func setupAccessibility() {
        extSearchItem.accessibilityLabel = NSLocalizedString("ExtSearch", comment: "")
        categoriesItem.accessibilityLabel = NSLocalizedString("FanficsCategories", comment: "")
    }
    
    func openWorkDetails(workId: String, fromNotif: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc: WorkDetailViewController = storyboard.instantiateViewController(withIdentifier: "WorkDetailViewController") as! WorkDetailViewController
        let item: WorkItem = WorkItem()
        item.workId = workId
        vc.workItem = item
        vc.modalDelegate = self
        vc.fromNotif = true
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
        self.collectionView.backgroundColor = UIColor(named: "tableViewBg")
    }
    
    deinit {
        #if DEBUG
        print ("Feed View Controller deinit")
        #endif
    }
    
    override func authFinished(success: Bool) {
        if (success == true) {
            loadAfterAuth()
        }
    }
    
    override func loadAfterAuth() {
        if (self.query.isEmpty() == true && DefaultsManager.getBool(DefaultsManager.SEARCHED) ?? false == false) {
            self.performSegue(withIdentifier: "choosePref", sender: self)
        } else if (works.count == 0 ){
            refresh(tableView)
        }
    }
    
    @IBAction func tryAgainTouched(_ sender: AnyObject) {
        refresh(tableView)
    }
    
    @objc func refresh(_ sender:AnyObject) {
        
        searchApplied(self.query, shouldAddKeyword: true)
        
        if (Reachability.isConnectedToNetwork()) {
            if (!DefaultsManager.getString(DefaultsManager.PSEUD_ID).isEmpty &&  (/*(UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 ||*/ (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0)) {
                
                if (triedToLogin < 2) {
                    openLoginController(force:true)
                    triedToLogin += 1
                }
            } else if (query.isEmpty()) {
                self.performSegue(withIdentifier: "choosePref", sender: self)
            } else {
                
                searchApplied(self.query, shouldAddKeyword: true)
            }
        } else {
            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
        }
    }
   
    
    //MARK: - feed
    
    @IBAction func checkStatusTouched(_ sender: AnyObject) {
        if let url = URL(string: "https://twitter.com/ao3_status") {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([ : ]), completionHandler: { (res) in
                print("open twitter status")
            })
        }
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
            
            DefaultsManager.putBool(true, key: DefaultsManager.SEARCHED)
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
                    
        return createFeedCell(tableView: tableView, indexPath: indexPath)
        
    }
    
    func createFeedCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
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
    
    func createAdCell(tableView: UITableView, indexPath: IndexPath, adIndex: Int) -> UITableViewCell {
        let cellIdentifier: String = "NativeAdTableViewCell"
        
        var cell: FeedTableViewCell! = nil
        if let c:FeedTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FeedTableViewCell {
            cell = c
        }
        
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
       // let newIndexPath = correctIndexPathAccordingToAds(originalIndexPath: indexPath)
        
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
    
    var selectedRow = 0
    
    
    override func doInsteadOfAd() {
        showWorkDetail()
    }
    
    func showWorkDetail() {
        
        if (selectedRow >= works.count) {
            return
        }
        
        let newsItem:NewsFeedItem = works[selectedRow]
        if (newsItem.workId.contains("serie")) {
            self.performSegue(withIdentifier: "serieDetail", sender: self)
        } else {
            self.performSegue(withIdentifier: "workDetail", sender: self)
        }
    }
    
    override func selectCell(row: Int, works: [NewsFeedItem]) {
        selectedRow = row
        
        doInsteadOfAd()
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "workDetail") {
            
                if (selectedRow < works.count) {
                    selectedWorkDetail(segue: segue, row: selectedRow, modalDelegate: self, newsItem: works[selectedRow])
                }
            
            hideBackTitle()
            
        } else if (segue.identifier == "serieDetail") {
            if let row = tableView.indexPathForSelectedRow?.row {
                
                if (row < works.count) {
                    selectedSerieDetail(segue: segue, row: row, newsItem: works[row])
                }
            }
            
            hideBackTitle()
            
        } else if(segue.identifier == "searchSegue") {
            if let searchController: SearchViewController = segue.destination as? SearchViewController {
                
                if (self.query.quick_tags.isEmpty == false) {
                    self.query.include_tags = self.query.quick_tags.split(separator: " ").joined(separator: ", ")
                    self.query.quick_tags = ""
                }
                DefaultsManager.putObject(self.query, key: DefaultsManager.SEARCH_Q)
                
                searchController.delegate = self
                searchController.modalDelegate = self
                
                Answers.logCustomEvent(withName: "Search: Extended Opened",
                                       customAttributes: [:])
                Analytics.logEvent("Search_Extended_Opened", parameters: [:])
            }
        } else if (segue.identifier == "choosePref") {
            if let choosePref: UINavigationController = segue.destination as? UINavigationController {
                (choosePref.topViewController as! ChoosePrefController).chosenDelegate = self
            }
        }
        
        i += 1
        
        doneButtonAction()
        hideBackTitle()
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
        //Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies([HTTPCookie](), for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
       
        showLoadingView(msg: Localization("Searching"))
        
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
            var str = ""
            (self.pages, self.works, self.foundItems, str) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: self.worksElement, downloadedCheckItems: checkItems)
            //self.getFeed(d)
        } else {
            self.hideLoadingView()
            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
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
        
        let rowIndexToUpdate = row
        
        if self.works.count > row {
        //    self.tableView.beginUpdates()
            self.tableView.reloadRows(at: [ IndexPath(row: rowIndexToUpdate, section: 0)], with: UITableView.RowAnimation.automatic)
        //    self.tableView.endUpdates()
        }
    }
    
    
    //MARK: - SAVE WORK TO DB
    
    override func downloadTouched(rowIndex: Int) {
        //let correctedIndexPath = correctIndexPathAccordingToAds(originalIndexPath: IndexPath(row: rowIndex, section: 0))
        
        super.downloadTouched(rowIndex: rowIndex)
    }
    
    func saveWork() {
        hideLoadingView()
    }
    
    override func controllerDidClosed() {
       // if (!purchased && i%2 == 0) {
       //     showWvInterstitial()
       // }
        
        
    }
    
   @objc func controllerDidClosedWithLogin() {
        if (self.query.isEmpty()) {
            loadQueryFromDefaults()
        }
        self.searchApplied(self.query, shouldAddKeyword: true)
    }
    
    @objc func controllerDidClosedWithChange() {
        
    }
    
    func showContentAlert() {
        let refreshAlert = UIAlertController(title: Localization("Attention"), message: Localization("SensitiveAttention"), preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: Localization("MoreDetails"), style: .default, handler: { (action: UIAlertAction!) in
            if let url: URL = URL(string: "https://www.tumblr.com/blog/unofficialao3app") {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([ : ]), completionHandler: { (result) in
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
        Analytics.logEvent("Fandom_Chosen", parameters: ["pref": pref as NSObject])
        
        self.searchApplied(self.query, shouldAddKeyword: true)
    }
    

}

extension FeedViewController : UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let txt = searchBar.text else {
            self.showError(title: Localization("Error"), message: Localization("CannotBeEmpty"))
            return
        }
        
        if (!txt.isEmpty && query.quick_tags != txt) {
            query = SearchQuery()
            
            query.quick_tags = txt
            DefaultsManager.putObject(query, key: DefaultsManager.SEARCH_Q)
            
            Answers.logCustomEvent(withName: "Search: Quick",
                                   customAttributes: [
                                    "txt": txt])
            Analytics.logEvent("Search_Quick", parameters: ["txt": txt as NSObject])
            
            searchApplied(query, shouldAddKeyword: false)
            
            resultSearchController.isActive = false
        } else if (txt.isEmpty == true) {
            query = SearchQuery()
            
            query.include_tags = "popular"
            DefaultsManager.putObject(query, key: DefaultsManager.SEARCH_Q)
            
            Answers.logCustomEvent(withName: "Search: Quick",
                                   customAttributes: [
                                    "txt": txt])
            Analytics.logEvent("Search_Quick", parameters: ["txt": txt as NSObject])
            
            searchApplied(query, shouldAddKeyword: false)
            
            resultSearchController.isActive = false
        }
    }
    
    //MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    //
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

extension FeedViewController: NativeAdsManagerDelegate {
    func nativeAdsManagerDidReceivedAds(_ adsManager: NativeAdsManager) {
        self.tableView.reloadData()
    }
}
