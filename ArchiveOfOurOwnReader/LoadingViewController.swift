 //
//  LoadingViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 9/29/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import KRProgressHUD
import CoreTelephony
import Firebase
import RxSwift

class LoadingViewController: CenterViewController, ModalControllerDelegate, AuthProtocol, UIAlertViewDelegate {
    
    
    static var uncategorized = "Uncategorized"
    
    var activityView: UIActivityIndicatorView!
    var loadingView: UIView!
    var loadingLabel: UILabel!
    
    
    var isAdult = false
    var isSafe = true
    
    var triedTo = -1
    
    private var notification: NSObjectProtocol?
    
    var xcsrfToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notification = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) {
            [unowned self] notification in
            
            self.checkAuth()
        }
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "onlyDarkBlue")
        appearance.titleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.white ]
        self.navigationController?.navigationBar.standardAppearance = appearance;
        self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
    }
    
    func checkAuth() {
        let needsAuth: Bool = DefaultsManager.getBool(DefaultsManager.NEEDS_AUTH) ?? false
        if (needsAuth == true) {
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let newViewController = storyBoard.instantiateViewController(withIdentifier: "AuthNavController") as? UINavigationController {
                self.present(newViewController, animated: true, completion: {
                    (newViewController.topViewController as? AuthViewController)?.authDelegate = self
                })
            }
            //self.performSegue(withIdentifier: "authSegue", sender: self)
        } else {
            loadAfterAuth()
        }
    }
    
    func authFinished(success: Bool) {
//        if (success == true) {
//            loadAfterAuth()
//        }
    }
    
    func loadAfterAuth() {
        
    }
    
    deinit {
        if let notification = notification {
            NotificationCenter.default.removeObserver(notification)
        }
    }
    
    func showNav() {
        
        if let navVC = self.navigationController {
            
            navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navVC.navigationBar.shadowImage = UIImage()
            navVC.navigationBar.isTranslucent = false
        }
    }
    
    
    func doInsteadOfAd() {
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                        
        self.isAdult = true
        
        if let safe = DefaultsManager.getBool(DefaultsManager.SAFE) {
           self.isSafe = safe
        }
        
        applyTheme()
    }
    
    
    override func applyTheme() {
        super.applyTheme()
    }
    
    func logout() {
        
        Alamofire.request("https://archiveofourown.org/users/logout", method: .get, parameters: [:])
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                #endif
        })
        
        let s: [String:String] = [:]
        
        DefaultsManager.putString("", key: DefaultsManager.LOGIN)
        DefaultsManager.putString("", key: DefaultsManager.PSWD)
        DefaultsManager.putString("", key: DefaultsManager.PSEUD_ID)
        DefaultsManager.putString("", key: DefaultsManager.TOKEN)
        DefaultsManager.putObject(s as AnyObject, key: DefaultsManager.PSEUD_IDS)
        
        (UIApplication.shared.delegate as! AppDelegate).cookies = [HTTPCookie]()
        (UIApplication.shared.delegate as! AppDelegate).token = ""
        DefaultsManager.putObject([HTTPCookie]() as AnyObject, key: DefaultsManager.COOKIES)
        
        Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies([HTTPCookie](), for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
    }
    
    func showLoadingView(msg: String) {
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        
        /*let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height*/
        
       loadingView = UIView(frame:CGRect(x: 100, y: 100, width: 180, height: 170))
        
        let colorDark = UIColor(named: "global_tint")!
        
        DispatchQueue.main.async {
            KRProgressHUD.set(activityIndicatorViewColors: [colorDark, AppDelegate.redBrightTextColor])
                .show(withMessage: msg)
        }
    }
    
    func hideLoadingView() {
        #if DEBUG
        print("hide loading view")
            #endif
        
        DispatchQueue.main.async {
        KRProgressHUD.dismiss()
        }
        
//        if (activityView != nil && activityView.isAnimating) {
//            activityView.stopAnimating()
//        }
        if (loadingView != nil && loadingView.superview != nil) {
            loadingView.removeFromSuperview()
            loadingView = nil
        }
    }
    
    
    func sendUpdateWorkRequest(id: String, title: String, published: String, updated: String, chapters: String) {
        let reqDeviceToken = DefaultsManager.getString(DefaultsManager.REQ_DEVICE_TOKEN)
        
        var params:[String:Any] = [String:Any]()
        params["id"] = id
        params["title"] = title
        params["published"] = published
        if (updated.isEmpty == false) {
            params["updated"] = updated
        }
        params["chapters"] = chapters
        
        var headers:[String:String] = [String:String]()
        headers["auth"] = reqDeviceToken
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        let url = "https://fanfic-pocket-reader.herokuapp.com/api/works"
        
        Alamofire.request(url, method: HTTPMethod.put, parameters: params, headers: headers).response(completionHandler: { (response) in
            print(response.error ?? "")
            
            if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
                
            }
            
            if (response.response?.statusCode == 200) {
                print("update work ok")
            }
        })
    }
    
    // MARK: - Downloading work
    
    var chapters: [ChapterOnline] = [ChapterOnline]()
    
    func downloadWork(_ data: Data, curWork: NewsFeedItem? = nil, workItemOld: WorkItem? = nil, workItemToReload: DBWorkItem? = nil) -> DBWorkItem? {
        
        var workItem : DBWorkItem! = nil
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return workItemToReload
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        var wid = ""
        if let curWork = curWork {
            wid = curWork.workId
        } else if let wItemOld = workItemOld {
            wid = wItemOld.workId
        }
        
        if (workItemToReload == nil && workItem == nil) {
            
            let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
            let predicate = NSPredicate(format: "workId == %@", wid)
            req.predicate = predicate
            do {
                if let fetchedWorks = try managedContext.fetch(req) as? [DBWorkItem] {
                    if (fetchedWorks.count > 0) {
                        workItem = fetchedWorks.first
                    }
                }
            } catch {
                fatalError("Failed to fetch works: \(error)")
            }
            
            if (workItem == nil) {
            
            guard let entity = NSEntityDescription.entity(forEntityName: "DBWorkItem",  in: managedContext) else {
                return workItemToReload
            }
            workItem = DBWorkItem(entity: entity, insertInto:managedContext)
            }
        } else if (workItemToReload != nil) {
            workItem = workItemToReload
        }
        
        workItem.needsUpdate = 0
        
        var err: NSError?
        
        chapters = [ChapterOnline]()
        
        if let curWork = curWork {
            
            workItem.setValue(curWork.warning, forKey: "archiveWarnings")
            workItem.setValue(curWork.title, forKey: "workTitle")
            workItem.setValue(curWork.topic, forKey: "topic")
            workItem.setValue(curWork.topicPreview, forKey: "topicPreview")
            workItem.setValue(curWork.tags.joined(separator: ", "), forKey: "tags")
            workItem.setValue(curWork.dateTime, forKey: "datetime")
            workItem.setValue(curWork.language, forKey: "language")
            workItem.setValue(curWork.words, forKey: "words")
            workItem.setValue(curWork.comments, forKey: "comments")
            workItem.setValue(curWork.kudos, forKey: "kudos")
            workItem.setValue(curWork.chapters, forKey: "chaptersCount")
            workItem.setValue(curWork.bookmarks, forKey: "bookmarks")
            workItem.setValue(curWork.hits, forKey: "hits")
            workItem.setValue(curWork.rating, forKey: "ratingTags")
            workItem.setValue(curWork.category, forKey: "category")
            workItem.setValue(curWork.complete, forKey: "complete")
            workItem.setValue(curWork.workId, forKey: "workId")
            workItem.setValue(Date(), forKey: "dateAdded")
            
        } else if (workItemOld != nil) {
            workItem.setValue(workItemOld!.archiveWarnings, forKey: "archiveWarnings")
            workItem.setValue(workItemOld!.workTitle, forKey: "workTitle")
            workItem.setValue(workItemOld!.topic, forKey: "topic")
            workItem.setValue(workItemOld!.topicPreview, forKey: "topicPreview")
            workItem.setValue(workItemOld!.tags, forKey: "tags")
            workItem.setValue(workItemOld!.datetime, forKey: "datetime")
            workItem.setValue(workItemOld!.language, forKey: "language")
            workItem.setValue(workItemOld!.words, forKey: "words")
            workItem.setValue(workItemOld!.comments, forKey: "comments")
            workItem.setValue(workItemOld!.kudos, forKey: "kudos")
            workItem.setValue(workItemOld!.chaptersCount, forKey: "chaptersCount")
            workItem.setValue(workItemOld!.bookmarks, forKey: "bookmarks")
            workItem.setValue(workItemOld!.hits, forKey: "hits")
            workItem.setValue(workItemOld!.ratingTags, forKey: "ratingTags")
            workItem.setValue(workItemOld!.category, forKey: "category")
            workItem.setValue(workItemOld!.complete, forKey: "complete")
            workItem.setValue(workItemOld!.workId, forKey: "workId")
            workItem.setValue(Date(), forKey: "dateAdded")
        }
        
        //var dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        // println("the string is: \(dta)")
        let doc: TFHpple = TFHpple(htmlData: data)
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
        
        if(sorrydiv.count>0) {
            if let sorrydivFirst = sorrydiv[0] as? TFHppleElement {
                if (sorrydivFirst.text().range(of: "Sorry") != nil) {
                    workItem.setValue(Localization("Sorry"), forKey: "author")
                    workItem.setValue(Localization("WrkAvailOnlyRegistered"), forKey: "workTitle")
                    workItem.setValue("", forKey: "complete")
                    //   return NEXT_CHAPTER_NOT_EXIST;
                    return workItemToReload
                }
            }
        }
        }
        
        if let caution = doc.search(withXPathQuery: "//p[@class='caution']") {
        
        if (caution.count>0 && (caution[0] as? TFHppleElement)?.text().range(of: "adult content") != nil) {
            workItem.setValue(Localization("Sorry"), forKey: "author")
            workItem.setValue(Localization("ContainsAdultContent"), forKey: "workTitle")
            workItem.setValue("", forKey: "complete")
            
            return workItemToReload
        }
        }
        
        // var landmark = doc.searchWithXPathQuery("//h6[@class='landmark heading']")
        
        var firstFandom: String = ""
        var firstRelationship: String = ""
        
        if let workmeta: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='work meta group']") as? [TFHppleElement] {
        
        if(workmeta.count > 0) {
            if let ratings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='rating tags']/ul[@class='commas']/li") as? [TFHppleElement] {
                if (ratings.count > 0) {
                    workItem.setValue(ratings[0].content, forKey: "ratingTags")
                }
            }
            
            if let archiveWarnings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='warning tags']/ul[@class='commas']/li") as? [TFHppleElement] {
                workItem.archiveWarnings = ""
                for i in 0..<archiveWarnings.count {
                    if var warnStr = archiveWarnings[i].content {
                        if (warnStr.contains("Underage")) {
                            warnStr = warnStr.replacingOccurrences(of: "Underage", with: "Archive Warnings")
                            // isSensitive = true
                        }
                        if (warnStr.contains("Rape")) {
                            warnStr = warnStr.replacingOccurrences(of: "Rape", with: "Warning: Violence")
                            // isSensitive = true
                        }
                        
                        workItem.archiveWarnings?.append(warnStr)
                        if (i < archiveWarnings.count - 1) {
                            workItem.archiveWarnings?.append(", ")
                        }
                    }
                    
                }
            }
            
            if let freeformTags: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='freeform tags']/ul[@class='commas']/li") as? [TFHppleElement] {
                workItem.freeform = ""
                for i in 0..<freeformTags.count {
                    workItem.freeform?.append(freeformTags[i].content)
                    if (i < freeformTags.count - 1) {
                        workItem.freeform?.append(", ")
                    }
                }
            }
            
            if let fandomsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='fandom tags']/ul[@class='commas']/li") as? [TFHppleElement] {
            
                workItem.mutableSetValue(forKey: "fandoms").removeAllObjects()
                let workFandoms = workItem.mutableSetValue(forKey: "fandoms")

            for i in 0..<fandomsLiArr.count {
                let entityf =  NSEntityDescription.entity(forEntityName: "DBFandom",  in: managedContext)
                let f = NSManagedObject(entity: entityf!, insertInto:managedContext)
                f.setValue(fandomsLiArr[i].content, forKey: "fandomName")
                firstFandom = fandomsLiArr[i].content
                if let element = fandomsLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement,
                   let attributes = element.attributes as? [String: String] {
                    f.setValue((attributes["href"] as? String ?? ""), forKey: "fandomUrl")
                }
                            
                workFandoms.add(f)
                
                let works = f.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem!)
            }
            }
            
            //   var categoryLiArr: [TFHppleElement] = workmeta[0].searchWithXPathQuery("//dd[@class='category tags']/ul[@class=*]/li") as! [TFHppleElement]
            //
            //   var categoryStr = ""
            //  for i in 0..<categoryLiArr.count {
            //
            //     categoryStr += categoryLiArr[i].text() + " "
            //  }
            // workItem.setValue(categoryStr, forKey: "category")
            
            if let relationshipsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='relationship tags']/ul[@class='commas']/li") as? [TFHppleElement] {
                workItem.mutableSetValue(forKey: "relationships").removeAllObjects()
                let workRel = workItem.mutableSetValue(forKey: "relationships")
            
            for i in 0..<relationshipsLiArr.count {
                let entityr =  NSEntityDescription.entity(forEntityName: "DBRelationship",  in: managedContext)
                let r = NSManagedObject(entity: entityr!, insertInto:managedContext)
                r.setValue(relationshipsLiArr[i].content, forKey: "relationshipName")
                firstRelationship = relationshipsLiArr[i].content
                let href = (relationshipsLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement)?
                             .attributes["href"] as? String ?? ""
                r.setValue(href, forKey: "relationshipUrl")
                
                workRel.add(r)
                
                let works = r.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem!)
            }
            }
            
            if let charactersLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='character tags']/ul[@class='commas']/li") as? [TFHppleElement] {

                workItem.mutableSetValue(forKey: "characters").removeAllObjects()
                let workCharacters = workItem.mutableSetValue(forKey: "characters")

            for i in 0..<charactersLiArr.count {
                let entityc =  NSEntityDescription.entity(forEntityName: "DBCharacterItem",  in: managedContext)
                let c = NSManagedObject(entity: entityc!, insertInto:managedContext)
                c.setValue(charactersLiArr[i].content, forKey: "characterName")
                if let aElement = charactersLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement,
                   let href = aElement.attributes["href"] as? String {
                    c.setValue(href, forKey: "characterUrl")
                } else {
                    c.setValue("", forKey: "characterUrl") // fallback if href not found
                }
                
                workCharacters.add(c)
                
                let works = c.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem!)
            }
            }
            
            if let languageEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='language']") as? [TFHppleElement] {
            if(languageEl.count > 0) {
                let language = languageEl[0].text().replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                
                workItem.setValue(language, forKey: "language")
            }
            }
            
            if (workItem.serieUrl?.isEmpty ?? true) {
            
                if let seriesEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='series']//span[@class='position']") as? [TFHppleElement] {
                    if(seriesEl.count > 0) {
                        let sTxt = seriesEl[0].content.replacingOccurrences(of: "\n", with:"")
                        .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                        if (!sTxt.isEmpty) {
                            //  workItem.topicPreview = "\(sTxt) \n\n\(workItem.topicPreview ?? "")"
                        
                            workItem.serieName = sTxt
                        }
                    
                        workItem.serieUrl = (seriesEl[0].search(withXPathQuery: "//a").first as? TFHppleElement)?
                                                .attributes["href"] as? String ?? ""
                    }
                }
            }
            
            if let statsElDt: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dt") as? [TFHppleElement],
                let statsElDd: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dd") as? [TFHppleElement] {
                if(statsElDt.count > 0 && statsElDd.count > 0) {
                
                    var statsStr = ""
                    for i in 0..<statsElDt.count {
                        statsStr += statsElDt[i].text() + " "
                        if ((statsElDd.count > i) && (statsElDd[i].text() != nil)) {
                            statsStr += statsElDd[i].text() + " "
                        }
                    }
                    workItem.setValue(statsStr, forKey: "stats")
                }
            }
            
            var stats : TFHppleElement? = nil
            let statsEl: [TFHppleElement]? =  workmeta[0].search(withXPathQuery: "//dl[@class='stats']") as? [TFHppleElement]
            if (statsEl?.count ?? 0 > 0) {
                stats = statsEl?[0]
            }
            
            //Mark: - parse stats
            
            //Mark: - parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let datesEl = stats?.search(withXPathQuery: "//dd[@class='status']") as? [TFHppleElement], datesEl.count > 0 {
                workItem.datetime = datesEl[0].text() ?? ""
            } else if let datesEl: [TFHppleElement] = stats?.search(withXPathQuery: "//dd[@class='published']") as? [TFHppleElement], datesEl.count > 0 {
                workItem.datetime = datesEl[0].text() ?? ""
            }
            
            if let dt = workItem.datetime, dt.isEmpty == false {
                if let date = dateFormatter.date(from: dt) {
                    dateFormatter.dateFormat = "dd MMM yyyy"
                    workItem.datetime = dateFormatter.string(from: date)
                }
            }
            
            //Mark: - parse other stats
            
            if let langVar = stats?.search(withXPathQuery: "//dd[@class='language']") {
                if(langVar.count > 0) {
                    workItem.language = (langVar[0] as? TFHppleElement)?.text() ?? ""
                }
            }  else {
                workItem.language = "-"
            }
            
            if let wordsVar = stats?.search(withXPathQuery: "//dd[@class='words']") {
                if(wordsVar.count > 0) {
                    if let wordsNum: TFHppleElement = wordsVar[0] as? TFHppleElement {
                        if (wordsNum.text() != nil) {
                            workItem.words = wordsNum.text()
                        }
                    }
                }
            }
            
            if let chaptersVar = stats?.search(withXPathQuery: "//dd[@class='chapters']") {
                if(chaptersVar.count > 0) {
                    workItem.chaptersCount = (chaptersVar[0] as? TFHppleElement)?.text() ?? ""
                }
            }
            
            if let commentsVar = stats?.search(withXPathQuery: "//dd[@class='comments']") {
                if(commentsVar.count > 0) {
                    workItem.comments = (commentsVar[0] as? TFHppleElement)?.text() ?? ""
                } else {
                    workItem.comments = "0"
                }
            }
            
            if let kudosVar = stats?.search(withXPathQuery: "//dd[@class='kudos']") {
                if(kudosVar.count > 0) {
                    workItem.kudos = (kudosVar[0] as? TFHppleElement)?.text() ?? ""
                } else {
                    workItem.kudos = "0"
                }
            }
            
            if let bookmarksVar = stats?.search(withXPathQuery: "//dd[@class='bookmarks']") {
                if(bookmarksVar.count > 0) {
                    workItem.bookmarks = (bookmarksVar[0] as? TFHppleElement)?.text() ?? ""
                } else {
                    workItem.bookmarks = "0"
                }
            }
            
            if let hitsVar = stats?.search(withXPathQuery: "//dd[@class='hits']") {
                if(hitsVar.count > 0) {
                    workItem.hits = (hitsVar[0] as? TFHppleElement)?.text() ?? ""
                } else {
                    workItem.hits = "0"
                }
            }
        }
        }
        
        if let h2El = doc.search(withXPathQuery: "//h2[@class='title heading']") as? [TFHppleElement] {
        if (h2El.count > 0) {
            var title = h2El.first?.raw.replacingOccurrences(of: "\n", with:"")
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil) ?? ""
            title = title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            workItem.setValue(title, forKey: "workTitle")
        }
        }
        
        if let bylineHeadingEl = doc.search(withXPathQuery: "//div[@id='workskin']//div[@class='preface group']/h3[@class='byline heading']") as? [TFHppleElement] {
        if (bylineHeadingEl.count > 0) {
            let authorStr = bylineHeadingEl[0].content.replacingOccurrences(of: "\n", with:"")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            
            workItem.setValue(authorStr, forKey: "author")
        }
        }
        
        if let summaryEl = doc.search(withXPathQuery: "//div[@class='summary module']//blockquote[@class='userstuff']") as? [TFHppleElement],
            summaryEl.count > 0 {
            let summaryStr = summaryEl[0].content.replacingOccurrences(of: "\n", with:"")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            
            workItem.topicPreview = summaryStr
        }
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            if (workContentEl.count > 0) {
            var workContentStr = workContentEl[0].raw ?? ""
            
            //var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
                
                let regex1:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive)
                workContentStr = regex1.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
            
            workItem.setValue(workContentStr, forKey: "workContent")
            
            var chptName = ""
            if let chapterNameEl = doc.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
                var str: String = chapterNameEl.first?.raw ?? ""
                str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                str = str.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)

                chptName = str
            }
            
            var chpt = ChapterOnline()
            chpt.content = workContentStr
            chpt.url = chptName
            
            chapters.append(chpt)
            }
        }
        
        let navigationEl: [TFHppleElement]? = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement]
        if let nxt: [TFHppleElement] = navigationEl?.first?.search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement],
            let nxtFirst = nxt.first {
            
            guard let aEl: TFHppleElement = nxtFirst.search(withXPathQuery: "//a")[0] as? TFHppleElement else {
                   return workItemToReload
            }
            let attributes : NSDictionary = aEl.attributes as NSDictionary
            
            guard let next : String = (attributes["href"] as? String) else {
                return workItemToReload
            }
                
            if (!next.isEmpty) {
                    
                workItem.setValue(next, forKey: "nextChapter")
                    
                var params:[String:AnyObject] = [String:AnyObject]()
                params["view_adult"] = "true" as AnyObject?
                    
                Alamofire.request("https://archiveofourown.org" + next, parameters: params).response(completionHandler: { response in
                    
                    #if DEBUG
                        print(response.request ?? "")
                        print(response.error ?? "")
                    #endif
                        if let data = response.data {
                            self.showLoadingView(msg: Localization("LoadingNxtChapter"))
                            self.parseNxtChapter(data, curworkItem: workItem, managedContext: managedContext)
                        }
                        
                })
            } /*else {
                saveChapters(workItem, managedContext: managedContext)
                hideLoadingView()
            }*/
        } else {
            saveChapters(workItem, managedContext: managedContext)
            hideLoadingView()
        }
        
        //save to DB
        do {
            try managedContext.save()
            hideLoadingView()
        } catch let error as NSError {
            err = error
            #if DEBUG
            print("Could not save \(String(describing: err?.userInfo))")
                #endif
            hideLoadingView()
            
            self.showError(title: Localization("Error"), message: "Could not save \(err?.localizedDescription ?? "")")
            
            return nil
        }
        
        saveToAnalytics(workItem.author ?? "", category: workItem.value(forKey: "category") as? String ?? "", mainFandom: firstFandom, mainRelationship: firstRelationship)
        
        if let wId = workItem.workId {
            self.saveWorkNotifItem(workId: wId, wasDeleted: NSNumber(booleanLiteral: false))
            self.sendAllNotSentForNotif()
        }
        
        
        self.showSuccess(title: Localization("Success"), message: "Work has been downloaded! You can access if from Downloaded screen")
        
        if let wRl = workItemToReload {
            return wRl
        } else {
            return workItem
        }
    }
    
    func saveChapters(_ curworkItem: NSManagedObject, managedContext: NSManagedObjectContext) {
        
        #if DEBUG
        print("save chapters begin")
            #endif
        
     //   if let appDelegate = UIApplication.shared.delegate as? AppDelegate
      //  {
        
            var err: NSError?
        
            var workChapters = NSMutableSet()
            if let wc = curworkItem.value(forKeyPath: "chapters") as? NSMutableSet {
                workChapters = wc
            } /*else {
                curworkItem.setValue(workChapters, forKey: "chapters")
            }*/
        
            for item in workChapters {
                managedContext.delete(item as! NSManagedObject)
            }
            
//            if (workChapters.count > 0) {
//                workChapters.removeAllObjects()
//            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                err = error
                #if DEBUG
                print("Could not save \(String(describing: err?.userInfo))")
                #endif
            }
        
            for i in 0..<chapters.count {
            
                if let wid = curworkItem.value(forKey: "id") as? Int {
                
                    let entity =  NSEntityDescription.entity(forEntityName: "DBChapter",  in: managedContext)
                    let chapter = NSManagedObject(entity: entity!, insertInto:managedContext)
            
                    chapter.setValue(i, forKey: "chapterIndex")
                    chapter.setValue(wid * 10000 + i, forKey: "id")
                    chapter.setValue(curworkItem, forKey: "workItem")
                    chapter.setValue(chapters[i].content, forKey: "chapterContent")
                    chapter.setValue(chapters[i].url, forKey: "chapterName")
                    chapter.setValue(NSNumber(value: 0), forKey: "unread")
            
                    workChapters.add(chapter)
            
                    do {
                        try managedContext.save()
                    } catch let error as NSError {
                        err = error
                        #if DEBUG
                        print("Could not save \(String(describing: err?.userInfo))")
                        #endif
                    }
                }
            }
            
            curworkItem.setValue(workChapters, forKey: "chapters")
        
            #if DEBUG
            print("save chapters end")
            #endif
        /*} else {
            #if DEBUG
            print("save chapters end with error")
            #endif
        }*/
    }
    
    func parseNxtChapter(_ data: Data, curworkItem: NSManagedObject, managedContext: NSManagedObjectContext) {
        
        //let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            var workContentStr = workContentEl.first?.raw ?? ""
        
            //var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
            
            let regex1:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex1.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
        
            var chptName = ""
            if let chapterNameEl = doc.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
                var str: String = chapterNameEl.first?.raw ?? ""
                str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                str = str.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                
                chptName = str
            }
            
            var chpt = ChapterOnline()
            chpt.content = workContentStr
            chpt.url = chptName
            
            chapters.append(chpt)
            
        }
        
        let navigationEl: [TFHppleElement]? = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement]
        if let nxt: [TFHppleElement] = navigationEl?.first?.search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement],
            let nxtFirst = nxt.first {
                    
                    if let atrs = nxtFirst.search(withXPathQuery: "//a") ,
                        let firstAttribute = atrs.first {
                        if let element = firstAttribute as? TFHppleElement,
                           let next = element.attributes["href"] as? String {
                            
                                if (!next.isEmpty) {
                                    var params:[String:AnyObject] = [String:AnyObject]()
                                    params["view_adult"] = "true" as AnyObject?
                                
                                    let urlStr: String = "https://archiveofourown.org" + next
                                
                                    Alamofire.request(urlStr, parameters: params)
                                        .response(completionHandler: { response in
                                        
                                            #if DEBUG
                                            print(response.request ?? "")
                                            print(response.error ?? "")
                                                #endif
                                            if let d = response.data {
                                                self.parseNxtChapter(d, curworkItem: curworkItem, managedContext: managedContext)
                                            }
                                        })
                                }
                                }
                            }
                        
                    } else {
                        saveChapters(curworkItem, managedContext: managedContext)
            DispatchQueue.main.async {
                self.hideLoadingView()
            }
                        
                    }
    }
    
    func saveToAnalytics(_ author: String, category: String, mainFandom: String, mainRelationship: String) {
       
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
            let entity =  NSEntityDescription.entity(forEntityName: "AnalyticsItem",  in: managedContext)
            if let analyticsItem: AnalyticsItem = NSManagedObject(entity: entity!, insertInto:managedContext) as? AnalyticsItem {
                analyticsItem.setValue(author, forKey: "author")
                analyticsItem.setValue(category, forKey: "category")
                analyticsItem.setValue(mainFandom, forKey: "fandom")
                analyticsItem.setValue(mainRelationship, forKey: "relationship")
                analyticsItem.setValue(Date(), forKey: "date")
        
        
                var err: NSError?
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    err = error
                    #if DEBUG
                    print("Could not save \(String(describing: err)), \(String(describing: err?.userInfo))")
                    #endif
                }
            } else {
            #if DEBUG
                print("Could not save AppDel = nil")
            #endif

            }
    }
    
    func getDownloadedStats() -> [CheckDownloadItem] {
        
        var result: [CheckDownloadItem] = []
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return result
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let downloadedWorks = fetchedResults {
                for downloadedWork in downloadedWorks {
                    var item = CheckDownloadItem()
                    item.date = downloadedWork.datetime ?? ""
                    item.workId = downloadedWork.workId ?? ""
                    
                    result.append(item)
                }
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        return result
    }
    
    func getWorkById(workId: String) -> DBWorkItem? {
        var res: DBWorkItem?
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return res
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        fetchRequest.fetchLimit = 1
        let searchPredicate: NSPredicate = NSPredicate(format: "workId = %@", workId)
        
        fetchRequest.predicate = searchPredicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let results = fetchedResults {
                res = results.first
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        return res
    }
    
    func updateAppBadge() {
        let worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        UIApplication.shared.applicationIconBadgeNumber = worksToReload.count
    }
    
    func queryComponents(_ key: String, value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value: value)
                
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value: value)
            }
        } else {
            let escapedString = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            components.append((key, "\(escapedString!)"))
        }
        
        return components
    }
    
    func query(_ parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sorted(by: <) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key, value: value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }
    
    //Encoding
    
    struct SearchParamEncoding: ParameterEncoding {
        private let array: [String]
        
        init(array: [String]) {
            self.array = array
        }
        
        func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            var urlRequest = urlRequest.urlRequest
            
            let data = try JSONSerialization.data(withJSONObject: array, options: [])
            
            if urlRequest?.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest?.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            urlRequest?.httpBody = data
            
            return urlRequest!
        }
    }
    
    func encode(_ one:URLRequestConvertible, parameters:[String: AnyObject]?) -> (NSMutableURLRequest, NSError?) {
        let str: String = (one.urlRequest?.url?.absoluteString)!
        let mutableURLRequest = NSMutableURLRequest(url: URL(string: str)!) //one.urlRequest.mutableCopy() as! NSMutableURLRequest
        
      /*  if let method = Method(rawValue: mutableURLRequest.HTTPMethod) , encodesParametersInURL(method) {
            if let URLComponents = URLComponents(url: mutableURLRequest.url!, resolvingAgainstBaseURL: false) {
                //  var ulr = NSURL(string:"\(mutableURLRequest.URL!.absoluteString)?=" +  query(parameters!))
                let str = query(parameters!)
                //  NSLog(mutableURLRequest.URL!.absoluteString + "?=" +  str)
                mutableURLRequest.url = URL(string:mutableURLRequest.url!.absoluteString + "?=" +  str)
            }
        } else {
            if mutableURLRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
            
            mutableURLRequest.httpBody = query(parameters!).data(using: String.Encoding.utf8, allowLossyConversion: false)
        }
         */
        
        return (mutableURLRequest,nil)
    }
    
    func parseCookies(_ response: DefaultDataResponse) {
       // let headers = response.allHeaderFields
        guard let resp = response.response else {
            return
        }
        guard var allHeaders = resp.allHeaderFields as? [String: String] else {
            return
        }
        
        allHeaders["user_credentials"] = "1"
        
        let cookiesH: [HTTPCookie] = HTTPCookie.cookies(withResponseHeaderFields: allHeaders, for: URL(string: AppDelegate.ao3SiteUrl)!)
            //let cookies = headers["Set-Cookie"]
        if cookiesH.count > 0 {
            (UIApplication.shared.delegate as? AppDelegate)?.cookies = cookiesH
            DefaultsManager.putObject(cookiesH as AnyObject, key: DefaultsManager.COOKIES)
        }
        
       // print(cookies)
    }
    
    //MARK: - login
    
    var openLogin = false
    
    func openLoginController(force: Bool = true) {
        if (openLogin == false || force == true) {
            let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
            (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
        
            self.present(nav, animated: true, completion: nil)
            
            openLogin = true
        }
    }
    
    func controllerDidClosed() {
        
    }
    
    func addDoneButtonOnKeyboard(_ textField: UITextView)
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.backgroundColor = UIColor.white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: Localization("Done"), style: UIBarButtonItem.Style.done, target: self, action: #selector(LoadingViewController.doneButtonAction))
        done.tintColor = UIColor(named: "global_tint")
        
        var items: [UIBarButtonItem] = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
        
    }
    
    func addDoneButtonOnKeyboardTf(_ textField: UITextField)
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.backgroundColor = UIColor(red: 198/255, green: 208/255, blue: 209/255, alpha: 1)
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: Localization("Done"), style: UIBarButtonItem.Style.done, target: self, action: #selector(LoadingViewController.doneButtonAction))
        done.tintColor = UIColor(named: "global_tint")
        
        var items: [UIBarButtonItem] = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func doneButtonAction() {
    }
    
    func countWroksFromDB() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return 0
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            let count = try managedContext.count(for: fetchRequest)
            
            return count
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            return 0
        }
    }
    
    func makeRoundButton(button: UIButton) {
         button.layer.cornerRadius = AppDelegate.smallCornerRadius
    }
    func makeRoundView(view: UIView) {
        view.layer.cornerRadius = AppDelegate.smallCornerRadius
    }
        
    
    func doDownloadWork(wId: String, isOnline: Bool, wasSaved: Bool) {
        
        downloadWorkForSure(wId: wId, isOnline: isOnline)
        
    }
    
    func downloadWorkForSure(wId: String, isOnline: Bool) {
        showLoadingView(msg: Localization("DwnloadingWrk"))
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            }
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
                
        var vadult = ""
        params["view_adult"] = "true" as AnyObject?
        vadult = "?view_adult=true"
        
        //purchased = true
        
        
        if (isOnline == true) {
            Alamofire.request("https://archiveofourown.org/works/" + wId + vadult, method: .get, parameters: params)
                .response(completionHandler: onOnlineWorkLoaded(_:))
        } else {
            
            Alamofire.request("https://archiveofourown.org/works/" + wId + vadult, method: .get, parameters: params)
                .response(completionHandler: onSavedWorkLoaded(_:))
        }
    }
    
    func onSavedWorkLoaded(_ response: DefaultDataResponse) {
        
    }
    
    func onOnlineWorkLoaded(_ response: DefaultDataResponse) {
        
    }
    
    func kudosToAnalytics() {
        
    }
}

 //MARK: - remote notifications
 
 extension LoadingViewController {
    
    
    func saveWorkNotifItem(workId: String, wasDeleted: NSNumber) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "DBWorkNotifItem",  in: managedContext) else {
            return
        }
        let nItem = DBWorkNotifItem(entity: entity, insertInto:managedContext)
        nItem.workId = workId
        nItem.isItemDeleted = wasDeleted
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(String(describing: error.userInfo))")
        }
    }
    
    func deleteWorkNotifItem(notifItem: DBWorkNotifItem) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(notifItem as NSManagedObject)
        do {
            try managedContext.save()
        } catch _ {
            NSLog("Cannot delete notif item")
        }
    }
    
    func deleteWorkNotifItemById(workId: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkNotifItem")
        
        let searchPredicate = NSPredicate(format: "workId == %@ ", workId)
        fetchRequest.predicate = searchPredicate
        fetchRequest.fetchLimit = 1
        
        var notifItem: NSManagedObject?
        
        do {
            if let fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject], fetchedResults.count > 0  {
                notifItem = fetchedResults.first
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        if let _ = notifItem {
            managedContext.delete(notifItem!)
        }
        do {
            try managedContext.save()
        } catch _ {
            NSLog("Cannot delete notif item")
        }
    }
    
    func getAllWorkNotifItems(areDeleted: NSNumber) -> [DBWorkNotifItem] {
        var res: [DBWorkNotifItem] = []
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return res
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkNotifItem")
        
        let searchPredicate = NSPredicate(format: "isItemDeleted == %@ ", areDeleted)
        fetchRequest.predicate = searchPredicate
        
        do {
            if let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkNotifItem]  {
                res = fetchedResults
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        return res
    }
    
    func sendRequestWorkDownloadedForNotif(workIds: [String]) {
        let deviceToken = DefaultsManager.getString(DefaultsManager.REQ_DEVICE_TOKEN)
        
        var params:[String:Any] = [String:Any]()
        params["works"] = workIds
        
        var headers:[String:String] = [String:String]()
        headers["auth"] = deviceToken
        
        let url = "https://fanfic-pocket-reader.herokuapp.com/api/downloads"
        
        Alamofire.request(url,
                          method: .post,
                          parameters: params,
                          encoding: URLEncoding.default,
                          headers: headers).response(completionHandler: { (response) in
            
                            switch(response.response?.statusCode ?? 0) {
                            case 200:
                                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                                    print(responseString)
                                    
                                    for workId in workIds {
                                        self.deleteWorkNotifItemById(workId: workId)
                                    }
                                }
                                break
                                
                            default:
                                print(response.error?.localizedDescription ?? "")
                                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                                    print(responseString)
                                }
                                
                                break
                                
                            }
        })
    }
    
    func sendRequestWorkDeletedForNotif(workIds: [String]) {
        let deviceToken = DefaultsManager.getString(DefaultsManager.REQ_DEVICE_TOKEN)
        
        var headers:[String:String] = [String:String]()
        headers["auth"] = deviceToken
        
        var urlStr = "https://fanfic-pocket-reader.herokuapp.com/api/downloads/" //"http://192.168.100.49/api/downloads"
        var count = 0
        for workId in workIds {
            urlStr.append(workId)
            if (count < workIds.count - 1) {
               urlStr.append(",")
            }
            count = count + 1
        }
        
        Alamofire.request(urlStr, method: HTTPMethod.delete, headers: headers).response(completionHandler: { (response) in
            
            switch(response.response?.statusCode ?? 0) {
            case 200:
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print(responseString)
                    
                    for workId in workIds {
                        self.deleteWorkNotifItemById(workId: workId)
                    }
                }
                break
                
            default:
                print(response.error?.localizedDescription ?? "")
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print(responseString)
                }
                break
                
            }
            
            if let err = response.error {
                print(err.localizedDescription)
            } else {
                for workId in workIds {
                    self.deleteWorkNotifItemById(workId: workId)
                }
            }
        })
    }

    func sendAllNotSentForNotif() {
        var notSentDownloadedWorks: [DBWorkNotifItem] = getAllWorkNotifItems(areDeleted: NSNumber(booleanLiteral: false))
        
        var workIds: [String] = []
        
        for notSentDownloadedWork in notSentDownloadedWorks {
            if let wId = notSentDownloadedWork.workId {
                workIds.append(wId)
            }
        }
        
        notSentDownloadedWorks = []
        
        if (workIds.count > 0) {
            sendRequestWorkDownloadedForNotif(workIds: workIds)
        }
    }
    
    func sendAllNotSentForDelete() {
        var notSentDownloadedWorks: [DBWorkNotifItem] = getAllWorkNotifItems(areDeleted: NSNumber(booleanLiteral: true))
        
        var workIds: [String] = []
        
        for notSentDownloadedWork in notSentDownloadedWorks {
            if let wId = notSentDownloadedWork.workId {
                workIds.append(wId)
            }
        }
        
        notSentDownloadedWorks = []
        
        if (workIds.count > 0) {
            sendRequestWorkDeletedForNotif(workIds: workIds)
        }
    }
    
    func parseNotifWorkResponse(_ data: Data) {
        let jsonWithObjectRoot = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = jsonWithObjectRoot as? [String: Any] {
            if let result = dictionary["result"] as? String,
                let workId = dictionary["workId"] as? String {
                if (result == "ok") {
                    self.deleteWorkNotifItemById(workId: workId)
                }
            }
        }
    }
 }
 
 
 //MARK: - kudos
 
 extension LoadingViewController {
    
    func doLeaveKudos(workId: String, kudosToken: String) -> Observable<Void> {
        if ((UIApplication.shared.delegate as? AppDelegate)?.cookies.count == 0 || ((UIApplication.shared.delegate as? AppDelegate)?.token ?? "").isEmpty) {
            triedTo = 0
            openLoginController() 
            return Observable.empty()
        }
        
        showLoadingView(msg: Localization("LeavingKudos"))
        
        let requestStr = "https://archiveofourown.org/kudos.js"
        //let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        var params:[String:Any] = [String:Any]()
     //   params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = kudosToken
        
        params["kudo"] = ["commentable_id": workId,
                          "commentable_type": "Work",
                          
        ]
        
        if let cookies = (UIApplication.shared.delegate as? AppDelegate)?.cookies,
            cookies.count > 0 {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies(cookies,
                                                                                                 for: URL(string: AppDelegate.ao3SiteUrl),
                                                                                                 mainDocumentURL: nil)
        }
        
        let headers: HTTPHeaders = [
            "referer": "https://archiveofourown.org/works/\(workId)",
            "content-type": "application/x-www-form-urlencoded;charset=UTF-8",
            "origin": "https://archiveofourown.org",
            "User-Agent": "iOS Safari",
            "Host": "archiveofourown.org",
            "Accept-Encoding": "gzip, deflate, br",
            "Accept-Language": "en-GB,en;q=0.9",
            "Accept": "*/*",
            "X-Requested-With": "XMLHttpRequest",
            "x-newrelic-id": "VQcCWV9RGwIJVFFRAw==",
            "x-csrf-token": xcsrfToken
        ]
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            return Observable.create({ (observer) -> Disposable in
                Alamofire.request(requestStr, method: .post, parameters: params,
                                  encoding: URLEncoding.httpBody,
                                  headers: headers)
                    .response(completionHandler: { response in
                        #if DEBUG
                        print(response.request ?? "")
                        // print(response.response ?? "")
                        print(response.error ?? "")
                        #endif
                        
                        if let d = response.data {
                            self.parseCookies(response)
                            self.parseAddKudosResponse(d)
                            self.hideLoadingView()
                            
                            observer.onNext(())
                            observer.onCompleted()
                            
                        } else {
                            self.hideLoadingView()
                            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                            
                            observer.onError(ErrorsAF.noResponseData)
                        }
                    })
                return Disposables.create()
            })
           
            
        } else {
            
            self.hideLoadingView()
            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
            
            return Observable.error(ErrorsAF.noInternet)
        }
    }
    
    func parseAddKudosResponse(_ data: Data) {
        guard let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return
        }
        //print("the string is: \(dta)")
        
        if (dta.contains("errors") == true) {
            self.showError(title: Localization("Error"), message: dta as String)
        } else if (dta.contains("#kudos") == true) {
            
            self.showSuccess(title: Localization("Kudos"), message: Localization("KudosAdded"))
            
            self.kudosToAnalytics()
        }
        
    }
    
    func getCountryCode() -> String {
        if let countryCode = NSLocale.current.regionCode {
            print("country code = \(countryCode)")
            return countryCode
        } else {
            return ""
        }
    }
    
    func showAddFolder(folderName: String) {
        let alert = UIAlertController(title: "Folder", message: "Add New Group", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.text = folderName
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if let txt = textField?.text {
                
                self.addNewFolder(name: txt)
                Analytics.logEvent("New_folder", parameters: ["name": txt as NSObject])
            } else {
                self.showError(title: Localization("Error"), message: Localization("FolderNameEmpty"))
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: Localization("Cancel"), style: UIAlertAction.Style.cancel, handler: { (action) in
            #if DEBUG
            print("cancel")
            #endif
        }))
        
        alert.view.tintColor = UIColor(named: "global_tint")
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewFolder(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Folder")
        let predicate = NSPredicate(format: "name == %@", name)
        req.predicate = predicate
        do {
            if let fetchedWorks = try managedContext.fetch(req) as? [Folder] {
                if (fetchedWorks.count > 0) {
                    self.showError(title: Localization("Error"), message: Localization("FolderAlreadyExists"))
                    return
                }
            }
        } catch {
            debugLog(message: "Failed to fetch folders: \(error)")
            fatalError("Failed to fetch folders: \(error)")
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Folder",  in: managedContext) else {
            return
        }
        let newFolder = Folder(entity: entity, insertInto:managedContext)
        newFolder.name = name
        
        //save to DB
        do {
            try managedContext.save()
        } catch let error as NSError {
            #if DEBUG
            print("Could not save \(String(describing: error.userInfo))")
            #endif
        }
        
        //        tableView.reloadData()
    }
 }

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: true)
        return request
    }
    
}

 extension Float {
    
    func formatUsingAbbrevation () -> String {
        let numFormatter = NumberFormatter()
        
        typealias Abbrevation = (threshold:Double, divisor:Double, suffix:String)
        let abbreviations:[Abbrevation] = [(0, 1, ""),
                                           (1000.0, 1000.0, "K"),
                                           (100_000.0, 1_000_000.0, "M"),
                                           (100_000_000.0, 1_000_000_000.0, "B")]
        // you can add more !
        
        let startValue = Double (abs(self))
        let abbreviation:Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if (startValue < tmpAbbreviation.threshold) {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        } ()
        
        let value = Double(self) / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1
        
        return numFormatter.string(from: NSNumber (value:value)) ?? ""
    }
 }

 
 
struct FandomObject {
    
    var sectionName : String!
    var sectionObject : String!
    
    var isSelected = false
 }

 protocol GetFandomsProtocol {
    func fandomsGot(fandoms:[FandomObject])
 }

