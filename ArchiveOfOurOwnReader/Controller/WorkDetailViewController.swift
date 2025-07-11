//
//  WorkDetailViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 8/26/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import Firebase
import RxSwift
import FirebaseCrashlytics

enum ErrorsAF : Error {
    case noResponseData
    case noInternet
    case noWorkId
    case noCookies
}

class WorkDetailViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    let disposeBag = DisposeBag()
    
    var modalDelegate: ModalControllerDelegate?
    
    var loginPublishSubject = PublishSubject<Void>()
    
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var kudosButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var downloadedWorkItem: DBWorkItem! = nil
    var downloadedFandoms: [DBFandom]! = nil
    var downloadedRelationships: [DBRelationship]! = nil
    var downloadedCharacters: [DBCharacterItem]! = nil
    
    var workItem: WorkItem! = nil
    var fandoms: [Fandom]!
    var relationships: [Relationship]!
    var characters: [CharacterItem]!
    var warnings: [String] = [String]()
    
    var workUrl: String = ""
    
    var indexesToHide: [Int]!
    
    var bookmarked = false
    var markedForLater = false
    var needReload = false
    var bookmarkId = ""
    
    var bookmarkToken = ""
    var kudosToken = ""
    
    var changedSmth = false
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var NEXT_CHAPTER_EXIST = 1
    var NEXT_CHAPTER_NOT_EXIST = -1
    
    var commentsUrl = ""
    var tagUrl = ""
    
    var isSensitive = false
    
    var fromNotif = false
    
    var downloadUrls: [String:String] = [:]
    
    var authToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        }
        
        let name = String(format:"b%d", Int(arc4random_uniform(5)))
        bgImage.image = UIImage(named:name)
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.layoutMargins = .init(top: 0.0, left: 20, bottom: 0.0, right: 20)
        tableView.separatorInset = tableView.layoutMargins
        tableView.isScrollEnabled = false
                
        self.bgView.layer.cornerRadius = Constants.smallCornerRadius
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        if (workUrl.isEmpty == false) {
            let workIdArr = workUrl.split(separator: "/")
            if (workIdArr.count > 0) {
                let workId = String(workIdArr[workIdArr.count - 1])
                
                downloadedWorkItem = getWorkById(workId: workId)
            }
            if (downloadedWorkItem != nil) {
                
                showDownloadedWork()
                self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
            } else {
                workItem = WorkItem()
                showOnlineWork(workUrl)
            }
        } else if (workItem != nil) {
            
            let checkItems = self.getDownloadedStats()
            for downloadedItem in checkItems {
                if (downloadedItem.workId == workItem.workId) {
                    workItem.isDownloaded = true
                    
                    if (downloadedItem.date != workItem.datetime) {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd MMM yyyy"
                        if let oldDate = dateFormatter.date(from: downloadedItem.date),
                            let newDate = dateFormatter.date(from: workItem.datetime),
                            oldDate <= newDate {
                            workItem.needReload = true
                        }
                    }
                }
            }
            
            if (workItem.isDownloaded == true) {
                
                if let downloadedWork = getWorkById(workId: workItem.workId) {
                    self.downloadedWorkItem = downloadedWork
                    self.updateWork(workItem: workItem)
                    self.workItem = nil
                    self.showDownloadedWork()
                    self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
                } else {
                    showOnlineWork()
                }
                
            } else {
                showOnlineWork()
            }
        } else if (downloadedWorkItem != nil) {
            showDownloadedWork()
            self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
        }
        
        
        if (self.fromNotif == true) {
            Analytics.logEvent("WorkDetail_from_notification", parameters: [:])
        }
        
        setupAccessibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.isHidden = false

        //        if (workItem != nil) {
