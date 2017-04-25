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
    var showInterstitial = false
    
    @IBOutlet weak var downloadTrashButton: UIButton!
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var authorLabel: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var audienceLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
     @IBOutlet weak var bannerView: GADBannerView!

    var purchased = false
    var donated = false
    
    var downloadedWorkItem: NSManagedObject! = nil
    var downloadedFandoms: [DBFandom]! = nil
    var downloadedRelationships: [DBRelationship]! = nil
    var downloadedCharacters: [DBCharacterItem]! = nil
    
    var workItem: WorkItem! = nil
    var fandoms: [Fandom]!
    var relationships: [Relationship]!
    var characters: [CharacterItem]!
    var warnings: [String] = [String]()
    
    var indexesToHide: [Int]!
    
    var bookmarked = false
    var bookmarkId = ""
    var changedSmth = false
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var NEXT_CHAPTER_EXIST = 1
    var NEXT_CHAPTER_NOT_EXIST = -1
    
    var commentsUrl = ""
    var tagUrl = ""
    
    var triedTo = -1
    
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
        
       // donated = true
        
        if ((purchased || donated) && DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        }
        
        if (!purchased && !donated) {
            //loadAdMobInterstitial()
            bannerView.adUnitID = "ca-app-pub-8760316520462117/1990583589"
            bannerView.rootViewController = self
            let request = GADRequest()
            request.testDevices = [ kGADSimulatorID ]
            bannerView.load(request)
            
        } else {
            self.bannerView.isHidden = true
        }
        
        let name = String(format:"b%d", Int(arc4random_uniform(4)))
        bgImage.image = UIImage(named:name)
        
        self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, -1.0, 0.0)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        if (workItem != nil) {
            showOnlineWork()
        } else if (downloadedWorkItem != nil) {
            showDownloadedWork()
        }
        
        checkBookmark()
        
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
            self.title = downloadedWorkItem.value(forKey: "workTitle") as? String ?? ""
        }
        
    }
    
    deinit {
        print ("Work Detail View Controller deinit")
    }
    
    func showDownloadedWork() {
        
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: (downloadedWorkItem.value(forKey: "author") as? String ?? ""), attributes: underlineAttribute)
        authorLabel.setAttributedTitle(underlineAttributedString, for: .normal) // = underlineAttributedString
        
        let trimmedTitle = (downloadedWorkItem.value(forKey: "workTitle") as? String)!.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        
        titleLabel.text = trimmedTitle
        
        audienceLabel.text = downloadedWorkItem.value(forKey: "ratingTags") as? String
        categoryLabel.text = downloadedWorkItem.value(forKey: "category") as? String
        completeLabel.text = downloadedWorkItem.value(forKey: "complete") as? String
        
       // fitLabel(titleLabel, text: titleLabel.text!)
       // fitLabel(authorLabel, text: authorLabel.text!)
        
        
        warnings = [String]()
        if let warn = downloadedWorkItem.value(forKey: "ArchiveWarnings") as? String {
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
        
        tableView.reloadData()
        
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.tableView.flashScrollIndicators()
        }
    }
    
    func showOnlineWork() {
        
//        if let image = UIImage(named: "download-red") {
//            downloadTrashButton.setImage(image, forState: .Normal)
//        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
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
        if let isAdult = DefaultsManager.getBool(DefaultsManager.ADULT)  {
            if (isAdult == true) {
                
                params["view_adult"] = "true" as AnyObject?
                vadult = "?view_adult=true"
            }
        }
        
        showLoadingView(msg: "Loading work")
        
        Alamofire.request("http://archiveofourown.org/works/" + workItem.workId + vadult, method: .get, parameters: params)
            .response(completionHandler: { response in
                // print(response.request)
                if let d = response.data {
                    self.parseCookies(response)
                    self.downloadCurWork(d)
                    self.showWork()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
        
    }
    
    func downloadCurWork(_ data: Data) {
        
        //let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        //print("the string is: \(dta)")
        
        onlineChapters.removeAll()
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
        
        if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
            workItem.author = "Sorry!";
            workItem.workTitle = "This work is only available to registered users of the Archive";
            workItem.complete = "";
         //   return NEXT_CHAPTER_NOT_EXIST;
            return
        }
        
        var caution = doc.search(withXPathQuery: "//p[@class='caution']")
        
        if (caution != nil && (caution?.count)!>0 && (caution?[0] as! TFHppleElement).text().range(of: "adult content") != nil) {
            workItem.setValue("Sorry!", forKey: "author")
            workItem.setValue("This work contains adult content. To view it you need to login and confirm that you are at least 18.", forKey: "workTitle")
            workItem.setValue("", forKey: "complete")
            
            return
        }
        
         var errH = doc.search(withXPathQuery: "//h2[@class='heading']")
        
        if (errH != nil && (errH?.count)!>0 && (errH?[0] as! TFHppleElement).text().range(of: "Error") != nil) {
            workItem.setValue("Sorry!", forKey: "author")
            workItem.setValue("AO3 has been notified about this issue and they will take a look at it shortly.", forKey: "workTitle")
            workItem.setValue("", forKey: "complete")
            
            return
        }
        
        //var landmark = doc.searchWithXPathQuery("//h6[@class='landmark heading']")
        
        var workmeta: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='work meta group']") as! [TFHppleElement]
        
        var firstFandom = ""
        var firstRelationship = ""
        
        if(workmeta.count > 0) {
            var ratings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='rating tags']/ul[@class='*']/li") as! [TFHppleElement]
            if (ratings.count > 0) {
                workItem.ratingTags = ratings[0].content
            }
        
            var archiveWarnings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='warning tags']/ul[@class='commas']/li") as! [TFHppleElement]
            warnings = [String]()
            for i in 0..<archiveWarnings.count {
                warnings.append(archiveWarnings[i].content)
                //workItem.archiveWarnings = archiveWarnings[0].content
            }
            
            var fandomsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='fandom tags']/ul[@class='commas']/li") as! [TFHppleElement]
            fandoms = [Fandom]()
            
            for i in 0..<fandomsLiArr.count {
                let f : Fandom = Fandom()
                f.fandomName = fandomsLiArr[i].content
                firstFandom = f.fandomName
                let attributes : NSDictionary = (fandomsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                f.fandomUrl = (attributes["href"] as! String)
                fandoms.append(f)
            }
            
            var categoryLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='category tags']/ul[@class=*]/li") as! [TFHppleElement]
            
            for i in 0..<categoryLiArr.count {
                workItem.category += categoryLiArr[i].text() + " "
            }
            
            var relationshipsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='relationship tags']/ul[@class='commas']/li") as! [TFHppleElement]
            relationships = [Relationship]()
            
            for i in 0..<relationshipsLiArr.count {
                let r : Relationship = Relationship()
                r.relationshipName = relationshipsLiArr[i].content
                firstRelationship = r.relationshipName
                let attributes : NSDictionary = (relationshipsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                r.relationshipUrl = (attributes["href"] as! String)
                relationships.append(r)
            }
            
            var charactersLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='character tags']/ul[@class='commas']/li") as! [TFHppleElement]
            characters = [CharacterItem]()
            
            for i in 0..<charactersLiArr.count {
                let c : CharacterItem = CharacterItem()
                c.characterName = charactersLiArr[i].content
                let attributes : NSDictionary = (charactersLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                c.characterUrl = (attributes["href"] as! String)
                characters.append(c)
            }
            
            var languageEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='language']") as! [TFHppleElement]
            if(languageEl.count > 0) {
                workItem.language = languageEl[0].text().replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            }
            
            workItem.stats = ""
            
            var statsElDt: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dt") as! [TFHppleElement]
            var statsElDd: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='stats']/dl[@class='stats']/dd") as! [TFHppleElement]
            if(statsElDt.count > 0 && statsElDd.count > 0) {
                
                for i in 0..<statsElDt.count {
                    workItem.stats += statsElDt[i].text() + " "
                    if ((statsElDd.count > i) && (statsElDd[i].text() != nil)) {
                        workItem.stats += statsElDd[i].text() + " "
                    }
                }
            }
        }
        
        let h2El = doc.search(withXPathQuery: "//h2[@class='title heading']")as! [TFHppleElement]
        if (h2El.count > 0) {
            let title = h2El.first?.raw.replacingOccurrences(of: "\n", with:"")
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil) ?? ""
            workItem.workTitle = title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)

        }
        
        var bylineHeadingEl = doc.search(withXPathQuery: "//div[@id='workskin']/div[@class='preface group']/h3[@class='byline heading']")as! [TFHppleElement]
        if (bylineHeadingEl.count > 0) {
            workItem.author = bylineHeadingEl[0].content.replacingOccurrences(of: "\n", with:"")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
        }
        
        var workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as! [TFHppleElement]
        if (workContentEl.count > 0) {
            workItem.workContent = workContentEl[0].raw
        }
        
        //var error:NSErrorPointer = NSErrorPointer()
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
        workItem.workContent = regex.stringByReplacingMatches(in: workItem.workContent, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workItem.workContent.characters.count), withTemplate: "$1")
        
       // stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$1"];
        //workItem.workContent = workItem.workContent.stringByReplacingOccurrencesOfString("<a.*\"\\s*>", withString:"")
        //workItem.workContent = workItem.workContent.stringByReplacingOccurrencesOfString("</a>", withString:"");
        
        var navigationEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as! [TFHppleElement]
        if (navigationEl.count > 0) {
            var nxt : [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as! [TFHppleElement]
            if (nxt.count > 0) {
                let attributes : NSDictionary = (nxt[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                workItem.nextChapter = (attributes["href"] as! String)
            }
            NSLog("%@", workItem.nextChapter)
        }
        
        let editBookmarkEl = doc.search(withXPathQuery: "//a[@class='bookmark_form_placement_open']") as! [TFHppleElement]
        if (editBookmarkEl.count > 0) {
            if (editBookmarkEl[0].raw.contains("Edit")) {
                bookmarked = true
            }
        }
        
        let chaptersEl = doc.search(withXPathQuery: "//ul[@id='chapter_index']") as! [TFHppleElement]
        if (chaptersEl.count > 0) {
            var optionsEl: [TFHppleElement] = chaptersEl[0].search(withXPathQuery: "//select/option")  as! [TFHppleElement]
            for i in 0..<optionsEl.count {
                let chptOnline: ChapterOnline = ChapterOnline()
                chptOnline.url = optionsEl[i].text()
                chptOnline.chapterId = optionsEl[i].attributes["value"] as? String ?? ""
                
                onlineChapters[i] = chptOnline
            }
        }
        
        saveToAnalytics(workItem.author, category: workItem.category, mainFandom: firstFandom, mainRelationship: firstRelationship)
        
    }
    
    func checkBookmark() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
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
            wid = downloadedWorkItem.value(forKey: "workId") as? String ?? ""
        }
        
        Alamofire.request("http://archiveofourown.org/works/" + wid + vadult + "#bookmark-form", method: .get, parameters: params)
            .response(completionHandler: { response in
                // print(response.request)
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseCheckBookmark(d)
                    //self.showWork()
                    //self.hideLoadingView()
                }
            })
        
       
    }
    
    func parseCheckBookmark(_ data: Data) {
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
                bookmarked = true
                }
            }
        }
        }
        
        if let downloadEl = doc.search(withXPathQuery: "//li[@class='download']") as? [TFHppleElement] {
            if (downloadEl.count > 0) {
                if let downloadUl: [TFHppleElement] = downloadEl.first?.search(withXPathQuery: "//li") as! [TFHppleElement]? {
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
        
    }
    
    func parseAddBookmarkResponse(_ data: Data) {
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("the string is: \(String(describing: dta))")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as! [TFHppleElement]
        if(noticediv.count > 0) {
            TSMessage.showNotification(in: self, title: "Adding Bookmark", subtitle: noticediv[0].content, type: .success)
            
            changedSmth = true
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                TSMessage.showNotification(in: self, title: "Adding Bookmark", subtitle: (sorrydiv![0] as AnyObject).content, type: .error)
                return
            }
        }
    }
    
    //MARK: - show work
    func showWork() {
        
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: workItem.author, attributes: underlineAttribute)
        authorLabel.setAttributedTitle(underlineAttributedString, for: .normal) // = underlineAttributedString
        
        titleLabel.text = workItem.workTitle
        
        audienceLabel.text = workItem.ratingTags
        categoryLabel.text = workItem.category
        completeLabel.text = workItem.complete
        
        tableView.reloadData()
        
        hideLoadingView()
        
        tableView.flashScrollIndicators()
        
        if (!DefaultsManager.getString(DefaultsManager.LASTWRKID).isEmpty) {
            performSegue(withIdentifier: "readSegue", sender: nil)

        }
    }
    
    func fitLabel(_ label:UILabel, text:String) {
        let textWidth = text.boundingRect(with: CGSize(width: 280, height: Int.max), options: NSStringDrawingOptions.usesLineFragmentOrigin,                  attributes: [NSFontAttributeName: label.font] as [String:AnyObject],
            context:nil)
        
        var lines:Int = 1
        
        if (textWidth.width > (label.frame.width - 26)) {
            lines += Int(textWidth.width / (tableView.frame.width - 26))
        }
        
        label.numberOfLines = lines
        label.frame = CGRect(x: label.frame.origin.x, y: label.frame.origin.y, width: label.frame.width, height: CGFloat(lines * 18))
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "readSegue") {
            
            //showInterstitial = true
            
            let workController: WorkViewController = segue.destination as! WorkViewController
            
            if (workItem != nil) {
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
                workId = (downloadedWorkItem.value(forKey: "workId") as? String)!
            }
            
            cController.workId = workId
            
        }  else if (segue.identifier == "listSegue") {
            let cController: WorkListController = segue.destination as! WorkListController
            
            cController.tagUrl = tagUrl
        }
        
    }
    
    // MARK: - tableview
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: WorkDetailCell? = tableView.dequeueReusableCell(withIdentifier: "cell") as? WorkDetailCell
        
        if(cell == nil) {
            cell = WorkDetailCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        }
        
        if (indexesToHide != nil) {
            indexesToHide.removeAll(keepingCapacity: false)
        } else {
            indexesToHide = [Int]()
        }
        
        switch ((indexPath as NSIndexPath).section) {
        case 0:
        
            if (workItem != nil) {
                cell!.label.text = workItem.topicPreview
            } else {
                cell!.label.text = downloadedWorkItem.value(forKey: "topicPreview") as? String
            }
            //cell!.label.font = UIFont.systemFont(ofSize: 13)
            cell!.imgView.image = UIImage(named: "preview")
            
        case 1:
            if (warnings != nil && warnings.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = warnings.joined(separator: ", ")
                
               // cell!.label.font = UIFont.systemFont(ofSize: 13)
            } else {
                indexesToHide.append(0)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "warning")
        case 2:
            if (fandoms != nil && fandoms.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = fandoms[(indexPath as NSIndexPath).row].fandomName
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
                
            } else if (downloadedFandoms != nil && downloadedFandoms.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = downloadedFandoms[(indexPath as NSIndexPath).row].value(forKey: "fandomName") as? String
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
                
            } else {
                indexesToHide.append(1)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "fandom")
        case 3:
            if (relationships != nil && relationships.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = relationships[(indexPath as NSIndexPath).row].relationshipName
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
                
            } else if (downloadedRelationships != nil && downloadedRelationships.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = downloadedRelationships[(indexPath as NSIndexPath).row].value(forKey: "relationshipName") as? String
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
                
            } else {
                indexesToHide.append(2)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "heart")
        case 4:
            if (characters != nil && characters.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = characters[(indexPath as NSIndexPath).row].characterName
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
                
            } else if (downloadedCharacters != nil && downloadedCharacters.count > (indexPath as NSIndexPath).row) {
                cell!.label.text = downloadedCharacters[(indexPath as NSIndexPath).row].value(forKey: "characterName") as? String
                
                //cell!.label.font = UIFont.systemFont(ofSize: 13)
            } else {
                indexesToHide.append(3)
                cell!.label.text = "None"
            }
            cell!.imgView.image = UIImage(named: "characters")
        case 5:
            if (workItem != nil) {
                cell!.label.text = workItem.language
            } else {
                cell!.label.text = downloadedWorkItem.value(forKey: "language") as? String
            }
            cell!.imgView.image = UIImage(named: "lang")
                
            //cell!.label.font = UIFont.systemFont(ofSize: 13)
        case 6:
            if (workItem != nil) {
                cell!.label.text = workItem.stats
            } else {
                cell!.label.text = downloadedWorkItem.value(forKey: "stats") as? String
            }
            //cell!.label.font = UIFont.italicSystemFont(ofSize: 13)
            cell!.imgView.image = UIImage(named: "info")
            
            
        default:
            //cell!.label.font = UIFont.systemFont(ofSize: 13)
            break
        }
        
        return cell!
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        var heightForRow : CGFloat = 42
//        
//        if(indexesToHide != nil) {
//            for i in 0..<indexesToHide.count {
//                if(indexesToHide[i] == indexPath.section) {
//                    heightForRow = 0
//                    break
//                }
//            }
//        }
//        
//        if (indexPath.section == 5) {
//            heightForRow = 21 * 4
//        }
//        
//        return heightForRow
//        
//    }
//    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 1.0
        
        //return heightForSection(section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 1.0
        
        //return heightForSection(section)
    }
