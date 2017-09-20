//
//  RecommendationsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/11/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import TSMessages
import Alamofire

class RecommendationsController : LoadingViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    @IBOutlet weak var descLabel:UILabel!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    var analyticsItems : [NSManagedObject] = [NSManagedObject]()
    var foundItems = "0 Found"
    
    var shouldReload = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.title = NSLocalizedString("Recommendations", comment: "")
        descLabel.text = NSLocalizedString("RecommendationsExplainedShort", comment: "")
        
        //test!
        //generateRecommendations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (shouldReload) {
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            if (pp) {
                generateRecommendations()
            } else if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
                if (dd) {
                    generateRecommendations()
                }
            } else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("NotPurchased", comment: ""), type: .error)
            }
        }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldReload = true
    }
    
    @IBAction func infoTouched(_ sender: AnyObject) {
        let refreshAlert = UIAlertController(title: NSLocalizedString("Recommendations", comment: ""), message: NSLocalizedString("RecommendationsExplained", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
            DefaultsManager.putBool(true, key: DefaultsManager.CONTENT_SHOWSN)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
   
    func scheduleLocal() {
        
        guard let settings = UIApplication.shared.currentUserNotificationSettings else { return }
        
        if settings.types == UIUserNotificationType() {
           /* let ac = UIAlertController(title: "Can't schedule", message: "Either we don't have permission to schedule notifications, or we haven't asked yet.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(ac, animated: true, completion: nil) */
            return
        }
        
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 84600 * 7)
        notification.alertBody = NSLocalizedString("SeeThem", comment: "")
        notification.alertAction = NSLocalizedString("TimeForRecommendations", comment: "")
        notification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.repeatInterval = .weekOfMonth // .WeekOfMonth //Minute
        //notification.userInfo = ["CustomField1": "w00t"]
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    
    func generateRecommendations() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        guard let lastDate = DefaultsManager.getObject(DefaultsManager.LAST_DATE) else {
            generateNewRecs()
            DefaultsManager.putObject(Date() as AnyObject, key: DefaultsManager.LAST_DATE)
            
            descLabel.text = "\(NSLocalizedString("RecommendationsExplainedShort", comment: "")) \(NSLocalizedString("LastUpdate_", comment: "")) \(dateFormatter.string(from:  Date()))"
            
            
            UIApplication.shared.cancelAllLocalNotifications()
            scheduleLocal()
            
            return
        }
        
        let days = howManyDaysHavePassed(lastDate as! Date, today: Date())
        
        descLabel.text = "\(NSLocalizedString("RecommendationsExplainedShort", comment: "")) \(NSLocalizedString("LastUpdate_", comment: "")) \(dateFormatter.string(from: lastDate as? Date ?? Date()))"
        
        if (days >= 7) {
            
            generateNewRecs()
            DefaultsManager.putObject(Date() as AnyObject, key: DefaultsManager.LAST_DATE)
            
            UIApplication.shared.cancelAllLocalNotifications()
            scheduleLocal()
            
        } else {
            var searchQuery = SearchQuery()
            
            if (DefaultsManager.getObject(DefaultsManager.SEARCH_Q_RECOMMEND) != nil) {
                searchQuery = DefaultsManager.getObject(DefaultsManager.SEARCH_Q_RECOMMEND) as! SearchQuery
            }
            
            let queryResult = searchQuery.formQuery()
            let encodableURLRequest = URLRequest(url: URL( string: "http://archiveofourown.org/works/search" )!)
            var encodedURLRequest: URLRequest? = nil
            do {
                encodedURLRequest = try URLEncoding.queryString.encode(encodableURLRequest, with: queryResult)
            } catch {
                print(error)
            }
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
            
            let mutableURLRequest = NSMutableURLRequest(url: URL( string: (encodedURLRequest!.url?.absoluteString)!)!)
            mutableURLRequest.httpMethod = "GET"
            
            request("http://archiveofourown.org/works/search", parameters: queryResult, encoding: URLEncoding.queryString)
                .response(completionHandler: { response in
                    #if DEBUG
                    //print(request)
                    //print(response)
                    print(response.error ?? "")
                        #endif
                    if let d = response.data {
                        self.parseCookies(response)
                        (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: "work")
                        //self.getFeed(d)
                        self.showFeed()
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
                    }
                })
        }
    }
    
    func loadAnalyticsFromDB() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"AnalyticsItem")
        fetchRequest.fetchLimit = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            
            if let results = fetchedResults {
                analyticsItems = results
            }
        } catch {
            print("cannot fetch.")
        }
    }
    
    func howManyDaysHavePassed(_ lastDate: Date, today: Date) -> Int {
        let startDate: Date = lastDate
        let endDate: Date = today
        
        let gregorian: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let components: DateComponents = (gregorian as NSCalendar).components(.day, from:startDate, to:endDate, options: .matchFirst)
        let days = components.day
        return days!
    }
    
    func generateNewRecs() {
        loadAnalyticsFromDB()
        
        let searchQuery:SearchQuery = SearchQuery()
        
        var count = 0
        
        for aitem in analyticsItems {
            searchQuery.tag += "("
            if (!searchQuery.tag.contains(aitem.value(forKey: "fandom") as! String)) {
                //searchQuery.tag += ", "
                searchQuery.tag += aitem.value(forKey: "fandom") as! String
            }
            
            
            if (!searchQuery.tag.contains(aitem.value(forKey: "relationship") as! String)) {
                searchQuery.tag += ", "
                searchQuery.tag += aitem.value(forKey: "relationship") as! String
            }
            
            searchQuery.tag += ")"
            if (count != analyticsItems.count - 1) {
                searchQuery.tag += " || "
            }
            
            //searchQuery.categories.append(aitem.valueForKey("category") as! String)
            
            count += 1
        }
        
        
        DefaultsManager.putObject(searchQuery, key: DefaultsManager.SEARCH_Q_RECOMMEND)
        
        applySearch(searchQuery)
    }
    
    func applySearch(_ searchQuery: SearchQuery) {
        pages = [PageItem]()
        works = [NewsFeedItem]()
        
        let queryResult = searchQuery.formQuery()
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
        
        showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
        
        let urlStr: String = (encodedURLRequest?.url?.absoluteString)!
        
        let mutableURLRequest = NSMutableURLRequest(url: URL( string: urlStr)!)
        mutableURLRequest.httpMethod = "GET"
        
        let surlStr = "http://archiveofourown.org/works/search"
        
        Alamofire.request(surlStr, parameters: queryResult, encoding: /*ParameterEncoding.Custom(encodeParams) */ URLEncoding.httpBody)
            .response(completionHandler: { response in
                #if DEBUG
                //print(request ?? "")
                //print(response ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: "work")
                    //self.getFeed(d)
                    self.showFeed()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error, duration: 2.0)
                }
            })
        
    }

    //MARK: - get and show feed
    
    func showFeed() {
        
        tableView.reloadData()
        collectionView.reloadData()
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        self.title = foundItems
        
        if (tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        collectionView.flashScrollIndicators()
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
        cell?.wordsLabel.text = curWork.words
        cell?.chaptersLabel.text = NSLocalizedString("Chapters_", comment: "") + curWork.chapters
        cell?.commentsLabel.text = curWork.comments
        cell?.kudosLabel.text = curWork.kudos
        cell?.bookmarksLabel.text = curWork.bookmarks
        cell?.hitsLabel.text = curWork.hits
        /*cell?.completeLabel.text = curWork.complete
         cell?.categoryLabel.text = curWork.category
         cell?.ratingLabel.text = curWork.rating*/
        
        let tagsString:NSString = curWork.tags.joined(separator: ", ") as NSString
        cell?.tagsLabel.text = tagsString as String
        
        cell?.downloadButton.tag = (indexPath as NSIndexPath).row
        cell?.deleteButton.tag = (indexPath as NSIndexPath).row
        cell?.deleteButton.isHidden = true
        
        return cell!
    }

    
    //MARK: - collectionView
    
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch ((indexPath as NSIndexPath).row) {
        case 0, self.collectionView(collectionView, numberOfItemsInSection: (indexPath as NSIndexPath).section) - 1:
            return CGSize(width: 100, height: 28)
        default:
            return CGSize(width: 50, height: 28)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: "")) \(page.name)")
            
            Alamofire.request("http://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                #if DEBUG
                print(response.error ?? "")
                    #endif
                if let data = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(data, itemsCountHeading: "h3", worksElement: "work")
                    //self.getFeed(data)
                    self.showFeed()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
            
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "recDetail") {
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
            
            currentWorkItem.id = Int64(Int(newsItem.workId)!)
            
            (workDetail.viewControllers[0] as! WorkDetailViewController).workItem = currentWorkItem
            (workDetail.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
        }
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
    
    //MARK: - ModalControllerDelegate
    
    override func controllerDidClosed() {
        shouldReload = false
    }
    
    func controllerDidClosedWithChange() {
        shouldReload = false
    }
}
