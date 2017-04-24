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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.title = "Recommendations"
        
        descLabel.text = "Recommendations are based on your activity inside the app and are generated every week since you first open this page. Your data is not transferred anywhere and is used only to generate recommendations. (Available for Pro users only)"
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            if (pp) {
                generateRecommendations()
            } else if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
                if (dd) {
                    generateRecommendations()
                }
            } else {
                TSMessage.showNotification(in: self, title: "Error", subtitle: "Sorry, you have not purchased the Pro Version!", type: .error)
            }
        }
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
        notification.alertBody = "Hi! It's time for new recommendations!"
        notification.alertAction = "See them"
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
            
            descLabel.text = "Recommendations are based on your activity inside the app and are generated every week since you first open this page. Your data is not transferred anywhere and is used only to generate recommendations. (Available for Pro users only)" + "\nLast update: " + dateFormatter.string(from: Date())
            
            
            UIApplication.shared.cancelAllLocalNotifications()
            scheduleLocal()
            
            return
        }
        
        let days = howManyDaysHavePassed(lastDate as! Date, today: Date())
        
        descLabel.text = "Recommendations are based on your activity inside the app and are generated every week since you first open this page. Your data is not transferred anywhere and is used only to generate recommendations. (Available for Pro users only)" + "\nLast update: " + dateFormatter.string(from: lastDate as! Date)
        
        if (days == 7) {
            
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
            
            showLoadingView(msg: "Getting works")
            
            let mutableURLRequest = NSMutableURLRequest(url: URL( string: (encodedURLRequest!.url?.absoluteString)!)!)
            mutableURLRequest.httpMethod = "GET"
            
            request("http://archiveofourown.org/works/search", parameters: queryResult, encoding: URLEncoding.queryString)
                .response(completionHandler: { response in
                    //print(request)
                    //print(response)
                    print(response.error ?? "")
                    if let d = response.data {
                        self.parseCookies(response)
                        self.getFeed(d)
                        self.showFeed()
                    } else {
                        self.hideLoadingView()
                        self.view.makeToast(message: "Check your Internet connection", duration: 2.0, position: "center" as AnyObject)
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
        
        showLoadingView(msg: "Getting works")
        
        let urlStr: String = (encodedURLRequest?.url?.absoluteString)!
        
        let mutableURLRequest = NSMutableURLRequest(url: URL( string: urlStr)!)
        mutableURLRequest.httpMethod = "GET"
        
        let surlStr = "http://archiveofourown.org/works/search"
        
        Alamofire.request(surlStr, parameters: queryResult, encoding: /*ParameterEncoding.Custom(encodeParams) */ URLEncoding.httpBody)
            .response(completionHandler: { response in
                //print(request ?? "")
                //print(response ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    self.getFeed(d)
                    self.showFeed()
                } else {
                    self.hideLoadingView()
                    self.view.makeToast(message: "Check your Internet connection", duration: 2.0, position: "center" as AnyObject)
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
    }
    
    func getFeed(_ data: Data) {
        
        works.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        //var dta = NSString(data: data, encoding: NSUTF8StringEncoding)
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
                        var requiredTagsList = workListItem.search(withXPathQuery: "//ul[@class='required-tags']")
                        if((requiredTagsList?.count)! > 0) {
                            var requiredTags = (requiredTagsList?[0] as AnyObject).search(withXPathQuery: "//li") as! [TFHppleElement]
                            
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
                        
                        //parse work ID
                        let attributes : NSDictionary = workListItem.attributes as NSDictionary
                        item.workId = (attributes["id"] as! String).replacingOccurrences(of: "work_", with: "")
                        
                        works.append(item)
                        
                        //parse pages
                        var paginationActions = doc.search(withXPathQuery: "//ol[@class='pagination actions']")
                        if((paginationActions?.count)! > 0) {
                            guard let paginationArr = (paginationActions?[0] as AnyObject).search(withXPathQuery: "//li") else {
                                return
                            }
                            
                            for i in 0..<paginationArr.count {
                                let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                                let pageItem = PageItem()
                                
                                pageItem.name = page.content
                                
                                let attrs = page.search(withXPathQuery: "//a") as! [TFHppleElement]
                                
                                if (attrs.count > 0) {
                                    
                                    let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                                    if (attributesh != nil) {
                                        pageItem.url = attributesh!["href"] as! String
                                    }
                                }
                                
                                let current = page.search(withXPathQuery: "//span") as! [TFHppleElement]
                                if (current.count > 0) {
                                    pageItem.isCurrent = true
                                }
                                
                                pages.append(pageItem)
                            }
                        }
                    }
                }
            }
        }
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
        cell?.chaptersLabel.text = "Chapters: " + curWork.chapters
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
}
