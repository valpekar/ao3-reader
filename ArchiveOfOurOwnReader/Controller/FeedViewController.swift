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

protocol SearchControllerDelegate {
    func searchApplied(_ searchQuery:SearchQuery, shouldAddKeyword: Bool)
}

class FeedViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SearchControllerDelegate, UIWebViewDelegate, ChoosePrefProtocol {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    @IBOutlet weak var checkStatusButton:UIButton!
    
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
        
       /* if (DefaultsManager.getObject(DefaultsManager.DONTSHOW_CONTEST) == nil || DefaultsManager.getObject(DefaultsManager.DONTSHOW_CONTEST) as! Bool == false) {
            showContestAlert()
        }*/
        
        refresh(tableView)
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
            
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            collectionView.flashScrollIndicators()
        }
    }
    
    func getFeed(_ data: Data) {
        
        works.removeAll(keepingCapacity: false)
        pages.removeAll()
        
        guard let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return
        }
        #if DEBUG
        print(dta)
            #endif
        guard let doc : TFHpple = TFHpple(htmlData: data) else {
            return
        }
        
        if let workGroup : [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='work index group']") as? [TFHppleElement] {
            
            if (workGroup.count > 0) {
                
                if let worksList : [TFHppleElement] = workGroup[0].search(withXPathQuery: "//li[@class='work blurb group']") as? [TFHppleElement] {
        
                    if let itemsElement : TFHppleElement = doc.search(withXPathQuery: "//h3[@class='heading']")[0] as? TFHppleElement {
                        foundItems = itemsElement.text().replacingOccurrences(of: "?", with: "")
                        //NSLog(foundItems)
                    }
                    
                    for workListItem in worksList {
                        
                        let item : NewsFeedItem = NewsFeedItem()
                        
                        if let header : TFHppleElement = workListItem.search(withXPathQuery: "//div[@class='header module']")[0] as? TFHppleElement {
                        
                            let topic : TFHppleElement = header.search(withXPathQuery: "//h4[@class='heading']")[0] as! TFHppleElement
                            
                            item.topic = topic.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                        }
                        let stats : TFHppleElement = workListItem.search(withXPathQuery: "//dl[@class='stats']")[0] as! TFHppleElement
            
                        if let userstuffArr = workListItem.search(withXPathQuery: "//blockquote[@class='userstuff summary']/p") {
                            if(userstuffArr.count > 0) {
                                if let userstuff : TFHppleElement = userstuffArr[0] as? TFHppleElement {
                                    item.topicPreview = userstuff.content
                                }
                            }
                        }
            
                        if let fandomsArr = workListItem.search(withXPathQuery: "//h5[@class='fandoms heading']") {
                            if(fandomsArr.count > 0) {
                                let fandoms  = fandomsArr[0] as! TFHppleElement
                                item.fandoms = fandoms.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                                item.fandoms = item.fandoms.replacingOccurrences(of: "Fandoms:", with: "")
                            }
                        }
            
                        if let tagsUl : [TFHppleElement] = workListItem.search(withXPathQuery: "//ul[@class='tags commas']/li") as? [TFHppleElement] {
                            for tagUl in tagsUl {
                                item.tags.append(tagUl.content)
                            }
                        }
            
                        if let dateTimeVar = workListItem.search(withXPathQuery: "//p[@class='datetime']") {
                            if(dateTimeVar.count > 0) {
                                item.dateTime = (dateTimeVar[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
           
                        //parse stats
                        if let langVar = stats.search(withXPathQuery: "//dd[@class='language']") {
                            if(langVar.count > 0) {
                                item.language = (langVar[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        if let wordsVar = stats.search(withXPathQuery: "//dd[@class='words']") {
                            if(wordsVar.count > 0) {
                                if let wordsNum: TFHppleElement = wordsVar[0] as? TFHppleElement {
                                    if (wordsNum.text() != nil) {
                                        item.words = wordsNum.text()
                                    }
                                }
                            }
                        }
            
                        if let chaptersVar = stats.search(withXPathQuery: "//dd[@class='chapters']") {
                            if(chaptersVar.count > 0) {
                                item.chapters = (chaptersVar[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        if let commentsVar = stats.search(withXPathQuery: "//dd[@class='comments']") {
                            if(commentsVar.count > 0) {
                                item.comments = ((commentsVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        if let kudosVar = stats.search(withXPathQuery: "//dd[@class='kudos']") {
                            if(kudosVar.count > 0) {
                                item.kudos = ((kudosVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        if let bookmarksVar = stats.search(withXPathQuery: "//dd[@class='bookmarks']") {
                            if(bookmarksVar.count > 0) {
                                item.bookmarks = ((bookmarksVar[0] as? TFHppleElement)?.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        if let hitsVar = stats.search(withXPathQuery: "//dd[@class='hits']") {
                            if(hitsVar.count > 0) {
                                item.hits = (hitsVar[0] as? TFHppleElement)?.text() ?? ""
                            }
                        }
            
                        //parse tags
                        if let requiredTagsList = workListItem.search(withXPathQuery: "//ul[@class='required-tags']") as? [TFHppleElement] {
                            if(requiredTagsList.count > 0) {
                                if let requiredTags: [TFHppleElement] = (requiredTagsList[0] ).search(withXPathQuery: "//li") as? [TFHppleElement] {
               
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
                            }
                        }
            
                        //parse work ID
                        if let attributes : NSDictionary = workListItem.attributes as NSDictionary? {
                            item.workId = (attributes["id"] as? String)?.replacingOccurrences(of: "work_", with: "") ?? ""
                        }
            
                        works.append(item)
                    }
                    
                    //parse pages
                    if let paginationActions: [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='pagination actions']") as? [TFHppleElement] {
                    if((paginationActions.count) > 0) {
                        guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") else {
                            return
                        }
                        
                        for i in 0..<paginationArr.count {
                            let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                            let pageItem = PageItem()
                            
                            pageItem.name = page.content
                            
                            if let attrs = page.search(withXPathQuery: "//a") as? [TFHppleElement] {
                                if (attrs.count > 0) {
                                
                                    let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                                    if (attributesh != nil) {
                                        pageItem.url = attributesh!["href"] as? String ?? ""
                                    }
                                }
                            }
                            
                            if let current: [TFHppleElement] = page.search(withXPathQuery: "//span") as? [TFHppleElement] {
                                if (current.count > 0) {
                                    pageItem.isCurrent = true
                                }
                            }
                            
                            pages.append(pageItem)
                        }
                        }
                    }
                }
            }
        } else {
            foundItems = NSLocalizedString("0Found", comment: "")
        }
    }
    
    func loadQueryFromDefaults() {
        if (DefaultsManager.getObject(DefaultsManager.SEARCH_Q) != nil) {
            self.query = DefaultsManager.getObject(DefaultsManager.SEARCH_Q) as! SearchQuery
        }
    }
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        if (cell == nil) {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        if (works.count == 0) {
            return cell!
        }
        
        let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
        
        (cell as! FeedTableViewCell).topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        (cell as! FeedTableViewCell).fandomsLabel.text = curWork.fandoms
       
        if (curWork.topicPreview != nil) {
            (cell as! FeedTableViewCell).topicPreviewLabel.text = curWork.topicPreview
        }
        else {
            (cell as! FeedTableViewCell).topicPreviewLabel.text = ""
        }
        
        (cell as! FeedTableViewCell).datetimeLabel.text = curWork.dateTime
        (cell as! FeedTableViewCell).languageLabel.text = curWork.language
        (cell as! FeedTableViewCell).wordsLabel.text = curWork.words
        (cell as! FeedTableViewCell).chaptersLabel.text = NSLocalizedString("Chapters_", comment: "") + curWork.chapters
        (cell as! FeedTableViewCell).commentsLabel.text = curWork.comments
        (cell as! FeedTableViewCell).kudosLabel.text = curWork.kudos
        (cell as! FeedTableViewCell).bookmarksLabel.text = curWork.bookmarks
        (cell as! FeedTableViewCell).hitsLabel.text = curWork.hits
       // cell?.completeLabel.text = curWork.complete
       // cell?.categoryLabel.text = curWork.category
       // cell?.ratingLabel.text = curWork.rating
        
        
        var tagsString = ""
        if (curWork.tags.count > 0) {
            tagsString = curWork.tags.joined(separator: ", ")
        }
        (cell as! FeedTableViewCell).tagsLabel.text = tagsString
        
        (cell as! FeedTableViewCell).downloadButton.tag = (indexPath as NSIndexPath).row
        
        return cell!
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
            
                showLoadingView(msg: ("\(NSLocalizedString("LoadingPage", comment: "")) \(indexPath.row)"))
            
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
                            self.getFeed(data)
                        }
                        self.showFeed()
                })
            }
        }
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
            self.getFeed(d)
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
        }
        
        self.refreshControl.endRefreshing()
        
        self.showFeed()
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
        
      //  if (flag == true) {
      //      webView.hidden = false
     //   }
        
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
    
    //Mark: - ChoosePrefProtocol
    func prefChosen(pref: String) {
        query.fandom_names = pref
        DefaultsManager.putObject(query, key: DefaultsManager.SEARCH_Q)
        
        self.searchApplied(self.query, shouldAddKeyword: false)
    }
    

}