//
//    func heightForSection(_ section: Int) -> CGFloat {
//        var res:CGFloat = 1.0
//        
//        switch (section) {
//        case 0, 5, 6:
//            res = 2.0
//        case 1:
//            if (warnings != nil && warnings.count > 0) {
//                res = 2.0
//            }
//        case 2:
//            if ((fandoms != nil && fandoms.count > 0) || (downloadedFandoms != nil && downloadedFandoms.count > 0)) {
//                res = 2.0
//            }
//        case 3:
//            if ((relationships != nil && relationships.count > 0) || (downloadedRelationships != nil && downloadedRelationships.count > 0)) {
//                res = 2.0
//            }
//        case 4:
//            if ((characters != nil && characters.count > 0) || (downloadedCharacters != nil && downloadedCharacters.count > 0)) {
//                res = 2.0
//            }
//        default:
//            break
//        }
//        
//        return res
//    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var res:Int = 1
        
        switch (section) {
        case 1:
            return 1 //warnings.count
        case 2:
            if (workItem != nil) {
                if (fandoms != nil) {
                    res = fandoms.count
                }
            } else if (downloadedFandoms != nil) {
                return downloadedFandoms.count
            }
        case 3:
            if (workItem != nil && relationships != nil) {
                res = relationships.count
            } else if (downloadedRelationships != nil) {
                return downloadedRelationships.count
            }
        case 4:
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
        tagUrl = ""
        
        switch indexPath.section {
        case 2:
                if (workItem != nil && fandoms != nil && fandoms.count > pos) {
                    tagUrl = fandoms[pos].fandomUrl
                } else if (downloadedFandoms != nil && downloadedFandoms.count > pos) {
                    tagUrl = (downloadedFandoms[pos].value(forKey: "fandomUrl") as? String)!
                }
                NSLog("link Tapped = " + tagUrl)
                
                performSegue(withIdentifier: "listSegue", sender: self)
            
        case 3:
            if (workItem != nil && relationships != nil && relationships.count > pos) {
                tagUrl = relationships[pos].relationshipUrl
            } else if (downloadedRelationships != nil && downloadedRelationships.count > pos) {
                tagUrl = (downloadedRelationships[pos].value(forKey: "relationshipUrl") as? String)!
            }
            NSLog("link Tapped = " + tagUrl)
            
            performSegue(withIdentifier: "listSegue", sender: self)
            
        case 4:
            if (workItem != nil && characters != nil && characters.count > pos) {
                tagUrl = characters[pos].characterUrl
            } else if (downloadedCharacters != nil && downloadedCharacters.count > pos) {
                tagUrl = (downloadedCharacters[pos].value(forKey: "characterUrl") as? String)!
            }
            NSLog("link Tapped = " + tagUrl)
            
            performSegue(withIdentifier: "listSegue", sender: self)
            
        default:
            break
        }
    }
    
    @IBAction func authorTouched(_sender: AnyObject) {
        var authorName = ""
        
        if(workItem != nil) {
            authorName = workItem.author
        } else if (downloadedWorkItem != nil) {
            authorName = downloadedWorkItem.value(forKey: "author") as? String ?? ""
        }
        
        tagUrl = "http://archiveofourown.org/users/\(authorName)/works"
        performSegue(withIdentifier: "listSegue", sender: self)
    }
    
    func addOneLabel(_ text:String, imageName:String, cell:UITableViewCell ) {
        let label = UILabel(frame: CGRect(x: 21, y: 0, width: authorLabel.frame.width, height: 21))
        label.textAlignment = NSTextAlignment.left
        label.font = UIFont(name: "HelveticaNeue", size: 14)
        label.text = text
        
        let textWidth = text.boundingRect(with: CGSize(width: 280, height: Int.max), options: NSStringDrawingOptions.usesLineFragmentOrigin,                  attributes: [NSFontAttributeName: label.font] as [String:AnyObject],
            context:nil)
        
        var lines:Int = 1
        
        if (textWidth.width > (tableView.frame.width - 24)) {
            lines = Int(textWidth.width / (tableView.frame.width - 24))
        }
        
        label.numberOfLines = lines
        label.frame = CGRect(x: label.frame.origin.x, y: label.frame.origin.y, width: label.frame.width, height: CGFloat(lines * 18))
        cell.addSubview(label)
        
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        cell.addSubview(imageView)
        
    }
    
    
    func buildLabelsWithLinks(_ items:[String], urls:[String], imageName:String, cell:UITableViewCell, selector:Selector) {
        var wordLocation : CGPoint = CGPoint(x: 24.0, y: 0.0)
        
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        cell.addSubview(imageView)
        
        for i in 0..<items.count {
            
            let size = CGSize(width: 280, height: Int.max)
            let font = UIFont(name: "HelveticaNeue", size: 14)
            
            let boundingRect = items[i].boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin,                  attributes: [NSFontAttributeName: font!] as [String:AnyObject],
                context:nil)
            
            let label = UILabel(frame: CGRect(x: 24, y: 0, width: boundingRect.width, height: 21))
            label.textAlignment = NSTextAlignment.left
            label.font = font
            label.text = items[i]
            if(i != items.count - 1) {
                label.text? += ","
            }
            label.isUserInteractionEnabled = true
            label.tag = i
            
            label.textColor = UIColor(red:110/255.0, green:181/255.0, blue:229/255.0, alpha:1.0)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: selector)
            label.addGestureRecognizer(tapGesture)
            
            label.sizeToFit()
            
            if ((cell.frame.size.width - 24) < wordLocation.x + label.bounds.size.width)
            {
                wordLocation.x = 0.0;                       // move this word all the way to the left...
                wordLocation.y += label.frame.size.height;  // ...on the next line
                
            }
            
            // Set the location for this label:
            label.frame = CGRect(x: wordLocation.x,
                y: wordLocation.y,
                width: label.frame.size.width,
                height: label.frame.size.height);
            // Show this label:
            cell.addSubview(label)
            
            // Update the horizontal position for the next word:
            wordLocation.x += label.frame.size.width;
        }
    }
    
    @IBAction func closeClicked(_ sender: AnyObject) {
        
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKSCROLL)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKID)
        DefaultsManager.putString("", key: DefaultsManager.LASTWRKCHAPTER)
        
        self.dismiss(animated: true, completion: { () -> Void in
            if (self.changedSmth) {
                self.modalDelegate?.controllerDidClosedWithChange!()
            } else {
                self.modalDelegate?.controllerDidClosed()
            }
            NSLog("closeClicked")
        })
    }
    
    //MARK: - bookmarks
    
    func bookmarkWorkAction() {
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        if (pseud_id.isEmpty || (UIApplication.shared.delegate as! AppDelegate).cookies.count == 0
            || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            openLoginController()
            triedTo = 1
        } else {
            sendAddBookmarkRequest()
        }
    }
    
    func deletebookmarkWorkAction() {
        let deleteAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you would like to delete this work from bookmarks?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
            
            self.sendDeleteBookmarkRequest()
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func sendAddBookmarkRequest() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            triedTo = 1
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: "Adding bookmark")
        
        var requestStr = "http://archiveofourown.org/works/"
        var bid = ""
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
    
        
        if (workItem != nil) {
            bid = workItem.workId
            requestStr += bid + "/bookmarks"
            
            
            if ( fandoms != nil && relationships != nil && fandoms.count > 0 && relationships.count > 0) {
                saveToAnalytics(workItem.value(forKey: "author") as! String, category: workItem.value(forKey: "category") as! String, mainFandom: fandoms[0].fandomName, mainRelationship: relationships[0].relationshipName)
            }
            
        } else if (downloadedWorkItem != nil) {
            guard let bd = (downloadedWorkItem.value(forKey: "workId") as? String) else {
                return
            }
            bid = bd
            requestStr += bid + "/bookmarks"
            
            if (downloadedFandoms.count > 0 && downloadedRelationships.count > 0) {
                saveToAnalytics(downloadedWorkItem.value(forKey: "author") as! String, category: downloadedWorkItem.value(forKey: "category") as! String, mainFandom: downloadedFandoms[0].fandomName ?? "", mainRelationship: downloadedRelationships[0].relationshipName ?? "")
            }
        }
        
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
                cStorage.setCookies(del.cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
        
        if (del.cookies.count > 0) {
            Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    // print(response)
                    print(response.error ?? "")
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseAddBookmarkResponse(d)
                        self.hideLoadingView()
                        
                        self.checkBookmark()
                        
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
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
        
        showLoadingView(msg: "Deleting bookmark")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
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
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        params["_method"] = "delete" as AnyObject?
        
        request("http://archiveofourown.org" + bookmarkId, method: .post, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)

                }
            })
    }

    func parseDeleteResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as! [TFHppleElement]
        if(noticediv.count > 0) {
            bookmarked = false
            changedSmth = true
            self.view.makeToast(message: noticediv[0].content, duration: 3.0, position: "center" as AnyObject, title: "Delete from Bookmarks")
            
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                TSMessage.showNotification(in: self, title: "Delete from Bookmarks", subtitle: (sorrydiv![0] as AnyObject).content, type: .error)

                return
            }
        }
    }
    
    //MARK: - settings menu actions
    
    func downloadWorkAction() {
        
        if (purchased || donated) {
         print("premium")
        } else {
            if (countWroksFromDB() > 29) {
                TSMessage.showNotification(in: self, title: "Error", subtitle: "You can only download 30 stories. Please, upgrade to download more.", type: .error, duration: 2.0)
                
                return
            }
        }
        
        showLoadingView(msg: "Downloading work")
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            }
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

        
        if (workItem != nil) {
            Alamofire.request("http://archiveofourown.org/works/" + workItem.workId + vadult, method: .get, parameters: params)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    
                    print(response.error ?? "")
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.downloadWork(d, workItemOld: self.workItem)
                        
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                    }
                })
        } else if (downloadedWorkItem != nil) {
            Alamofire.request("http://archiveofourown.org/works/" + (downloadedWorkItem.value(forKey: "workId") as! String), method: .get, parameters: params)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    
                    print(response.error ?? "")
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.downloadWork(d, workItemToReload: self.downloadedWorkItem)
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                    }
                })
        }

    }
    
    func deleteWork() {
        if (downloadedWorkItem != nil) {
            let deleteAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you would like to delete this work?", preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
                print("Cancel")
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
                let appDel:AppDelegate = UIApplication.shared.delegate as! AppDelegate
                let context:NSManagedObjectContext = appDel.managedObjectContext!
                context.delete(self.downloadedWorkItem as NSManagedObject)
                do {
                    try context.save()
                } catch _ {
                }
                
                self.dismiss(animated: true, completion: { () -> Void in
                    self.modalDelegate?.controllerDidClosed()
                    NSLog("Read completed")
                })
            }))
            
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
        let optionMenu = UIAlertController(title: nil, message: "Work Options", preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        if (downloadedWorkItem != nil) {
            let deleteAction = UIAlertAction(title: "Delete Work", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deleteWork()
            })
            optionMenu.addAction(deleteAction)
        }
        
        if (workItem != nil) {
            let saveAction = UIAlertAction(title: "Download Work", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(saveAction)
        } else if (downloadedWorkItem != nil) {
            let reloadAction = UIAlertAction(title: "Reload Work", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadWorkAction()
            })
            optionMenu.addAction(reloadAction)
        }
        
        let commentAction = UIAlertAction(title: "View Comments", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.commentWorkAction()
        })
        optionMenu.addAction(commentAction)
        
        let kudosAction = UIAlertAction(title: "Leave Kudos", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.leaveKudos()
        })
        optionMenu.addAction(kudosAction)
        
        if (!bookmarked) {
            let bookmarkAction = UIAlertAction(title: "Bookmark", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.bookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        } else {
            let bookmarkAction = UIAlertAction(title: "Delete Bookmark", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.deletebookmarkWorkAction()
            })
            optionMenu.addAction(bookmarkAction)
        }
        
        if (downloadUrls.count > 0) {
        let downloadAction = UIAlertAction(title: "Download DPF/EPUB/HTML/MOBI", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showDownloadDialog()
        })
        optionMenu.addAction(downloadAction)
        }
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView = self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
    
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func showDownloadDialog() {
        
        let keys: [String] = Array(downloadUrls.keys)
        
        let optionMenu = UIAlertController(title: nil, message: "Work Options", preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        for key in keys {
            let downloadAction = UIAlertAction(title: key, style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.downloadFile(downloadUrl: self.downloadUrls[key] ?? "")
            })
            optionMenu.addAction(downloadAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView = self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func leaveKudos() {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            triedTo = 0
            openLoginController() //openLoginController()
            return
        }
        
        showLoadingView(msg: "Leaving kudos")
        
        var workId = ""
        
        if (workItem != nil) {
            workId = workItem.workId
        } else if (downloadedWorkItem != nil) {
            workId = downloadedWorkItem.value(forKey: "workId") as! String
        }
        
        let requestStr = "http://archiveofourown.org/kudos.js"
        //let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        
        params["kudo"] = ["commentable_id": workId,
                             "commentable_type": "Work",
                             
        ]
        
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.request(requestStr, method: .post, parameters: params, encoding:URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    // print(response.response ?? "")
                    print(response.error ?? "")
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseAddKudosResponse(d)
                        self.hideLoadingView()
                        
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                    }
                })
            
        } else {
            
             self.hideLoadingView()
            TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
        }
    }
    
    func parseAddKudosResponse(_ data: Data) {
        guard let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return
        }
        //print("the string is: \(dta)")
        
        if (dta.contains("errors") == true) {
            TSMessage.showNotification(in: self, title: "Error", subtitle: "You have already left kudos here. :)", type: .error)
        } else if (dta.contains("#kudos") == true) {
            TSMessage.showNotification(in: self, title: "Kudos", subtitle: "Kudos added! :)", type: .success)
            
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
                
                author = downloadedWorkItem.value(forKey: "author") as? String ?? ""
                category = downloadedWorkItem.value(forKey: "category") as? String ?? ""
                
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
    
    /* func tftBanner(banner: TFTBanner!, didFail reason: String!) {
        print(reason)
    }
    
    func tftBannerDidReceiveAd(banner: TFTBanner!) {
        print("tftBannerDidReceiveAd")
    }
    
    func createTFTBanner() {
        let y = self.view.frame.size.height - 50.0
        let banner: TFTBanner = TFTBanner(frame: CGRectMake(0, y, 320, 50), delegate: self)
        adBannerView.addSubview(banner)
    } */
    
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
        default: break
        }
        triedTo = -1
    }
    
    func downloadFile(downloadUrl: String) {
        let finalPath = "http://archiveofourown.org" + downloadUrl
        print("download"+downloadUrl)
        
        Answers.logCustomEvent(withName: "Download_work",
                                       customAttributes: [
                                        "url": downloadUrl])
        
        if let url = URL(string: finalPath) {
            UIApplication.shared.openURL(url)
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
   
}