//            self.title = workItem.workTitle
//        } else if (downloadedWorkItem != nil) {
//            self.title = downloadedWorkItem.workTitle ?? ""
//        }
        
        self.title = ""
        
        tableView.backgroundColor = UIColor.clear
        
        tableView.separatorColor = UIColor(named: "greyColor")
        bgView.backgroundColor = UIColor(named: "transparentBg")
    }
    
    deinit {
        #if DEBUG
        print ("Work Detail View Controller deinit")
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKSCROLL)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKID)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKCHAPTER)
        
         self.modalDelegate?.controllerDidClosed()
    }
    
    func setupAccessibility() {
        self.kudosButton.accessibilityLabel = NSLocalizedString("AddKudos", comment: "")
    }
    
    @IBAction func kudosTouched(_ sender: AnyObject) {
        var workId = ""
        
        if let workItem = self.workItem {
            workId = workItem.workId
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            workId = downloadedWorkItem.workId ?? "0"
        }
        
        Analytics.logEvent("WorkDetail_Kudos_add", parameters: ["workId": workId as NSObject, "origin" : "btn" as NSObject])
        
        doLeaveKudos(workId: workId, kudosToken: self.kudosToken).subscribe { (_) in
        }.disposed(by: self.disposeBag)
    }
    
    func showDownloadedWork() {
        
        //var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        //let wId = downloadedWorkItem.workId ?? ""

        //        if worksToReload.contains(wId), let idx = worksToReload.index(of: wId) {
//            worksToReload.remove(at: idx)
//        }
//        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        
        updateAppBadge()
        
        if (downloadedWorkItem.needsUpdate ?? 0 == 1) {
            self.showSuccess(title: Localization("Update"), message: Localization("UpdateAvail"))
        }
        
        let auth = downloadedWorkItem.author ?? ""
        
        let title = downloadedWorkItem.workTitle ?? ""
        let trimmedTitle = title.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
                
        warnings = [String]()
        if let warn = downloadedWorkItem.archiveWarnings {
            if (!warn.isEmpty) {
                let str = warn.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                warnings.append(str)
            }
        }
        
        if let dFandoms = downloadedWorkItem.mutableSetValue(forKey: "fandoms").allObjects as? [DBFandom] {
            downloadedFandoms = dFandoms
        } else {
            downloadedFandoms = []
        }
        if let dRels = downloadedWorkItem.mutableSetValue(forKey: "relationships").allObjects as? [DBRelationship] {
            downloadedRelationships = dRels
        } else {
            downloadedRelationships = []
        }
        if let dCharacters = downloadedWorkItem.mutableSetValue(forKey: "characters").allObjects as? [DBCharacterItem] {
            downloadedCharacters = dCharacters
        } else {
            downloadedCharacters = []
        }
        
        
        let delay = 0.2 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.tableView.reloadData()
        }
        
        let delay1 = 0.7 * Double(NSEC_PER_SEC)
        let time1 = DispatchTime.now() + Double(Int64(delay1)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time1) {
            self.scrollView.flashScrollIndicators()
        }
    }
    
    func showOnlineWork(_ url: String = "") {
        
//        if let image = UIImage(named: "download-red") {
//            downloadTrashButton.setImage(image, forState: .Normal)
//        }
        
        var workId = workItem.workId
        if (workId.isEmpty == true) {
            let workIdArr = url.split(separator: "/")
            if (workIdArr.count > 0) {
                workId = String(workIdArr[workIdArr.count - 1])
                workItem.workId = workId
            }
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
                
        var vadult = ""
        params["view_adult"] = "true" as AnyObject?
        vadult = "?view_adult=true"
        
        showLoadingView(msg: Localization("LoadingWrk"))
        
        var workUrl = url
        if (url.isEmpty) {
            workUrl = "https://archiveofourown.org/works/" + workItem.workId + vadult
        }
        
        Alamofire.request(workUrl, method: .get, parameters: params)
            .response(completionHandler: { response in
                // print(response.request)
                if let d = response.data {
                    self.parseCookies(response)
                    self.downloadCurWork(d)
                    
                    if let wItem = self.workItem {
                        //TODO: - send update details to our server
                       // self.sendUpdateWorkRequest(id: wItem.workId, title: wItem.workTitle, published: wItem.published, updated: wItem.updated, chapters: wItem.chaptersCount)
                        
                    }
                    
                    self.showWork()
                    
                    self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
                    
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
    }
    
    func downloadCurWork(_ data: Data) {
        
        //let dta = String(data: data, encoding: .utf8)
        //print("the string is: \(dta)")
        
        if (workItem == nil) {
            Analytics.logEvent("WorkDetail_Show_Online", parameters: ["downloadCurWork" : "is nil" as NSObject])
            return
        }
        
        onlineChapters.removeAll()
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
        
        if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
            workItem.author = Localization("Sorry")
            workItem.workTitle = Localization("WrkAvailOnlyRegistered");
            workItem.complete = "";
         //   return NEXT_CHAPTER_NOT_EXIST;
            return
        }
        }
        
        if let caution = doc.search(withXPathQuery: "//p[@class='caution']") as? [TFHppleElement],
            caution.count > 0,
            let _ = caution[0].text().range(of: "adult content")  {
            
            workItem.author = Localization("Sorry")
            workItem.workTitle = Localization("ContainsAdultContent")
            workItem.complete = ""
            
            return
        }
        
        if let errH = doc.search(withXPathQuery: "//h2[@class='heading']") {
        
        if (errH.count>0 && (errH[0] as! TFHppleElement).text().range(of: "Error") != nil) {
            workItem.author = Localization("Sorry")
            workItem.workTitle = Localization("AO3Issue")
            workItem.complete = ""
            
            return
        }
        }
        
        //var landmark = doc.searchWithXPathQuery("//h6[@class='landmark heading']")
        
        var firstFandom = ""
        var firstRelationship = ""
        
        if let workSumm: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='workskin']//div[@class='summary module']//blockquote") as? [TFHppleElement] {
            if (workSumm.count > 0) {
                if let summ = workSumm[0].content {
                if (!summ.isEmpty) {
                    workItem.topicPreview = summ.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                }
            }
        }
        
        if let workmeta: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='work meta group']") as? [TFHppleElement] {
            
        isSensitive = false
        
        if(workmeta.count > 0) {
            if let ratings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='rating tags']/ul/li") as? [TFHppleElement] {
            if (ratings.count > 0) {
                if let ratingStr = ratings[0].content {
                    workItem.ratingTags = ratingStr
                }
            }
            }
        
            if let archiveWarnings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='warning tags']/ul/li") as? [TFHppleElement] {
            warnings = [String]()
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
                    warnings.append(warnStr)
                }
                }
                //workItem.archiveWarnings = archiveWarnings[0].content
            }
            
            if let fandomsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='fandom tags']/ul[@class='commas']/li") as? [TFHppleElement] {
            fandoms = [Fandom]()
            
            for i in 0..<fandomsLiArr.count {
                var f : Fandom = Fandom()
                f.fandomName = fandomsLiArr[i].content
                firstFandom = f.fandomName
                f.fandomUrl = (fandomsLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement)?
                                 .attributes["href"] as? String ?? ""
                fandoms.append(f)
            }
            }
            
            if let categoryLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='category tags']/ul/li") as? [TFHppleElement] {
                workItem.category = ""
                for i in 0..<categoryLiArr.count {
                    workItem.category += categoryLiArr[i].content.trimmingCharacters(in: .whitespacesAndNewlines) + " "
                }
            }
            
            if let freeformLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='freeform tags']/ul/li") as? [TFHppleElement] {
                workItem.freeform = ""
                for i in 0..<freeformLiArr.count {
                    workItem.freeform += freeformLiArr[i].content.trimmingCharacters(in: .whitespacesAndNewlines) + " "
                }
            }
            
            var relationshipsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='relationship tags']/ul[@class='commas']/li") as! [TFHppleElement]
            relationships = [Relationship]()
            
            for i in 0..<relationshipsLiArr.count {
                var r : Relationship = Relationship()
                r.relationshipName = relationshipsLiArr[i].content
                firstRelationship = r.relationshipName
                r.relationshipUrl = (relationshipsLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement)?
                    .attributes["href"] as? String ?? ""
                relationships.append(r)
            }
            
            var charactersLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='character tags']/ul[@class='commas']/li") as! [TFHppleElement]
            characters = [CharacterItem]()
            
            for i in 0..<charactersLiArr.count {
                var c : CharacterItem = CharacterItem()
                c.characterName = charactersLiArr[i].content
                c.characterUrl = (charactersLiArr[i].search(withXPathQuery: "//a").first as? TFHppleElement)?
                    .attributes["href"] as? String ?? ""
                characters.append(c)
            }
            
            var languageEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='language']") as! [TFHppleElement]
            if(languageEl.count > 0) {
                workItem.language = languageEl[0].text().replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            }
            
            if let seriesEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='series']//span[@class='position']") as? [TFHppleElement] {
            if(seriesEl.count > 0) {
                let sTxt = seriesEl[0].content.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                if (!sTxt.isEmpty) {
                    workItem.topicPreview = "\(sTxt) \n\n\(workItem.topicPreview)"
                    
                    workItem.serieName = sTxt
                }
                
                if let attributesEl : [TFHppleElement] = seriesEl[0].search(withXPathQuery: "//a") as? [TFHppleElement] {
                    if (attributesEl.count > 0) {
                        workItem.serieUrl = attributesEl.first?.attributes["href"] as? String ?? ""
                    }
                }
            }
            }
            
            workItem.stats = ""
            
            if let statsElDt: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dt") as? [TFHppleElement],
                let statsElDd: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dd") as? [TFHppleElement] {
                
                if(statsElDt.count > 0 && statsElDd.count > 0) {
                    for i in 0..<statsElDt.count {
                        if let txt = statsElDt[i].text() {
                            workItem.stats += txt + " "
                        }
                        if ((statsElDd.count > i) && (statsElDd[i].text() != nil)) {
                            workItem.stats += statsElDd[i].text() + " "
                        }
                    }
                }
            }
            
            var stats : TFHppleElement? = nil
            let statsEl: [TFHppleElement]? =  workmeta[0].search(withXPathQuery: "//dl[@class='stats']") as? [TFHppleElement]
            if (statsEl?.count ?? 0 > 0) {
                stats = statsEl?[0]
            }
            
            //Mark: - parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let datesEl = stats?.search(withXPathQuery: "//dd[@class='status']") as? [TFHppleElement], datesEl.count > 0 {
                workItem.datetime = datesEl[0].text() ?? ""
                workItem.updated = workItem.datetime
            }
            
            if let datesEl: [TFHppleElement] = stats?.search(withXPathQuery: "//dd[@class='published']") as? [TFHppleElement], datesEl.count > 0 {
                if (workItem.datetime.isEmpty) {
                    workItem.datetime = datesEl[0].text() ?? ""
                }
                workItem.published = datesEl[0].text() ?? ""
            }
            
            if (workItem.datetime.isEmpty == false) {
                if let date = dateFormatter.date(from: workItem.datetime) {
                    dateFormatter.dateFormat = "dd MMM yyyy"
                    workItem.datetime = dateFormatter.string(from: date)
                }
            }
            
            if let statsDD = workmeta[0].search(withXPathQuery: "//dd[@class='stats']") as? [TFHppleElement], statsDD.count > 0 {
                if let dateTimeVar = workmeta[0].search(withXPathQuery: "//dd[@class='status']") as? [TFHppleElement], dateTimeVar.count > 0 {
                    if (self.downloadedWorkItem != nil) {
                        let dateFormatter1 = DateFormatter()
                        dateFormatter1.dateFormat = "dd MMM yyyy"
                        
                        let dDate = dateFormatter1.date(from: self.downloadedWorkItem.datetime ?? "")
                        
                        let dateFormatter2 = DateFormatter()
                        dateFormatter2.dateFormat = "yyyy-MM-dd"
                        
                        let nDate = dateFormatter2.date(from: dateTimeVar[0].text() ?? "")
                        
                        if (dDate != nDate) {
                            self.needReload = true
                        } else {
                            self.needReload = false
                        }
                    }
                }
            }
            
            if (workItem.stats.contains("Completed")) {
                workItem.complete = "Complete"
            } else if (workItem.chaptersCount.contains("?")) {
                workItem.complete = "Work In Progress"
            }
            
            }
        }
        
        if let h2El = doc.search(withXPathQuery: "//h2[@class='title heading']") as? [TFHppleElement] {
        if (h2El.count > 0) {
            let title = h2El.first?.content.replacingOccurrences(of: "\n", with:"")
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil) ?? ""
            workItem.workTitle = title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            workItem.workTitle = workItem.workTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
        }
        
        if let bylineHeadingEl = doc.search(withXPathQuery: "//div[@id='workskin']/div[@class='preface group']/h3[@class='byline heading']") as? [TFHppleElement] {
        if (bylineHeadingEl.count > 0) {
            workItem.author = bylineHeadingEl[0].content.replacingOccurrences(of: "\n", with:"")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
        }
        }
            
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            if (workContentEl.count > 0) {
                workItem.workContent = workContentEl[0].raw ?? ""
            }
        }
        
        //var error:NSErrorPointer = NSErrorPointer()
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
        workItem.workContent = regex.stringByReplacingMatches(in: workItem.workContent, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workItem.workContent.count), withTemplate: "$1")
        
        let regex1:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive)
        workItem.workContent = regex1.stringByReplacingMatches(in: workItem.workContent, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workItem.workContent.count), withTemplate: "$1")
        
       // stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$1"];
        //workItem.workContent = workItem.workContent.stringByReplacingOccurrencesOfString("<a.*\"\\s*>", withString:"")
        //workItem.workContent = workItem.workContent.stringByReplacingOccurrencesOfString("</a>", withString:"");
        
        if let navigationEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement] {
            if (navigationEl.count > 0) {
                if let nxt : [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement] {
                    if (nxt.count > 0) {
                        workItem.nextChapter = (nxt.first?.search(withXPathQuery: "//a").first as? TFHppleElement)?
                            .attributes["href"] as? String ?? ""
                    }
                    NSLog("%@", workItem.nextChapter)
                }
                
                if (workItem.workId.isEmpty == true) {
                if let mark : [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='mark']") as? [TFHppleElement] {
                    if (mark.count > 0) {
                        let str = (mark.first?.search(withXPathQuery: "//a").first as? TFHppleElement)?
                                     .attributes["href"] as? String
                        
                        let components = str?.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        if let part = components?.joined() {
                        
                            workItem.workId = part
                        }

                    }
                    NSLog("%@", workItem.workId)
                }
                }
            }
        }
        
        if let editBookmarkEl = doc.search(withXPathQuery: "//a[@class='bookmark_form_placement_open']") as? [TFHppleElement] {
        if (editBookmarkEl.count > 0) {
            if (editBookmarkEl[0].raw.contains("Edit")) {
                self.bookmarked = true
            }
        }
        }
        
        if let markForLaterEl = doc.search(withXPathQuery: "//ul[@class='work navigation actions']//li[@class='mark']") as? [TFHppleElement] {
        if (markForLaterEl.count > 0) {
            if (markForLaterEl[0].raw.contains("Mark as Read")) {
                self.markedForLater = true
            }
        }
        }
        
        if let chaptersEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@id='chapter_index']") as? [TFHppleElement] {
        if (chaptersEl.count > 0) {
            if let optionsEl: [TFHppleElement] = chaptersEl[0].search(withXPathQuery: "//select/option") as? [TFHppleElement] {
            for i in 0..<optionsEl.count {
                var chptOnline: ChapterOnline = ChapterOnline()
                chptOnline.url = optionsEl[i].text()
                chptOnline.chapterId = optionsEl[i].attributes["value"] as? String ?? ""
                
                onlineChapters[i] = chptOnline
            }
            }
        }
           // chaptersEl = nil
        }
        
        saveToAnalytics(workItem.author, category: workItem.category, mainFandom: firstFandom, mainRelationship: firstRelationship)
        
    }
    
    func checkBookmarkAndUpdate() -> Observable<Void> {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
                
        var vadult = ""
        if let isAdult = DefaultsManager.getBool(DefaultsManager.ADULT)  {
            if (isAdult == true) {
                
                params["view_adult"] = "true" as AnyObject?
                vadult = "?view_adult=true"
            }
        }

        var wid = ""
        if (workItem != nil) {
            wid = workItem.workId
        } else if (downloadedWorkItem != nil) {
            wid = downloadedWorkItem.workId ?? ""
        }
        
        return Observable.create({ (observer) -> Disposable in
            
            Alamofire.request("https://archiveofourown.org/works/" + wid + vadult + "#bookmark-form", method: .get, parameters: params)
                .response(completionHandler: { response in
                    // print(response.request)
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseCheckBookmarkAndUpdate(d)
                        //self.showWork()
                        //self.hideLoadingView()
                        
                        if (self.needReload) {
                            let delay = 0.2 * Double(NSEC_PER_SEC)
                            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: time) {
                                
                                self.showSuccess(title: Localization("Update"), message: Localization("UpdateAvail"))
                            }
                        }
                        
                        observer.onNext(())
                        observer.onCompleted()
                    } else {
                        observer.onError(ErrorsAF.noResponseData)
                    }
                })
            
            return Disposables.create()
        })
        
        
    }
    
    func parseCheckBookmarkAndUpdate(_ data: Data) {
        downloadUrls.removeAll()
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let xTokenEls: [TFHppleElement] = doc.search(withXPathQuery: "//meta[@name='csrf-token']") as? [TFHppleElement] {
            if (xTokenEls.count > 0) {
                if let attrs = xTokenEls[0].attributes as NSDictionary? {
                    if let tokenStr = attrs["content"] as? String, tokenStr.isEmpty == false {
                        self.authToken = tokenStr
                    }
                }
            }
        }
        
        
        if let bookmarkIdEls = doc.search(withXPathQuery: "//div[@id='bookmark-form']") as? [TFHppleElement] {
            if (bookmarkIdEls.count > 0) {
                if let formEls = bookmarkIdEls[0].search(withXPathQuery: "//form") as? [TFHppleElement],
                    formEls.count > 0 {
                        if let attributes : NSDictionary = formEls[0].attributes as NSDictionary?  {
                            bookmarkId = (attributes["action"] as? String ?? "")
                        }
                }
                if let inputTokenEls = bookmarkIdEls[0].search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement],
                    inputTokenEls.count > 0 {
                    if let attrs : NSDictionary = inputTokenEls[0].attributes as NSDictionary?  {
                        self.bookmarkToken = (attrs["value"] as? String ?? "")
                    }
                }
            }
        }
        
        if let editBookmarkEl = doc.search(withXPathQuery: "//a[@class='bookmark_form_placement_open']") as? [TFHppleElement] {
        if (editBookmarkEl.count > 0) {
            if let _ : NSDictionary = editBookmarkEl[0].attributes as NSDictionary? {
            if (editBookmarkEl[0].raw.contains("Edit")) {
                self.bookmarked = true
                }
            }
        }
        }
        
        if let kudosIdEls = doc.search(withXPathQuery: "//div[@class='feedback']") as? [TFHppleElement],
            kudosIdEls.count > 0 {
                if let formEls = kudosIdEls[0].search(withXPathQuery: "//form[@id='new_kudo']") as? [TFHppleElement],
                    formEls.count > 0 {
                    if let inputTokenEls = formEls[0].search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement],
                        inputTokenEls.count > 0 {
                        if let attrs : NSDictionary = inputTokenEls[0].attributes as NSDictionary?  {
                            self.kudosToken = (attrs["value"] as? String ?? "")
                        }
                    }
                }
            
        }
        
        if let xTokenEls: [TFHppleElement] = doc.search(withXPathQuery: "//meta[@name='csrf-token']") as? [TFHppleElement] {
            if (xTokenEls.count > 0) {
                if let attrs = xTokenEls[0].attributes as NSDictionary? {
                    if let tokenStr = attrs["content"] as? String, tokenStr.isEmpty == false {
                        xcsrfToken = tokenStr
                    }
                }
            }
        }
        
        self.markedForLater = false
        if let markForLaterEl = doc.search(withXPathQuery: "//ul[@class='work navigation actions']//li[@class='mark']") as? [TFHppleElement] {
            if (markForLaterEl.count > 0) {
                if (markForLaterEl[0].raw.contains("Mark as Read")) {
                    self.markedForLater = true
                }
            }
        }
        
        if let downloadEl = doc.search(withXPathQuery: "//li[@class='download']") as? [TFHppleElement] {
            if (downloadEl.count > 0) {
                if let downloadUl: [TFHppleElement] = downloadEl.first?.search(withXPathQuery: "//li") as? [TFHppleElement] {
                    for i in 0..<downloadUl.count {
                        let anchor = downloadUl[i].search(withXPathQuery: "//a").first as? TFHppleElement
                        let attributes = anchor?.attributes ?? [:]
                        let key = downloadUl[i].content ?? ""
                        let val = attributes["href"] as? String ?? ""
                        
                        if (!val.contains("#") && !val.isEmpty) {
                            downloadUrls[key] = val
                        }
                    }
                }
            }
        }
        
        if let dateTimeVar = doc.search(withXPathQuery: "//div[@class='work']//dd[@class='stats']//dd[@class='status']") as? [TFHppleElement] {
            if(dateTimeVar.count > 0) {
                if (self.downloadedWorkItem != nil) {
                    let dateFormatter1 = DateFormatter()
                    dateFormatter1.dateFormat = "dd MMM yyyy"
                    
                    let dDate = dateFormatter1.date(from: self.downloadedWorkItem.datetime ?? "")
                    
                    let dateFormatter2 = DateFormatter()
                    dateFormatter2.dateFormat = "yyyy-MM-dd"
                    
                    let nDate = dateFormatter2.date(from: dateTimeVar[0].text() ?? "")
                    
                    if (dDate != nDate) {
                        self.needReload = true
                    } else {
                        self.needReload = false
                    }
                }
            }
        }
    }
    
    func parseAddBookmarkResponse(_ data: Data) {
        #if DEBUG
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("the string is: \(String(describing: dta))")
            #endif
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] {
            if(noticediv.count > 0) {
                self.showSuccess(title: Localization("AddingBmk"), message: noticediv[0].content)
            
                changedSmth = true
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.showError(title: Localization("AddingBmk"), message: (sorrydiv[0] as AnyObject).content ?? "")
                return
            }
        }
        
        if (data.isEmpty) {
            self.showError(title: Localization("CannotAddBmk"), message: "Response Is Empty")
        }
        return
    }
    
    //MARK: - show work
    
    func showWork() {
        tableView.reloadData()
        tableViewHeight.constant = tableView.contentSize.height
        tableView.layoutIfNeeded()
        
        hideLoadingView()
        
        scrollView.flashScrollIndicators()
        
        if (!DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            performSegue(withIdentifier: "readSegue", sender: nil)
        }
        
        if (isSensitive == true) {
            readButton.isEnabled = false
            readButton.alpha = 0.5
            
            self.showError(title:  Localization("Error"), message: Localization("SensitiveContent"))
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "readSegue") {
                        
            let workController: WorkViewController = segue.destination as! WorkViewController
            workController.kudosToken = self.kudosToken
            
            if (workItem != nil) {
                
                /*var url = ""
                
                for downloadUrl in downloadUrls {
                    if (downloadUrl.key == "EPUB") {
                        url = downloadUrl.value
                    }
                }
                
                downloadEpub(epubUrl: "https://archiveofourown.org" + url)
                //openEpub(bookPath: "https://archiveofourown.org" + url)
 */
                
                workController.workItem = workItem
                workController.onlineChapters = onlineChapters
                
            } else if (downloadedWorkItem != nil) {
                workController.downloadedWorkItem = downloadedWorkItem
            }
        } else if (segue.identifier == "leaveComment") {
            let cController: CommentViewController = segue.destination as! CommentViewController
            
            var workId = ""
            if (workItem != nil) {
                workId = workItem.workId
            } else if (downloadedWorkItem != nil) {
                workId = downloadedWorkItem.workId ?? "0"
            }
            
            cController.workId = workId
            
        }  else if (segue.identifier == "listSegue") {
            if let cController: WorkListController = segue.destination as? WorkListController {
                cController.tagUrl = tagUrl
            }
        } else if (segue.identifier == "authorSegue") {
            if let cController: AuthorViewController = segue.destination as? AuthorViewController {
                cController.authorName = tagUrl
            }
            
        } else if (segue.identifier == "showSerie") {
            if let cController: SerieViewController = segue.destination as? SerieViewController {
                
                if (workItem != nil) {
                    cController.serieId = workItem.serieUrl
                    
                    Analytics.logEvent("WorkDetail_view_serie", parameters: ["work" : "online" as NSObject, "id" : cController.serieId as NSObject])
                    
                } else if (downloadedWorkItem != nil) {
                    cController.serieId = downloadedWorkItem.serieUrl ?? ""
                    
                    Analytics.logEvent("WorkDetail_view_serie", parameters: ["work" : "downloaded" as NSObject, "id" : cController.serieId as NSObject])
                }
             }
        }
        
    }
    
    //MARK : - download temp epub 
    
    //better - https://www.ralfebert.de/snippets/ios/urlsession-background-downloads/
    
    /*func downloadEpub(epubUrl: String) {
        // Create destination URL
        let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let destinationFileUrl = documentsUrl.appendingPathComponent("tempWork.epub")
        
        //Create URL to the source file you want to download
        let fileURL = URL(string: epubUrl)
        
        if (FileManager.default.fileExists(atPath: destinationFileUrl.absoluteString)) {
            do {
                try
                    FileManager.default.removeItem(at: fileURL!)
            } catch (let writeError) {
                #if DEBUG
                print("Error deleting a file \(destinationFileUrl) : \(writeError)")
                #endif
            }
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL!)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    #if DEBUG
                    print("Successfully downloaded. Status code: \(statusCode)")
                        #endif
                    
                    self.openEpub(bookPath: destinationFileUrl.absoluteString)
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                } catch (let writeError) {
                    #if DEBUG
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                    #endif
                }
                
            } else {
                #if DEBUG
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "")
                #endif
            }
        }
        task.resume()
    }*/
    
    //https://github.com/taku33/FolioReaderPlus
    
