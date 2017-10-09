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
import LocalAuthentication

protocol SearchControllerDelegate {
    func searchApplied(_ searchQuery:SearchQuery, shouldAddKeyword: Bool)
}

class FeedViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SearchControllerDelegate, UIWebViewDelegate, ChoosePrefProtocol {
    

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    @IBOutlet weak var checkStatusButton:UIButton!
    
    var resultSearchController = UISearchController()
    
    //var placer: MPTableViewAdPlacer!
    
    var query: SearchQuery = SearchQuery()
    var foundItems = "0 Found"
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var i = 0 //counts page transitions, display ads every 3rd time
    var adsShown = 0
    var triedToLogin = 0
    
    var refreshControl: UIRefreshControl!
   
    //@IBOutlet weak var webView: UIWebView!

    
    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
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
            controller.searchBar.tintColor = AppDelegate.redLightColor
            controller.searchBar.delegate = self
            
            if let tf = controller.searchBar.value(forKey: "_searchField") as? UITextField {
                addDoneButtonOnKeyboardTf(tf)
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
            let vc: UINavigationController = storyboard.instantiateViewController(withIdentifier: "navWorkDetailViewController") as! UINavigationController
            let item: WorkItem = WorkItem()
            item.workId = DefaultsManager.getString(DefaultsManager.LASTWRKID)
            (vc.viewControllers[0] as! WorkDetailViewController).workItem = item
            (vc.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
            
            self.present(vc, animated: true, completion: nil)
        }
        
        tryAgainButton.layer.borderWidth = 1.0
        tryAgainButton.layer.borderColor = AppDelegate.redColor.cgColor
        tryAgainButton.layer.cornerRadius = 5.0
        
        checkStatusButton.layer.borderWidth = 1.0
        checkStatusButton.layer.borderColor = AppDelegate.redColor.cgColor
        checkStatusButton.layer.cornerRadius = 5.0
        
        let shown: Bool = DefaultsManager.getBool(DefaultsManager.CONTENT_SHOWSN) ?? false
        if (shown == false) {
            showContentAlert()
        }
        
//        let needsAuth: Bool = DefaultsManager.getBool(DefaultsManager.CONTENT_SHOWSN) ?? false
//        if (needsAuth == true) {
//            self.authenticateUser()
//        } else {
        
            refresh(tableView)
//        }
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
        
        if (!purchased || !donated) {
            print("not purchased")
            //self.setupAdPlacer()
            if (adsShown % 3 == 0) {
                loadAdMobInterstitial()
                adsShown += 1
            }
        }
    }
    
