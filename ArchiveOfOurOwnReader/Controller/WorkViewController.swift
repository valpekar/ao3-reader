//
//  WorkViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 8/26/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import TSMessages

class WorkViewController: LoadingViewController, UIGestureRecognizerDelegate, UIWebViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var layoutView: UIView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var contentsButton: UIButton!
    
    var prevChapter: String = ""
    var nextChapter: String = ""
    
    var currentChapterIndex = 0
    var currentOnlineChapter = ""
    var currentOnlineChapterIdx = 0
    
    var workItem: WorkItem! = nil
    var workChapters: [Chapter] = [Chapter]()
    
    var downloadedWorkItem: NSManagedObject! = nil
    var downloadedChapters: [DBChapter]?
    
    var work: String = ""
    var fontSize: Int = 100
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var viewLaidoutSubviews = false // <-- variable to prevent the viewDidLayoutSubviews code from happening more than once

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        addNavItems()
        
        prevButton.isHidden = true
        webView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        
        if (workItem != nil) {
            if (onlineChapters.count == 0 || onlineChapters.count == 1) {
                contentsButton.isHidden = true
            }
            
            if (!workItem.nextChapter.isEmpty) {
                nextChapter = workItem.nextChapter;
            } else {
                nextButton.isHidden = true
            }
            
            if (workItem.chapters.count > 0) {
                work = workItem.chapters.allObjects[0] as? String ?? ""
                loadCurrentTheme()
            } else if (!workItem.workContent.isEmpty) {
                work = workItem.workContent.replacingOccurrences(of: "\n", with: "<p></p>")
                loadCurrentTheme()
            }
            
            
            
        } else if (downloadedWorkItem != nil) {
            downloadedChapters = downloadedWorkItem.mutableSetValue(forKey: "chapters").allObjects as? [DBChapter]
            downloadedChapters?.sort(by: { (a:DBChapter, b: DBChapter) -> Bool in
                return b.value(forKey: "chapterIndex") as! Int > a.value(forKey: "chapterIndex") as! Int
            })
            if (downloadedChapters != nil && downloadedChapters!.count > 0) {
                if (downloadedChapters!.count > 1) {
                    contentsButton.isHidden = false
                }
                currentChapterIndex = downloadedWorkItem.value(forKey: "currentChapter") as? Int ?? 0
                work = downloadedChapters?[currentChapterIndex].value(forKey: "chapterContent") as? String ?? ""
                loadCurrentTheme()
                
                
                if (downloadedChapters!.count == 1 || currentChapterIndex == downloadedChapters!.count - 1) {
                    nextButton.isHidden = true
                    //contentsButton.hidden = true
                }
                
                if (currentChapterIndex > 0) {
                    prevButton.isHidden = false
                }
            }
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(WorkViewController.handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.delegate = self
        webView.addGestureRecognizer(tapRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WorkViewController.lockScreen), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        #if DEBUG
            print("Work view controller deinit")
        #endif
        NotificationCenter.default.removeObserver(self)
    }
    
    func willResignActive(_ notification: Notification) {
        saveChanges()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        
        if (workItem != nil) {
            self.title = workItem.workTitle
        
        }
        
        if (!nextChapter.isEmpty || !prevChapter.isEmpty) {
            animateLayoutDown()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveChanges()
    }
    
    func saveChanges() {
        
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if (workItem != nil) {
            //            DefaultsManager.putString(NSStringFromCGPoint(webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
            //            DefaultsManager.putString(workItem.workId, key: DefaultsManager.LASTWRKID)
            //            DefaultsManager.putString(currentOnlineChapter, key: DefaultsManager.LASTWRKCHAPTER)
            
            saveHistoryItem(workItem: workItem)
        }
    }
    
    func lockScreen() {
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if (workItem != nil) {
            DefaultsManager.putString(NSStringFromCGPoint(webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
            DefaultsManager.putString(workItem.workId, key: DefaultsManager.LASTWRKID)
            DefaultsManager.putString(currentOnlineChapter, key: DefaultsManager.LASTWRKCHAPTER)
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // Retrieve and set your content offset when the view re-appears
    // and its subviews are first laid out
    override func viewDidLayoutSubviews() {
        
        if (!viewLaidoutSubviews) {
            
            if (workItem != nil) {
                self.title = workItem.workTitle
                
                if let historyItem: HistoryItem = self.getHistoryItem(workId: workItem.workId) {
                    if let nxtChapter = historyItem.lastChapter,
                        let nxtChapterIdx = historyItem.lastChapterIdx {
                        nextChapter = nxtChapter
                        turnOnlineChapter(nextChapter, index: Int(nxtChapterIdx))
                        //nextButtonTouched(self.view)
                    }
                    
                    if let lastScroll = historyItem.scrollProgress,
                        let _ = self.webView {
                        let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            let scrollOffset:CGPoint? = CGPointFromString(lastScroll)
                            if let position:CGPoint = scrollOffset {
                                self.webView.scrollView.setContentOffset(position, animated: true)
                            }
                        }
                    }
                }
                
//                if (!DefaultsManager.getString(DefaultsManager.LASTWRKCHAPTER).isEmpty) {
//                    
//                    nextChapter = DefaultsManager.getString(DefaultsManager.LASTWRKCHAPTER)
//                    nextButtonTouched(self.view)
//                }
                
//                if (!DefaultsManager.getString(DefaultsManager.LASTWRKSCROLL).isEmpty) {
//                    let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                    let offset: String = DefaultsManager.getString(DefaultsManager.LASTWRKSCROLL)
//                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
//                        let scrollOffset:CGPoint? = CGPointFromString(offset)
//                        if let position:CGPoint = scrollOffset {
//                            self.webView.scrollView.setContentOffset(position, animated: false)
//                        }
//                    }
//                }
                
                
                
//                DefaultsManager.putString("", key: DefaultsManager.LASTWRKSCROLL)
//                DefaultsManager.putString("", key: DefaultsManager.LASTWRKID)
//                DefaultsManager.putString("", key: DefaultsManager.LASTWRKCHAPTER)
            }  else if (downloadedWorkItem != nil) {
                var title = downloadedWorkItem.value(forKey: "workTitle") as? String ?? ""
                
                if let tt = downloadedChapters?[currentChapterIndex].value(forKey: "chapterName") as? String {
                    title = tt
                }
                
                self.title = title
                
                if let offset: String = downloadedWorkItem.value(forKey: "scrollProgress") as? String,
                    let _ = self.webView {
                        let scrollOffset:CGPoint = CGPointFromString(offset)
                        self.webView.scrollView.setContentOffset(scrollOffset, animated: true)
                }
            }
            viewLaidoutSubviews = true
        }
        
        self.view.layoutIfNeeded()
    }
    
    func addNavItems() {
        let imageS = UIImage(named: "ic_themechange") as UIImage?
        let searchButton = UIBarButtonItem(image : imageS, style: .plain, target: self, action: #selector(WorkViewController.changeThemeTouched));
        searchButton.tintColor = UIColor.white
        
        let imageI = UIImage(named: "ic_textsize") as UIImage?
        let igButton = UIBarButtonItem(image : imageI, style: .plain, target: self, action: #selector(WorkViewController.changeTextSizeTouched) );
        igButton.tintColor = UIColor.white
        igButton.imageInsets = UIEdgeInsetsMake(0.0, 0.0, 0, -30);
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        
        self.navigationItem.rightBarButtonItems = [ searchButton, igButton, flexSpace]
    }
    
    //https://stackoverflow.com/questions/31114340/setstatusbarhidden-is-deprecated-in-ios-9-0
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        if(layoutView.isHidden) {
            layoutView.isHidden = false
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            UIApplication.shared.setStatusBarHidden(false, with: .fade)
            animateLayoutDown()
        } else {
            layoutView.isHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            UIApplication.shared.setStatusBarHidden(true, with: .fade)
        }
    }
    
    func animateLayoutDown() {
        UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            
            if (!self.prevChapter.isEmpty || !self.nextChapter.isEmpty || (self.downloadedChapters != nil && self.downloadedChapters!.count > 0)) {
                
                var basketTopFrame = self.layoutView.frame
                basketTopFrame.origin.y = basketTopFrame.size.height - 44
                if (self.layoutView != nil) {
                    self.layoutView.frame = basketTopFrame
                }
            }
            
            if let navigationController = self.navigationController {
                var nbTopFrame = navigationController.navigationBar.frame
                nbTopFrame.origin.y = nbTopFrame.size.height - 24
                navigationController.navigationBar.frame = nbTopFrame
            }
            
            }, completion: { finished in
                #if DEBUG
                print("animation done")
                #endif
        })
    }
    
    
    func gestureRecognizer(_: UIGestureRecognizer,  shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //webView.stringByEvaluatingJavaScriptFromString("var links = document.getElementsByTagName('a');for (var i = 0; i < links.length; ++i) {links[i].style = 'text-decoration:none;color:#000;';} alert('a');")
        webView.scrollView.flashScrollIndicators()
    }
    
    func turnOnChapter(_ chapterIndex: Int) {
        
        currentChapterIndex = chapterIndex
        
        if (downloadedChapters != nil && chapterIndex == downloadedChapters!.count - 1) {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        
        if (chapterIndex > 0) {
            prevButton.isHidden = false
        } else {
            prevButton.isHidden = true
        }
        
        if (downloadedWorkItem != nil && downloadedChapters!.count > 1) {
            contentsButton.isHidden = false
        } else {
            contentsButton.isHidden = true
        }
        
        if (downloadedWorkItem != nil && downloadedChapters != nil && chapterIndex < downloadedChapters!.count) {
            work = downloadedChapters?[chapterIndex].chapterContent ?? ""
            loadCurrentTheme()
            downloadedWorkItem.setValue(NSNumber(value: chapterIndex as Int), forKey: "currentChapter")
            
            //favWork.setCurrentChapter(String.valueOf(chapterIndex));
            //saveFavWorkChanges();
            saveWorkChanged()
            
            self.title = downloadedChapters![chapterIndex].chapterName
        }
    }
    
    
    func turnOnlineChapter(_ chapterId: String, index: Int) {
        currentOnlineChapter = chapterId
        currentOnlineChapterIdx = index
        
        showLoadingView(msg: NSLocalizedString("LoadingChapter", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        
        if let isAdult = DefaultsManager.getObject(DefaultsManager.ADULT) as? Bool {
            if (isAdult == true ) {
                
                params["view_adult"] = "true" as AnyObject?
            }
        }
        
//        Alamofire.request("http://archiveofourown.org/works/" + workItem.workId + "/chapters/" + chapterId, method: .get, parameters: params)
//            .response(completionHandler: { response in
//                print(response.request ?? "")
//                
//                print(response.error ?? "")
//                
//                if let d = response.data {
//                    self.parseCookies(response)
//                    self.work = self.parseChapter(d)
//                    self.hideLoadingView()
//                    self.showWork()
//                    
//                } else {
//                    self.hideLoadingView()
//                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
//                }
//            })
        
        Alamofire.request("http://archiveofourown.org/works/" + workItem.workId + "/chapters/" + chapterId, method: .get, parameters: params)
            .response(completionHandler: onWorksLoaded(_:))
    }
    
    func onWorksLoaded(_ response: DefaultDataResponse) {
        #if DEBUG
        print(response.request ?? "")
        print(response.error ?? "")
        #endif
        
        var title = ""
        
        if let d = response.data {
            self.parseCookies(response)
            (self.work, title) = self.parseChapter(d)
            self.hideLoadingView()
            self.showWork(title: title)
            
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
        }
        
    }
    
    func parseChapter(_ data: Data) -> (String, String) {
        //
        guard let doc : TFHpple? = TFHpple(htmlData: data) else {
            return ("", "")
        }
        var workContentStr: String = ""
        
        if let workContentEl = doc?.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            workContentStr = workContentEl[0].raw ?? ""
            
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.characters.count), withTemplate: "$1")
            
            workContentStr = workContentStr.replacingOccurrences(of: "(?i)<strike\\b[^<]*>\\s*</strike>", with: "", options: .regularExpression, range: nil)
            //workContentStr = workContentStr.replacingOccurrences(of: "<strike/>", with: "")
            workContentStr = workContentStr.replacingOccurrences(of: "<[^>]+/>", with: "", options: .regularExpression, range: nil)
        }
        
        var title = ""
        if let tt = doc?.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
            if (tt.count > 0) {
                title = tt[0].content ?? ""
                title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let navigationEl: [TFHppleElement] = doc?.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement] {
        
        if (navigationEl.count > 0) {
            
            let chapterNextEl: [TFHppleElement]? = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement]
            if (chapterNextEl?.count ?? 0 > 0) {
                let attributes : NSDictionary = (chapterNextEl?[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                nextChapter = (attributes["href"] as? String) ?? ""
            } else {
                nextChapter = ""
            }
            
            let chapterPrevEl: [TFHppleElement]? = navigationEl[0].search(withXPathQuery: "//li[@class='chapter previous']") as? [TFHppleElement]
            if(chapterPrevEl?.count ?? 0 > 0) {
                let attributesp : NSDictionary = (chapterPrevEl?[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                prevChapter = (attributesp["href"] as! String)
            } else {
                prevChapter = ""
            }
            }
        }
        
        return (workContentStr, title)
    }
    
    func saveWorkChanged() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        guard let workId = downloadedWorkItem.value(forKey: "workId") as? String else {
            return
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workId)
        if let selectWorks = (try! managedContext.fetch(fetchRequest)) as? [DBWorkItem] {
        
            if (selectWorks.count > 0) {
            let currentWork = selectWorks[0] as DBWorkItem
            currentWork.currentChapter = NSNumber(value: currentChapterIndex as Int)
            currentWork.scrollProgress = NSStringFromCGPoint(webView.scrollView.contentOffset)
            
            do {
                try managedContext.save()
            } catch _ {
            }
        }
        }
    }
    
    
    //MARK: - history items
    
    func saveHistoryItem(workItem: WorkItem) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "HistoryItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workItem.workId)
        var selectWorks = (try! managedContext.fetch(fetchRequest)) as? [HistoryItem]
        
        if (selectWorks?.count ?? 0 > 0) {
            let currentWork = selectWorks?[0]
            currentWork?.lastChapter = currentOnlineChapter
            currentWork?.lastChapterIdx = currentOnlineChapterIdx as NSNumber
            currentWork?.scrollProgress = NSStringFromCGPoint(webView.scrollView.contentOffset)
            currentWork?.timeStamp = NSDate()
            
            do {
                try managedContext.save()
            } catch _ {
            }
        } else {
            //insert into managed context
            
            guard let entity = NSEntityDescription.entity(forEntityName: "HistoryItem",  in: managedContext) else {
                return
            }
            let historyItem = HistoryItem(entity: entity, insertInto:managedContext)
            historyItem.lastChapter = currentOnlineChapter
            historyItem.lastChapterIdx = currentOnlineChapterIdx as NSNumber
            historyItem.scrollProgress = NSStringFromCGPoint(webView.scrollView.contentOffset)
            historyItem.timeStamp = NSDate()
            historyItem.workId = workItem.workId
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save \(String(describing: error.userInfo))")
            }
        }
    }
    
    func getHistoryItem(workId: String) -> HistoryItem? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return nil
        }
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "HistoryItem")
        let predicate = NSPredicate(format: "workId == %@", workId)
        req.predicate = predicate
        do {
            if let fetchedWorks = try managedContext.fetch(req) as? [HistoryItem] {
                if (fetchedWorks.count > 0) {
                    return fetchedWorks.first
                }
            }
        } catch {
            fatalError("Failed to fetch works: \(error)")
        }
        
        return nil
    }
    
    //MARK: - chapter next/prev
    
    @IBAction func nextButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            showLoadingView(msg: NSLocalizedString("LoadingNxtChapter", comment: ""))
            
            currentOnlineChapter = nextChapter
            if (currentOnlineChapterIdx < onlineChapters.count - 1) {
                currentOnlineChapterIdx = currentOnlineChapterIdx + 1
            }
            
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
            
            let urlStr = "http://archiveofourown.org" + nextChapter
            
            var title = ""
        
            Alamofire.request(urlStr, method: .get, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                    #endif
                if let d = response.data {
                    title = self.downloadFullWork(d)
                    self.showWork(title: title)
                }
            })
            
        } else {
            currentChapterIndex += 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    @IBAction func prevButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            showLoadingView(msg: NSLocalizedString("LoadingPrevChapter", comment: ""))
            
            currentOnlineChapter = prevChapter
            if (currentOnlineChapterIdx > 0) {
                currentOnlineChapterIdx = currentOnlineChapterIdx - 1
            }
        
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
            
            var title = ""
        
            Alamofire.request("http://archiveofourown.org" + prevChapter, method: .get, parameters: params)
                .response(completionHandler: { response in
                    #if DEBUG
                    print(response.request ?? "")
                        #endif
                    if let d = response.data {
                        title = self.downloadFullWork(d)
                        self.showWork(title: title)
                    }
                })
        } else {
            currentChapterIndex -= 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    func downloadFullWork(_ data: Data) -> String {
        
        prevChapter = ""
        nextChapter = ""
        
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        #if DEBUG
            print("the string is: \(String(describing: dta))")
        #endif
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let  chaptersEl: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
        
        if (chaptersEl.count > 0) {
            work = chaptersEl[0].raw
          //  work = work.stringByReplacingOccurrencesOfString("<a.*\"\\s*>", withString:"")
          //  work = work.stringByReplacingOccurrencesOfString("</a>", withString: "")
         //   var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            work = regex.stringByReplacingMatches(in: work, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: work.characters.count), withTemplate: "$1")
        }
        }
        
        var title = ""
        if let tt = doc.search(withXPathQuery: "//h3[@class='title']") as? [TFHppleElement] {
            if (tt.count > 0) {
            title = tt[0].content ?? ""
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let navigationEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement] {
        
        if (navigationEl.count > 0) {
            
            if let chapterNextEl: [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement] {
            if (chapterNextEl.count > 0) {
                let attributes : NSDictionary = (chapterNextEl[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                nextChapter = (attributes["href"] as? String ?? "")
            }
            }
            
            if let chapterPrevEl: [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter previous']") as? [TFHppleElement] {
            if(chapterPrevEl.count > 0) {
                let attributesp : NSDictionary = (chapterPrevEl[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                prevChapter = (attributesp["href"] as? String ?? "")
            }
            }
        }
        }
        return title
    }
    
    func showWork(title: String = "") {
        //webView.loadHTMLString(work, baseURL: nil)
        loadCurrentTheme()
        
        if (nextChapter.isEmpty) {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        
        if (prevChapter.isEmpty) {
            prevButton.isHidden = true
        } else {
            prevButton.isHidden = false
        }
        
        if (onlineChapters.count == 0 || onlineChapters.count == 1) {
            contentsButton.isHidden = true
        }
        
        hideLoadingView()
        if ((!nextChapter.isEmpty || !prevChapter.isEmpty) && layoutView != nil) {
            animateLayoutDown()
        }
        
        if (!title.isEmpty) {
            self.title = title
        }
    }
    
    func showDownloadedWork() {
        
    }
    
    //Theme and Font changes
    
    func loadCurrentTheme() {
        var theme: Int
        
        if (DefaultsManager.getInt(DefaultsManager.THEME) != nil) {
            theme = DefaultsManager.getInt(DefaultsManager.THEME)!
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (DefaultsManager.getInt(DefaultsManager.FONT_SIZE) != nil) {
            fontSize = DefaultsManager.getInt(DefaultsManager.FONT_SIZE)!
        }
        
        var worktext: String = work
        
        switch (theme) {
            case DefaultsManager.THEME_DAY :
                webView.backgroundColor = UIColor.clear
                webView.isOpaque = false
                
                let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
                worktext = String(format:"<style>body { color: #021439; %@ }</style>%@", fontStr, work)
                
            case DefaultsManager.THEME_NIGHT :
                self.webView.backgroundColor = UIColor(red: 50/255, green: 52/255, blue: 57/255, alpha: 1)
                self.webView.isOpaque = false
                
                let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
                worktext = String(format:"<style>body { color: #f5f5e9; %@ }</style>%@", fontStr, work)
                
            default:
                break
        }
        
        webView(wview: webView, enableGL: false)
        
        webView.reload()
        webView.loadHTMLString(worktext, baseURL: nil)
    }
    
    func changeThemeTouched() {
        
        var theme: Int
        
        if (DefaultsManager.getInt(DefaultsManager.THEME) != nil) {
            theme = DefaultsManager.getInt(DefaultsManager.THEME)!
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        switch (theme) {
        case DefaultsManager.THEME_DAY :
            DefaultsManager.putInt(DefaultsManager.THEME_NIGHT, key: DefaultsManager.THEME)
            
        case DefaultsManager.THEME_NIGHT :
            DefaultsManager.putInt(DefaultsManager.THEME_DAY, key: DefaultsManager.THEME)
            
        default:
            break
        }
        
        loadCurrentTheme()
    }
    
    func changeTextSizeTouched() {
        let alert = UIAlertController(title: NSLocalizedString("FontSize", comment: ""), message: String(format: "%d", fontSize) + "%", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "+", style: UIAlertActionStyle.default, handler: { action in
            switch action.style{
            case .default:
                if (self.fontSize < 400) {
                    self.fontSize += 25
                } else {
                    self.fontSize = 400
                }
                DefaultsManager.putInt(self.fontSize, key: DefaultsManager.FONT_SIZE)
            default:
                break
            }
            
            alert.message = String(format: "%d", self.fontSize) + "%"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "-", style: UIAlertActionStyle.default, handler: { action in
            switch action.style{
            case .default:
                if (self.fontSize > 25) {
                    self.fontSize -= 25
                } else {
                    self.fontSize = 25
                }
                DefaultsManager.putInt(self.fontSize, key: DefaultsManager.FONT_SIZE)
            default:
                break
            }
            
            alert.message = String(format: "%d", self.fontSize) + "%"
            self.loadCurrentTheme()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func contentsClicked(_ sender: UIButton) {
        if (downloadedChapters != nil || onlineChapters != nil) {
            let storyboard : UIStoryboard = UIStoryboard(
                name: "Main",
                bundle: nil)
            let contentsViewController: ContentsViewController = storyboard.instantiateViewController(withIdentifier: "contentsController") as! ContentsViewController
        
            if (workItem != nil) {
                contentsViewController.onlineChapters = onlineChapters
                contentsViewController.downloadedChapters = nil
            } else {
                contentsViewController.onlineChapters = nil
                contentsViewController.downloadedChapters = downloadedChapters
            }
            contentsViewController.modalDelegate = self
            contentsViewController.modalPresentationStyle = .popover
            let screenSize: CGRect = UIScreen.main.bounds
            
            var chptNum = 0
            if (downloadedChapters != nil) {
                chptNum = downloadedChapters!.count
            } else {
                chptNum = onlineChapters.count
            }
            
            contentsViewController.preferredContentSize = CGSize(width: screenSize.width * 0.6, height: CGFloat(chptNum) * 44.0)
        
        let popoverMenuViewController = contentsViewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .up
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = sender
        popoverMenuViewController?.sourceRect = CGRect(
            x: 0,
            y: sender.frame.minY,
            width: sender.frame.width,
            height: sender.frame.height)
        
        present(
            contentsViewController,
            animated: true,
            completion: nil)
        }
    }
    
    func adaptivePresentationStyle(
        for controller: UIPresentationController) -> UIModalPresentationStyle {
            return .none
    }
    
    override func controllerDidClosed() { }
    
    func controllerDidClosedWithChapter(_ chapter: Int) {
        currentChapterIndex = chapter
        if (downloadedChapters != nil) {
            self.turnOnChapter(currentChapterIndex)
        } else {
            turnOnlineChapter((onlineChapters[chapter]?.chapterId) ?? "0", index: chapter)
        }
    }
    
    //typedef void (*CallFuc)(id, SEL, BOOL)
    //typedef BOOL (*GetFuc)(id, SEL)
    
    func webView(wview: UIWebView, enableGL: Bool) -> Bool {
        var bRet: Bool = false
        repeat
        {
            guard let internalVar: Ivar = class_getInstanceVariable(UIWebView.self, "_internal") else {
                #if DEBUG
                print("enable GL _internal invalid!")
                    #endif
                break
            }
    
            let internalObj = object_getIvar(wview, internalVar)
            guard let browserVar: Ivar = class_getInstanceVariable(object_getClass(internalObj), "browserView") else {
                #if DEBUG
                print("enable GL browserView invalid!")
                    #endif
                break
            }
    
            let webbrowser: Any = object_getIvar(internalObj, browserVar)
            guard let webViewVar: Ivar = class_getInstanceVariable(object_getClass(webbrowser), "_webView") else {
                #if DEBUG
                print("enable GL _webView invalid!")
                    #endif
                break
            }
    
            guard let webView: Any = object_getIvar(webbrowser, webViewVar) else {
                #if DEBUG
                print("enable GL webView obj nil!")
                    #endif
                break
            }
    
            if(object_getClass(webView) != NSClassFromString("WebView"))
            {
                #if DEBUG
                print("enable GL webView not WebView!")
                    #endif
                break
            }
    
            let selector: Selector = NSSelectorFromString("_setWebGLEnabled:")
            
            if let anyObj: AnyObject = webView as? AnyObject {
                let impSet: IMP = anyObj.method(for: selector)
                
                typealias ClosureType = @convention(c) (AnyObject, Selector, Bool) -> Void
                typealias ClosureTypeGet = @convention(c) (AnyObject, Selector) -> Bool
                
                let clo = unsafeBitCast(impSet, to: ClosureType.self)
                clo(webView as AnyObject, selector, enableGL)
                
                let selectorGet: Selector = NSSelectorFromString("_webGLEnabled")
                let impGet: IMP = anyObj.method(for: selectorGet)
                
                let cGet = unsafeBitCast(impGet, to: ClosureTypeGet.self)
                let val = cGet(webView as AnyObject, selector)
                
                bRet = (val == enableGL)
                
            }
    
        } while(false)
    
        return bRet
    }
    
}
