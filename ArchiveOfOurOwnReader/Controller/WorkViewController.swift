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
import Crashlytics
import WebKit
import Spring

class WorkViewController: ListViewController, UIGestureRecognizerDelegate, UIWebViewDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var layoutView: SpringView!
    @IBOutlet weak var layoutBottomView: SpringView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var contentsButton: UIButton!
    
    @IBOutlet weak var kudosButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    var prevChapter: String = ""
    var nextChapter: String = ""
    
    var currentChapterIndex = 0
    var currentOnlineChapter = ""
    var currentOnlineChapterIdx = 0
    
    var workItem: WorkItem?
    var workChapters: [Chapter] = [Chapter]()
    
    var downloadedWorkItem: DBWorkItem?
    var downloadedChapters: [DBChapter]?
    
    var work: String = ""
    var fontSize: Int = 175
    var fontFamily: String = "Verdana"
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var viewLaidoutSubviews = false // <-- variable to prevent the viewDidLayoutSubviews code from happening more than once
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        addNavItems()
        
        prevButton.isHidden = true
        self.webView.navigationDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        
        if let workItem = self.workItem {
            
            showOnlineWork(workItem: workItem)
            
        } else if let downloadedWork = self.downloadedWorkItem,
            let downloadedChapters = downloadedWork.mutableSetValue(forKey: "chapters").allObjects as? [DBChapter] {
            
            showDownloadedWork(downloadedWork: downloadedWork, downloadedChapters: downloadedChapters)
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(WorkViewController.handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 2
        tapRecognizer.delegate = self
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.delaysTouchesEnded = true
        webView.addGestureRecognizer(tapRecognizer)
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(WorkViewController.handleSwipe(_:)))
        swipeRecognizer.direction = UISwipeGestureRecognizerDirection.left
        self.webView.addGestureRecognizer(swipeRecognizer)
        
        let swipeRecognizerR = UISwipeGestureRecognizer(target: self, action: #selector(WorkViewController.handleSwipe(_:)))
        swipeRecognizerR.direction = UISwipeGestureRecognizerDirection.right
        self.webView.addGestureRecognizer(swipeRecognizerR)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WorkViewController.lockScreen), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        if (DefaultsManager.getBool("featuresShown") ?? false == false) {
            showContentAlert()
        }
    }
    
    func showOnlineWork(workItem: WorkItem) {
        downloadButton.setImage(UIImage(named: "download-100"), for: .normal)
        
        if (onlineChapters.count == 0 || onlineChapters.count == 1) {
            contentsButton.isHidden = true
        }
        
        if (!workItem.nextChapter.isEmpty) {
            nextChapter = workItem.nextChapter
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
        
        self.scrollWorks()
    }
    
    func showDownloadedWork(downloadedWork: DBWorkItem, downloadedChapters: [DBChapter]) {
        if (downloadButton == nil) { //user left to another screen
            return
        }
        downloadButton.setImage(UIImage(named: "ic_refresh"), for: .normal)
        
        self.downloadedChapters = downloadedChapters.sorted(by: { (a:DBChapter, b: DBChapter) -> Bool in
            return b.value(forKey: "chapterIndex") as? Int ?? -1 > a.value(forKey: "chapterIndex") as? Int ?? 0
        })
        if (downloadedChapters.count > 0) {
            if (downloadedChapters.count > 1) {
                contentsButton.isHidden = false
            } else {
                contentsButton.isHidden = true
            }
            
            currentChapterIndex = downloadedWork.currentChapter?.intValue ?? 0
            if (currentChapterIndex >= self.downloadedChapters?.count ?? 0) {
                currentChapterIndex = 0
            }
            work = self.downloadedChapters?[currentChapterIndex].chapterContent ?? ""
            loadCurrentTheme()
            
            if (nextButton != nil && (downloadedChapters.count == 1 || currentChapterIndex == downloadedChapters.count - 1)) {
                nextButton.isHidden = true
                //contentsButton.hidden = true
            }
            
            if (prevButton != nil && currentChapterIndex > 0) {
                prevButton.isHidden = false
            }
        }
        
        self.scrollWorks()
    }
    
    func showContentAlert() {
        let refreshAlert = UIAlertController(title: NSLocalizedString("Attention", comment: ""), message: "Enter/Leave Fullscreen mode with 2 taps; swipe to switch Next/Previous chapter", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
            DefaultsManager.putBool(true, key: "featuresShown")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
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
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.title = ""
        
//        if let workItem = self.workItem {
//            self.title = workItem.workTitle
//        }
        
        // iterate over all subviews of the WKWebView's scrollView
        for subview in self.webView.scrollView.subviews {
            // iterate over recognizers of subview
            for recognizer in subview.gestureRecognizers ?? [] {
                // check the recognizer is  a UITapGestureRecognizer
                if recognizer.isKind(of: UITapGestureRecognizer.self) {
                    // cast the UIGestureRecognizer as UITapGestureRecognizer
                    let tapRecognizer = recognizer as! UITapGestureRecognizer
                    // check if it is a 1-finger double-tap
                    if tapRecognizer.numberOfTapsRequired == 2 && tapRecognizer.numberOfTouchesRequired == 1 {
                        // remove the recognizer
                        subview.removeGestureRecognizer(recognizer)
                    }
                }
            }
        }
        
     //   scrollWorks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveChanges()
    }
    
    func scrollWorks() {
        if let workItem = self.workItem {
            //self.title = workItem.workTitle
            
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
            
        }  else if let downloadedWorkItem = downloadedWorkItem {
            var title = downloadedWorkItem.workTitle ?? ""
            
            if (currentChapterIndex < downloadedChapters?.count ?? 0) {
                if let tt = downloadedChapters?[currentChapterIndex].chapterName, tt.isEmpty == false {
                    title = tt
                }
            }
            
           // self.title = title
            
            if let offset: String = downloadedWorkItem.scrollProgress,
                let _ = self.webView,
                offset.isEmpty == false {
                let delayTime = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    let scrollOffset:CGPoint = CGPointFromString(offset)
                    self.webView.scrollView.setContentOffset(scrollOffset, animated: true)
                }
            }
        }
    }
    
    func saveChanges() {
        
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if let workItem = self.workItem {
            //            DefaultsManager.putString(NSStringFromCGPoint(webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
            //            DefaultsManager.putString(workItem.workId, key: DefaultsManager.LASTWRKID)
            //            DefaultsManager.putString(currentOnlineChapter, key: DefaultsManager.LASTWRKCHAPTER)
            
            saveHistoryItem(workItem: workItem)
        }
    }
    
    func lockScreen() {
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if let workItem = self.workItem {
            DefaultsManager.putString(NSStringFromCGPoint(webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
            DefaultsManager.putString(workItem.workId, key: DefaultsManager.LASTWRKID)
            DefaultsManager.putString(currentOnlineChapter, key: DefaultsManager.LASTWRKCHAPTER)
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // Retrieve and set your content offset when the view re-appears
    // and its subviews are first laid out
    /*override func viewDidLayoutSubviews() {
        
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
    }*/
    
    func addNavItems() {
        let imageS = UIImage(named: "ic_themechange") as UIImage?
        let searchButton = UIBarButtonItem(image : imageS, style: .plain, target: self, action: #selector(WorkViewController.changeThemeTouched));
        searchButton.tintColor = UIColor.white
        
        let imageI = UIImage(named: "ic_textsize") as UIImage?
        let igButton = UIBarButtonItem(image : imageI, style: .plain, target: self, action: #selector(WorkViewController.changeTextSizeTouched) );
        igButton.tintColor = UIColor.white
     //   igButton.imageInsets = UIEdgeInsetsMake(0.0, 0.0, 0, -30);
        
        let imageF = UIImage(named: "ic_textfamily") as UIImage?
        let ffButton = UIBarButtonItem(image : imageF, style: .plain, target: self, action: #selector(WorkViewController.changeTextFamilyTouched) );
        ffButton.tintColor = UIColor.white
      //  ffButton.imageInsets = UIEdgeInsetsMake(0.0, 0.0, 0, -60);
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        
        self.navigationItem.rightBarButtonItems = [ searchButton, igButton, ffButton, flexSpace]
    }
    
    //https://stackoverflow.com/questions/31114340/setstatusbarhidden-is-deprecated-in-ios-9-0
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        self.webView.scrollView.isScrollEnabled = false
        self.webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'") { (res, error) in
            print(error.debugDescription)
        }
        self.webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'", completionHandler: { (res, error) in
            print(error.debugDescription)
        })
        
        if (self.layoutView.tag == 1) {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            UIApplication.shared.isStatusBarHidden = false //.setStatusBarHidden(false, with: .fade)
            animateLayoutDown()
            
            self.layoutView.tag = 0
            
        } else {
            self.layoutView.animation = "fadeOut"
            self.layoutView.animate()
            
            if (self.layoutBottomView != nil) {
                self.layoutBottomView.animation = "fadeOut"
                self.layoutBottomView.animate()
            }
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            UIApplication.shared.isStatusBarHidden = true //.setStatusBarHidden(true, with: .fade)
            
            self.layoutView.tag = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            
            self.webView.scrollView.isScrollEnabled = true
            
            self.webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='text'") { (res, error) in
                print(error.debugDescription)
            }
            self.webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='default'", completionHandler: { (res, error) in
                print(error.debugDescription)
            })
        }
    }
    
    func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == UISwipeGestureRecognizerDirection.right {
            prevButtonTouched(prevButton)
        }
        else if recognizer.direction == UISwipeGestureRecognizerDirection.left {
            nextButtonTouched(nextButton)
        }
    }
    
    func animateLayoutDown() {
        
        if (self.layoutBottomView != nil) {
            self.layoutBottomView.animation = "fadeIn"
            self.layoutBottomView.animate()
        }
        
        if (!self.prevChapter.isEmpty || !self.nextChapter.isEmpty || (self.downloadedChapters != nil && self.downloadedChapters!.count > 0)) {
            self.layoutView.animation = "fadeIn"
            self.layoutView.animate()
        }
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
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
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
        
        if let downloadedWorkItem = self.downloadedWorkItem,
            let downloadedChapters = self.downloadedChapters, chapterIndex < downloadedChapters.count {
            
            let chapter = downloadedChapters[chapterIndex]
            self.work = chapter.chapterContent ?? ""
            
            loadCurrentTheme()
            downloadedWorkItem.setValue(NSNumber(value: chapterIndex as Int), forKey: "currentChapter")
            chapter.setValue(NSNumber(value: 1), forKey: "unread")
            
                //favWork.setCurrentChapter(String.valueOf(chapterIndex));
                //saveFavWorkChanges();
                saveWorkChanged()
            
           // self.title = downloadedChapters[chapterIndex].chapterName
        }
    }
    
    
    func turnOnlineChapter(_ chapterId: String, index: Int) {
        currentOnlineChapter = chapterId
        currentOnlineChapterIdx = index
        
        showLoadingView(msg: NSLocalizedString("LoadingChapter", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        
        params["view_adult"] = "true" as AnyObject?
        
//        Alamofire.request("https://archiveofourown.org/works/" + workItem.workId + "/chapters/" + chapterId, method: .get, parameters: params)
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
        
        var strUrl = chapterId
        if (!strUrl.contains("/works/")) {
            strUrl = "/works/" + (self.workItem?.workId ?? "") + "/chapters/" + chapterId
        }
        Alamofire.request("https://archiveofourown.org" + strUrl, method: .get, parameters: params)
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
            if (workContentEl.count > 0) {
                workContentStr = workContentEl[0].raw ?? ""
            
                let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
                workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
                
                let regex1:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive)
                workContentStr = regex1.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
            
                workContentStr = workContentStr.replacingOccurrences(of: "(?i)<strike\\b[^<]*>\\s*</strike>", with: "", options: .regularExpression, range: nil)
                //workContentStr = workContentStr.replacingOccurrences(of: "<strike/>", with: "")
                workContentStr = workContentStr.replacingOccurrences(of: "<[^>]+/>", with: "", options: .regularExpression, range: nil)
            }
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
                prevChapter = attributesp["href"] as? String ?? ""
            } else {
                prevChapter = ""
            }
            }
        }
        
        return (workContentStr, title)
    }
    
    func saveWorkChanged() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext,
            let workId = downloadedWorkItem?.workId else {
            return
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workId)
        if let selectWorks = (try? managedContext.fetch(fetchRequest)) as? [DBWorkItem] {
        
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
    
    func currentWorkSaveChanges() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return
        }
        
        do {
            try managedContext.save()
        } catch _ {
            print("cannot save current work after download")
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
        let selectWorks = (try? managedContext.fetch(fetchRequest)) as? [HistoryItem]
        
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
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
    
    @IBAction func kudosButtonTouched(_ sender: AnyObject) {
    
        var workId = ""
        
        if let workItem = self.workItem {
            workId = workItem.workId
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            workId = downloadedWorkItem.workId ?? "0"
        }
        
        Answers.logCustomEvent(withName: "WorkView: Kudos add",
                               customAttributes: [
                                "workId": workId])
        
        doLeaveKudos(workId: workId)
    
    }
    
    var beforeDownloadChapter = -1
    var beforeDownloadOffset = ""
    
    @IBAction func downloadButtonTouched(_ sender: AnyObject) {
        var workId = ""
        var isOnline = true
        
        if let workItem = self.workItem {
            workId = workItem.workId
            beforeDownloadChapter = currentOnlineChapterIdx
            isOnline = true
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            workId = downloadedWorkItem.workId ?? "0"
            beforeDownloadChapter = currentChapterIndex
            isOnline = false
        }
        
        beforeDownloadOffset = NSStringFromCGPoint(webView.scrollView.contentOffset)
        
        Answers.logCustomEvent(withName: "WorkView: Download touched",
                               customAttributes: [
                                "workId": workId])
        
        doDownloadWork(wId: workId, isOnline: isOnline)
    }
    
    var commentsForEntireWork = true
    @IBAction func commentButtonTouched() {
        
        Answers.logCustomEvent(withName: "WorkView: Comments touched",
                               customAttributes: [:])
        
        let alert = UIAlertController(title: NSLocalizedString("Comments", comment: ""), message: "View Comments For:", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Entire Work", style: UIAlertActionStyle.default, handler: { action in
            self.commentsForEntireWork = true
            self.performSegue(withIdentifier: "leaveComment", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Current Chapter", style: UIAlertActionStyle.default, handler: { action in
            self.commentsForEntireWork = false
            self.performSegue(withIdentifier: "leaveComment", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //MARK: - chapter next/prev
    
    @IBAction func nextButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            if (nextChapter.isEmpty) {
                return
            }
            
            showLoadingView(msg: NSLocalizedString("LoadingNxtChapter", comment: ""))
            
            currentOnlineChapter = nextChapter
            if (currentOnlineChapterIdx < onlineChapters.count - 1) {
                currentOnlineChapterIdx = currentOnlineChapterIdx + 1
            }
            
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
            
            let urlStr = "https://archiveofourown.org" + nextChapter
            
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
            if (currentChapterIndex == (downloadedChapters?.count ?? 0) - 1) {
                return
            }
            currentChapterIndex += 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    @IBAction func prevButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            if (prevChapter.isEmpty) {
                return
            }
            
            showLoadingView(msg: NSLocalizedString("LoadingPrevChapter", comment: ""))
            
            currentOnlineChapter = prevChapter
            if (currentOnlineChapterIdx > 0) {
                currentOnlineChapterIdx = currentOnlineChapterIdx - 1
            }
        
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
            
            var title = ""
        
            Alamofire.request("https://archiveofourown.org" + prevChapter, method: .get, parameters: params)
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
            if (currentChapterIndex == 0) {
                return
            }
            currentChapterIndex -= 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    override func onSavedWorkLoaded(_ response: DefaultDataResponse) {
        
        #if DEBUG
            print(response.request ?? "")
            
            print(response.error ?? "")
        #endif
        
        if let d = response.data {
            self.parseCookies(response)
            if let dd = self.downloadWork(d, workItemToReload: self.downloadedWorkItem),
                let downloadedChapters = dd.chapters?.allObjects as? [DBChapter] {
                self.downloadedWorkItem = dd
                if (self.beforeDownloadChapter >= 0) {
                    self.downloadedWorkItem?.currentChapter = NSNumber(value: self.beforeDownloadChapter)
                    self.beforeDownloadChapter = -1
                }
                if (self.beforeDownloadOffset.isEmpty == false) {
                    self.downloadedWorkItem?.scrollProgress = self.beforeDownloadOffset
                    self.beforeDownloadOffset = ""
                }
                currentWorkSaveChanges()
                
                self.showDownloadedWork(downloadedWork: self.downloadedWorkItem!, downloadedChapters: downloadedChapters)

            }
            self.hideLoadingView()
            
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
            if let dd = self.downloadWork(d, workItemOld: self.workItem),
                let downloadedChapters = dd.chapters?.allObjects as? [DBChapter] {
                
                self.downloadedWorkItem = dd
                if (self.beforeDownloadChapter >= 0) {
                    self.downloadedWorkItem?.currentChapter = NSNumber(value: self.beforeDownloadChapter)
                    self.beforeDownloadChapter = -1
                }
                if (self.beforeDownloadOffset.isEmpty == false) {
                    self.downloadedWorkItem?.scrollProgress = self.beforeDownloadOffset
                    self.beforeDownloadOffset = ""
                }
                
                currentWorkSaveChanges()
                
                self.workItem = nil
                
                self.showDownloadedWork(downloadedWork: self.downloadedWorkItem!, downloadedChapters: downloadedChapters)
                
            }
            
            self.hideLoadingView()
            
        } else {
            self.hideLoadingView()
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
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
            if let regex:NSRegularExpression = try? NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive) {
                work = regex.stringByReplacingMatches(in: work, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: work.count), withTemplate: "$1")
                
                let regex1:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive)
                work = regex1.stringByReplacingMatches(in: work, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: work.count), withTemplate: "$1")
            } else {
                work = ""
            }
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
        
//        if (!title.isEmpty) {
//            self.title = title
//        }
    }
    
    //Theme and Font changes
    
    func loadCurrentTheme() {
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME) {
            self.theme = th
        } else {
            self.theme = DefaultsManager.THEME_DAY
        }
        
        if let fs = DefaultsManager.getInt(DefaultsManager.FONT_SIZE) {
            fontSize = fs
        }
        
       let ffam = DefaultsManager.getString(DefaultsManager.FONT_FAMILY)
       if (ffam.isEmpty == false) {
            fontFamily = ffam
        }
        
        var worktext: String = work
        
        Answers.logCustomEvent(withName: "Work: Theme Load", customAttributes: ["font_family" : fontFamily,
                                                                                "font_size" : fontSize])
        
        var bgColor: UIColor = AppDelegate.greyLightColor
        var txtColor = AppDelegate.redColor
        
        switch (theme) {
            case DefaultsManager.THEME_DAY :
                webView.backgroundColor = AppDelegate.greyLightBg
                webView.isOpaque = false
                
                let fontStr = "font-size: " + String(format:"%d", fontSize) + "%; font-family: \"\(fontFamily)\";"
                worktext = String(format:"<style>body { color: #021439; %@; padding:5em 1.5em 4em 1.5em; text-align: justify; text-indent: 2em; } p {margin-bottom:1.1em}</style>%@", fontStr, work)
            
                bgColor = AppDelegate.greyLightColor
                txtColor = AppDelegate.redColor
                
            case DefaultsManager.THEME_NIGHT :
                self.webView.backgroundColor = AppDelegate.nightBgColor
                self.webView.isOpaque = false
                
                let fontStr = "font-size: " + String(format:"%d", fontSize) + "%; font-family: \"\(fontFamily)\""
                worktext = String(format:"<style>body { color: #e1e1ce; %@; padding:5em 1.5em 4em 1.5em; text-align: justify; text-indent: 2em; } p {margin-bottom:1.1em} </style>%@", fontStr, work)
            
                bgColor = AppDelegate.greyDarkBg
                txtColor = AppDelegate.textLightColor
                
            default:
                break
        }
        
       // let _ = webView(wview: webView, enableGL: false)
        
        layoutView.backgroundColor = bgColor
        layoutBottomView.backgroundColor = bgColor
        
        self.view.backgroundColor = bgColor
        
        prevButton.setTitleColor(txtColor, for: .normal)
        contentsButton.setTitleColor(txtColor, for: .normal)
        nextButton.setTitleColor(txtColor, for: .normal)
        
        webView.reload()
        webView.loadHTMLString(worktext, baseURL: nil)
    }
    
    func changeThemeTouched() {
        
        saveChanges()
        
        var theme: Int
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        switch (theme) {
        case DefaultsManager.THEME_DAY :
            DefaultsManager.putInt(DefaultsManager.THEME_NIGHT, key: DefaultsManager.THEME)
            Answers.logCustomEvent(withName: "Work_Theme", customAttributes: ["theme" : "night"])
            
        case DefaultsManager.THEME_NIGHT :
            DefaultsManager.putInt(DefaultsManager.THEME_DAY, key: DefaultsManager.THEME)
            Answers.logCustomEvent(withName: "Work_Theme", customAttributes: ["theme" : "day"])
            
        default:
            break
        }
        
        loadCurrentTheme()
        
        scrollWorks()
    }
    
    func changeTextSizeTouched() {
        let alert = UIAlertController(title: NSLocalizedString("FontSize", comment: ""), message: String(format: "%d", fontSize) + "%", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "+", style: UIAlertActionStyle.default, handler: { action in
            switch action.style{
            case .default:
                if (self.fontSize < 450) {
                    self.fontSize += 25
                } else {
                    self.fontSize = 450
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
                if (self.fontSize > 50) {
                    self.fontSize -= 25
                } else {
                    self.fontSize = 50
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
    
    func changeTextFamilyTouched() {
        let alert = UIAlertController(title: NSLocalizedString("FontFamily", comment: ""), message: "Select font family (\(fontFamily)", preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Verdana (default)", style: UIAlertActionStyle.default, handler: { action in
        
            self.fontFamily = "Verdana"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Arial", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Arial"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Courier New", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Courier New"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Helvetica", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Helvetica"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Georgia", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Georgia"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Trebuchet MS", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Trebuchet MS"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        alert.addAction(UIAlertAction(title: "Times New Roman", style: UIAlertActionStyle.default, handler: { action in
            
            self.fontFamily = "Times New Roman"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            alert.message = "Select font family (\(self.fontFamily)"
            self.loadCurrentTheme()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func contentsClicked(_ sender: UIButton) {
        if (downloadedChapters != nil || onlineChapters != nil) {
            let storyboard : UIStoryboard = UIStoryboard(
                name: "Main",
                bundle: nil)
            guard let contentsViewController: ContentsViewController = storyboard.instantiateViewController(withIdentifier: "contentsController") as? ContentsViewController else {
                return
            }
        
            if (workItem != nil) {
                contentsViewController.onlineChapters = onlineChapters
                contentsViewController.downloadedChapters = nil
            } else {
                contentsViewController.onlineChapters = nil
                contentsViewController.downloadedChapters = downloadedChapters
            }
            contentsViewController.modalDelegate = self
            contentsViewController.theme = theme
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
    
    func webView(wview: WKWebView, enableGL: Bool) -> Bool {
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
            
            if let anyObj = webView as? AnyObject {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "leaveComment") {
            let cController: CommentViewController = segue.destination as! CommentViewController
            
            var workId = ""
            var chapterId = ""
            
            if let workItem = self.workItem {
                workId = workItem.workId
                if commentsForEntireWork == false && onlineChapters.count > 0 && currentOnlineChapterIdx < onlineChapters.count {
                    chapterId = onlineChapters[currentOnlineChapterIdx]?.chapterId ?? ""
                }
                
            } else if let downloadedWorkItem = self.downloadedWorkItem {
                workId = downloadedWorkItem.workId ?? "0"
                if let downloadedChapters = self.downloadedChapters,
                    commentsForEntireWork == false,
                    downloadedChapters.count > 0,
                    currentChapterIndex < downloadedChapters.count {
                    chapterId = downloadedChapters[currentChapterIndex].chapterIndex?.stringValue ?? ""
                }
            }
            
            cController.workId = workId
            
            if (chapterId.isEmpty == false) {
                cController.chapterId = chapterId
            }
            
        }
    }
    
}
