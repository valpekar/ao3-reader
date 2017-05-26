 //
//  LoadingViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 9/29/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import iAd
import CoreData
import GoogleMobileAds
import Alamofire

class LoadingViewController: CenterViewController, ModalControllerDelegate, UIAlertViewDelegate {
    
   // var interstitial: ADInterstitialAd! = nil
    
   // var tftinterstitial: TFTInterstitial? = nil
    
    var activityView: UIActivityIndicatorView!
    var loadingView: UIView!
    var loadingLabel: UILabel!
    var interstitial: GADInterstitial!
   // var interstitial: MPInterstitialAdController =
   //     MPInterstitialAdController(forAdUnitId: "24f81f4beba548248fc64cfcf5d4d8f5")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.interstitialPresentationPolicy = ADInterstitialPresentationPolicy.Manual
   
    }
    
    func loadAdMobInterstitial() {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-8760316520462117/1282893180")
        let request = GADRequest()
        interstitial.load(request)
    }

    func showAdMobInterstitial() {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
       // cycleInterstitial()
    }
        
    func showLoadingView(msg: String) {
        
        if (loadingView != nil) {
            hideLoadingView()
        }
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        loadingView = UIView(frame:CGRect(x: screenWidth/2 - 170/2, y: screenHeight/2 - 170, width: 170, height: 170))
        loadingView.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.5)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10.0
        
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        
        guard let aView = activityView else {
            return
        }
        
        activityView!.frame = CGRect(x: 65, y: 40, width: aView.bounds.size.width, height: aView.bounds.size.height)
        loadingView.addSubview(activityView!)
        
        loadingLabel = UILabel(frame:CGRect(x: 20, y: 115, width: 130, height: 22))
        loadingLabel.backgroundColor = UIColor.clear
        loadingLabel.textColor = UIColor.white
        loadingLabel.adjustsFontSizeToFitWidth = true
        loadingLabel.textAlignment = .center
        loadingLabel.text = msg
        loadingView.addSubview(loadingLabel)
        
        self.view.addSubview(loadingView)
        activityView?.startAnimating()
    }
    
    func hideLoadingView() {
        print("hide loading view")
        if (activityView != nil && activityView.isAnimating) {
            activityView.stopAnimating()
        }
        if (loadingView != nil && loadingView.superview != nil) {
            loadingView.removeFromSuperview()
            loadingView = nil
        }
    }
    
    //MARK: - tapfortap
//    func loadtftInterstitial() {
      //  TFTInterstitial.loadBreakInterstitialWithDelegate(self)
//    }
    
//    func showftfInterstitial() {
//        if let tftinterstitial = tftinterstitial {
//            if (tftinterstitial.readyToShow()) {
//                tftinterstitial.showAndLoadWithViewController(self)
//            }
//        } else {
//            TFTInterstitial.loadBreakInterstitialWithDelegate(self)
//            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
//            dispatch_after(delayTime, dispatch_get_main_queue()) {
//                self.showftfInterstitial()
//            }
//        }
//    }
    
    //pragma mark: -
    //pragma MARK: - Interstitial Management
    
 //   func cycleInterstitial() {
//        // Clean up the old interstitial...
//        if (interstitial != nil) {
//            interstitial.delegate = nil
//            interstitial = nil
//        }
//        
//        // and create a new interstitial. We set the delegate so that we can be notified of when
//        interstitial = ADInterstitialAd()
//        interstitial.delegate = self
 //   }
    