//    func openEpub(bookPath: String) {
//        /*let config = FolioReaderConfig()
//       // let bookPath = Bundle.main.path(forResource: "tempWork", ofType: "epub")
//        let folioReader = FolioReader()
//        folioReader.presentReader(parentViewController: self, withEpubPath: bookPath, andConfig: config) */
//    }
    
    // MARK: - tableview
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var createdCell: UITableViewCell! = nil
        
        let authorSection = 0
        let firstTxtSection = authorSection + 1
        let secondTxtSection = firstTxtSection  + 1
        let lastTxtSection = firstTxtSection + 8
        
        if (indexPath.section == authorSection) {
            createdCell = tableView.dequeueReusableCell(withIdentifier: "WorkDetailsAuthorCell") as? WorkDetailsAuthorCell
        } else if (indexPath.section == firstTxtSection || indexPath.section == secondTxtSection || indexPath.section == lastTxtSection) {
            createdCell = tableView.dequeueReusableCell(withIdentifier: "txtCell") as? WorkDetailCell
        } else {
            createdCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? WorkDetailCell
        }
        
        if (createdCell == nil) {
            if (indexPath.section == authorSection) {
                createdCell = WorkDetailsAuthorCell(style: .default, reuseIdentifier: "WorkDetailsAuthorCell")
            } else if (indexPath.section == firstTxtSection || indexPath.section == secondTxtSection || indexPath.section == lastTxtSection) {
                createdCell = WorkDetailTxtCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "txtCell")
            } else {
                if(createdCell == nil) {
                    createdCell = WorkDetailCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
                }
            }
        }
        
        if (indexesToHide != nil) {
            indexesToHide.removeAll(keepingCapacity: false)
        } else {
            indexesToHide = [Int]()
        }

        let txtColor = UIColor(named: "textColorMedium")
        
        if (indexPath.section == authorSection) {
            if let wrk = workItem {
                (createdCell as? WorkDetailsAuthorCell)?.setup(with: wrk, and: theme)
            } else if let wrkd = downloadedWorkItem {
                (createdCell as? WorkDetailsAuthorCell)?.setupDwnl(with: wrkd, and: theme)
            }
            
            return createdCell
        }
               
        let cell: WorkDetailCell! = createdCell as? WorkDetailCell
        
        cell.label.textColor = txtColor
        cell.backgroundColor = UIColor.clear
        cell.contentView.layoutMargins = .init(top: 0.0, left: 20, bottom: 0.0, right: 20)
        
        let cellSection = indexPath.section - (authorSection + 1)
        
        switch (cellSection) {
        case 0:
            
            cell.label.textColor = txtColor
            if (UIDevice.current.userInterfaceIdiom == .pad) {
                cell.label.font = UIFont(name: "Helvetica Neue Light Italic", size: 17.0)
            } else {
                cell.label.font = UIFont(name: "Helvetica Neue Light Italic", size: 13.0) 
            }
            
            if (workItem != nil) {
                
                if workItem.tags.isEmpty == false {
                    cell.label.text = workItem.tags
                } else {
                    var allTags = workItem.archiveWarnings
                    if (allTags.isEmpty == false) {
                        allTags.append(", ")
                    }
                    
                    if let rels = relationships {
                        for case let rel in rels  {
                            if rel.relationshipName.isEmpty == false {
                                allTags.append(rel.relationshipName)
                                allTags.append(", ")
                            }
                        }
                    }
                    
                    if let chrs = characters {
                        for case let character in chrs  {
                            if character.characterName.isEmpty == false {
                                allTags.append(character.characterName)
                                allTags.append(", ")
                            }
                        }
                    }
                    
                    let freeTags = workItem.freeform
                    if freeTags.isEmpty == false {
                        allTags.append(freeTags)
                    }
                    
                    let lastChars = allTags.suffix(2)
                    if lastChars == ", " {
                        let index = allTags.index(allTags.endIndex, offsetBy: -2)
                        allTags = String(allTags[..<index])
                    }
                    
                    cell.label.text = allTags
                }
                
            } else if (downloadedWorkItem != nil) {
                if let tags = downloadedWorkItem?.tags, tags.isEmpty == false {
                    cell.label.text = downloadedWorkItem?.tags
                } else {
                    var allTags = downloadedWorkItem?.archiveWarnings ?? ""
                    if (allTags.isEmpty == false) {
                        allTags.append(", ")
                    }
                    
                    if let rels = downloadedWorkItem?.relationships {
                        for case let rel as DBRelationship in rels  {
                            if let relName = rel.relationshipName, relName.isEmpty == false {
                                allTags.append(relName)
                                allTags.append(", ")
                            }
                        }
                    }
                    
                    if let characters = downloadedWorkItem?.characters {
                        for case let character as DBCharacterItem in characters  {
                            if let charName = character.characterName, charName.isEmpty == false {
                                allTags.append(charName)
                                allTags.append(", ")
                            }
                        }
                    }
                    
                    if let freeTags = downloadedWorkItem?.freeform, freeTags.isEmpty == false {
                        allTags.append(freeTags)
                    }
                    
                    let lastChars = allTags.suffix(2)
                    if lastChars == ", " {
                        let index = allTags.index(allTags.endIndex, offsetBy: -2)
                        allTags = String(allTags[..<index])
                    }
                    
                    cell.label.text = allTags
                }
            }

        case 1:
            
            if (UIDevice.current.userInterfaceIdiom == .pad) {
                cell.label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
            } else {
                cell.label.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            }
            
            cell.label.textColor = txtColor
            
            if (workItem != nil) {
                if (!isSensitive) {
                    if (workItem.topicPreview.isEmpty == false) {
                        cell!.label.text = workItem.topicPreview
                    } else {
                        cell!.label.text = "No Preview"
                    }
                } else {
                    cell!.label.text = Localization("SensitiveContent")
                }
            } else if (downloadedWorkItem != nil) {
                cell!.label.text = downloadedWorkItem.topicPreview ?? "No Preview" + " Hello!!!"
            }
            
        case 2:
            if (workItem != nil) {
                cell!.label.text = workItem.stats
            } else if (downloadedWorkItem != nil) {
                cell!.label.text = downloadedWorkItem.stats ?? ""
            }
            cell!.imgView.image = UIImage(named: "info")
            
        case 3:
            if (warnings.count > indexPath.row) {
                cell!.label.text = warnings.joined(separator: ", ")
                
            } else {
                indexesToHide.append(0)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "warning")
        case 4:
            if (fandoms != nil && fandoms.count > indexPath.row) {
                cell!.label.text = fandoms[indexPath.row].fandomName
                
            } else if (downloadedFandoms != nil && downloadedFandoms.count > indexPath.row) {
                cell!.label.text = downloadedFandoms[indexPath.row].fandomName ?? ""
                
            } else {
                indexesToHide.append(1)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "fandom")
        case 5:
            if (relationships != nil && relationships.count > indexPath.row) {
                cell!.label.text = relationships[indexPath.row].relationshipName
                
            } else if (downloadedRelationships != nil && downloadedRelationships.count > indexPath.row) {
                cell!.label.text = downloadedRelationships[indexPath.row].relationshipName ?? ""
                
            } else {
                indexesToHide.append(2)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "heart")
        case 6:
            if (characters != nil && characters.count > indexPath.row) {
                cell!.label.text = characters[indexPath.row].characterName
                
            } else if (downloadedCharacters != nil && downloadedCharacters.count > indexPath.row) {
                cell!.label.text = downloadedCharacters[indexPath.row].characterName ?? ""
                
            } else {
                indexesToHide.append(3)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "characters")
//        case 7:
//            if (workItem != nil) {
//                cell!.label.text = workItem.language
//            } else if (downloadedWorkItem != nil) {
//                cell!.label.text = downloadedWorkItem.value(forKey: "language") as? String ?? ""
//            }
//            cell!.imgView.image = UIImage(named: "lang")
            
        case 7:
            if (workItem != nil) {
                cell!.label.text = "\(workItem.words) \(Localization("Words"))"
            } else if (downloadedWorkItem != nil) {
                cell!.label.text = downloadedWorkItem.words ?? ""
            }
            if (theme == DefaultsManager.THEME_DAY) {
                cell!.imgView.image = UIImage(named: "word")
            } else {
                cell!.imgView.image = UIImage(named: "word_light")
            }
            
        case 8:
            var serieName: String = ""
            if (workItem != nil) {
                serieName = workItem.serieName
            } else if (downloadedWorkItem != nil) {
                serieName = downloadedWorkItem.serieName ?? ""
            }
             cell.label.text = "View Serie (\(serieName))"
            
            if (UIDevice.current.userInterfaceIdiom == .pad) {
                cell.label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
            } else {
                cell.label.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            }
            
            cell!.imgView?.image = nil
            
        default:
            break
        }
        
        
        return cell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 9
        
        if (workItem != nil && workItem.serieUrl.isEmpty) {
            numberOfSections = 9
        } else if (downloadedWorkItem != nil && (downloadedWorkItem.serieUrl ?? "").isEmpty) {
            numberOfSections = 9
        } else {
            numberOfSections = 10
        }
        
        
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var res:Int = 1
        
        let authorSection = 0
        
        let sectionNumber = section - (authorSection + 1) // skip author and ads section (if present)
        
        switch (sectionNumber) {
        case 4:
            if (workItem != nil) {
                if (fandoms != nil) {
                    res = fandoms.count
                }
            } else if (downloadedFandoms != nil) {
                return downloadedFandoms.count
            }
        case 5:
            if (workItem != nil && relationships != nil) {
                res = relationships.count
            } else if (downloadedRelationships != nil) {
                return downloadedRelationships.count
            }
        case 6:
            if (workItem != nil && characters != nil) {
                res = characters.count
            } else if (downloadedCharacters != nil) {
                return downloadedCharacters.count
            }
        default:
            break
        }
        
        return res
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let pos = indexPath.row
        
        Crashlytics.crashlytics().log(format: "WorkDetail: didSelectRowAt pos=\(pos); section=\(indexPath.section)", arguments: getVaList([]))
        
        self.tagUrl = ""
        
        let authorSection = 0
        
        let sectionNumber = indexPath.section - (authorSection + 1) // skip author and ads section (if present)
        
        switch sectionNumber {
        case 4:
                if (fandoms != nil && fandoms.count > pos) {
                    tagUrl = fandoms[pos].fandomUrl
                } else if (downloadedFandoms != nil && downloadedFandoms.count > pos) {
                    tagUrl = downloadedFandoms[pos].fandomUrl ?? ""
                }
                NSLog("link Tapped = %@", tagUrl)
            Crashlytics.crashlytics().log(format: "WorkDetail: link Tapped = %@", arguments: getVaList([tagUrl]))
                
                if (tagUrl.isEmpty == false) {
                    performSegue(withIdentifier: "listSegue", sender: self)
                }
            
        case 5:
            if (relationships != nil && relationships.count > pos) {
                tagUrl = relationships[pos].relationshipUrl
            } else if (downloadedRelationships != nil && downloadedRelationships.count > pos) {
                Crashlytics.crashlytics().log(format: "WorkDetail: section=5; downloadedRelationships=\(downloadedRelationships.count)", arguments: getVaList([]))
                tagUrl = downloadedRelationships[pos].relationshipUrl ?? ""
            }
          //  NSLog("link Tapped = \(tagUrl)" )
            Crashlytics.crashlytics().log(format: "WorkDetail: link Tapped = %@", arguments: getVaList([tagUrl]))
            
            if (tagUrl.isEmpty == false) {
                performSegue(withIdentifier: "listSegue", sender: self)
            }
            
        case 6:
            if (characters != nil && characters.count > pos) {
                tagUrl = characters[pos].characterUrl
            } else if (downloadedCharacters != nil && downloadedCharacters.count > pos) {
                tagUrl = downloadedCharacters[pos].characterUrl ?? ""
            }
           // NSLog("link Tapped = " + tagUrl)
            Crashlytics.crashlytics().log(format: "WorkDetail: link Tapped = %@", arguments: getVaList([tagUrl]))
                        
            if (tagUrl.isEmpty == false) {
                performSegue(withIdentifier: "listSegue", sender: self)
            }
            
        case 8:
            performSegue(withIdentifier: "showSerie", sender: self)
            Crashlytics.crashlytics().log(format: "WorkDetail: showSerie", arguments: getVaList([]))
            
        default:
            break
        }
    }
    
    @objc @IBAction func authorTouched(_ sender: UITapGestureRecognizer) {
        var authorName = ""
        
        if(workItem != nil) {
            authorName = workItem.author
        } else if (downloadedWorkItem != nil) {
            authorName = downloadedWorkItem.author ?? ""
        }
        
         Analytics.logEvent("WorkDetail_author_touched", parameters: ["author": authorName as NSObject])
        
        if (authorName.contains(" ") && !authorName.contains(",")) {
            let nameArr = authorName.split{$0 == " "}.map(String.init)
            var an = nameArr[1].replacingOccurrences(of: "(", with: "")
            an = an.replacingOccurrences(of: ")", with: "")
            tagUrl = an //"https://archiveofourown.org/users/\(an)/pseuds/\(nameArr[0])/works"
        } else if (authorName.contains(",")) {
            var nameArr = authorName.split{$0 == ","}.map(String.init)
            if (nameArr[0].contains(" ")) {
                tagUrl = nameArr[0].addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? tagUrl
            }
           // tagUrl = nameArr[0] //"https://archiveofourown.org/users/\(nameArr[0])/works"
        } else {
            if (authorName.contains(" ")) {
                tagUrl = authorName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? tagUrl
            }
            tagUrl = authorName //"https://archiveofourown.org/users/\(authorName)/works"
        }
        
        performSegue(withIdentifier: "authorSegue", sender: self)
    }
    
    @IBAction func closeClicked(_ sender: AnyObject) {
        
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKSCROLL)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKID)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKCHAPTER)
        
        if (self.changedSmth) {
            self.modalDelegate?.controllerDidClosedWithChange!()
        } else {
            self.modalDelegate?.controllerDidClosed()
        }
        self.dismiss(animated: true, completion: { () -> Void in
            
            NSLog("closeClicked")
        })
    }
    
    //MARK: - mark for later
    
    func markForLaterWorkAction() {
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        if (pseud_id.isEmpty || ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty)) {
            openLoginController()
            triedTo = 3
        } else {
            self.sendMarkForLaterRequest()
        }
    }
    
    func markAsReadWorkAction() {
        self.sendMarkAsReadRequest()
    }
    
    func sendMarkAsReadRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 4
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: Localization("MarkingForLater"))
        
        var requestStr = "https://archiveofourown.org/works/"
        var bid = ""
        var pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if(pseud_id.isEmpty) {
            if let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String : String] {
                pseud_id = pseuds.first?.value ?? ""
                
                DefaultsManager.putString(pseud_id, key: DefaultsManager.PSEUD_ID)
            }
        }
        
        if (workItem != nil) {
            bid = workItem.workId
            requestStr += bid + "/mark_as_read"
            
            
            if ( fandoms != nil && relationships != nil && fandoms.count > 0 && relationships.count > 0) {
                saveToAnalytics(workItem.author, category: workItem.category, mainFandom: fandoms[0].fandomName, mainRelationship: relationships[0].relationshipName)
            }
            
        } else if (downloadedWorkItem != nil) {
            guard let bd = downloadedWorkItem.workId else {
                return
            }
            bid = bd
            requestStr += bid + "/mark_as_read"
            
            if (downloadedFandoms.count > 0 && downloadedRelationships.count > 0) {
                saveToAnalytics(downloadedWorkItem.author ?? "", category: downloadedWorkItem.category ?? "", mainFandom: downloadedFandoms[0].fandomName ?? "", mainRelationship: downloadedRelationships[0].relationshipName ?? "")
            }
        }
        
        Analytics.logEvent("WorkDetail_MarkAsRead", parameters: ["workId": bid as NSObject])
        
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            if (del.cookies.count > 0) {
                Alamofire.request(requestStr, method: .get, parameters: [:], encoding: URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                    .response(completionHandler: { response in
                        #if DEBUG
                            print(response.request ?? "")
                            // print(response)
                            print(response.error ?? "")
                        #endif
                        
                        if let d = response.data {
                            self.parseCookies(response)
                            self.parseMarkForLaterResponse(d)
                            self.hideLoadingView()
                            
                            self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
                            
                        } else {
                            self.hideLoadingView()
                            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                        }
                    })
            }
        }
    }
    
    func parseMarkForLaterResponse(_ data: Data) {
        #if DEBUG
            let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print("the string is: \(String(describing: dta))")
        #endif
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] {
            if(noticediv.count > 0) {
                showSuccess(title: Localization("MarkingForLater"), message: noticediv[0].content)
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.showError(title: Localization("MarkingForLater"), message: (sorrydiv[0] as AnyObject).content ?? "")
                return
            }
        }
        
        if (data.isEmpty) {
            self.showError(title: Localization("CannotMark"), message: "Response Is Empty")
        }
        return
    }
    
    func sendMarkForLaterRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 3
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: Localization("MarkingForLater"))
        
        var requestStr = "https://archiveofourown.org/works/"
        var bid = ""
        var pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if(pseud_id.isEmpty) {
            if let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String : String] {
                pseud_id = pseuds.first?.value ?? ""
                
                DefaultsManager.putString(pseud_id, key: DefaultsManager.PSEUD_ID)
            }
        }
        
        if (workItem != nil) {
            bid = workItem.workId
            requestStr += bid + "/mark_for_later"
            
            
            if ( fandoms != nil && relationships != nil && fandoms.count > 0 && relationships.count > 0) {
                saveToAnalytics(workItem.author, category: workItem.category, mainFandom: fandoms[0].fandomName, mainRelationship: relationships[0].relationshipName)
            }
            
        } else if (downloadedWorkItem != nil) {
            guard let bd = downloadedWorkItem.workId else {
                return
            }
            bid = bd
            requestStr += bid + "/mark_for_later"
            
            if (downloadedFandoms.count > 0 && downloadedRelationships.count > 0) {
                saveToAnalytics(downloadedWorkItem.author ?? "", category: downloadedWorkItem.category ?? "", mainFandom: downloadedFandoms[0].fandomName ?? "", mainRelationship: downloadedRelationships[0].relationshipName ?? "")
            }
        }
        
        Analytics.logEvent("WorkDetail_MarkForLater_add", parameters: ["workId": bid as NSObject])
        
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            if (del.cookies.count > 0) {
                Alamofire.request(requestStr, method: .get, parameters: [:], encoding: URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                    .response(completionHandler: { response in
                        #if DEBUG
                            print(response.request ?? "")
                            // print(response)
                            print(response.error ?? "")
                        #endif
                        
                        if let d = response.data {
                            self.parseCookies(response)
                            self.parseMarkForLaterResponse(d)
                            self.hideLoadingView()
                            
                            self.checkBookmarkAndUpdate().subscribe(onNext: {}).disposed(by: self.disposeBag)
                            
                        } else {
                            self.hideLoadingView()
                            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                        }
                    })
            }
        }
    }
    
    //MARK: - bookmarks
    
    func bookmarkWorkAction() {
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        if (pseud_id.isEmpty || ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty)) {
            openLoginController()
            triedTo = 1
        } else {
            sendAddBookmarkRequest().subscribe { (event) in
                print(event)
            }.disposed(by: self.disposeBag)
        }
    }
    
    func deletebookmarkWorkAction() {
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("SureDeleteWrkFromBmks"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            
            self.sendDeleteBookmarkRequest()
        }))
        
        deleteAlert.view.tintColor = UIColor(named: "global_tint")
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func sendAddBookmarkRequest() -> Observable<Void> {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 1
            openLoginController() //openLoginController()
            return Observable.empty()
        }
        
        showLoadingView(msg: Localization("AddingBmk"))
        
        var requestStr = "https://archiveofourown.org/works/"
        var bid = ""
        var pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if(pseud_id.isEmpty) {
            if let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String : String] {
                pseud_id = pseuds.first?.value ?? ""
                
                DefaultsManager.putString(pseud_id, key: DefaultsManager.PSEUD_ID)
            }
        }
        
        if (workItem != nil) {
            bid = workItem.workId
            requestStr += bid + "/bookmarks"
            
            
            if ( fandoms != nil && relationships != nil && fandoms.count > 0 && relationships.count > 0) {
                saveToAnalytics(workItem.author, category: workItem.category, mainFandom: fandoms[0].fandomName, mainRelationship: relationships[0].relationshipName)
            }
            
        } else if (downloadedWorkItem != nil) {
            guard let bd = downloadedWorkItem.workId else {
                return Observable.error(ErrorsAF.noWorkId)
            }
            bid = bd
            requestStr += bid + "/bookmarks"
            
            if (downloadedFandoms.count > 0 && downloadedRelationships.count > 0) {
                saveToAnalytics(downloadedWorkItem.author ?? "", category: downloadedWorkItem.category ?? "", mainFandom: downloadedFandoms[0].fandomName ?? "", mainRelationship: downloadedRelationships[0].relationshipName ?? "")
            }
        }
        
        Analytics.logEvent("WorkDetail_Bookmark_add", parameters: ["boomarkableId": bid as NSObject])
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = self.bookmarkToken
        
        params["bookmark"] = ["pseud_id": pseud_id,
            "bookmarkable_id": bid,
            "bookmarkable_type": "Work",
            "bookmarker_notes": "",
            "tag_string": "",
            "collection_names": "",
            "private": "0",
            "rec": "0",
        ]  as AnyObject?
        
        params["commit"] = "Create" as AnyObject?
        
        let headers: HTTPHeaders = [
            "Referer": "https://archiveofourown.org/works/\(bid)",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return Observable.error(ErrorsAF.noCookies)
                }
                cStorage.setCookies(del.cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            }
            
        
        if (del.cookies.count > 0) {
            
            return Observable.create({ (observer) -> Disposable in
                Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.httpBody /*ParameterEncoding.Custom(encodeParams)*/, headers: headers)
                    .response(completionHandler: { response in
                        #if DEBUG
                        print(response.request ?? "")
                        // print(response)
                        print(response.error ?? "")
                        #endif
                        
                        if let d = response.data {
                            self.parseCookies(response)
                            self.hideLoadingView()
                            
                            self.parseAddBookmarkResponse(d)
                            
                            observer.onNext(())
                            observer.onCompleted()
                            
                        } else {
                            self.hideLoadingView()
                            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                        }
                    })
                return Disposables.create()
            }).flatMap{self.checkBookmarkAndUpdate()}
            
            }
        }
        
        return Observable.error(ErrorsAF.noCookies)
    }
    
    func sendDeleteBookmarkRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            triedTo = 2
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: Localization("DeletingBmk"))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        //let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        /*let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            }
        }*/
        
        Analytics.logEvent("WorkDetail_Bookmark_delete", parameters: [:])
        
        var params:[String:AnyObject] = [String:AnyObject]()
     //   params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = self.authToken as AnyObject?
        params["_method"] = "delete" as AnyObject?
        
        request("\(AppDelegate.ao3SiteUrl)\(bookmarkId)", method: .post, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
    }

    func parseDeleteResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] {
            if(noticediv.count > 0) {
                bookmarked = false
                changedSmth = true
//                showNotification(in: self, title: Localization("DeleteFromBmk"), subtitle: noticediv[0].content, type: Type.success, customTypeName: "", callback: {
//
//                })
                
                showSuccess(title: Localization("DeleteFromBmk"), message: noticediv[0].content)
                self.checkBookmarkAndUpdate().subscribe { (_) in
                    
                }.disposed(by: self.disposeBag)
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
                self.showError(title: Localization("DeleteFromBmk"), message: (sorrydiv[0] as AnyObject).content ?? "")

                return
            }
        }
    }
    
    //MARK: - settings menu actions
    
    func downloadWorkAction() {
        
        var wId = ""
    //    var isOnline = true
        var wasSaved = false
        
        if let workItem = self.workItem {
            wId = workItem.workId
         //   isOnline = true
            wasSaved = false
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            wId = downloadedWorkItem.workId ?? "0"
         //   isOnline = false
            wasSaved = true
        }
        
        doDownloadWork(wId: wId, isOnline: false, wasSaved: wasSaved)
        
        Analytics.logEvent("WorkDetail_download", parameters: ["workId": wId as NSObject])
    }
    
   override func onSavedWorkLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        
        print(response.error ?? "")
            #endif
        
        if let d = response.data {
            self.parseCookies(response)
            if let dd = self.downloadWork(d, workItemOld: self.workItem, workItemToReload: self.downloadedWorkItem) {
                self.downloadedWorkItem = dd
                self.workItem = nil
                showDownloadedWork()
                
                self.hideLoadingView()
                
                var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
                let workId = dd.workId ?? "0"
                if worksToReload.contains(workId), let idx = worksToReload.firstIndex(of: workId) {
                    worksToReload.remove(at: idx)
                }
                DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
                
                updateAppBadge()
            }
        } else {
            self.hideLoadingView()
            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
        }
    }
    
    override func onOnlineWorkLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        
        print(response.error ?? "")
            #endif
        
        if let d = response.data {
            self.parseCookies(response)
            let _ = self.downloadWork(d, workItemOld: self.workItem)
            
            var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
            let workId = self.workItem.workId
            if worksToReload.contains(workId), let idx = worksToReload.firstIndex(of: workId) {
                worksToReload.remove(at: idx)
            }
            DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
            
            updateAppBadge()
            
        } else {
            self.hideLoadingView()
            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
        }
    }
    
    func deleteWork() {
        if (downloadedWorkItem != nil) {
            let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("SureDeleteWrk"), preferredStyle: UIAlertController.Style.alert)
            
            deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .default, handler: { (action: UIAlertAction) in
                print("Cancel")
            }))
            
            deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
                
                let wId = self.downloadedWorkItem.workId ?? "0"
                
                Analytics.logEvent("WorkDetail_delete_from_db", parameters: ["workId": self.downloadedWorkItem.workId ?? "0" as NSObject])
                
                guard let appDel:AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                let context = appDel.persistentContainer.viewContext
                context.delete(self.downloadedWorkItem as NSManagedObject)
                do {
                    try context.save()
                } catch _ {
                    NSLog("Cannot delete saved work")
                    self.showError(title: Localization("Error"), message: Localization("CannotDeleteWrk"))
                }
                
                self.saveWorkNotifItem(workId: wId, wasDeleted: NSNumber(booleanLiteral: true))
                self.sendAllNotSentForDelete()
                
                self.showSuccess(title: Localization("Success"), message: Localization("WorkDeletedFromDownloads"))
            }))
            
            deleteAlert.view.tintColor = UIColor(named: "global_tint")
            
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func commentWorkAction() {
        //let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        //let nextViewController: CommentViewController = storyBoard.instantiateViewControllerWithIdentifier("commentViewController") as! CommentViewController
       // self.navigationController?.pushViewController(nextViewController, animated: true) //presentViewController(nextViewController, animated:true, completion:nil)
        self.performSegue(withIdentifier: "leaveComment", sender: self)
    }
    
    func stopNotifAction() {
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        
        var workId = ""
        
        if (workItem != nil) {
            workId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            workId = downloadedWorkItem.workId ?? "0"
        }
        
        if worksToReload.contains(workId), let idx = worksToReload.firstIndex(of: workId) {
            worksToReload.remove(at: idx)
        }
        if worksToReload.contains(""), let idx = worksToReload.firstIndex(of: "") {
            worksToReload.remove(at: idx)
        }
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        
        updateAppBadge()
    }
    
    @IBAction func settingsButtonTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: Localization("WrkOptions"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        
        if (downloadedWorkItem != nil) {
            let deleteAction = UIAlertAction(title: Localization("DeleteWrk"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deleteWork()
            })
            optionMenu.addAction(deleteAction)
        }
        
        let markNotifAction = UIAlertAction(title: "Clear Notifications For This Work", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.stopNotifAction()
        })
        optionMenu.addAction(markNotifAction)
        
        if (downloadedWorkItem != nil) {
            let reloadAction = UIAlertAction(title: Localization("ReloadWrk"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(reloadAction)
        } else if (workItem != nil  && !isSensitive) {
            let saveAction = UIAlertAction(title: Localization("DownloadWrk"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(saveAction)
        }
        
        let commentAction = UIAlertAction(title: Localization("ViewComments"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.commentWorkAction()
        })
        optionMenu.addAction(commentAction)
        
        let kudosAction = UIAlertAction(title: Localization("LeaveKudos"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            self.leaveKudos().subscribe({ (_) in
            }).disposed(by: self.disposeBag)
        })
        optionMenu.addAction(kudosAction)
        
        if (!bookmarked) {
            let bookmarkAction = UIAlertAction(title: Localization("Bookmark"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.bookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        } else {
            let bookmarkAction = UIAlertAction(title: Localization("DeleteBmk"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deletebookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        }
        
        if (self.markedForLater == false) {
            let markForLaterAction = UIAlertAction(title: Localization("MarkForLater"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.markForLaterWorkAction()
            })
            optionMenu.addAction(markForLaterAction)
        } else {
            let markAsReadAction = UIAlertAction(title: Localization("MarkAsRead"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.markAsReadWorkAction()
            })
            optionMenu.addAction(markAsReadAction)
        }
        
        if (downloadUrls.count > 0 && !isSensitive) {
            let downloadAction = UIAlertAction(title: Localization("DownloadFile"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.showDownloadDialog()
            })
            optionMenu.addAction(downloadAction)
        }
        
        let browserAction = UIAlertAction(title: Localization("OpenInBrowser"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openBrowserAction()
        })
        optionMenu.addAction(browserAction)
        
        let shareAction = UIAlertAction(title: Localization("Share"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.shareFic()
        })
        optionMenu.addAction(shareAction)
        
        //
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        
        let authorCellIndexPath = IndexPath(row: 0, section: 0)
        self.tableView.rectForRow(at: authorCellIndexPath)
        
        let senderView = (sender as! UIView)
        
        optionMenu.popoverPresentationController?.sourceView = self.tableView
        optionMenu.popoverPresentationController?.sourceRect =  self.tableView.convert(senderView.frame, from: senderView.superview)
        
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func showDownloadDialog() {
        
        let keys: [String] = Array(downloadUrls.keys)
        
        let optionMenu = UIAlertController(title: nil, message: Localization("WrkOptions"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        
        for key in keys {
            let downloadAction = UIAlertAction(title: key, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadFile(downloadUrl: self.downloadUrls[key] ?? "")
            })
            optionMenu.addAction(downloadAction)
        }
        
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView = self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func leaveKudos() -> Observable<Void> {
        var workId = ""
        
        if (workItem != nil) {
            workId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            workId = downloadedWorkItem.workId ?? "0"
        }
        
        Analytics.logEvent("WorkDetail_Kudos_add", parameters: ["workId": workId as NSObject])
                
        return doLeaveKudos(workId: workId, kudosToken: self.kudosToken)
        
    }
    
    
    
    //MARK: - update work
    
    func updateWork(workItem: WorkItem) {
        self.downloadedWorkItem.words = workItem.words
        self.downloadedWorkItem.chaptersCount = workItem.chaptersCount
        self.downloadedWorkItem.hits = workItem.hits
        self.downloadedWorkItem.kudos = workItem.kudos
        self.downloadedWorkItem.bookmarks = workItem.bookmarks
        self.downloadedWorkItem.comments = workItem.comments
        
        saveChanges()
        
        if (workItem.needReload) {
            let delay = 0.2 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time) {
                DispatchQueue.main.asyncAfter(deadline: time) {
//                    showNotification(in: self, title: Localization("Update"), subtitle: Localization("UpdateAvail"), type: Type.success, customTypeName: "", duration: 15.0, callback: {
//
//                    } , canBeDismissedByUser: true)
                    self.showSuccess(title: Localization("Update"), message: Localization("UpdateAvail"))
                }
            }
        }
    }
    
    func saveChanges() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        appDelegate.saveContext()
    }
    
    //MARK: - Banner
    
//   func bannerViewWillLoadAd(banner: ADBannerView) {
//        NSLog("Ad Banner will load ad.")
//    }
//
//    func bannerViewDidLoadAd(banner: ADBannerView) {
//        NSLog("Ad Banner did load ad.")
//        
//        if (!purchased) {
//        UIView.animateWithDuration(0.5, animations: {
//            self.adBanner.alpha = 1.0 })
//        }
//    }
//    
//    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
//        return true
//    }
//    
//    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
//       self.adBanner.alpha = 0.0
//    }
    
    
    @objc override func controllerDidClosed() {
        //if (!purchased) {
        //    showMoPubInterstitial()
        //}
    }
    
    @objc func controllerDidClosedWithLogin() {
        
        
        switch (triedTo) {
        case 0:
            self.checkBookmarkAndUpdate()
                .flatMap { self.leaveKudos() }
                .subscribe { (_) in
            }.disposed(by: self.disposeBag)
            
        case 1:
            self.checkBookmarkAndUpdate()
                .flatMap { self.sendAddBookmarkRequest() }
                .subscribe { (_) in
                }.disposed(by: self.disposeBag)
        case 2:
            sendDeleteBookmarkRequest()
        case 3:
            sendMarkForLaterRequest()
        case 4:
            sendMarkAsReadRequest()
        default: break
        }
        triedTo = -1
        
        self.loginPublishSubject.onNext(())
    }
    
    func downloadFile(downloadUrl: String) {
        let finalPath = "https://archiveofourown.org" + downloadUrl
        print("download"+downloadUrl)
        
        Analytics.logEvent("WorkDetail_download_file", parameters: ["url": downloadUrl as NSObject])
        
        if let url = URL(string: finalPath) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([ : ]), completionHandler: { (res) in
                print(res)
            })
        }
        
        //http://stackoverflow.com/questions/27959023/swift-how-to-open-local-pdf-from-my-app-to-ibooks
        
//        Alamofire.download(.GET, downloadUrl, { (temporaryURL, response) in
//            
//            if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
//                
//                fileName = response.suggestedFilename!
//                finalPath = directoryURL.URLByAppendingPathComponent(fileName!)
//                return finalPath!
//            }
//            
//            return temporaryURL
//        })
//            .response { (request, response, data, error) in
//                
//                if error != nil {
//                    println("REQUEST: \(request)")
//                    println("RESPONSE: \(response)")
//                } 
//                
//                if finalPath != nil {
//                    doSomethingWithTheFile(finalPath!, fileName: fileName!)
//                    var docController: UIDocumentInteractionController?
//                    docController = UIDocumentInteractionController(URL: finalPath)
//                    let url = NSURL(string:"itms-books:");
//                    if UIApplication.sharedApplication().canOpenURL(url!) {
//                        docController!.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
//                        println("iBooks is installed")
//                    }else{
//                        println("iBooks is not installed")
//                    }
//                }
//        }
    }
    
    func openBrowserAction() {
        var wId = ""
        if (workItem != nil) {
            wId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            wId = downloadedWorkItem.workId ?? ""
        }
        
        Analytics.logEvent("WorkDetail_browser_open", parameters: ["workId": wId as NSObject])
        
        UIApplication.shared.open(URL(string: "https://archiveofourown.org/works/\(wId)")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([ : ]), completionHandler: { (res) in
            print("open url \(res)")
        })

    }
    
    func shareFic() {
        var wId = ""
      //  var wname = ""
        if (workItem != nil) {
            wId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            wId = downloadedWorkItem.workId ?? ""
        }
        
        Analytics.logEvent("WorkDetail_share", parameters: ["workId": wId as NSObject])
        
        let url = URL(string: "https://archiveofourown.org/works/\(wId)")!
        
        let shareItems:Array = [url]
        let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
       // activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToVimeo]
        self.present(activityViewController, animated: true, completion: nil)

    }
    
    override func kudosToAnalytics() {
        var author = ""
        var category = ""
        var fandom = ""
        var relationship = ""
        
        if (workItem != nil) {
            author = workItem.author
            category = workItem.category
            
            if (fandoms != nil && fandoms.count > 0) {
                fandom = fandoms[0].fandomName
            }
            
            if (relationships != nil && relationships.count > 0) {
                relationship = relationships[0].relationshipName
            }
        } else if (downloadedWorkItem != nil) {
            
            author = downloadedWorkItem.author ?? ""
            category = downloadedWorkItem.category ?? ""
            
            if (downloadedFandoms != nil && downloadedFandoms.count > 0) {
                fandom = downloadedFandoms[0].fandomName ?? ""
            }
            
            if (downloadedRelationships != nil && downloadedRelationships.count > 0) {
                relationship = downloadedRelationships[0].relationshipName ?? ""
            }
        }
        
        saveToAnalytics(author, category: category, mainFandom: fandom, mainRelationship: relationship)
        
        if (workItem != nil) {
            self.hideLoadingView()
            showOnlineWork()
        }
    }
   
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

