//
//  CommentViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/22/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
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
    
    // Constraints
    @IBOutlet weak var constraintContentHeight: NSLayoutConstraint!
    
    var lastOffset: CGPoint!
    var keyboardHeight: CGFloat!
    
    var pages : [PageItem] = [PageItem]()
    
    var shouldScroll = false
    
    var htmlStr = Localization("NoComments")
    
    var fontSize: Int = 200
    var fontFamily: String = "Verdana"
    
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
        webView.navigationDelegate = self
        
        self.title = Localization("Comments")
        makeRoundView(view: commentTv)
        
        commentTv.layer.borderColor = UIColor.purple.cgColor
        commentTv.layer.borderWidth = 1
        
        commentTv.delegate = self
        
       // commentsWebView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        addDoneButtonOnKeyboard(commentTv)
        
        // Add touch gesture for contentView
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(returnTextView(gesture:))))
        
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
        
        self.sendBtn.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
    }
    
    func controllerDidClosedWithLogin() {
        //TODO: 
    }
    
    @objc func returnTextView(gesture: UIGestureRecognizer) {
        guard commentTv != nil else {
            return
        }
        
        commentTv?.resignFirstResponder()
        commentTv = nil
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
        
        if let tokenIdEls = doc.search(withXPathQuery: "//div[@id='add_comment_placeholder']") as? [TFHppleElement],
            tokenIdEls.count > 0 {
            if let formEls = tokenIdEls[0].search(withXPathQuery: "//form[@class='new_comment']") as? [TFHppleElement],
                formEls.count > 0 {
                if let inputTokenEls = formEls[0].search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement],
                    inputTokenEls.count > 0 {
                    if let attrs : NSDictionary = inputTokenEls[0].attributes as NSDictionary?  {
                        self.commentsToken = (attrs["value"] as? String ?? "")
                    }
                }
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
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (DefaultsManager.getInt(DefaultsManager.FONT_SIZE) != nil) {
            fontSize = DefaultsManager.getInt(DefaultsManager.FONT_SIZE)!
        }
        
        let ffam = DefaultsManager.getString(DefaultsManager.FONT_FAMILY)
        if (ffam.isEmpty == false) {
            fontFamily = ffam
        }
        
        var worktext: String = htmlStr
        
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
            self.bgView.backgroundColor = AppDelegate.greyLightBg
            self.view.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
            self.commentTv.textColor = AppDelegate.dayTextColor
            
            webView.backgroundColor = AppDelegate.greyLightBg
            self.webView.isOpaque = false
            
            worktext = String(format:"<style>\(fontCss) body, table { color: #021439; %@; padding:5em 1.5em 4em 1.5em; text-align: left; line-height: 1.5em;  overflow-y: scroll; -webkit-overflow-scrolling: touch; } p {margin-bottom:1.0em}</style>%@", fontStr, htmlStr)
            
        case DefaultsManager.THEME_NIGHT :
            self.bgView.backgroundColor = AppDelegate.nightBgColor
            self.view.backgroundColor = AppDelegate.nightBgColor
            self.collectionView.backgroundColor = AppDelegate.nightBgColor
            self.commentTv.textColor = AppDelegate.nightTextColor
            
            self.webView.backgroundColor = AppDelegate.nightBgColor
            self.webView.isOpaque = false
            
            worktext = String(format:"<style>\(fontCss) body, table { color: #e1e1ce; %@; padding:5em 1.5em 4em 1.5em; text-align: left; line-height: 1.5em; overflow-y: scroll; -webkit-overflow-scrolling: touch; } p {margin-bottom:1.0em} </style>%@", fontStr, htmlStr)
            
        default:
            break
        }
        
        webView.reload()
        webView.loadHTMLString(worktext, baseURL: nil)
        
        collectionView.reloadData()
    }
    
    //MARK: - WKWebViewDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil {
                self.webView?.load(navigationAction.request)
            }
            if let url = navigationAction.request.url, !url.absoluteString.hasPrefix(AppDelegate.ao3SiteUrl) {
                UIApplication.shared.open(url, options: [:]) { (result) in
                    print("Comments link open \(url)")
                }
                print(url.absoluteString)
                decisionHandler(.cancel)
                return
            }
        default:
            break
        }
        
        if let url = navigationAction.request.url {
            print(url.absoluteString)
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (shouldScroll) {
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - webView.scrollView.bounds.size.height);
            webView.scrollView.setContentOffset(bottomOffset, animated:true)
            
            webView.evaluateJavaScript("document.body.offsetHeight;") { (result, error) in
                let height: Int = (result as? Int) ?? 0
                
                let javascript = String(format:"window.scrollBy(0, %d);", height)
                
                webView.evaluateJavaScript(javascript, completionHandler: { (result, error) in
                    webView.scrollView.flashScrollIndicators()
                })
            }
            
        }
        
    }
    
    //MARK: - move textview on keyboard
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if keyboardHeight != nil {
            return
        }
        if let keyboardSize = sender.keyboardSize {
            keyboardHeight = keyboardSize.height
            self.constraintContentHeight.constant += self.keyboardHeight
            
            // so increase contentView's height by keyboard height
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        self.constraintContentHeight.constant -= keyboardHeight
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        keyboardHeight = nil
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
        params["authenticity_token"] = self.commentsToken
        
        params["comment"] = ["pseud_id": pseud_id,
                              "comment_content": txt,
                              
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
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.httpBody /*ParameterEncoding.Custom(encodeParams)*/)
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
                        self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                    }
                })
        }
    }
    
    func parseAddCommentResponse(_ data: Data) {
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("parseAddCommentResponse is: \(dta ?? "")")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let successdiv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash comment_notice']") as? [TFHppleElement],
            successdiv.count > 0 {
            self.showSuccess(title: NSLocalizedString("AddingComment", comment: ""), message: successdiv[0].content)
            self.shouldScroll = true
            
        } else if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash']") as? [TFHppleElement],
            noticediv.count > 0 {
            
            self.showError(title: NSLocalizedString("AddingComment", comment: ""), message: noticediv[0].content)
            
            //changedSmth = true
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                
                self.showError(title: NSLocalizedString("AddingComment", comment: ""), message: (sorrydiv![0] as AnyObject).content)
                
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
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
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

extension CommentViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textField: UITextView) -> Bool {
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.commentTv.resignFirstResponder()
        return true
    }
}

extension Notification {
    var keyboardSize: CGSize? {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
    }
    var keyboardAnimationDuration: Double? {
        return userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
    }
}
