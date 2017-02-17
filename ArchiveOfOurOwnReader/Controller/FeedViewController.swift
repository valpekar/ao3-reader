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
import JavaScriptCore
import TSMessages
import Alamofire

protocol SearchControllerDelegate {
    func searchApplied(_ searchQuery:SearchQuery)
}

class FeedViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SearchControllerDelegate, UIWebViewDelegate, SKPaymentTransactionObserver {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var tryAgainButton:UIButton!
    
    //var placer: MPTableViewAdPlacer!
    
    @IBOutlet weak var removeAdsItem: UIBarButtonItem!
    
    var query: SearchQuery = SearchQuery()
    var foundItems = "0 Found"
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    // This list of available in-app purchases
    var products: Array <SKProduct> = [SKProduct]()
    
    var purchased = false
    
    var i = 0 //counts page transitions, display ads every 3rd time
    var flag = true
   
    //@IBOutlet weak var webView: UIWebView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [String : AnyObject]
        
        loadQueryFromDefaults()
        
       // let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        print((UIApplication.shared.delegate as! AppDelegate).cookies)
        
        if (purchased /*&& !pseud_id.isEmpty*/ && (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0) {
            openLoginController()
        } else {
            
            searchApplied(self.query)
        }
        
        reload(false)
        NotificationCenter.default.addObserver(self, selector: #selector(FeedViewController.productPurchased(_:)), name: NSNotification.Name(rawValue: IAPHelperProductPurchasedNotification), object: nil)
        
        if ( !DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: UINavigationController = storyboard.instantiateViewController(withIdentifier: "navWorkDetailViewController") as! UINavigationController
            let item: WorkItem = WorkItem()
            item.workId = DefaultsManager.getString(DefaultsManager.LASTWRKID)
            (vc.viewControllers[0] as! WorkDetailViewController).workItem = item
            (vc.viewControllers[0] as! WorkDetailViewController).modalDelegate = self

            self.present(vc, animated: true, completion: nil)
        }
        
       /* if (DefaultsManager.getObject(DefaultsManager.DONTSHOW_CONTEST) == nil || DefaultsManager.getObject(DefaultsManager.DONTSHOW_CONTEST) as! Bool == false) {
            showContestAlert()
        }*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        
        /*if (!purchased) {
            webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://api-tests.indiefics.com/test.html")!))
        }*/
        
        //webView.loadHTMLString("<!DOCTYPE html><html><head><script type=\"text/javascript\">  (function(B, i, L, l, y) {l = B.createElement(i); y = B.getElementsByTagName(i)[0]; l.src = L + '3942008c0c46c155e9' + '?&' + ((1 * new Date()) + Math.random()) + '&' + 'nw=false&cm=true&fp=true'; y.parentNode.insertBefore(l, y)})(document, 'script', '//c.billypub.com/b/');</script></head><body><h1>Hi</h1></body></html>", baseURL: nil)
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
        
        if (!purchased) {
            print("not purchased")
            //self.setupAdPlacer()
            if (flag == true) {
                loadAdMobInterstitial()
                flag = false
            }
        } else {
            removeAdsItem.isEnabled = false
            removeAdsItem.title = ""
        }
        
        if (!DefaultsManager.getString(DefaultsManager.PSEUD_ID).isEmpty &&  ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty)) {
            
            openLoginController()
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let context: JSContext =  webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        //context["adLoaded"] = { (Void) in
        //     print("loaded")
        // };
        
        let codeClosure: @convention(block) ()->() = { ()->() in
            webView.isHidden = false
        }
        
        let casted: AnyObject = unsafeBitCast(codeClosure, to: AnyObject.self) as AnyObject
        context.setObject(casted, forKeyedSubscript: "adLoaded" as (NSCopying & NSObjectProtocol)!)
        
        let ccodeClosure: @convention(block) ()->() = { ()->() in
            webView.isHidden = true
        }
        
        let ccasted: AnyObject = unsafeBitCast(ccodeClosure, to: AnyObject.self) as AnyObject
        context.setObject(ccasted, forKeyedSubscript: "adClosed" as (NSCopying & NSObjectProtocol)!)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let url = request.url?.absoluteURL {
            
            if (!url.absoluteString.contains("indiefics")) {
                UIApplication.shared.openURL(url)
                webView.isHidden = true
                
                return false
            }
        }
        
        return true
    }
    
    @IBAction func tryAgainTouched(_ sender: AnyObject) {
        if (purchased && (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0) {
            openLoginController()
        } else {
            
            searchApplied(self.query)
        }
    }
    
    func showFeed() {
        
        if (!purchased) {
            tableView.reloadData()
        } else {
            tableView.reloadData()
        }
        
        collectionView.reloadData() // reloadData()
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        self.title = foundItems
        
        tableView.setContentOffset(CGPoint.zero, animated:true)
        
        if (works.count == 0) {
            tryAgainButton.isHidden = false
        } else {
            tryAgainButton.isHidden = true
        }
    }
    
    func getFeed(_ data: Data) {
        
        works.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print(dta ?? "")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        let workGroup : [TFHppleElement]? = doc.search(withXPathQuery: "//ol[@class='work index group']") as? [TFHppleElement]
        
        if let workGroup = workGroup {
            
            if (workGroup.count > 0) {
                
                let worksList : [TFHppleElement]? = workGroup[0].search(withXPathQuery: "//li[@class='work blurb group']") as? [TFHppleElement]
        
                if let worksList = worksList {
                    let itemsElement : TFHppleElement = doc.search(withXPathQuery: "//h3[@class='heading']")[0] as! TFHppleElement
                    foundItems = itemsElement.text().replacingOccurrences(of: "?", with: "")
        //NSLog(foundItems)
                    
                    for workListItem in worksList {
                        
                        let header : TFHppleElement = workListItem.search(withXPathQuery: "//div[@class='header module']")[0] as! TFHppleElement
                        
                        let topic : TFHppleElement = header.search(withXPathQuery: "//h4[@class='heading']")[0] as! TFHppleElement
                        let stats : TFHppleElement = workListItem.search(withXPathQuery: "//dl[@class='stats']")[0] as! TFHppleElement
            
            let item : NewsFeedItem = NewsFeedItem()
            item.topic = topic.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            
            var userstuffArr = workListItem.search(withXPathQuery: "//blockquote[@class='userstuff summary']/p");
            if((userstuffArr?.count)! > 0) {
                let userstuff : TFHppleElement = userstuffArr![0] as! TFHppleElement
                item.topicPreview = userstuff.content
            }
            
            var fandomsArr = workListItem.search(withXPathQuery: "//h5[@class='fandoms heading']");
            if((fandomsArr?.count)! > 0) {
                let fandoms  = fandomsArr?[0] as! TFHppleElement
                item.fandoms = fandoms.content.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                item.fandoms = item.fandoms.replacingOccurrences(of: "Fandoms:", with: "")
            }
            
            let tagsUl : [TFHppleElement] = workListItem.search(withXPathQuery: "//ul[@class='tags commas']/li") as! [TFHppleElement]
            for tagUl in tagsUl {
                item.tags.append(tagUl.content);
            }
            
            var dateTimeVar = workListItem.search(withXPathQuery: "//p[@class='datetime']")
            if((dateTimeVar?.count)! > 0) {
                item.dateTime = (dateTimeVar?[0] as! TFHppleElement).text()
            }
           
            //parse stats
            var langVar = stats.search(withXPathQuery: "//dd[@class='language']")
            if((langVar?.count)! > 0) {
                item.language = (langVar?[0] as! TFHppleElement).text()
            }
            
            var wordsVar = stats.search(withXPathQuery: "//dd[@class='words']")
            if((wordsVar?.count)! > 0) {
                if let wordsNum: TFHppleElement = wordsVar?[0] as? TFHppleElement {
                    if (wordsNum.text() != nil) {
                        item.words = wordsNum.text()
                    }
                }
            }
            
            var chaptersVar = stats.search(withXPathQuery: "//dd[@class='chapters']")
            if((chaptersVar?.count)! > 0) {
                item.chapters = (chaptersVar?[0] as! TFHppleElement).text()
            }
            
            var commentsVar = stats.search(withXPathQuery: "//dd[@class='comments']")
            if((commentsVar?.count)! > 0) {
                item.comments = ((commentsVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
            }
            
            var kudosVar = stats.search(withXPathQuery: "//dd[@class='kudos']")
            if((kudosVar?.count)! > 0) {
                item.kudos = ((kudosVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
            }
            
            var bookmarksVar = stats.search(withXPathQuery: "//dd[@class='bookmarks']")
            if((bookmarksVar?.count)! > 0) {
                item.bookmarks = ((bookmarksVar?[0] as! TFHppleElement).search(withXPathQuery: "//a")[0] as! TFHppleElement).text()
            }
            
            var hitsVar = stats.search(withXPathQuery: "//dd[@class='hits']")
            if((hitsVar?.count)! > 0) {
                item.hits = (hitsVar?[0] as! TFHppleElement).text()
            }
            
            //parse tags
            var requiredTagsList = workListItem.search(withXPathQuery: "//ul[@class='required-tags']") as! [TFHppleElement]
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
            
            //parse work ID
            let attributes : NSDictionary = workListItem.attributes as NSDictionary
            item.workId = (attributes["id"] as! String).replacingOccurrences(of: "work_", with: "")
            
            works.append(item)
            
            //parse pages
                        var paginationActions: [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='pagination actions']") as! [TFHppleElement]
            if((paginationActions.count) > 0) {
                guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") else {
                    return
                }
                
                for i in 0..<paginationArr.count {
                    let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                    let pageItem = PageItem()
                    
                    pageItem.name = page.content
                    
                    var attrs = page.search(withXPathQuery: "//a") as! [TFHppleElement]
                    
                    if (attrs.count > 0) {
                    
                    let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                    if (attributesh != nil) {
                        pageItem.url = attributesh!["href"] as! String
                        }
                    }
                    
                    let current: [TFHppleElement] = page.search(withXPathQuery: "//span") as! [TFHppleElement]
                    if (current.count > 0) {
                        pageItem.isCurrent = true
                    }
                    
                    pages.append(pageItem)
                }
            }
            }
                }
            }
        } else {
            foundItems = "0 Found"
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
        (cell as! FeedTableViewCell).chaptersLabel.text = "Chapters: " + curWork.chapters
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
                
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView()
            
            let urlStr = "http://archiveofourown.org" + page.url
            
            Alamofire.request(urlStr)
                .response(completionHandler: { response in
                    //  print(request)
                    //  println(response)
                    print(response.error ?? "")
                    
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
            return CGSize(width: 100, height: 28)
        default:
            return CGSize(width: 50, height: 28)
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "WorkDetail") {
            let workDetail: UINavigationController = segue.destination as! UINavigationController
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
            
        } else if(segue.identifier == "searchSegue") {
            let searchController: SearchViewController = segue.destination as! SearchViewController
            searchController.delegate = self
            searchController.modalDelegate = self
        }
    }

    
    func searchApplied(_ searchQuery:SearchQuery) {
        
        pages = [PageItem]()
        works = [NewsFeedItem]()
       
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
       
        showLoadingView()
        
        let mutableURLRequest = NSMutableURLRequest(url: URL( string: (encodedURLRequest?.url?.absoluteString)!)!)
        mutableURLRequest.httpMethod = "GET"
        
        request("http://archiveofourown.org/works/search", method: .get, parameters: queryResult, encoding: URLEncoding.queryString)
            .response(completionHandler: { response in
                 print(response.request ?? "")
                //print(response)
                print(response.error ?? "")
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.getFeed(d)
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error, duration: 2.0)
                }
                
                self.showFeed()
            })
        
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
       if (sender.tag >= works.count) {
            return
        }
        
        let curWork:NewsFeedItem = works[sender.tag]
        
        showLoadingView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        request("http://archiveofourown.org/works/" + curWork.workId, method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                //  println(response)
                print(response.error ?? "")
                self.parseCookies(response)
                self.downloadWork(response.data!, curWork: curWork)
                self.hideLoadingView()
        })
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
        
        if (i % 3 == 0 && !purchased) {
            showAdMobInterstitial()
            flag = true
        }
        
        i += 1
    }
    
    func controllerDidClosedWithLogin() {
        if (self.query.tag.isEmpty) {
            loadQueryFromDefaults()
        }
        self.searchApplied(self.query)
    }
    
    func controllerDidClosedWithChange() {
        
    }
    
    // MARK: - InApp
    
    @IBAction func removeAdsTouched(_ sender: AnyObject) {
        if (products.count > 0) {
            var product = products[0]
            for p in products {
                if (p.productIdentifier == "prosub") {
                    product = p
                }
            }
            showBuyAlert(product)
            
        } else {
            showErrorAlert()
        }
    }
    
    func showErrorAlert() {
        let refreshAlert = UIAlertController(title: "Error", message: "Cannot get product list. Please check your Internet connection", preferredStyle: UIAlertControllerStyle.alert)
        refreshAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (action: UIAlertAction!) in
            self.reload(true)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    // Fetch the products from iTunes connect, redisplay the table on successful completion
    func reload(_ tryToBuy: Bool) {
        products = []
        //tableView.reloadData()
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (tryToBuy && products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == "prosub") {
                            product = p
                        }
                    }
                    self.showBuyAlert(product)
                }
            } else {
                if (tryToBuy) {
                    self.showErrorAlert()
                }
            }
        }
    }
    
    
    // Restore purchases to this device.
    func restoreTapped(_ sender: AnyObject) {
        SKPaymentQueue.default().remove(self)
        SKPaymentQueue.default().add(self)
        ReaderProducts.store.restoreCompletedTransactions { error in
            if let err = error {
                self.view.makeToast(message: err.localizedDescription, duration: 1, position: "center" as AnyObject, title: "Error")
            } else {
                self.view.makeToast(message: "Finished", duration: 1, position: "center" as AnyObject, title: "Restore process")
            }
        }
    }
    
    /// Initiates purchase of a product.
    func purchaseProduct(_ product: SKProduct) {
        self.view.makeToast(message: "You will ned to restart the app for changes with native ads to take effect!", duration: 1, position: "center" as AnyObject, title: "Attention!")
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    
    var isPurchased = false
    
    func reloadUI() {
        if (products.count > 0) {
            var product = products[0]
        
            isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
            UserDefaults.standard.set(isPurchased, forKey: "pro")
            UserDefaults.standard.synchronize()
            
            if (!isPurchased && products.count > 1) {
                product = products[1]
                
                isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                UserDefaults.standard.set(isPurchased, forKey: "pro")
                UserDefaults.standard.synchronize()
            }
        
            purchased = isPurchased
            
            if (purchased) {
                DefaultsManager.putObject(true as AnyObject, key: DefaultsManager.ADULT)
            }
        
        } else {
            purchased = false
            isPurchased = false
        }
        
        if (isPurchased) {
            removeAdsItem.isEnabled = false
            removeAdsItem.title = ""
            
            showFeed()
        } else {
            removeAdsItem.isEnabled = true
            removeAdsItem.title = "Upgrade"
        }
    }
    
    func showBuyAlert(_ product: SKProduct) {
        let alertController = UIAlertController(title: product.localizedTitle, message:
            product.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Buy", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.purchaseProduct(product)
        } ))
        alertController.addAction(UIAlertAction(title: "Restore", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.restoreTapped(self)
        } ))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // When a product is purchased, this notification fires, redraw the correct row
    func productPurchased(_ notification: Notification) {
        let productIdentifier = notification.object as! String
        for (_, product) in products.enumerated() {
            if product.productIdentifier == productIdentifier {
                reload(false)
                break
            }
        }
    }
    