    deinit {
        #if DEBUG
        print ("Work View Controller deinit")
        #endif
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
    
    //MARK: - authenticate
    
    func authenticateUser() {
        // Get the local authentication context.
        let context : LAContext = LAContext()
        
        var error: NSError?
        
        // Set the reason string that will appear on the authentication alert.
        var reasonString = "Authentication is needed to access your stories."
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                
                if success {
                    self.refresh(self.tableView)
                }
                else{
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
                    print(evalPolicyError?.localizedDescription ?? "")
                    guard let Errcode = evalPolicyError?._code else {
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: .error, duration: 2.0)
                        return
                    }
                    
                    switch Errcode {
                        
                    case LAError.systemCancel.rawValue:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the system", comment: ""), type: .warning, duration: 2.0)
                        
                    case LAError.userCancel.rawValue:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the user", comment: ""), type: .warning, duration: 2.0)
                        
                    case LAError.userFallback.rawValue:
                        print("User selected to enter custom password")
                        OperationQueue.main.addOperation({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                    default:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: .error, duration: 2.0)
                        OperationQueue.main.addOperation({ () -> Void in
                            self.showPasswordAlert()
                        })
                    }
                }
            })]
        }  else {
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
                
            case LAError.touchIDNotEnrolled.rawValue:
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("TouchID is not enrolled", comment: ""), type: .error, duration: 2.0)
                
            case LAError.passcodeNotSet.rawValue:
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("A passcode has not been set", comment: ""), type: .error, duration: 2.0)
                
            default:
                // The LAError.TouchIDNotAvailable case.
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("TouchID not available", comment: ""), type: .error, duration: 2.0)
            }
            
            // Optionally the error description can be displayed on the console.
            print(error?.localizedDescription)
            
            // Show the custom alert view to allow users to enter the password.
            self.showPasswordAlert()
        }
    }
    
    func showPasswordAlert() {
        let passwordAlert = UIAlertController(title: "Password Authentication", message: "Please type your password", preferredStyle: .alert)
        let defaultButton = UIAlertAction(title: "OK",
                                          style: .default) {(_) in

                                            if let txt: String = passwordAlert.textFields?[0].text {
                                                if (txt.isEmpty) {
                                                    TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Please type your password!", comment: ""), type: .error, duration: 2.0)
                                                } else {
                                                    let userPass: String = DefaultsManager.getString(DefaultsManager.USER_PASS);
                                                    if (userPass == txt) {
                                                        self.refresh(self.tableView)
                                                    } else {
                                                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Incorrect password!", comment: ""), type: .error, duration: 2.0)
                                                    }
                                                }
                                            }
        }
        let cancelButton = UIAlertAction(title: "Cancel",
                                          style: .cancel) {(_) in
        }
        
        passwordAlert.addAction(defaultButton)
        passwordAlert.addAction(cancelButton)
        present(passwordAlert, animated: true) {
            // completion goes here
        }
    }
    
    //MARK: - feed
    
    @IBAction func checkStatusTouched(_ sender: AnyObject) {
        UIApplication.shared.openURL(URL(string: "https://twitter.com/ao3_status")!)
    }
    
    func showFeed() {
        
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
            
            if (tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0) {
                tableView.setContentOffset( CGPoint(x: 0, y: 0) , animated: true)
            }
            collectionView.flashScrollIndicators()
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
        
        if (works.count == 0) {
            return cell
        }
        
        let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
        
        cell = fillCell(cell: cell, curWork: curWork)
        
        cell.downloadButton.tag = (indexPath as NSIndexPath).row
        
        return cell
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) 
       // let cell: PageCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PageCollectionViewCell
        
    //    switch (indexPath.row) {
            
            (cell as! PageCollectionViewCell).titleLabel.text = pages[(indexPath as NSIndexPath).row].name
        
        if (pages[(indexPath as NSIndexPath).row].url.isEmpty) {
            (cell as! PageCollectionViewCell).titleLabel.textColor = UIColor(red: 169/255, green: 164/255, blue: 164/255, alpha: 1)
        } else {
            (cell as! PageCollectionViewCell).titleLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if (pages.count > indexPath.row) {
            let page: PageItem = pages[indexPath.row]

            if (!page.url.isEmpty) {
            
                if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                
                    guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage
                        else {
                            return
                    }
                    cStorage.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
                }
            
                showLoadingView(msg: ("\(NSLocalizedString("LoadingPage", comment: "")) \(page.name)"))
            
                let urlStr = "http://archiveofourown.org" + page.url
            
                Alamofire.request(urlStr)
                    .response(completionHandler: { response in
                        #if DEBUG
                    //  print(request)
                    //  println(response)
                        print(response.error ?? "")
                            #endif
                    
                        self.parseCookies(response)
                    
                        if let data = response.data {
                            (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(data, itemsCountHeading: "h3", worksElement: "work")
                            //self.getFeed(data)
                        }
                        self.showFeed()
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row >= works.count) {
            return
        }
        
        let newsItem:NewsFeedItem = works[indexPath.row]
        if (newsItem.workId.contains("serie")) {
            performSegue(withIdentifier: "serieDetail", sender: self)
        }
        self.performSegue(withIdentifier: "workDetail", sender: self)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch ((indexPath as NSIndexPath).row) {
        case 0, self.collectionView(collectionView, numberOfItemsInSection: (indexPath as NSIndexPath).section) - 1:
            return CGSize(width: 120, height: 28)
        default:
            return CGSize(width: 50, height: 28)
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "WorkDetail") {
            if let workDetail: UINavigationController = segue.destination as? UINavigationController {
            var row = 0
            //if (!purchased) {
            //    row = tableView.mp_indexPathForSelectedRow().row
            //} else {
                row = (tableView.indexPathForSelectedRow! as NSIndexPath).row
            //}
            
            if (row >= works.count) {
                return
            }
            
            let newsItem:NewsFeedItem = works[row]
            
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
            
           (workDetail.topViewController as! WorkDetailViewController).workItem = currentWorkItem
            (workDetail.topViewController as! WorkDetailViewController).modalDelegate = self
            }
        }else if (segue.identifier == "serieDetail") {
            if let navController: UINavigationController = segue.destination as? UINavigationController {
                if let row = tableView.indexPathForSelectedRow?.row {
                
                    if (row >= works.count) {
                        return
                    }
                
                    let newsItem:NewsFeedItem = works[row]
                    (navController.topViewController as! SerieViewController).serieId = newsItem.workId
                }
            }
            
        } else if(segue.identifier == "searchSegue") {
            if let searchController: SearchViewController = segue.destination as? SearchViewController {
                searchController.delegate = self
                searchController.modalDelegate = self
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
        let encodableURLRequest = URLRequest(url: URL( string: "http://archiveofourown.org/works/search" )!)
        var encodedURLRequest: URLRequest? = nil
        do {
            encodedURLRequest = try URLEncoding.queryString.encode(encodableURLRequest, with: queryResult)
        } catch {
            print(error.localizedDescription)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
       
        showLoadingView(msg: NSLocalizedString("Searching", comment: ""))
        
        guard let url = URL( string: (encodedURLRequest?.url?.absoluteString)!) else {
            return
        }
        let mutableURLRequest = NSMutableURLRequest(url: url)
        mutableURLRequest.httpMethod = "GET"
        
        request("http://archiveofourown.org/works/search", method: .get, parameters: queryResult, encoding: URLEncoding.queryString)
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
            (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: "work")
            //self.getFeed(d)
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
        }
        
        self.refreshControl.endRefreshing()
        
        self.showFeed()
    }
    
    override func doneButtonAction() {
        super.doneButtonAction()
        self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
    override func drawerClicked(_ sender: AnyObject) {
        
        doneButtonAction()
        super.drawerClicked(sender)
    }
    
    //MARK: - SAVE WORK TO DB
    
    var curWork:NewsFeedItem?
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
       if (sender.tag >= works.count) {
            return
        }
        
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
        
        curWork = works[sender.tag]
        
        showLoadingView(msg: "\(NSLocalizedString("DwnloadingWrk", comment: "")) \(curWork?.title ?? "")")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        request("http://archiveofourown.org/works/" + (curWork?.workId ?? ""), method: .get, parameters: params)
            .response(completionHandler: onSavedWorkLoaded(_:))
    }
    
    func onSavedWorkLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        //  println(response)
        print(response.error ?? "")
            #endif
        self.parseCookies(response)
        if let d = response.data {
            let _ = self.downloadWork(d, curWork: curWork)
            self.hideLoadingView()
        } else {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotDwnldWrk", comment: ""), type: .error, duration: 2.0)
            self.hideLoadingView()
        }
        
        curWork = nil
    }
    
    func saveWork() {
        hideLoadingView()
    }
    
    override func controllerDidClosed() {
       // if (!purchased && i%2 == 0) {
       //     showWvInterstitial()
       // }
        
        if (i % 7 == 0 && (!purchased && !donated)) {
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
                UIApplication.shared.openURL(url)
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
            
            searchApplied(query, shouldAddKeyword: false)
        }
    }
    
    //MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}


