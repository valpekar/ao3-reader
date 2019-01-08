//
//  CommentViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/22/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import RMessage
import WebKit
import SwiftMessages

class CommentViewController: LoadingViewController, UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate, WKUIDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var commentTv: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var webViewContainer: UIView!
    var webView: WKWebView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bgView: UIView!
    
    var pages : [PageItem] = [PageItem]()
    
    var shouldScroll = false
    
    var htmlStr = Localization("NoComments")
    var fontSize: Int = 100
    var workId = ""
    var chapterId = ""
    
    var commentsToken = ""
    
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
        
        self.title = Localization("Comments")
        
        makeRoundView(view: sendBtn)
        makeRoundView(view: commentTv)
        
        commentTv.layer.borderColor = UIColor.purple.cgColor
        commentTv.layer.borderWidth = 1
        
       // commentsWebView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        addDoneButtonOnKeyboard(commentTv)
        
        getAllComments()
        //loadCurrentTheme()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.isHidden = false
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            openLoginController(force: false)
        }
    }
    
    func controllerDidClosedWithLogin() {
        //TODO: 
    }
    
    //MARK: tableview
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CommentCell? = tableView.dequeueReusableCell(withIdentifier: "commentCell") as? CommentCell
        
        return cell!
    }
    
    //MARK: - get comments
    
    func getAllComments() {
        //https://archiveofourown.org/works/6107953?show_comments=true&view_full_work=true#comments
        var requestStr = ""
        if (chapterId.isEmpty == true) {
            requestStr = "https://archiveofourown.org/works/" + workId + "?show_comments=true&view_full_work=true#comments"
        } else {
            requestStr = "https://archiveofourown.org/comments/show_comments?" + "chapter_id=\(chapterId)"
        }
        
        showLoadingView(msg: Localization("GettingComments"))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        Alamofire.request(requestStr, method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseComments(d)
                    self.loadCurrentTheme()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
        
        
    }
    
    func parseComments(_ data: Data) {
        
        htmlStr = ""
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
        
            if(sorrydiv.count > 0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                /*workItem.setValue("Sorry!", forKey: "author")
                 workItem.setValue("This work is only available to registered users of the Archive", forKey: "workTitle")
                 workItem.setValue("", forKey: "complete")*/
                //   return NEXT_CHAPTER_NOT_EXIST;
                return
            }
        }
        
        htmlStr.append("<html><body><ol>")
        
        if let commentsSection: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='comments_placeholder']") as? [TFHppleElement] {
            for liEl in commentsSection {
            
                do {
                    let regex = try NSRegularExpression(pattern: "href", options: .dotMatchesLineSeparators)
                
                    if let content = liEl.content {
                        var c = content.replacingOccurrences(of: "\n", with: "")
                        c = c.replacingOccurrences(of: " ", with: "")
                        if (c.count > 0) {
                            let raw:String = liEl.raw
            
                            htmlStr.append(regex.stringByReplacingMatches(in: raw, options: .reportCompletion, range: NSRange(location: 0, length: raw.count), withTemplate: ""))
                        }
                    }
                } catch {
                    print("commentsSection parse error")
                }
            
            //htmlStr.appendContentsOf(liEl.raw.stringByReplacingOccurrencesOfString("<ul class='actions' role='menu' id='navigation_for_comment_[1-9]+'>(.|\n)*?</ul>", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil))
            }
        }
        if (htmlStr.count == 16) { //"<html><body><ol>"
            htmlStr.append("<h2 align=\"center\">")
            htmlStr.append(Localization("NoComments"))
            htmlStr.append("</h2>")
        }
        
        htmlStr.append("</ol></body></html>")
        htmlStr = htmlStr.replacingOccurrences(of: "\n", with: "<p></p>")
        //(.|\n)*?<\\/ul>
        
        pages.removeAll(keepingCapacity: false)
        
        //parse pages
        if let paginationActions = doc.search(withXPathQuery: "//ol[@class='pagination actions']") {
            if(paginationActions.count > 0) {
                guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") else {
                    return
                }
                
                for i in 0..<paginationArr.count {
                    let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                    var pageItem: PageItem = PageItem()
                    
                    pageItem.name = page.content
                    
                    if let attrs = page.search(withXPathQuery: "//a") as? [TFHppleElement] {
                    
                        if (attrs.count > 0) {
                            if let attributesh = attrs[0].attributes as NSDictionary?  {
                                pageItem.url = attributesh["href"] as? String ?? ""
                            }
                        }
                    }
                    
                    if let current = page.search(withXPathQuery: "//span") as? [TFHppleElement] {
                    if (current.count > 0) {
                        pageItem.isCurrent = true
                    }
                    }
                    
                    pages.append(pageItem)
                }
            }
        }
    }
    
    func loadCurrentTheme() {
        var theme: Int
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (DefaultsManager.getInt(DefaultsManager.FONT_SIZE) != nil) {
            fontSize = DefaultsManager.getInt(DefaultsManager.FONT_SIZE)!
        }
        
        var worktext: String = htmlStr
        
        switch (theme) {
        case DefaultsManager.THEME_DAY :
            self.bgView.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
            self.commentTv.textColor = AppDelegate.dayTextColor
            
            self.webView.backgroundColor = UIColor.clear
            self.webView.isOpaque = false
            
            let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
            worktext = String(format:"<style>body { color: #021439; %@ }</style>%@", fontStr, htmlStr)
            
        case DefaultsManager.THEME_NIGHT :
            self.bgView.backgroundColor = AppDelegate.redDarkColor
            self.collectionView.backgroundColor = AppDelegate.redDarkColor
            self.commentTv.textColor = AppDelegate.nightTextColor
            
            self.webView.backgroundColor = UIColor(red: 50/255, green: 52/255, blue: 57/255, alpha: 1)
            self.webView.isOpaque = false
            
            let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
            worktext = String(format:"<style>body { color: #f5f5e9; %@ }</style>%@", fontStr, htmlStr)
            
        default:
            break
        }
        
        webView.reload()
        webView.loadHTMLString(worktext, baseURL: nil)
        
        collectionView.reloadData()
    }
    
    //MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //webView.stringByEvaluatingJavaScriptFromString("var links = document.getElementsByTagName('a');for (var i = 0; i < links.length; ++i) {links[i].style = 'text-decoration:none;color:#000;';} alert('a');")
        
        if (shouldScroll) {
        let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - webView.scrollView.bounds.size.height);
        webView.scrollView.setContentOffset(bottomOffset, animated:true)
        
        let height = Int(webView.stringByEvaluatingJavaScript(from: "document.body.offsetHeight;")!)

        let javascript = String(format:"window.scrollBy(0, %d);", height!)
        webView.stringByEvaluatingJavaScript(from: javascript)
        }
        
        webView.scrollView.flashScrollIndicators()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    //MARK: - move textview on keyboard
    
    @objc func keyboardWillShow(_ sender: Notification) {
        let info: NSDictionary = (sender as NSNotification).userInfo! as NSDictionary
        let kbSize: CGSize = (info.object(forKey: UIResponder.keyboardFrameBeginUserInfoKey)! as AnyObject).cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: kbSize.height, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your application might not need or want this behavior.
        var aRect: CGRect = self.view.frame
        aRect.size.height -= kbSize.height
        if (!aRect.contains(commentTv.frame.origin) ) {
            let scrollPoint: CGPoint = CGPoint(x: 0.0, y: commentTv.frame.origin.y - kbSize.height/8)
            scrollView.setContentOffset(scrollPoint, animated:true)
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    
    override func doneButtonAction() {
        commentTv.endEditing(true)
    }
    
    @IBAction func sendCommentTouched(_ sender: AnyObject) {
        if(commentTv.text != nil && commentTv.text.count > 0) {
            sendComment()
        } else {
            self.showError(title: Localization("Error"), message: Localization("PleaseWriteComment"))
        }
    }
    
    func sendComment() {
        showLoadingView(msg: Localization("SendingComment"))
        
        //https://archiveofourown.org/chapters/31047816?show_comments=true&view_full_work=false#comment_147517083
        var requestStr = ""
        var pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        let txt = commentTv.text ?? ""
        print("Commenting: \(txt)")
        
        if(pseud_id.isEmpty) {
            if let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String : String] {
                pseud_id = pseuds.first?.value ?? ""
                DefaultsManager.putString(pseud_id, key: DefaultsManager.PSEUD_ID)
            }
        }
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        
        params["comment"] = ["pseud_id": pseud_id,
                              "content": txt,
                              
        ] as AnyObject?
        
        if (chapterId.isEmpty == true) {
            params["controller_name"] = "works" as AnyObject?
            params["view_full_work"] = "true" as AnyObject?
            
            requestStr = "https://archiveofourown.org/works/" + workId + "/comments"
            
        } else {
            params["controller_name"] = "chapters" as AnyObject?
            params["view_full_work"] = "false" as AnyObject?
            
            requestStr = "https://archiveofourown.org/" + "chapters/\(chapterId)/comments"
        }
        params["commit"] = "Comment" as AnyObject?
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/)
                .response(completionHandler: { response in
                    print(response.request ?? "")
                    // print(response ?? "")
                    print(response.error ?? "")
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseAddCommentResponse(d)
                        self.hideLoadingView()
                        self.clearField()
                        self.getAllComments()
                        
                    } else {
                        self.hideLoadingView()
                        RMessage.showNotification(in: self, title: Localization("Error"), subtitle: Localization("CheckInternet"), type: RMessageType.error, customTypeName: "", callback: {
                            
                        })
                    }
                })
        }
    }
    
    func parseAddCommentResponse(_ data: Data) {
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("parseAddCommentResponse is: \(dta ?? "")")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as! [TFHppleElement]
        if(noticediv.count > 0) {
           // self.view.makeToast(message: noticediv[0].content, duration: 3.0, position: "center" as AnyObject, title: Localization("AddingComment"))
            
            let error = MessageView.viewFromNib(layout: .messageView)
            error.configureTheme(.info)
            error.configureContent(title: "Adding Comment", body: noticediv[0].content)
            
            SwiftMessages.show(config: SwiftMessages.defaultConfig, view: error)
            
            //changedSmth = true
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
              //  self.view.makeToast(message: (sorrydiv![0] as AnyObject).content, duration: 3.0, position: "center" as AnyObject, title: "Adding Comment")
                let error = MessageView.viewFromNib(layout: .tabView)
                error.configureTheme(.error)
                error.configureContent(title: "Adding Comment", body: (sorrydiv![0] as AnyObject).content)
                
                SwiftMessages.show(config: SwiftMessages.defaultConfig, view: error)
                
                return
            }
        }
    }
    
    func clearField() {
        shouldScroll = true
        commentTv.endEditing(true)
        commentTv.text = ""
        
    }
    
    //MARK: - collectionview
    
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: "\(Localization("LoadingPage")) \(page.name)")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let data: Data = response.data {
                    self.parseCookies(response)
                    self.parseComments(data)
                    self.hideLoadingView()
                    self.loadCurrentTheme()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: Localization("Error"), subtitle: Localization("CheckInternet"), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch ((indexPath as NSIndexPath).row) {
        case 0, self.collectionView(collectionView, numberOfItemsInSection: (indexPath as NSIndexPath).section) - 1:
            return CGSize(width: 100, height: 28)
        default:
            return CGSize(width: 50, height: 28)
        }
    }
}
