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
import Crashlytics
import WebKit
import Spring
import PopupDialog
import Firebase
import RxSwift

class WorkViewController: ListViewController, UIGestureRecognizerDelegate, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var webViewContainer: UIView!
    var webView: WKWebView!
    
    @IBOutlet weak var layoutView: SpringView!
    @IBOutlet weak var layoutBottomView: SpringView!
    @IBOutlet weak var settingsView: SpringView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var contentsButton: UIButton!
    
    @IBOutlet weak var kudosButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    
    @IBOutlet weak var scrollingSlider: UISlider!
    
    var tapRecognizer: UITapGestureRecognizer! = nil
    
    var prevChapter: String = ""
    var nextChapter: String = ""
    
    var currentChapterIndex = 0
    var currentOnlineChapter = ""
    var currentOnlineChapterIdx = 0
    
    var kudosToken = ""
    
    var workItem: WorkItem?
    var workChapters: [Chapter] = [Chapter]()
    
    var downloadedWorkItem: DBWorkItem?
    var downloadedChapters: [DBChapter]?
    
    var work: String = ""
    var fontSize: Int = 200
    var fontFamily: String = "Verdana"
    
    var onlineChapters = [Int:ChapterOnline]()
    
    var viewLaidoutSubviews = false // <-- variable to prevent the viewDidLayoutSubviews code from happening more than once
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        let customFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 0.0, height: self.webViewContainer.frame.size.height))
        self.webView = WKWebView (frame: customFrame , configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webViewContainer.addSubview(webView)
        webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: webViewContainer.rightAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: webViewContainer.leftAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        webView.heightAnchor.constraint(equalTo: webViewContainer.heightAnchor).isActive = true
        webView.uiDelegate = self
        
        addNavItems()
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME) {
            self.theme = th
        } else {
            self.theme = DefaultsManager.THEME_DAY
        }
        
        prevButton.isHidden = true
        self.webView.navigationDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        if let workItem = self.workItem {
            
            showOnlineWork(workItem: workItem)
            
        } else if let downloadedWork = self.downloadedWorkItem,
            var downloadedChapters = downloadedWork.mutableSetValue(forKey: "chapters").allObjects as? [DBChapter] {
            
            downloadedChapters = downloadedChapters.sorted(by: { (chapter1, chapter2) -> Bool in
                return chapter1.chapterIndex?.int64Value ?? 0 > chapter2.chapterIndex?.int64Value ?? 0
            })
            showDownloadedWork(downloadedWork: downloadedWork, downloadedChapters: downloadedChapters)
        }
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(WorkViewController.handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 2
        tapRecognizer.delegate = self
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.delaysTouchesEnded = true
        webView.addGestureRecognizer(tapRecognizer)
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(WorkViewController.handleSwipe(_:)))
        swipeRecognizer.direction = UISwipeGestureRecognizer.Direction.left
        self.webView.addGestureRecognizer(swipeRecognizer)
        
        let swipeRecognizerR = UISwipeGestureRecognizer(target: self, action: #selector(WorkViewController.handleSwipe(_:)))
        swipeRecognizerR.direction = UISwipeGestureRecognizer.Direction.right
        self.webView.addGestureRecognizer(swipeRecognizerR)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WorkViewController.lockScreen), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        if (DefaultsManager.getBool("featuresShown") ?? false == false) {
            showContentAlert()
        }
        
        self.webView.scrollView.delegate = self
        self.searchBar.delegate = self
        
        if let tf = self.searchBar.value(forKey: "_searchField") as? UITextField {
            addDoneButtonOnKeyboardTf(tf)
        }
        
        if (purchased == false && donated == false) {
            loadAdMobRewared()
        }
    }
    
    override func doneButtonAction() {
        self.searchBar.endEditing(true)
    }
    
    
    func showOnlineWork(workItem: WorkItem) {
        if (self.theme == DefaultsManager.THEME_DAY) {
            downloadButton.setImage(UIImage(named: "download-100"), for: .normal)
        } else {
            downloadButton.setImage(UIImage(named: "download-100_light"), for: .normal)
        }
        
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
        if (self.theme == DefaultsManager.THEME_DAY) {
            downloadButton.setImage(UIImage(named: "ic_refresh"), for: .normal)
        } else {
            downloadButton.setImage(UIImage(named: "ic_refresh_light"), for: .normal)
        }
        
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
            
            if let chapter = self.downloadedChapters?[currentChapterIndex] {
                chapter.setValue(NSNumber(value: 1), forKey: "unread")
                saveWorkChanged()
            }
            
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
        let refreshAlert = UIAlertController(title: Localization("Attention"), message: "Enter/Leave Fullscreen mode with 2 taps; swipe to switch Next/Previous chapter", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
            DefaultsManager.putBool(true, key: "featuresShown")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    deinit {
        
        if (webView != nil) {
            webView.navigationDelegate = nil
            webView.stopLoading()
        }
        
        #if DEBUG
            print("Work view controller deinit")
        #endif
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willResignActive(_ notification: Notification) {
        saveChanges()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
                
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        
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
        
        let tapRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(WorkViewController.handleHideTap(_:)))
        tapRecognizer1.numberOfTapsRequired = 1
        tapRecognizer1.delegate = self
        tapRecognizer1.delaysTouchesBegan = true
        tapRecognizer1.delaysTouchesEnded = true
        self.webView.addGestureRecognizer(tapRecognizer1)
        
     //   scrollWorks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveChanges()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func scrollWorks() {
        if let workItem = self.workItem {
            //self.title = workItem.workTitle
            
            if let historyItem: HistoryItem = self.getHistoryItem(workId: workItem.workId) {
                if let nxtChapter = historyItem.lastChapter,
                    let nxtChapterIdx = historyItem.lastChapterIdx {
                    nextChapter = nxtChapter
                    turnOnlineChapter(nextChapter, index: Int(truncating: nxtChapterIdx))
                    //nextButtonTouched(self.view)
                }
                
                if let lastScroll = historyItem.scrollProgress,
                    let _ = self.webView {
                    let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        let scrollOffset:CGPoint? = NSCoder.cgPoint(for: lastScroll)
                        if let position:CGPoint = scrollOffset {
                            self.webView.scrollView.setContentOffset(position, animated: true)
                        }
                    }
                }
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.handleSingleTap(self.tapRecognizer)
                
                self.shouldStartTrackVelocity = true
            }
            
        }  else if let downloadedWorkItem = downloadedWorkItem {
            //var title = downloadedWorkItem.workTitle ?? ""
            
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
                    let scrollOffset:CGPoint = NSCoder.cgPoint(for: offset)
                    self.webView.scrollView.setContentOffset(scrollOffset, animated: true)
                }
            }
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.handleSingleTap(self.tapRecognizer)
                
                self.shouldStartTrackVelocity = true
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
    
    @objc func lockScreen() {
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if let workItem = self.workItem {
            DefaultsManager.putString(NSCoder.string(for: webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
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
        
        let imageQ = UIImage(named: "quotes") as UIImage?
        let qButton = UIBarButtonItem(image : imageQ, style: .plain, target: self, action: #selector(WorkViewController.quoteTouched) );
        qButton.tintColor = UIColor.white
        
        let imageSs = UIImage(named: "search") as UIImage?
        let ssButton = UIBarButtonItem(image : imageSs, style: .plain, target: self, action: #selector(WorkViewController.searchTouched) );
        ssButton.tintColor = UIColor.white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        
        self.navigationItem.rightBarButtonItems = [ searchButton, igButton, ffButton, qButton, ssButton, flexSpace]
    }
    
    @objc func handleHideTap(_ recognizer: UITapGestureRecognizer) {
        if (self.settingsView.isHidden == false) {
            self.settingsView.animation = "fadeOut"
            self.settingsView.duration = 0.8
            self.settingsView.animate()
            
            let delayTime = DispatchTime.now() + Double(Int64(0.8 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.settingsView.isHidden = true
            }
        }
        
        self.searchBar.isHidden = true
        self.removeAllHighlights()
    }
    
    //https://stackoverflow.com/questions/31114340/setstatusbarhidden-is-deprecated-in-ios-9-0
    @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        self.webView.scrollView.isScrollEnabled = false
        self.webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'") { (res, error) in
            print(error.debugDescription)
        }
        self.webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'", completionHandler: { (res, error) in
            print(error.debugDescription)
        })
        
        if (self.layoutView.tag == 1) {
           self.showBars()
            
        } else {
           hideAllBars()
            
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
    
    override var prefersStatusBarHidden: Bool {
        if (self.layoutView.tag == 1) {
            return false
        } else {
            return true
        }
    }
    
    func hideAllBars() {
        self.layoutView.animation = "fadeOut"
        self.layoutView.duration = 1.5
        self.layoutView.animate()
        
        if (self.layoutBottomView != nil) {
            self.layoutBottomView.animation = "fadeOut"
            self.layoutBottomView.duration = 1.5
            self.layoutBottomView.animate()
        }
        
        self.settingsView.animation = "fadeOut"
        self.settingsView.duration = 0.8
        self.settingsView.animate()
        
        let delayTime = DispatchTime.now() + Double(Int64(0.8 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.settingsView.isHidden = true
        }
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.layoutView.tag = 1
    }
    
    func showBars() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        animateLayoutDown()
        
        self.layoutView.tag = 0
    }
    
    @objc func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == UISwipeGestureRecognizer.Direction.right {
            prevButtonTouched(prevButton)
        }
        else if recognizer.direction == UISwipeGestureRecognizer.Direction.left {
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
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        return true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
//        if let path = Bundle.main.path(forResource: "UIWebViewSearch", ofType: "js"), let jsCode = try? String(contentsOfFile:path, encoding:String.Encoding.utf8) {
//
//            self.webView.evaluateJavaScript(jsCode) { (res, error) in
//                print(res ?? "")
//                print(error?.localizedDescription ?? "")
//            }
//        }
        
        self.webView.scrollView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        let delayTime = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.scrollingSlider.minimumValue = 0.0
            self.scrollingSlider.maximumValue = Float(self.webView.scrollView.contentSize.height - self.webView.scrollView.bounds.height )
        }
       // if (self.scrollingSlider.maximumValue == 1.0) {
//            self.webView.evaluateJavaScript("document.body.scrollHeight;", completionHandler: { (res, error) in
//                if let resFloat = res as? Float {
//                    self.scrollingSlider.maximumValue = resFloat
//                }
//            })
   //     }
    }
    
    func turnOnChapter(_ chapterIndex: Int) {
        
        showLoadingView(msg: Localization("LoadingNxtChapter"))
        
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
        
        self.hideLoadingView()
    }
    
    
    func turnOnlineChapter(_ chapterId: String, index: Int) {
        currentOnlineChapter = chapterId
        currentOnlineChapterIdx = index
        
        showLoadingView(msg: Localization("LoadingChapter"))
        
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
//                    showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
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
            showError(title: Localization("Error"), message: Localization("CheckInternet"))
        }
        
    }
    
    func parseChapter(_ data: Data) -> (String, String) {
        //
        guard let doc : TFHpple = TFHpple(htmlData: data) else {
            return ("", "")
        }
        var workContentStr: String = ""
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            if (workContentEl.count > 0) {
                workContentStr = workContentEl[0].raw ?? ""
            
                if let regex:NSRegularExpression = try? NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive) {
                workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
                }
                
                if let regex1:NSRegularExpression = try? NSRegularExpression(pattern: "<a href=.*/>", options: NSRegularExpression.Options.caseInsensitive) {
                workContentStr = regex1.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.count), withTemplate: "$1")
                }
            
                workContentStr = workContentStr.replacingOccurrences(of: "(?i)<strike\\b[^<]*>\\s*</strike>", with: "", options: .regularExpression, range: nil)
                //workContentStr = workContentStr.replacingOccurrences(of: "<strike/>", with: "")
                workContentStr = workContentStr.replacingOccurrences(of: "<[^>]+/>", with: "", options: .regularExpression, range: nil)
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
            let workId = downloadedWorkItem?.workId else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workId)
        if let selectWorks = (try? managedContext.fetch(fetchRequest)) as? [DBWorkItem] {
        
            if (selectWorks.count > 0) {
            let currentWork = selectWorks[0] as DBWorkItem
            currentWork.currentChapter = NSNumber(value: currentChapterIndex as Int)
                if (webView.scrollView.contentOffset != CGPoint(x:0.0, y:0.0)) {
                    let offset = NSCoder.string(for: webView.scrollView.contentOffset)
                    currentWork.scrollProgress = offset
                }
            currentWork.dateUpdated = Date() as NSDate
                
                let maxBottomYOffset = webView.scrollView.contentSize.height - webView.scrollView.bounds.size.height + webView.scrollView.contentInset.bottom
                let readOffset = /*maxBottomYOffset -*/ webView.scrollView.contentOffset.y
                
                let chptCount = currentWork.chapters?.count ?? 0
                if (chptCount == 1 || chptCount == 0) {
                    
                    if (readOffset >= 0 && (maxBottomYOffset - readOffset) <= 50) {
                        currentWork.progress = NSNumber(value: 1.0)
                    } else {
                        currentWork.progress = NSNumber(value: Float(readOffset/maxBottomYOffset))
                    }
                } else {
                    if (currentChapterIndex == 0) {
                        
                        let progressInChapter: Float = Float(readOffset/maxBottomYOffset)
                        currentWork.progress = NSNumber(value: progressInChapter/Float(chptCount))
                        
                    } else {
                        if (readOffset == maxBottomYOffset) {
                            let progress: Float = Float(currentChapterIndex )/Float(chptCount)
                            currentWork.progress = NSNumber(value: progress)
                        } else if (readOffset >= 0 && (maxBottomYOffset - readOffset) <= 50) {
                            let progress: Float = Float(currentChapterIndex + 1)/Float(chptCount)
                            currentWork.progress = NSNumber(value: progress)
                        } else {
                            let progress: Float = Float(currentChapterIndex)/Float(chptCount) + (Float(readOffset/maxBottomYOffset)/Float(chptCount))
                            currentWork.progress = NSNumber(value: progress)
                        }
                        
                    }
                }

            
            do {
                try managedContext.save()
            } catch _ {
            }
        }
        }
    }
    
    func currentWorkSaveChanges() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        appDelegate.saveContext()
    }
    
    
    //MARK: - history items
    
    func saveHistoryItem(workItem: WorkItem) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "HistoryItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workItem.workId)
        let selectWorks = (try? managedContext.fetch(fetchRequest)) as? [HistoryItem]
        
        if (selectWorks?.count ?? 0 > 0 && self.webView != nil) {
            let currentWork = selectWorks?[0]
            currentWork?.lastChapter = currentOnlineChapter
            currentWork?.lastChapterIdx = currentOnlineChapterIdx as NSNumber
            currentWork?.scrollProgress = NSCoder.string(for: webView.scrollView.contentOffset)
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
            historyItem.scrollProgress = NSCoder.string(for: webView.scrollView.contentOffset)
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
        let managedContext = appDelegate.persistentContainer.viewContext
        
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
        Analytics.logEvent("WorkView_Kudos_add", parameters: ["workId": workId as NSObject])
        
        doLeaveKudos(workId: workId, kudosToken: self.kudosToken).subscribe { (_) in
            }.disposed(by: self.disposeBag)
    
    }
    
     @objc func controllerDidClosedWithLogin() {
        
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
        
        beforeDownloadOffset = NSCoder.string(for: webView.scrollView.contentOffset)
        
        Answers.logCustomEvent(withName: "WorkView: Download touched",
                               customAttributes: [
                                "workId": workId])
        
        doDownloadWork(wId: workId, isOnline: false, wasSaved: !isOnline)
    }
    
    var commentsForEntireWork = true
    @IBAction func commentButtonTouched() {
        
        Answers.logCustomEvent(withName: "WorkView: Comments touched",
                               customAttributes: [:])
        
        let alert = UIAlertController(title: Localization("Comments"), message: "View Comments For:", preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "Entire Work", style: UIAlertAction.Style.default, handler: { action in
            self.commentsForEntireWork = true
            self.performSegue(withIdentifier: "leaveComment", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Current Chapter", style: UIAlertAction.Style.default, handler: { action in
            self.commentsForEntireWork = false
            self.performSegue(withIdentifier: "leaveComment", sender: self)
        }))
        
        alert.addAction(UIAlertAction(title: Localization("Cancel"), style: UIAlertAction.Style.cancel, handler: nil))
        
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
            
            showLoadingView(msg: Localization("LoadingNxtChapter"))
            
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
            
            showLoadingView(msg: Localization("LoadingPrevChapter"))
            
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
                self.workItem = nil
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
            showError(title: Localization("Error"), message: Localization("CheckInternet"))
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
            showError(title: Localization("Error"), message: Localization("CheckInternet"))
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
            work = chaptersEl[0].raw ?? ""
        
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
    
    override func applyTheme() {
        //do nothing
    }
    
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
        
        
        var fontCss = ""
        let fontFamilyStr = "font-family: \"\(fontFamily)\""
        if (fontFamily.contains("Rooney")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(Rooney-Regular.ttf); format('truetype')} "
        } else if (fontFamily.contains("OpenDyslexic")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(OpenDyslexic-Regular.ttf); format('truetype'); } "
        } else if (fontFamily.contains("Futura")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(FuturaBook.ttf); format('truetype')} "
        }
        else if (fontFamily.contains("Burton\'s Nightmare")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(NITEMARE.TTF); format('truetype')} "
        } else if (fontFamily.contains("Star Jedi")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(Starjedi.ttf); format('truetype')} "
        } else if (fontFamily.contains("Romance Fatal Serif")) {
            fontCss = "@font-face { font-family: \"\(fontFamily)\"; src: url(RFS_Juan_Casco.ttf); format('truetype')} "
        }
        
        let fontStr = "font-size: " + String(format:"%d", fontSize) + "%; \(fontFamilyStr); "
        
        switch (theme) {
            case DefaultsManager.THEME_DAY :
                webView.backgroundColor = AppDelegate.greyLightBg
                webView.isOpaque = false
                
                worktext = String(format:"<style>\(fontCss) body, table { color: #021439; %@; padding:5em 1.5em 4em 1.5em; text-align: left; line-height: 1.5em;  overflow-y: scroll; -webkit-overflow-scrolling: touch; word-wrap:break-word; } p {margin-bottom:1.0em;}</style>%@", fontStr, work)
            
                bgColor = AppDelegate.greyLightColor
                txtColor = AppDelegate.redColor
            
                commentsButton.setImage(UIImage(named: "comments"), for: UIControl.State.normal)
                kudosButton.setImage(UIImage(named: "likes"), for: UIControl.State.normal)
            
                self.view.backgroundColor = AppDelegate.greyLightBg
                
            case DefaultsManager.THEME_NIGHT :
                self.webView.backgroundColor = AppDelegate.nightBgColor
                self.webView.isOpaque = false
                
                worktext = String(format:"<style>\(fontCss) body, table { color: #e1e1ce; %@; padding:5em 1.5em 4em 1.5em; text-align: left; line-height: 1.5em; overflow-y: scroll; -webkit-overflow-scrolling: touch; word-wrap:break-word; } p {margin-bottom:1.0em} </style>%@", fontStr, work)
            
                bgColor = AppDelegate.greyDarkBg
                txtColor = AppDelegate.textLightColor
            
                commentsButton.setImage(UIImage(named: "comments_light"), for: UIControl.State.normal)
                kudosButton.setImage(UIImage(named: "likes_light"), for: UIControl.State.normal)
            
                self.view.backgroundColor = AppDelegate.redDarkColor
                
            default:
                break
        }
        
        worktext.append("<p style='margin-bottom:30%;'><br/></p>")
        
       // let _ = webView(wview: webView, enableGL: false)
        layoutView.backgroundColor = bgColor
        layoutBottomView.backgroundColor = bgColor
        settingsView.backgroundColor = bgColor
        
        self.view.backgroundColor = bgColor
        
        prevButton.setTitleColor(txtColor, for: .normal)
        contentsButton.setTitleColor(txtColor, for: .normal)
        nextButton.setTitleColor(txtColor, for: .normal)
        
        webView.reload()
        var url: URL? = nil
        if let resourcePath = Bundle.main.resourcePath {
            url = URL.init(fileURLWithPath: resourcePath)
        }
        webView.loadHTMLString(worktext, baseURL: url)
    }
    
    @objc func searchTouched() {
        if (purchased == true || donated == true) {
            self.searchBar.isHidden = false
        } else {
            self.showWarning(title: "Premium Feature", message: "Searching on the page is available to premium users only.")
        }
    }
    
    @objc func changeThemeTouched() {
        
        self.searchBar.isHidden = true
        
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
    
    @IBAction func fontSizeAddTouched(_ sender: AnyObject) {
        if (self.fontSize < 420) {
            self.fontSize += 10
        } else {
            self.fontSize = 400
        }
        DefaultsManager.putInt(self.fontSize, key: DefaultsManager.FONT_SIZE)
        
        self.loadCurrentTheme()
    }
    
    @IBAction func fontSizeMinusTouched(_ sender: AnyObject) {
        if (self.fontSize > 20) {
            self.fontSize -= 10
        } else {
            self.fontSize = 20
        }
        DefaultsManager.putInt(self.fontSize, key: DefaultsManager.FONT_SIZE)
        
        self.loadCurrentTheme()
    }
    
    @objc func changeTextSizeTouched() {
        self.searchBar.isHidden = true
        
        if (settingsView.isHidden == true) {
            
            settingsView.isHidden = false
            self.settingsView.animation = "fadeIn"
            self.settingsView.duration = 0.8
            self.settingsView.animate()
        } else {
            self.settingsView.animation = "fadeOut"
            self.settingsView.duration = 0.8
            self.settingsView.animate()
            
            let delayTime = DispatchTime.now() + Double(Int64(0.8 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.settingsView.isHidden = true
            }
        }
        
       /* let alert = UIAlertController(title: Localization("FontSize"), message: String(format: "%d", fontSize) + "%", preferredStyle: UIAlertControllerStyle.actionSheet)
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
        
        alert.addAction(UIAlertAction(title: Localization("OK"), style: UIAlertActionStyle.cancel, handler: nil))
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil) */
    }
    
    @objc func changeTextFamilyTouched() {
        let popup = PopupDialog(title: Localization("FontFamily"), message: "Select font family (\(fontFamily)")
        
        let buttonCancel = CancelButton(title: "CANCEL") {
            print("You canceled the car dialog.")
        }
        
        let buttonOne = DefaultButton(title: "Verdana (default)") {
            self.fontFamily = "Verdana"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let buttonTwo = DefaultButton(title: "Arial") {
            self.fontFamily = "Arial"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let buttonThree = DefaultButton(title: "Courier New") {
            self.fontFamily = "Courier New"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let button4 = DefaultButton(title: "Helvetica") {
            self.fontFamily = "Helvetica"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let button5 = DefaultButton(title: "Georgia") {
            self.fontFamily = "Georgia"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let button6 = DefaultButton(title: "Trebuchet MS") {
            self.fontFamily = "Trebuchet MS"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let button7 = DefaultButton(title: "Times New Roman") {
            self.fontFamily = "Times New Roman"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
        }
        
        let button8 = DefaultButton(title: "Open Dyslexic Regular (Premium)") {
            if (self.purchased == true) {
            self.fontFamily = "OpenDyslexic"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        let button9 = DefaultButton(title: "Rooney (Premium)") {
            if (self.purchased == true) {
            self.fontFamily = "Rooney"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        let button10 = DefaultButton(title: "Futura (Premium)") {
            if (self.purchased == true) {
            self.fontFamily = "Futura"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        let button11 = DefaultButton(title: "Burton\'s Nightmare (Premium)") {
            if (self.purchased == true) {
            self.fontFamily = "Burton\'s Nightmare"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        let button12 = DefaultButton(title: "Star Wars (Premium)") {
            if (self.purchased == true) {
            self.fontFamily = "Star Jedi"
            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
            self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        let button13 = DefaultButton(title: "Romance Fatal Serif (Premium)") {
            if (self.purchased == true) {
                self.fontFamily = "Romance Fatal Serif"
                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
                self.loadCurrentTheme()
            }  else {
                self.showWarning(title: "Warning: This Font is Premium", message: "Please upgrade to be able to use it!")
            }
        }
        
        popup.addButtons([buttonOne, buttonTwo, buttonThree, button4, button5, button6, button7, button8, button9, button10, button11, button12, button13, buttonCancel])
        
        self.present(popup, animated: true, completion: nil)
        
//        let alert = UIAlertController(title: Localization("FontFamily"), message: "Select font family (\(fontFamily)", preferredStyle: UIAlertControllerStyle.actionSheet)
//        alert.addAction(UIAlertAction(title: "Verdana (default)", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Verdana"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Arial", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Arial"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Courier New", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Courier New"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Helvetica", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Helvetica"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Georgia", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Georgia"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Trebuchet MS", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Trebuchet MS"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//        alert.addAction(UIAlertAction(title: "Times New Roman", style: UIAlertActionStyle.default, handler: { action in
//
//            self.fontFamily = "Times New Roman"
//            DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//            alert.message = "Select font family (\(self.fontFamily)"
//            self.loadCurrentTheme()
//        }))
//
//        alert.addAction(UIAlertAction(title: "Open Dyslexic Regular (Premium)", style: UIAlertActionStyle.default, handler: { action in
//
//            if (self.purchased == false) {
//                self.fontFamily = "OpenDyslexic"
//                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//                alert.message = "Select font family (\(self.fontFamily)"
//                self.loadCurrentTheme()
//            } else {
//                showNotification(in: self, title: "Warning: This Font is Premium", subtitle: "Please upgrade to be able to use it!", type: NotificationType.warning)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Rooney (Premium)", style: UIAlertActionStyle.default, handler: { action in
//
//            if (self.purchased == false) {
//                self.fontFamily = "Rooney"
//                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//                alert.message = "Select font family (\(self.fontFamily)"
//                self.loadCurrentTheme()
//            } else {
//                showNotification(in: self, title: "Warning: This Font is Premium", subtitle: "Please upgrade to be able to use it!", type: NotificationType.warning)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Futura (Premium)", style: UIAlertActionStyle.default, handler: { action in
//
//            if (self.purchased == false) {
//                self.fontFamily = "Futura"
//                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//                alert.message = "Select font family (\(self.fontFamily)"
//                self.loadCurrentTheme()
//            } else {
//                showNotification(in: self, title: "Warning: This Font is Premium", subtitle: "Please upgrade to be able to use it!", type: NotificationType.warning)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Burton\'s Nightmare (Premium)", style: UIAlertActionStyle.default, handler: { action in
//
//            if (self.purchased == false) {
//                self.fontFamily = "Burton\'s Nightmare"
//                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//                alert.message = "Select font family (\(self.fontFamily)"
//                self.loadCurrentTheme()
//            } else {
//                showNotification(in: self, title: "Warning: This Font is Premium", subtitle: "Please upgrade to be able to use it!", type: NotificationType.warning)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Star Wars (Premium)", style: UIAlertActionStyle.default, handler: { action in
//
//            if (self.purchased == false) {
//                self.fontFamily = "Star Jedi"
//                DefaultsManager.putString(self.fontFamily, key: DefaultsManager.FONT_FAMILY)
//                alert.message = "Select font family (\(self.fontFamily)"
//                self.loadCurrentTheme()
//            } else {
//                showNotification(in: self, title: "Warning: This Font is Premium", subtitle: "Please upgrade to be able to use it!", type: NotificationType.warning)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: Localization("Cancel"), style: UIAlertActionStyle.cancel, handler: nil))
        
//        alert.popoverPresentationController?.sourceView = self.view
//        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
//
//        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func contentsClicked(_ sender: UIButton) {
        
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
                
                if (self.downloadedChapters == nil) {
                    self.downloadedChapters = [DBChapter]()
                }
                
                contentsViewController.onlineChapters = nil
                contentsViewController.downloadedChapters = self.downloadedChapters
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
    
    override func controllerDidClosed() { }
    
    @objc func controllerDidClosedWithChapter(_ chapter: Int) {
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
            self.showBars()
            
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
    
    var previousScrollMoment: Date = Date()
    var previousScrollX: CGFloat = 0
    var shouldStartTrackVelocity = false
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //TODO: - https://stackoverflow.com/questions/3719753/iphone-uiscrollview-speed-check
        
        let d = Date()
        let x = scrollView.contentOffset.y
        let elapsed = Date().timeIntervalSince(previousScrollMoment)
        let distance = (x - previousScrollX)
        let velocity = (elapsed == 0) ? 0 : abs(distance / CGFloat(elapsed))
        previousScrollMoment = d
        previousScrollX = x
       // print("scrolling velocity \(velocity)")
        
        self.scrollingSlider.removeTarget(self, action: #selector(self.scrollingSliderValueChanged(_:)), for: UIControl.Event.valueChanged)
        self.scrollingSlider.value = Float(scrollView.contentOffset.y)
        
        let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.scrollingSlider.addTarget(self, action: #selector(self.scrollingSliderValueChanged(_:)), for: UIControl.Event.valueChanged)
        }
        
        if (velocity > 2000 && shouldStartTrackVelocity == true && self.layoutView.tag == 0) {
            hideAllBars()
        }
        
        if (( abs((scrollView.contentSize.height - scrollView.frame.size.height) - scrollView.contentOffset.y) <= 4)
            && velocity < 5 && distance < 5) {
            let delayTime = DispatchTime.now() + Double(Int64(0.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.nextButtonTouched(self)
            }
        }
    }
    
}

//MARK: - scrolling slider

extension WorkViewController {
    
    @IBAction func scrollingSliderValueChanged(_ sender: UISlider) {
        let newValue: Float = sender.value
        if (newValue < 0) {
            return
        }
        self.webView.scrollView.delegate = nil
        
        let scrollOffset:CGPoint? = CGPoint(x: 0.0, y: Double(newValue))
        if let position:CGPoint = scrollOffset {
            self.webView.scrollView.setContentOffset(position, animated: false)
            //self.webView.scrollView.flashScrollIndicators()
        }
        
        self.webView.scrollView.delegate = self
    }
}

//MARK: - selecting quote

extension WorkViewController {

    @objc func quoteTouched() {
        self.webView.evaluateJavaScript("window.getSelection().toString()") { (result, error) in
            if let selectedString = result as? String, selectedString.isEmpty == false {
                self.showQuoteDialog(text: selectedString)
            } else {
                self.showWarning(title: "Empty Selection", message: "Please select any text to save it as quote.")
            }
        }

    }
    
    func showQuoteDialog(text: String) {
        if (text.isEmpty == true) {
            return
        }
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("You want to save this lines to your Highlights?"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            self.saveQuote(text: text)
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func saveQuote(text: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "DBHighlightItem",  in: managedContext) else {
            return
        }
        
        var workId = ""
        var workName = ""
        var authorName = ""
       // var fandom = ""
       // var relationship = ""
        
        if let workItem = self.workItem {
            workId = workItem.workId
            workName = workItem.workTitle
            authorName = workItem.author
        } else if let downloadedWorkItem = self.downloadedWorkItem {
            workId = downloadedWorkItem.workId ?? "0"
            workName = downloadedWorkItem.workTitle ?? "None"
            authorName = downloadedWorkItem.author ?? "None"
        }
        
        let nItem = DBHighlightItem(entity: entity, insertInto: managedContext)
        nItem.workId = workId
        nItem.workName = workName
        nItem.author = authorName
        nItem.content = text
        nItem.date = NSDate()
        
        Answers.logCustomEvent(withName: "Work: save highlight", customAttributes: ["workName" : workName, "content": text])
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(String(describing: error.userInfo))")
        } 
        
//        showNotification(in: self, title: Localization("Success"), subtitle: "Highlight was successfully saved!", type: Type.success, customTypeName: "", callback: {
//
//        })
        showSuccess(title: Localization("Success"), message: "Highlight was successfully saved!")
        
    }
}

extension WorkViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.count ?? 0 > 2) {
            
            Answers.logCustomEvent(withName: "WorkView: search",
                                   customAttributes: [
                                    "searchText": searchText])
            
            if let path = Bundle.main.path(forResource: "UIWebViewSearch", ofType: "js"), let jsCode = try? String(contentsOfFile:path, encoding:String.Encoding.utf8) {
                
                self.webView.evaluateJavaScript(jsCode) { (res, error) in
                    print(res ?? "")
                    print(error?.localizedDescription ?? "")
                    
                    let startSearch = String(format: "uiWebview_HighlightAllOccurencesOfString('%@')", searchText)
                    self.webView.evaluateJavaScript(startSearch) { (res, error) in
                        print(res ?? "")
                        print(error?.localizedDescription ?? "")
                    }
                }
            }
            
           
        } else if (searchBar.text?.count ?? 0 == 0) {
            removeAllHighlights()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        removeAllHighlights()
        self.searchBar.isHidden = true
    }
    
    func removeAllHighlights() {
        self.webView.evaluateJavaScript("uiWebview_RemoveAllHighlights()") { (res, error) in
            
        }
        self.searchBar.text = ""
        self.searchBar.endEditing(true)
    }
    
    
}
