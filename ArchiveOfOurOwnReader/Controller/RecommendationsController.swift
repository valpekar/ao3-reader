//
//  RecommendationsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/11/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import RMessage
import Alamofire
import Crashlytics
import UserNotifications

class RecommendationsController : ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    @IBOutlet weak var descLabel:UILabel!
    
    var refreshControl: UIRefreshControl!
    
    var analyticsItems : [NSManagedObject] = [NSManagedObject]()
    
    var shouldReload = true
    
    var noFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.foundItems = "0 Found"
        self.worksElement = "work"
        self.itemsCountHeading = "h3"
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(RecommendationsController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.title = NSLocalizedString("Recommendations", comment: "")
        descLabel.text = NSLocalizedString("RecommendationsExplainedShort", comment: "")
        
        //test!
        scheduleLocal()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
        
        showNav()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
       refresh(tableView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldReload = true
    }
    
    @objc func refresh(_ sender: AnyObject) {
        if (shouldReload || noFound) {
            UserDefaults.standard.synchronize()
            if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool, pp == true {
                    generateRecommendations()
                } else if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool , dd == true {
                        generateRecommendations()
                } else {
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("NotPurchased", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                    })
                    
                    refreshControl.endRefreshing()
                }
        }
    }
    
    @IBAction func infoTouched(_ sender: AnyObject) {
        let refreshAlert = UIAlertController(title: NSLocalizedString("Recommendations", comment: ""), message: NSLocalizedString("RecommendationsExplained", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
            DefaultsManager.putBool(true, key: DefaultsManager.CONTENT_SHOWSN)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
   
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
            self.descLabel.textColor = UIColor.black
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.collectionView.backgroundColor = AppDelegate.redDarkColor
            self.descLabel.textColor = UIColor.lightText
        }
    }
    
    func scheduleLocal() {
        
        let needsNotifications = DefaultsManager.getBool(DefaultsManager.NOTIFY) ?? true
        
        if (needsNotifications == false) {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: NSLocalizedString("TimeForRecommendations", comment: ""), arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: NSLocalizedString("SeeThem", comment: ""),
                                                                arguments: nil)
      //  content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        var dateInfo = DateComponents()
        dateInfo.hour = 19
        dateInfo.minute = 00
        dateInfo.weekday = 6 //friday = 6, sunday = 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "UserRecommendations", content: content, trigger: trigger)
        
        // Schedule the request.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
        
//        let notification = UILocalNotification()
//        notification.fireDate = Date(timeIntervalSinceNow: 84600 * 7)
//        notification.alertBody = NSLocalizedString("SeeThem", comment: "")
//        notification.alertAction = NSLocalizedString("TimeForRecommendations", comment: "")
//        notification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
//        notification.soundName = UILocalNotificationDefaultSoundName
//        notification.repeatInterval = .weekOfMonth // .WeekOfMonth //Minute
//        //notification.userInfo = ["CustomField1": "w00t"]
//        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    
    func generateRecommendations() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        guard let lastDate = DefaultsManager.getObject(DefaultsManager.LAST_DATE) else {
            generateNewRecs()
            DefaultsManager.putObject(Date() as AnyObject, key: DefaultsManager.LAST_DATE)
            
            descLabel.text = "\(NSLocalizedString("RecommendationsExplainedShort", comment: "")) \(NSLocalizedString("LastUpdate_", comment: "")) \(dateFormatter.string(from:  Date()))"
            
            
            //UIApplication.shared.cancelAllLocalNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            scheduleLocal()
            
            return
        }
        
        let days = howManyDaysHavePassed(lastDate as? Date ?? Date(), today: Date())
        
        descLabel.text = "\(NSLocalizedString("RecommendationsExplainedShort", comment: "")) \(NSLocalizedString("LastUpdate_", comment: "")) \(dateFormatter.string(from: lastDate as? Date ?? Date()))"
        
        if (days >= 7 || noFound) {
            
            generateNewRecs()
            DefaultsManager.putObject(Date() as AnyObject, key: DefaultsManager.LAST_DATE)
            
           // UIApplication.shared.cancelAllLocalNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            scheduleLocal()
            
        } else {
            var searchQuery = SearchQuery()
            
            if (DefaultsManager.getObject(DefaultsManager.SEARCH_Q_RECOMMEND) != nil) {
                searchQuery = DefaultsManager.getObject(DefaultsManager.SEARCH_Q_RECOMMEND) as! SearchQuery
            }
            
            let queryResult = searchQuery.formQuery()
            let encodableURLRequest = URLRequest(url: URL( string: "https://archiveofourown.org/works/search" )!)
            var encodedURLRequest: URLRequest? = nil
            do {
                encodedURLRequest = try URLEncoding.queryString.encode(encodableURLRequest, with: queryResult)
            } catch {
                print(error)
            }
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
            
            let mutableURLRequest = NSMutableURLRequest(url: URL( string: (encodedURLRequest!.url?.absoluteString)!)!)
            mutableURLRequest.httpMethod = "GET"
            
            request("https://archiveofourown.org/works/search", parameters: queryResult, encoding: URLEncoding.queryString)
                .response(completionHandler: { response in
                    #if DEBUG
                    print(request)
                    //print(response)
                    print(response.error ?? "")
                        #endif
                    if let d = response.data {
                        self.parseCookies(response)
                        let checkItems = self.getDownloadedStats()
                        (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: "work", downloadedCheckItems: checkItems)
                        //self.getFeed(d)
                        self.showWorks()
                    } else {
                        self.hideLoadingView()
                        RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                            
                        })
                    }
                })
        }
    }
    
    func loadAnalyticsFromDB() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return 
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
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
        
        if (analyticsItems.count == 0) {
            RMessage.showNotification(in: self, title: "Not enough data", subtitle: "Please use the app at least for few hours to let it collect data to build recommendations for you!", type: RMessageType.success, customTypeName: "", callback: {
                
            })
            return
        }
        
        let randF = Int(arc4random_uniform(UInt32(analyticsItems.count - 1)))
        let randC = Int(arc4random_uniform(UInt32(analyticsItems.count - 1)))
        let randR = Int(arc4random_uniform(UInt32(analyticsItems.count - 1)))
        
        for aitem in analyticsItems {
            
            if (count == randF || count == randC || count == randR) {
            
                if (!searchQuery.tag.isEmpty) {
                    searchQuery.tag += " || "
                }
                
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
//            if (count != analyticsItems.count - 1) {
//                searchQuery.tag += " || "
//            }
            }
            //searchQuery.categories.append(aitem.valueForKey("category") as! String)
            
            count += 1
        }
        
        
        DefaultsManager.putObject(searchQuery, key: DefaultsManager.SEARCH_Q_RECOMMEND)
        
        Answers.logCustomEvent(withName: "Recs_generated",
                               customAttributes: [
                                "query_tag": searchQuery.tag])
        
        applySearch(searchQuery)
    }
    
    func applySearch(_ searchQuery: SearchQuery) {
        pages = [PageItem]()
        works = [NewsFeedItem]()
        
        let queryResult = searchQuery.formQuery()
        let encodableURLRequest = URLRequest(url: URL( string: "https://archiveofourown.org/works/search" )!)
        var encodedURLRequest: URLRequest? = nil
        do {
            encodedURLRequest = try URLEncoding.queryString.encode(encodableURLRequest, with: queryResult)
        } catch {
            print(error.localizedDescription)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
        
        let urlStr: String = (encodedURLRequest?.url?.absoluteString)!
        
        let mutableURLRequest = NSMutableURLRequest(url: URL( string: urlStr)!)
        mutableURLRequest.httpMethod = "GET"
        
        let surlStr = "https://archiveofourown.org/works/search"
        
        Alamofire.request(surlStr, method: .get, parameters: queryResult, encoding: URLEncoding.queryString)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                //print(response ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h3", worksElement: "work", downloadedCheckItems: checkItems)
                    //self.getFeed(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
                self.refreshControl.endRefreshing()
            })
        
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableViewRowAnimation.automatic)
    }

    //MARK: - get and show feed
    
    override func showWorks() {
        
        refreshControl.endRefreshing()
        
        tableView.reloadData()
        collectionView.reloadData()
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        self.title = foundItems
        
        if (tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0) {
            tableView.setContentOffset( CGPoint(x: 0, y: 0) , animated: true)
        }
        collectionView.flashScrollIndicators()
        
        if (works.count == 0) {
            noFound = true
            
            generateNewRecs()
        }
    }
    
    
    //MARK: - tableview
    
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
        
        let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
        
        cell = fillCellXib(cell: cell, curWork: curWork, needsDelete: false, index: indexPath.row)
        
        cell.workCellView.tag = indexPath.row
        cell.workCellView.downloadButtonDelegate = self
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCell(row: indexPath.row, works: works)
    }
    
    //MARK: - collectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        var cell: PageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PageCollectionViewCell
        
        cell = fillCollCell(cell: cell, page: pages[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: AppDelegate.smallCollCellWidth, height: 28)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCollCell(indexPath: indexPath, sender: self.collectionView)
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
    
    //MARK: - SAVE WORK TO DB
    
    
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
