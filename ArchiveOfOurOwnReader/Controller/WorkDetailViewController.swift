//
//  WorkDetailViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 8/26/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds
import TSMessages
import Alamofire
import Crashlytics

class WorkDetailViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    var modalDelegate:ModalControllerDelegate?
    
    @IBOutlet weak var downloadTrashButton: UIButton!
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var authorImage: RoundImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var langLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var ratingImg: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var authorView: UIView!
     @IBOutlet weak var bannerView: GADBannerView!
    
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
    var changedSmth = false
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var NEXT_CHAPTER_EXIST = 1
    var NEXT_CHAPTER_NOT_EXIST = -1
    
    var commentsUrl = ""
    var tagUrl = ""
    
    var isSensitive = false
    
    var fromNotif = false
    
    var downloadUrls: [String:String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
       // donated = false
      //  purchased = true
        
        if ((purchased || donated) && DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        }
        
        if (purchased == false && donated == false) {
            //loadAdMobInterstitial()
            bannerView.adUnitID = "ca-app-pub-8760316520462117/1990583589"
            bannerView.rootViewController = self
            let request = GADRequest()
            request.testDevices = [ kGADSimulatorID ]
            bannerView.load(request)
            
        } else {
            self.bannerView.isHidden = true
        }
        //self.bannerView.isHidden = true
        let name = String(format:"b%d", Int(arc4random_uniform(4)))
        bgImage.image = UIImage(named:name)
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 64
        
        self.readButton.layer.cornerRadius = AppDelegate.smallCornerRadius
        self.bgView.layer.cornerRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        self.authorView.layer.shadowRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.shadowOffset = CGSize(width: 2.0, height: 1.5)
        self.authorView.layer.shadowOpacity = 0.7
        self.authorView.layer.shadowColor = AppDelegate.darkerGreyColor.cgColor
        
        self.authorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.authorTouched(_:))))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        if (workUrl.isEmpty == false) {
            let workIdArr = workUrl.split(separator: "/")
            if (workIdArr.count > 0) {
                let workId = String(workIdArr[workIdArr.count - 1])
                
                downloadedWorkItem = getWorkById(workId: workId)
            }
            if (downloadedWorkItem != nil) {
                
                showDownloadedWork()
            } else {
                workItem = WorkItem()
                showOnlineWork(workUrl)
            }
        } else if (workItem != nil) {
            if (workItem.isDownloaded == true) {
                
                if let downloadedWork = getWorkById(workId: workItem.workId) {
                    self.downloadedWorkItem = downloadedWork
                    self.updateWork(workItem: workItem)
                    self.workItem = nil
                    self.showDownloadedWork()
                } else {
                    showOnlineWork()
                }
                
            } else {
                showOnlineWork()
            }
        } else if (downloadedWorkItem != nil) {
            showDownloadedWork()
        }
        
        self.checkBookmarkAndUpdate()
        
        if (self.fromNotif == true) {
            Answers.logCustomEvent(withName: "WorkDetail: from notification",
                                   customAttributes: [:])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.isHidden = false
        // let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor(red: 99/255, green: 0, blue: 0, alpha: 1)]
        // self.navigationController?.navigationBar.titleTextAttributes = titleDict as [NSObject : AnyObject]
        
        if (workItem != nil) {
            self.title = workItem.workTitle
        } else if (downloadedWorkItem != nil) {
            self.title = downloadedWorkItem.workTitle ?? ""
        }
        
        tableView.backgroundColor = UIColor.clear
        
        if (theme == DefaultsManager.THEME_DAY) {
            tableView.separatorColor = AppDelegate.greyLightColor
            bgView.backgroundColor = AppDelegate.whiteTransparentColor
            authorView.backgroundColor = AppDelegate.whiteTransparentColor
            readButton.backgroundColor = AppDelegate.whiteTransparentColor
            readButton.setTitleColor(AppDelegate.redColor, for: .normal)
            downloadTrashButton.setImage(UIImage(named: "settings"), for: UIControlState.normal)
            titleLabel.textColor = UIColor.black
            authorLabel.textColor = AppDelegate.darkerGreyColor
            dateLabel.textColor = AppDelegate.greyColor
            authorView.layer.shadowColor = AppDelegate.darkerGreyColor.cgColor
        } else {
            tableView.separatorColor = AppDelegate.greyBg
            bgView.backgroundColor = AppDelegate.greyTransparentColor
            authorView.backgroundColor = AppDelegate.greyTransparentColor
            readButton.backgroundColor = AppDelegate.greyTransparentColor
            titleLabel.textColor = UIColor.white
            readButton.setTitleColor(UIColor.white, for: .normal)
            downloadTrashButton.setImage(UIImage(named: "settings_light"), for: UIControlState.normal)
            authorLabel.textColor = UIColor.white
            dateLabel.textColor = AppDelegate.nightTextColor
            authorView.layer.shadowColor = AppDelegate.redColor.cgColor
        }
        
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
    
    
    
    func showDownloadedWork() {
        
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        let wId = downloadedWorkItem.workId ?? ""
        if worksToReload.contains(wId), let idx = worksToReload.index(of: wId) {
            worksToReload.remove(at: idx)
        }
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        
        updateAppBadge()
        
        let auth = downloadedWorkItem.author ?? ""
        authorLabel.text = "\(auth)" // = underlineAttributedString
        langLabel.text = downloadedWorkItem.language ?? "-"
        dateLabel.text = downloadedWorkItem.datetime ?? ""
        
        let title = downloadedWorkItem.workTitle ?? ""
        let trimmedTitle = title.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        
        titleLabel.text = trimmedTitle
        
        categoryLabel.text = downloadedWorkItem.category ?? ""
        completeLabel.text = downloadedWorkItem.complete ?? ""
        
        switch (downloadedWorkItem.ratingTags ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            ratingImg.image = UIImage(named: "NC17")
        case "Explicit":
            ratingImg.image = UIImage(named: "R")
        default:
            ratingImg.image = UIImage(named: "NotRated")
        }
        
        
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
            self.tableView.flashScrollIndicators()
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
        var worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
        if worksToReload.contains(workId), let idx = worksToReload.index(of: workId) {
            worksToReload.remove(at: idx)
        }
        DefaultsManager.putStringArray(worksToReload, key: DefaultsManager.NOTIF_IDS_ARR)
        
        updateAppBadge()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
        var vadult = ""
        params["view_adult"] = "true" as AnyObject?
        vadult = "?view_adult=true"
        
        showLoadingView(msg: NSLocalizedString("LoadingWrk", comment: ""))
        
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
                    self.showWork()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
        
    }
    
    func downloadCurWork(_ data: Data) {
        
        //let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        //print("the string is: \(dta)")
        
        if (workItem == nil) {
            Answers.logCustomEvent(withName: "WorkDetail: Show Online", customAttributes: ["downloadCurWork" : "is nil"])
            return
        }
        
        onlineChapters.removeAll()
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
        
        if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
            workItem.author = NSLocalizedString("Sorry", comment: "")
            workItem.workTitle = NSLocalizedString("WrkAvailOnlyRegistered", comment: "");
            workItem.complete = "";
         //   return NEXT_CHAPTER_NOT_EXIST;
            return
        }
        }
        
        if let caution = doc.search(withXPathQuery: "//p[@class='caution']") as? [TFHppleElement],
            caution.count > 0,
            let _ = caution[0].text().range(of: "adult content")  {
            
            workItem.author = NSLocalizedString("Sorry", comment: "")
            workItem.workTitle = NSLocalizedString("ContainsAdultContent", comment: "")
            workItem.complete = ""
            
            return
        }
        
        if let errH = doc.search(withXPathQuery: "//h2[@class='heading']") {
        
        if (errH.count>0 && (errH[0] as! TFHppleElement).text().range(of: "Error") != nil) {
            workItem.author = NSLocalizedString("Sorry", comment: "")
            workItem.workTitle = NSLocalizedString("AO3Issue", comment: "")
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
                let attributes : NSDictionary = (fandomsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                f.fandomUrl = (attributes["href"] as? String ?? "")
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
                let attributes : NSDictionary = (relationshipsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                r.relationshipUrl = (attributes["href"] as? String ?? "")
                relationships.append(r)
            }
            
            var charactersLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='character tags']/ul[@class='commas']/li") as! [TFHppleElement]
            characters = [CharacterItem]()
            
            for i in 0..<charactersLiArr.count {
                var c : CharacterItem = CharacterItem()
                c.characterName = charactersLiArr[i].content
                let attributes : NSDictionary = (charactersLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                c.characterUrl = (attributes["href"] as? String ?? "")
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
                        let attributes: NSDictionary = (attributesEl[0] as AnyObject).attributes as NSDictionary
                        workItem.serieUrl = (attributes["href"] as? String ?? "")
                    }
                }
            }
            }
            
            workItem.stats = ""
            
            if let statsElDt: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dt") as? [TFHppleElement],
                let statsElDd: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dd") as? [TFHppleElement] {
                
                if(statsElDt.count > 0 && statsElDd.count > 0) {
                    for i in 0..<statsElDt.count {
                        workItem.stats += statsElDt[i].text() + " "
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
            } else if let datesEl: [TFHppleElement] = stats?.search(withXPathQuery: "//dd[@class='published']") as? [TFHppleElement], datesEl.count > 0 {
                workItem.datetime = datesEl[0].text() ?? ""
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
                        let attributes : NSDictionary = (nxt[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                        workItem.nextChapter = (attributes["href"] as? String) ?? ""
                    }
                    NSLog("%@", workItem.nextChapter)
                }
                
                if (workItem.workId.isEmpty == true) {
                if let mark : [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='mark']") as? [TFHppleElement] {
                    if (mark.count > 0) {
                        let attributes : NSDictionary = (mark[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                        let str = attributes["href"] as? String
                        
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
        
        if var chaptersEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@id='chapter_index']") as? [TFHppleElement] {
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
    
    func checkBookmarkAndUpdate() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        
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
                            TSMessage.showNotification(in: self, title: NSLocalizedString("Update", comment: ""), subtitle: NSLocalizedString("UpdateAvail", comment: ""), type: TSMessageNotificationType.success, duration: 15.0, canBeDismissedByUser: true)
                        }
                    }
                }
            })
        
       
    }
    
    func parseCheckBookmarkAndUpdate(_ data: Data) {
        downloadUrls.removeAll()
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let bookmarkIdEls = doc.search(withXPathQuery: "//div[@id='bookmark-form']") as? [TFHppleElement] {
            if (bookmarkIdEls.count > 0) {
                if let formEls = bookmarkIdEls[0].search(withXPathQuery: "//form") as? [TFHppleElement] {
                    if (formEls.count > 0) {
                        if let attributes : NSDictionary = formEls[0].attributes as NSDictionary?  {
                            bookmarkId = (attributes["action"] as? String ?? "")
                        }
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
                        let attributes : NSDictionary = (downloadUl[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                        let key: String = downloadUl[i].content ?? ""
                        let val: String = attributes["href"] as? String ?? ""
                        
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
                TSMessage.showNotification(in: self, title: NSLocalizedString("AddingBmk", comment: ""), subtitle: noticediv[0].content, type: .success)
            
                changedSmth = true
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                TSMessage.showNotification(in: self, title: NSLocalizedString("AddingBmk", comment: ""), subtitle: (sorrydiv[0] as AnyObject).content, type: .error)
                return
            }
        }
        
        if (data.isEmpty) {
            TSMessage.showNotification(in: self, title: NSLocalizedString("CannotAddBmk", comment: ""), subtitle: "Response Is Empty", type: .error)
        }
        return
    }
    
    //MARK: - show work
    
    func showWork() {
        
        authorLabel.text = "\(workItem.author)"
        dateLabel.text = workItem.datetime
        titleLabel.text = workItem.workTitle
        langLabel.text = workItem.language
        
        categoryLabel.text = workItem.category
        completeLabel.text = workItem.complete
        
        switch workItem.ratingTags.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            ratingImg.image = UIImage(named: "NC17")
        case "Explicit":
            ratingImg.image = UIImage(named: "R")
        default:
            ratingImg.image = UIImage(named: "NotRated")
        }
        
        tableView.reloadData()
        
        hideLoadingView()
        
        tableView.flashScrollIndicators()
        
        if (!DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            performSegue(withIdentifier: "readSegue", sender: nil)
        }
        
        if (isSensitive == true) {
            readButton.isEnabled = false
            readButton.alpha = 0.5
            
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("SensitiveContent", comment: ""), type: .warning, duration: 9.999999999999999e999, canBeDismissedByUser: true)
        }
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "readSegue") {
                        
            let workController: WorkViewController = segue.destination as! WorkViewController
            
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
                    
                    Answers.logCustomEvent(withName: "WorkDetail: view serie", customAttributes: ["work" : "online", "id" : cController.serieId ])
                    
                } else if (downloadedWorkItem != nil) {
                    cController.serieId = downloadedWorkItem.serieUrl ?? ""
                    
                    Answers.logCustomEvent(withName: "WorkDetail: view serie", customAttributes: ["work" : "downloaded", "id" : cController.serieId ])
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
        var cell: WorkDetailCell! = nil
        
        if (indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 9) {
            cell = tableView.dequeueReusableCell(withIdentifier: "txtCell") as! WorkDetailCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! WorkDetailCell
        }
        
        if (cell == nil) {
            if (indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 9) {
                cell = WorkDetailTxtCell(style: UITableViewCellStyle.default, reuseIdentifier: "txtCell")
            } else {
                if(cell == nil) {
                    cell = WorkDetailCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
                }
            }
        }
        
        if (indexesToHide != nil) {
            indexesToHide.removeAll(keepingCapacity: false)
        } else {
            indexesToHide = [Int]()
        }
        
        var txtColor: UIColor = UIColor.white
        if (theme == DefaultsManager.THEME_DAY) {
            txtColor = AppDelegate.redColor
        } else {
            txtColor = AppDelegate.nightTextColor
        }
        cell.label.textColor = txtColor
        cell.backgroundColor = UIColor.clear
        
        switch (indexPath.section) {
        case 0:
            
            cell.label.textColor = txtColor
            if (UIDevice.current.userInterfaceIdiom == .pad) {
                cell.label.font = UIFont(name: "Helvetica Neue Light Italic", size: 18.0)
            } else {
                cell.label.font = UIFont(name: "Helvetica Neue Light Italic", size: 12.0) //.italicSystemFont(ofSize: 12.0)
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
                cell.label.font = UIFont.systemFont(ofSize: 21.0, weight: UIFont.Weight.regular)
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
                    cell!.label.text = NSLocalizedString("SensitiveContent", comment: "")
                }
            } else if (downloadedWorkItem != nil) {
                cell!.label.text = downloadedWorkItem.topicPreview ?? "No Preview"
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
                cell!.label.text = "\(workItem.words) \(NSLocalizedString("Words", comment: ""))"
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
                cell.label.font = UIFont.systemFont(ofSize: 21.0, weight: UIFont.Weight.regular)
            } else {
                cell.label.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            }
            
            cell!.imgView.image = nil
            
        default:
            break
        }
        
        
        return cell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (workItem != nil && workItem.serieUrl.isEmpty) {
            return 8
        } else if (downloadedWorkItem != nil && (downloadedWorkItem.serieUrl ?? "").isEmpty) {
            return 8
        } else {
            return 9
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var res:Int = 1
        
        switch (section) {
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
        self.tagUrl = ""
        
        switch indexPath.section {
        case 4:
                if (fandoms != nil && fandoms.count > pos) {
                    tagUrl = fandoms[pos].fandomUrl
                } else if (downloadedFandoms != nil && downloadedFandoms.count > pos) {
                    tagUrl = downloadedFandoms[pos].fandomUrl ?? ""
                }
                NSLog("link Tapped = " + tagUrl)
                
                if (tagUrl.isEmpty == false) {
                    performSegue(withIdentifier: "listSegue", sender: self)
                }
            
        case 5:
            if (relationships != nil && relationships.count > pos) {
                tagUrl = relationships[pos].relationshipUrl
            } else if (downloadedRelationships != nil && downloadedRelationships.count > pos) {
                tagUrl = downloadedRelationships[pos].relationshipUrl ?? ""
            }
            NSLog("link Tapped = " + tagUrl)
            
            if (tagUrl.isEmpty == false) {
                performSegue(withIdentifier: "listSegue", sender: self)
            }
            
        case 6:
            if (characters != nil && characters.count > pos) {
                tagUrl = characters[pos].characterUrl
            } else if (downloadedCharacters != nil && downloadedCharacters.count > pos) {
                tagUrl = downloadedCharacters[pos].characterUrl ?? ""
            }
            NSLog("link Tapped = " + tagUrl)
                        
            if (tagUrl.isEmpty == false) {
                performSegue(withIdentifier: "listSegue", sender: self)
            }
            
        case 8:
            performSegue(withIdentifier: "showSerie", sender: self)
            
        default:
            break
        }
    }
    
    @objc func authorTouched(_ sender: UITapGestureRecognizer) {
        var authorName = ""
        
        if(workItem != nil) {
            authorName = workItem.author
        } else if (downloadedWorkItem != nil) {
            authorName = downloadedWorkItem.author ?? ""
        }
        
        Answers.logCustomEvent(withName: "WorkDetail: author touched",
                               customAttributes: [
                                "author": authorName])
        
        if (authorName.contains(" ") && !authorName.contains(",")) {
            let nameArr = authorName.split{$0 == " "}.map(String.init)
            var an = nameArr[1].replacingOccurrences(of: "(", with: "")
            an = an.replacingOccurrences(of: ")", with: "")
            tagUrl = an //"https://archiveofourown.org/users/\(an)/pseuds/\(nameArr[0])/works"
        } else if (authorName.contains(",")) {
            let nameArr = authorName.split{$0 == ","}.map(String.init)
            tagUrl = nameArr[0] //"https://archiveofourown.org/users/\(nameArr[0])/works"
        } else {
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
        
        showLoadingView(msg: NSLocalizedString("MarkingForLater", comment: ""))
        
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
        
        Answers.logCustomEvent(withName: "WorkDetail: MarkAsRead",
                               customAttributes: [
                                "workId": bid])
        
        
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
                            
                            self.checkBookmarkAndUpdate()
                            
                        } else {
                            self.hideLoadingView()
                            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
                TSMessage.showNotification(in: self, title: NSLocalizedString("MarkingForLater", comment: ""), subtitle: noticediv[0].content, type: .success)
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                TSMessage.showNotification(in: self, title: NSLocalizedString("MarkingForLater", comment: ""), subtitle: (sorrydiv[0] as AnyObject).content, type: .error)
                return
            }
        }
        
        if (data.isEmpty) {
            TSMessage.showNotification(in: self, title: NSLocalizedString("CannotMark", comment: ""), subtitle: "Response Is Empty", type: .error)
        }
        return
    }
    
    func sendMarkForLaterRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 3
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: NSLocalizedString("MarkingForLater", comment: ""))
        
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
        
        Answers.logCustomEvent(withName: "WorkDetail: MarkForLater add",
                               customAttributes: [
                                "workId": bid])
        
        
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
                            
                            self.checkBookmarkAndUpdate()
                            
                        } else {
                            self.hideLoadingView()
                            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
            sendAddBookmarkRequest()
        }
    }
    
    func deletebookmarkWorkAction() {
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteWrkFromBmks", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            self.sendDeleteBookmarkRequest()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func sendAddBookmarkRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 1
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: NSLocalizedString("AddingBmk", comment: ""))
        
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
                return
            }
            bid = bd
            requestStr += bid + "/bookmarks"
            
            if (downloadedFandoms.count > 0 && downloadedRelationships.count > 0) {
                saveToAnalytics(downloadedWorkItem.author ?? "", category: downloadedWorkItem.category ?? "", mainFandom: downloadedFandoms[0].fandomName ?? "", mainRelationship: downloadedRelationships[0].relationshipName ?? "")
            }
        }
        
        Answers.logCustomEvent(withName: "WorkDetail: Bookmark add",
                               customAttributes: [
                                "boomarkableId": bid])
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        
        params["bookmark"] = ["pseud_id": pseud_id,
            "bookmarkable_id": bid,
            "bookmarkable_type": "Work",
            "notes": "",
            "tag_string": "",
            "collection_names": "",
            "private": "0",
            "rec": "0",
        ]  as AnyObject?
        
        params["commit"] = "Create" as AnyObject?
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
        
        if (del.cookies.count > 0) {
            Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                .response(completionHandler: { response in
                    #if DEBUG
                    print(response.request ?? "")
                    // print(response)
                    print(response.error ?? "")
                        #endif
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseAddBookmarkResponse(d)
                        self.hideLoadingView()
                        
                        self.checkBookmarkAndUpdate()
                        
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                    }
                })
            }
        }
    }
    
    func sendDeleteBookmarkRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            triedTo = 2
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: NSLocalizedString("DeletingBmk", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
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
        
        Answers.logCustomEvent(withName: "WorkDetail: Bookmark delete",
                               customAttributes: [:])
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        params["_method"] = "delete" as AnyObject?
        
        request("https://archiveofourown.org" + bookmarkId, method: .post, parameters: params)
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
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)

                }
            })
    }

    func parseDeleteResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] {
            if(noticediv.count > 0) {
                bookmarked = false
                changedSmth = true
                TSMessage.showNotification(in: self, title: NSLocalizedString("DeleteFromBmk", comment: ""), subtitle: noticediv[0].content, type: .success)
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
                TSMessage.showNotification(in: self, title: NSLocalizedString("DeleteFromBmk", comment: ""), subtitle: (sorrydiv[0] as AnyObject).content, type: .error)

                return
            }
        }
    }
    
    //MARK: - settings menu actions
    
    func downloadWorkAction() {
        
        var wId = ""
        var isOnline = true
        
        if let workItem = self.workItem {
            wId = workItem.workId
            isOnline = true
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            wId = downloadedWorkItem.workId ?? "0"
            isOnline = false
        }
        
        doDownloadWork(wId: wId, isOnline: isOnline)
        
        Answers.logCustomEvent(withName: "WorkDetail: download",
                               customAttributes: [
                                "workId": wId])

    }
    
   override func onSavedWorkLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        
        print(response.error ?? "")
            #endif
        
        if let d = response.data {
            self.parseCookies(response)
            if let dd = self.downloadWork(d, workItemToReload: self.downloadedWorkItem) {
                self.downloadedWorkItem = dd
                showDownloadedWork()
            }
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
            
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
        }
    }
    
    func deleteWork() {
        if (downloadedWorkItem != nil) {
            let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteWrk", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
                print("Cancel")
            }))
            
            deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
                
                let wId = self.downloadedWorkItem.workId ?? "0"
                
                Answers.logCustomEvent(withName: "WorkDetail: delete from db",
                                       customAttributes: [
                                        "workId": self.downloadedWorkItem.workId ?? "0"])
                
                guard let appDel:AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                let context = appDel.persistentContainer.viewContext
                context.delete(self.downloadedWorkItem as NSManagedObject)
                do {
                    try context.save()
                } catch _ {
                    NSLog("Cannot delete saved work")
                    
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotDeleteWrk", comment: ""), type: .error)
                }
                
                self.saveWorkNotifItem(workId: wId, wasDeleted: NSNumber(booleanLiteral: true))
                self.sendAllNotSentForDelete()
                
                TSMessage.showNotification(in: self, title: NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("WorkDeletedFromDownloads", comment: ""), type: .success)
            }))
            
            deleteAlert.view.tintColor = AppDelegate.redColor
            
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    func commentWorkAction() {
        //let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        //let nextViewController: CommentViewController = storyBoard.instantiateViewControllerWithIdentifier("commentViewController") as! CommentViewController
       // self.navigationController?.pushViewController(nextViewController, animated: true) //presentViewController(nextViewController, animated:true, completion:nil)
        self.performSegue(withIdentifier: "leaveComment", sender: self)
    }
    
    @IBAction func settingsButtonTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("WrkOptions", comment: ""), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        if (downloadedWorkItem != nil) {
            let deleteAction = UIAlertAction(title: NSLocalizedString("DeleteWrk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deleteWork()
            })
            optionMenu.addAction(deleteAction)
        }
        
        if (workItem != nil  && !isSensitive) {
            let saveAction = UIAlertAction(title: NSLocalizedString("DownloadWrk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(saveAction)
        } else if (downloadedWorkItem != nil) {
            let reloadAction = UIAlertAction(title: NSLocalizedString("ReloadWrk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(reloadAction)
        }
        
        let commentAction = UIAlertAction(title: NSLocalizedString("ViewComments", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.commentWorkAction()
        })
        optionMenu.addAction(commentAction)
        
        let kudosAction = UIAlertAction(title: NSLocalizedString("LeaveKudos", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.leaveKudos()
        })
        optionMenu.addAction(kudosAction)
        
        if (!bookmarked) {
            let bookmarkAction = UIAlertAction(title: NSLocalizedString("Bookmark", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.bookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        } else {
            let bookmarkAction = UIAlertAction(title: NSLocalizedString("DeleteBmk", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deletebookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        }
        
        if (self.markedForLater == false) {
            let markForLaterAction = UIAlertAction(title: NSLocalizedString("MarkForLater", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.markForLaterWorkAction()
            })
            optionMenu.addAction(markForLaterAction)
        } else {
            let markAsReadAction = UIAlertAction(title: NSLocalizedString("MarkAsRead", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.markAsReadWorkAction()
            })
            optionMenu.addAction(markAsReadAction)
        }
        
        if (downloadUrls.count > 0 && !isSensitive) {
            let downloadAction = UIAlertAction(title: NSLocalizedString("DownloadFile", comment: ""), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.showDownloadDialog()
            })
            optionMenu.addAction(downloadAction)
        }
        
        let browserAction = UIAlertAction(title: NSLocalizedString("OpenInBrowser", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openBrowserAction()
        })
        optionMenu.addAction(browserAction)
        
        //
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.titleLabel
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.titleLabel.bounds.size.width / 2.0, y: self.titleLabel.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        optionMenu.view.tintColor = AppDelegate.redColor
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func showDownloadDialog() {
        
        let keys: [String] = Array(downloadUrls.keys)
        
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("WrkOptions", comment: ""), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        for key in keys {
            let downloadAction = UIAlertAction(title: key, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadFile(downloadUrl: self.downloadUrls[key] ?? "")
            })
            optionMenu.addAction(downloadAction)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView = self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        optionMenu.view.tintColor = AppDelegate.redColor
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func leaveKudos() {
        var workId = ""
        
        if (workItem != nil) {
            workId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            workId = downloadedWorkItem.workId ?? "0"
        }
        
        Answers.logCustomEvent(withName: "WorkDetail: Kudos add",
                               customAttributes: [
                                "workId": workId])
        
        doLeaveKudos(workId: workId)
        
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
                TSMessage.showNotification(in: self, title: NSLocalizedString("Update", comment: ""), subtitle: NSLocalizedString("UpdateAvail", comment: ""), type: TSMessageNotificationType.success, duration: 2.0, canBeDismissedByUser: true)
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
    
    
    override func controllerDidClosed() {
        //if (!purchased) {
        //    showMoPubInterstitial()
        //}
    }
    
    func controllerDidClosedWithLogin() {
        switch (triedTo) {
        case 0:
            leaveKudos()
        case 1:
            sendAddBookmarkRequest()
        case 2:
            sendDeleteBookmarkRequest()
        case 3:
            sendMarkForLaterRequest()
        case 4:
            sendMarkAsReadRequest()
        default: break
        }
        triedTo = -1
    }
    
    func downloadFile(downloadUrl: String) {
        let finalPath = "https://archiveofourown.org" + downloadUrl
        print("download"+downloadUrl)
        
        Answers.logCustomEvent(withName: "Work Detail: download file",
                                       customAttributes: [
                                        "url": downloadUrl])
        
        if let url = URL(string: finalPath) {
            UIApplication.shared.open(url, options: [ : ], completionHandler: { (res) in
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
        
        Answers.logCustomEvent(withName: "WorkDetail: browser open",
                               customAttributes: [
                                "workId": wId])
        
        UIApplication.shared.open(URL(string: "https://archiveofourown.org/works/\(wId)")!, options: [ : ], completionHandler: { (res) in
            print("open url \(res)")
        })

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