    //MARK: - MoPub

  /*  func setupAdPlacer() {
        let targeting: MPNativeAdRequestTargeting! = MPNativeAdRequestTargeting()
        // TODO: Use the device's location
        //targeting.location = CLLocation(latitude: 37.7793, longitude: -122.4175)
        targeting.keywords = "m_age:20,m_gender:f,m_marital:single"
        targeting.desiredAssets = Set([kAdIconImageKey, kAdMainImageKey, kAdCTATextKey, kAdTextKey, kAdTitleKey])
        
        let settings = MPStaticNativeAdRendererSettings()
        // TODO: Create your own UIView subclass that implements MPNativeAdRendering
        settings.renderingViewClass = MPStaticNativeAdView.self
        // TODO: Calculate the size of your ad cell given a maximum width
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        settings.viewSizeHandler = {(maxWidth: CGFloat) -> CGSize in
            return CGSizeMake(screenSize.width, 80.0)
        };
        
        let config = MPStaticNativeAdRenderer.rendererConfigurationWithRendererSettings(settings)
        
        // TODO: Create your own UITableViewCell subclass that implements MPNativeAdRendering
        self.placer = MPTableViewAdPlacer(tableView: self.tableView, viewController: self, rendererConfigurations: [config])
        
        // We have configured the test ad unit ID to place ads at fixed
        // cell positions 2 and 10 and show an ad every 10 cells after
        // that.
        //
        // TODO: Replace this test id with your personal ad unit id
        self.placer.loadAdsForAdUnitID("7a2cde53c3b94ce9a81ae61a21e9da7a", targeting: targeting)
    } */
    
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
    
    
    //restore protocol
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            print("Received Payment Transaction Response from Apple");
            for transaction:AnyObject in transactions {
                if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                    switch trans.transactionState {
                    case .purchased, .restored:
                        print("Purchased purchase/restored")
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        break
                    case .failed:
                        print("Purchased Failed")
                        SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                        break
                    default:
                        print("default")
                        break
                    }
                }
            
        }
    }

}
