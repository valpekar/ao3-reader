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
    
    var workItem: WorkItem! = nil
    var workChapters: [Chapter] = [Chapter]()
    
    var downloadedWorkItem: NSManagedObject! = nil
    var downloadedChapters: [DBChapter]! = nil
    
    var work: String = ""
    var fontSize: Int = 100
    
    var onlineChapters = [Int:ChapterOnline]()
    
    override func viewDidLoad() {
        
//        webView.scrollView.contentInset = UIEdgeInsetsMake(4, 0, 0, 0)
//        var basketTopFrame = self.layoutView.frame
//        basketTopFrame.origin.y -= basketTopFrame.size.height
//        self.layoutView.frame = basketTopFrame
        
        addNavItems()
        
        prevButton.isHidden = true
        webView.delegate = self
        
        if (workItem != nil) {
            if (onlineChapters.count == 0) {
                contentsButton.isHidden = true
            }
            
            if (!workItem.nextChapter.isEmpty) {
                nextChapter = workItem.nextChapter;
            } else {
                nextButton.isHidden = true
            }
            
            if (workItem.chapters.count > 0) {
                work = workItem.chapters.allObjects[0] as! String
                loadCurrentTheme()
            } else if (!workItem.workContent.isEmpty) {
                work = workItem.workContent.replacingOccurrences(of: "\n", with: "<p></p>")
                loadCurrentTheme()
            }
            
            if (!DefaultsManager.getString(DefaultsManager.LASTWRKCHAPTER).isEmpty) {
                    
                    nextChapter = DefaultsManager.getString(DefaultsManager.LASTWRKCHAPTER)
                    nextButtonTouched(self.view)
            }
            
            if (!DefaultsManager.getString(DefaultsManager.LASTWRKSCROLL).isEmpty) {
                let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                let offset: String? = DefaultsManager.getString(DefaultsManager.LASTWRKSCROLL)
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                    if (offset != nil) {
                        let scrollOffset:CGPoint? = CGPointFromString(offset!)
                        if let position:CGPoint = scrollOffset {
                            self.webView.scrollView.setContentOffset(position, animated: true)
                        }
                    }
                    
                }
            }
            
            DefaultsManager.putString("", key: DefaultsManager.LASTWRKSCROLL)
            DefaultsManager.putString("", key: DefaultsManager.LASTWRKID)
            DefaultsManager.putString("", key: DefaultsManager.LASTWRKCHAPTER)
            
        } else if (downloadedWorkItem != nil) {
            downloadedChapters = downloadedWorkItem.mutableSetValue(forKey: "chapters").allObjects as! [DBChapter]
            downloadedChapters.sort(by: { (a:DBChapter, b: DBChapter) -> Bool in
                return b.value(forKey: "chapterIndex") as! Int > a.value(forKey: "chapterIndex") as! Int
            })
            if (downloadedChapters != nil && downloadedChapters.count > 0) {
                contentsButton.isHidden = false
                currentChapterIndex = downloadedWorkItem.value(forKey: "currentChapter") as? Int ?? 0
                work = downloadedChapters[currentChapterIndex].value(forKey: "chapterContent") as? String ?? ""
                loadCurrentTheme()
                
                if (downloadedChapters.count == 1 || currentChapterIndex == downloadedChapters.count - 1) {
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
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        
        if (workItem != nil) {
            self.title = workItem.workTitle
        } else if (downloadedWorkItem != nil) {
            self.title = downloadedWorkItem.value(forKey: "workTitle") as? String
            let offset: String? = downloadedWorkItem.value(forKey: "scrollProgress") as? String
            if (offset != nil) {
                let scrollOffset:CGPoint? = CGPointFromString(offset!)
                if let position:CGPoint = scrollOffset {
                    webView.scrollView.setContentOffset(position, animated: true)
                }
            }
        }
        
//        let bounds = self.layoutView.bounds
//        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 10, options: nil, animations: {
//            self.layoutView.bounds = CGRect(x: bounds.origin.x - 20, y: bounds.origin.y, width: bounds.size.width + 60, height: bounds.size.height)
//            }, completion: nil)
        
        if (!nextChapter.isEmpty || !prevChapter.isEmpty) {
            animateLayoutDown()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    
        if (downloadedWorkItem != nil) {
            saveWorkChanged()
        } else if (workItem != nil) {
            DefaultsManager.putString(NSStringFromCGPoint(webView.scrollView.contentOffset), key: DefaultsManager.LASTWRKSCROLL)
            DefaultsManager.putString(workItem.workId, key: DefaultsManager.LASTWRKID)
            DefaultsManager.putString(currentOnlineChapter, key: DefaultsManager.LASTWRKCHAPTER)
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
            
            if (!self.prevChapter.isEmpty || !self.nextChapter.isEmpty || (self.downloadedChapters != nil && self.downloadedChapters.count > 0)) {
                
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
                print("animation done")
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
        if (downloadedChapters != nil && chapterIndex == downloadedChapters.count - 1) {
            nextButton.isHidden = true
        } else {
            nextButton.isHidden = false
        }
        
        if (chapterIndex > 0) {
            prevButton.isHidden = false
        } else {
            prevButton.isHidden = true
        }
        
        if (downloadedWorkItem != nil && downloadedChapters.count > 0) {
            contentsButton.isHidden = false
        } else {
           // contentsButton.hidden = true
        }
        
        if (downloadedWorkItem != nil && chapterIndex < downloadedChapters.count) {
            work = downloadedChapters[chapterIndex].chapterContent ?? ""
            loadCurrentTheme()
            downloadedWorkItem.setValue(NSNumber(value: chapterIndex as Int), forKey: "currentChapter")
            
            //favWork.setCurrentChapter(String.valueOf(chapterIndex));
            //saveFavWorkChanges();
            saveWorkChanged()
        }
    }
    
    
    func turnOnlineChapter(_ chapterId: String) {
        
        showLoadingView(msg: "Loading chapter")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        
        if let isAdult = DefaultsManager.getObject(DefaultsManager.ADULT) as? Bool {
            if (isAdult == true ) {
                
                params["view_adult"] = "true" as AnyObject?
            }
        }
        
        Alamofire.request("http://archiveofourown.org/works/" + workItem.workId + "/chapters/" + chapterId, method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                
                print(response.error ?? "")
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.work = self.parseChapter(d)
                    self.hideLoadingView()
                    self.showWork()
                    
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
    }
    
    func parseChapter(_ data: Data) -> String {
        //
        let doc : TFHpple = TFHpple(htmlData: data)
        var workContentStr = ""
        
        if let workContentEl = doc.search(withXPathQuery: "//div[@id='chapters']") as? [TFHppleElement] {
            workContentStr = workContentEl[0].raw ?? ""
            
            //var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            workContentStr = regex.stringByReplacingMatches(in: workContentStr, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: workContentStr.characters.count), withTemplate: "$1")
            
        }
        
        if let navigationEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as? [TFHppleElement] {
        
        if (navigationEl.count > 0) {
            
            let chapterNextEl: [TFHppleElement]? = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as? [TFHppleElement]
            if (chapterNextEl?.count ?? 0 > 0) {
                let attributes : NSDictionary = (chapterNextEl?[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                nextChapter = (attributes["href"] as! String)
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
        
        return workContentStr
    }
    
    func saveWorkChanged() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        guard let wid = downloadedWorkItem.value(forKey: "workId") as? String else {
            return
        }
        
        let workId = wid
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "workId = %@", workId)
        var selectWorks = (try! managedContext.fetch(fetchRequest)) as! [DBWorkItem]
        
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
    
    @IBAction func nextButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            showLoadingView(msg: "Loading next chapter")
            
            currentOnlineChapter = nextChapter
            
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
            
            let urlStr = "http://archiveofourown.org" + nextChapter
        
            Alamofire.request(urlStr, method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                self.downloadFullWork(response.data!)
                self.showWork()
            })
            
        } else {
            currentChapterIndex += 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    @IBAction func prevButtonTouched(_ sender: AnyObject) {
        
        if (workItem != nil) {
            showLoadingView(msg: "Loading previous chapter")
            
            currentOnlineChapter = prevChapter
        
            var params:[String:AnyObject] = [String:AnyObject]()
            params["view_adult"] = "true" as AnyObject?
        
            Alamofire.request("http://archiveofourown.org" + prevChapter, method: .get, parameters: params)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    self.downloadFullWork(response.data!)
                    self.showWork()
                })
        } else {
            currentChapterIndex -= 1
            turnOnChapter(currentChapterIndex)
        }
    }
    
    func downloadFullWork(_ data: Data) {
        
        prevChapter = ""
        nextChapter = ""
        
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("the string is: \(String(describing: dta))")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var chaptersEl: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='chapters']") as! [TFHppleElement]
        
        if (chaptersEl.count > 0) {
            work = chaptersEl[0].raw
          //  work = work.stringByReplacingOccurrencesOfString("<a.*\"\\s*>", withString:"")
          //  work = work.stringByReplacingOccurrencesOfString("</a>", withString: "")
         //   var error:NSErrorPointer = NSErrorPointer()
            let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<a href=\"[^\"]+\">([^<]+)</a>", options: NSRegularExpression.Options.caseInsensitive)
            work = regex.stringByReplacingMatches(in: work, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSRange(location: 0, length: work.characters.count), withTemplate: "$1")
        }
        
        var navigationEl: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='work navigation actions']") as! [TFHppleElement]
        
        if (navigationEl.count > 0) {
            
            var chapterNextEl: [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter next']") as! [TFHppleElement]
            if (chapterNextEl.count > 0) {
                let attributes : NSDictionary = (chapterNextEl[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                nextChapter = (attributes["href"] as! String)
            }
            
            var chapterPrevEl: [TFHppleElement] = navigationEl[0].search(withXPathQuery: "//li[@class='chapter previous']") as! [TFHppleElement]
            if(chapterPrevEl.count > 0) {
                let attributesp : NSDictionary = (chapterPrevEl[0].search(withXPathQuery: "//a")[0] as AnyObject).attributes as NSDictionary
                prevChapter = (attributesp["href"] as! String)
            }
        }
    }
    
    func showWork() {
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
        
        if (onlineChapters.count == 0) {
            contentsButton.isHidden = true
        }
        
        hideLoadingView()
        if ((!nextChapter.isEmpty || !prevChapter.isEmpty) && layoutView != nil) {
            animateLayoutDown()
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
        let alert = UIAlertController(title: "Font size", message: String(format: "%d", fontSize) + "%", preferredStyle: UIAlertControllerStyle.actionSheet)
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
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        
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
                chptNum = downloadedChapters.count
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
            turnOnlineChapter((onlineChapters[chapter]?.chapterId)!)
        }
    }
    
}