//    func presentInterlude() {
//        // If the interstitial managed to load, then we'll present it now.
//        if (interstitial.loaded) {
//            let res = self.requestInterstitialAdPresentation()
//            NSLog("requestInterstitialAdPresentation %@",res)
//        }
 //   }
    
    // MARK: - ADInterstitialViewDelegate methods
    
    // When this method is invoked, the application should remove the view from the screen and tear it down.
    // The content will be unloaded shortly after this method is called and no new content will be loaded in that view.
    // This may occur either when the user dismisses the interstitial view via the dismiss button or
    // if the content in the view has expired.
    func interstitialAdDidUnload(_ interstitialAd: ADInterstitialAd!) {
        NSLog("interstitialAdDidUnload")
        //self.cycleInterstitial()
    }
    
    // This method will be invoked when an error has occurred attempting to get advertisement content.
    // The ADError enum lists the possible error codes.
    func interstitialAd(_ interstitialAd: ADInterstitialAd, didFailWithError:NSError) {
        //self.cycleInterstitial()
    }
    
    func interstitialAdDidLoad(_ interstitialAd: ADInterstitialAd!) {
        NSLog("Loaded interstitial")
    }
    
    func interstitialAdActionDidFinish(_ interstitialAd: ADInterstitialAd!) {
    }
    
    // MARK: - Downloading work
    
    var chapters: [ChapterOnline] = [ChapterOnline]()
    
    func downloadWork(_ data: Data, curWork: NewsFeedItem? = nil, workItemOld: WorkItem? = nil, workItemToReload: NSManagedObject? = nil) {
        
        var workItem : NSManagedObject! = nil
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        if (workItemToReload == nil) {
            guard let entity = NSEntityDescription.entity(forEntityName: "DBWorkItem",  in: managedContext) else {
                return
            }
            workItem = NSManagedObject(entity: entity, insertInto:managedContext)
        } else {
            workItem = workItemToReload
        }
        
        var err: NSError?
        
        chapters = [ChapterOnline]()
        
        if let curWork = curWork {
            workItem.setValue(curWork.warning, forKey: "ArchiveWarnings")
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
            workItem.setValue(workItemOld!.archiveWarnings, forKey: "ArchiveWarnings")
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
        let doc : TFHpple = TFHpple(htmlData: data)
        
        let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
        
        if(sorrydiv != nil && (sorrydiv?.count)!>0) {
            if let sorrydivFirst = sorrydiv?[0] as? TFHppleElement {
                if (sorrydivFirst.text().range(of: "Sorry") != nil) {
                    workItem.setValue("Sorry!", forKey: "author")
                    workItem.setValue("This work is only available to registered users of the Archive", forKey: "workTitle")
                    workItem.setValue("", forKey: "complete")
                    //   return NEXT_CHAPTER_NOT_EXIST;
                    return
                }
            }
        }
        
        var caution = doc.search(withXPathQuery: "//p[@class='caution']")
        
        if (caution != nil && (caution?.count)!>0 && (caution?[0] as! TFHppleElement).text().range(of: "adult content") != nil) {
            workItem.setValue("Sorry!", forKey: "author")
            workItem.setValue("This work contains adult conetnt. To view it you need to login and confirm that you are at least 18.", forKey: "workTitle")
            workItem.setValue("", forKey: "complete")
            
            return
        }
        
        // var landmark = doc.searchWithXPathQuery("//h6[@class='landmark heading']")
        
        var firstFandom: String = ""
        var firstRelationship: String = ""
        
        if let workmeta: [TFHppleElement] = doc.search(withXPathQuery: "//dl[@class='work meta group']") as? [TFHppleElement] {
        
        if(workmeta.count > 0) {
            if let ratings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='rating tags']/ul[@class='*']/li") as? [TFHppleElement] {
                if (ratings.count > 0) {
                    workItem.setValue(ratings[0].content, forKey: "ratingTags")
                }
            }
            
            if let archiveWarnings: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='warning tags']/ul[@class='commas']/li") as? [TFHppleElement] {
            var warnings = [String]()
            for i in 0..<archiveWarnings.count {
                warnings.append(archiveWarnings[i].content)
                //workItem.archiveWarnings = archiveWarnings[0].content
            }
            }
            
            if let fandomsLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='fandom tags']/ul[@class='commas']/li") as? [TFHppleElement] {
            
            for i in 0..<fandomsLiArr.count {
                let entityf =  NSEntityDescription.entity(forEntityName: "DBFandom",  in: managedContext)
                let f = NSManagedObject(entity: entityf!, insertInto:managedContext)
                f.setValue(fandomsLiArr[i].content, forKey: "fandomName")
                firstFandom = fandomsLiArr[i].content
                let attributes : NSDictionary = (fandomsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                f.setValue((attributes["href"] as? String ?? ""), forKey: "fandomUrl")
                
                let workFandoms = workItem.value(forKeyPath: "fandoms") as! NSMutableSet
                workFandoms.add(f)
                
                let works = f.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem)
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
            
            for i in 0..<relationshipsLiArr.count {
                let entityr =  NSEntityDescription.entity(forEntityName: "DBRelationship",  in: managedContext)
                let r = NSManagedObject(entity: entityr!, insertInto:managedContext)
                r.setValue(relationshipsLiArr[i].content, forKey: "relationshipName")
                firstRelationship = relationshipsLiArr[i].content
                let attributes : NSDictionary = (relationshipsLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                r.setValue((attributes["href"] as? String ?? ""), forKey: "relationshipUrl")
                
                let workRel = workItem.value(forKeyPath: "relationships") as! NSMutableSet
                workRel.add(r)
                
                let works = r.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem)
            }
            }
            
            if let charactersLiArr: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='character tags']/ul[@class='commas']/li") as? [TFHppleElement] {
            
            for i in 0..<charactersLiArr.count {
                let entityc =  NSEntityDescription.entity(forEntityName: "DBCharacterItem",  in: managedContext)
                let c = NSManagedObject(entity: entityc!, insertInto:managedContext)
                c.setValue(charactersLiArr[i].content, forKey: "characterName")
                let attributes : NSDictionary = (charactersLiArr[i].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                c.setValue((attributes["href"] as? String ?? ""), forKey: "characterUrl")
                
                let workCharacters = workItem.value(forKeyPath: "characters") as! NSMutableSet
                workCharacters.add(c)
                
                let works = c.value(forKeyPath: "workItems") as! NSMutableSet
                works.add(workItem)
            }
            }
            
            if let languageEl: [TFHppleElement] = workmeta[0].search(withXPathQuery: "//dd[@class='language']") as? [TFHppleElement] {
            if(languageEl.count > 0) {
                let language = languageEl[0].text().replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                
                workItem.setValue(language, forKey: "language")
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
        
        if let bylineHeadingEl = doc.search(withXPathQuery: "//div[@id='workskin']/div[@class='preface group']/h3[@class='byline heading']") as? [TFHppleElement] {
        if (bylineHeadingEl.count > 0) {
            let authorStr = bylineHeadingEl[0].content.replacingOccurrences(of: "\n", with:"")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            
            workItem.setValue(authorStr, forKey: "author")
        }
        }
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            var workContentStr = workContentEl[0].raw ?? ""
            
            //var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.characters.count), withTemplate: "$1")
            
            workItem.setValue(workContentStr, forKey: "workContent")
            
            var chptName = ""
            if let chapterNameEl = doc.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
                var str: String = chapterNameEl.first?.raw ?? ""
                str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                str = str.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)

                chptName = str
            }
            
            let chpt = ChapterOnline()
            chpt.content = workContentStr
            chpt.url = chptName
            
            chapters.append(chpt)
        }
        
        let navigationEl: [TFHppleElement]? = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement]
        if let nxt: [TFHppleElement] = navigationEl?.first?.search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement],
            let nxtFirst = nxt.first {
                guard let aEl: TFHppleElement = nxtFirst.search(withXPathQuery: "//a")[0] as? TFHppleElement else {
                   return
                }
                let attributes : NSDictionary = aEl.attributes as NSDictionary
                let next : String? = (attributes["href"] as? String)
                
                if (!next!.isEmpty) {
                    
                    workItem.setValue(next, forKey: "nextChapter")
                    
                    var params:[String:AnyObject] = [String:AnyObject]()
                    params["view_adult"] = "true" as AnyObject?
                    
                    Alamofire.request("http://archiveofourown.org" + next! , parameters: params).response(completionHandler: { response in
                        
                        print(response.request ?? "")
                        print(response.error ?? "")
                        if let data = response.data {
                            self.showLoadingView(msg: "Loading next chapter")
                            self.parseNxtChapter(data, curworkItem: workItem)
                        }
                        
                    })
                }
            } else {
                saveChapters(workItem)
                hideLoadingView()
            }
        
        //save to DB
        do {
            try managedContext.save()
            hideLoadingView()
        } catch let error as NSError {
            err = error
            print("Could not save \(String(describing: err?.userInfo))")
            hideLoadingView()
        }
        
        saveToAnalytics(workItem.value(forKey: "author") as? String ?? "", category: workItem.value(forKey: "category") as? String ?? "", mainFandom: firstFandom, mainRelationship: firstRelationship)
    }
    
    func saveChapters(_ curworkItem: NSManagedObject) {
        
        print("save chapters begin")
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.managedObjectContext!
        
            var err: NSError?
        
            var workChapters = NSMutableSet()
            if let wc = curworkItem.value(forKeyPath: "chapters") as? NSMutableSet {
                workChapters = wc
            } else {
                curworkItem.setValue(workChapters, forKey: "chapters")
            }
        
            if (workChapters.count > 0) {
                workChapters.removeAllObjects()
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                err = error
                print("Could not save \(String(describing: err?.userInfo))")
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
            
                    workChapters.add(chapter)
            
                    do {
                        try managedContext.save()
                    } catch let error as NSError {
                        err = error
                        print("Could not save \(String(describing: err?.userInfo))")
                    }
                }
            }
        
            print("save chapters end")
        } else {
            print("save chapters end with error")
        }
    }
    
    func parseNxtChapter(_ data: Data, curworkItem: NSManagedObject) {
        
        //let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            var workContentStr = workContentEl.first?.raw ?? ""
        
            //var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.characters.count), withTemplate: "$1")
        
            var chptName = ""
            if let chapterNameEl = doc.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
                var str: String = chapterNameEl.first?.raw ?? ""
                str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
                str = str.replacingOccurrences(of: "\n", with:"")
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                
                chptName = str
            }
            
            let chpt = ChapterOnline()
            chpt.content = workContentStr
            chpt.url = chptName
            
            chapters.append(chpt)
            
        }
        
        let navigationEl: [TFHppleElement]? = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement]
        if let nxt: [TFHppleElement] = navigationEl?.first?.search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement],
            let nxtFirst = nxt.first {
                    
                    if let atrs = nxtFirst.search(withXPathQuery: "//a") ,
                        let firstAttribute = atrs.first {
                            let attributes : NSDictionary = (firstAttribute as AnyObject).attributes as NSDictionary
                            if let next : String = (attributes["href"] as? String) {
                            
                                if (!next.isEmpty) {
                                    var params:[String:AnyObject] = [String:AnyObject]()
                                    params["view_adult"] = "true" as AnyObject?
                                
                                    let urlStr: String = "http://archiveofourown.org" + next
                                
                                    Alamofire.request(urlStr, parameters: params)
                                        .response(completionHandler: { response in
                                        
                                            print(response.request ?? "")
                                            print(response.error ?? "")
                                            if let d = response.data {
                                                self.parseNxtChapter(d, curworkItem: curworkItem)
                                            }
                                        })
                                }
                                }
                            }
                        
                    } else {
                        saveChapters(curworkItem)
                        hideLoadingView()
                    }
    }
    
    func saveToAnalytics(_ author: String, category: String, mainFandom: String, mainRelationship: String) {
       
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.managedObjectContext!
        
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
                    print("Could not save \(String(describing: err)), \(String(describing: err?.userInfo))")
                }
            }
            } else {
                print("Could not save AppDel = nil")

            }
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
    
    
//    func encodesParametersInURL(_ method: Method) -> Bool {
//        switch method {
//        case .get, .head, .delete:
//            return true
//        default:
//            return false
//        }
//    }
    
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
        guard let allHeaders = resp.allHeaderFields as? [String: String] else {
            return
        }
        
        let cookiesH: [HTTPCookie] = HTTPCookie.cookies(withResponseHeaderFields: allHeaders, for: URL(string: "http://archiveofourown.org")!)
            //let cookies = headers["Set-Cookie"]
        if (cookiesH.count > 0) {
            (UIApplication.shared.delegate as! AppDelegate).cookies = cookiesH
            DefaultsManager.putObject(cookiesH as AnyObject, key: DefaultsManager.COOKIES)
        }
        
       // print(cookies)
    }
    
    //MARK: - login
    
    func openLoginController() {
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
        (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
        
        self.present(nav, animated: true, completion: nil)
    }
    
    func controllerDidClosed() {
        
    }
    
    func addDoneButtonOnKeyboard(_ textField: UITextView)
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.backgroundColor = UIColor.white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(LoadingViewController.doneButtonAction))
        done.tintColor = UIColor(red: 255/0, green: 77/255, blue: 80/255, alpha: 1)
        
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
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(LoadingViewController.doneButtonAction))
        done.tintColor = UIColor(red: 99/255, green: 0/255, blue: 0/255, alpha: 1)
        
        var items: [UIBarButtonItem] = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction() {
    }
    
    func countWroksFromDB() -> Int {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
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
    
}


extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: true)
        return request
    }
    
}
