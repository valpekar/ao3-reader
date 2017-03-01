//
//  CommentViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/22/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import TSMessages

class CommentViewController: LoadingViewController, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate {
    
    @IBOutlet weak var commentTv: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var commentsWebView: UIWebView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var shouldScroll = false
    
    var htmlStr = ""
    var fontSize: Int = 100
    var workId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Comments"
        sendBtn.layer.cornerRadius = 5.0
        
        commentTv.layer.cornerRadius = 5.0
        commentTv.layer.borderColor = UIColor.purple.cgColor
        commentTv.layer.borderWidth = 1
        
        commentsWebView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(CommentViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
        addDoneButtonOnKeyboard(commentTv)
        
        getAllComments()
        //loadCurrentTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
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
        //http://archiveofourown.org/works/6107953?show_comments=true&view_full_work=true#comments
        let requestStr = "http://archiveofourown.org/works/" + workId + "?show_comments=true&view_full_work=true#comments"
        
        showLoadingView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
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
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
        
        
    }
    
    func parseComments(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
        
        if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
            /*workItem.setValue("Sorry!", forKey: "author")
            workItem.setValue("This work is only available to registered users of the Archive", forKey: "workTitle")
            workItem.setValue("", forKey: "complete")*/
            //   return NEXT_CHAPTER_NOT_EXIST;
            return
        }
        
        htmlStr.append("<html><body><ol>")
        
        let commentsSection: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='comments_placeholder']") as! [TFHppleElement]
        for liEl in commentsSection {
            
            do {
            let regex = try NSRegularExpression(pattern: "href", options: .dotMatchesLineSeparators)
                
                let raw:String = liEl.raw
            
            htmlStr.append(regex.stringByReplacingMatches(in: raw, options: .reportCompletion, range: NSRange(location: 0, length: raw.characters.count), withTemplate: ""))
            } catch {
                print("error")
            }
            
            //htmlStr.appendContentsOf(liEl.raw.stringByReplacingOccurrencesOfString("<ul class='actions' role='menu' id='navigation_for_comment_[1-9]+'>(.|\n)*?</ul>", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil))
        }
        
        htmlStr.append("</ol></body></html>")
        htmlStr = htmlStr.replacingOccurrences(of: "\n", with: "<p></p>")
        //(.|\n)*?<\\/ul>
    }
    
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
        
        var worktext: String = htmlStr
        
        switch (theme) {
        case DefaultsManager.THEME_DAY :
            commentsWebView.backgroundColor = UIColor.clear
            commentsWebView.isOpaque = false
            
            let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
            worktext = String(format:"<style>body { color: #021439; %@ }</style>%@", fontStr, htmlStr)
            
        case DefaultsManager.THEME_NIGHT :
            self.commentsWebView.backgroundColor = UIColor(red: 50/255, green: 52/255, blue: 57/255, alpha: 1)
            self.commentsWebView.isOpaque = false
            
            let fontStr = "font-size: " + String(format:"%d", fontSize) + "%;"
            worktext = String(format:"<style>body { color: #f5f5e9; %@ }</style>%@", fontStr, htmlStr)
            
        default:
            break
        }
        
        commentsWebView.reload()
        commentsWebView.loadHTMLString(worktext, baseURL: nil)
    }
    
    //MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //webView.stringByEvaluatingJavaScriptFromString("var links = document.getElementsByTagName('a');for (var i = 0; i < links.length; ++i) {links[i].style = 'text-decoration:none;color:#000;';} alert('a');")
        
        if (shouldScroll) {
        let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - commentsWebView.scrollView.bounds.size.height);
        commentsWebView.scrollView.setContentOffset(bottomOffset, animated:true)
        
        let height = Int(webView.stringByEvaluatingJavaScript(from: "document.body.offsetHeight;")!)

        let javascript = String(format:"window.scrollBy(0, %d);", height!)
        webView.stringByEvaluatingJavaScript(from: javascript)
        }
        
        webView.scrollView.flashScrollIndicators()
    }
    
    //MARK: - move textview on keyboard
    
    func keyboardWillShow(_ sender: Notification) {
        let info: NSDictionary = (sender as NSNotification).userInfo! as NSDictionary
        let kbSize: CGSize = (info.object(forKey: UIKeyboardFrameBeginUserInfoKey)! as AnyObject).cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
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
    
    func keyboardWillHide(_ sender: Notification) {
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    
    override func doneButtonAction() {
        commentTv.endEditing(true)
    }
    
    @IBAction func sendCommentTouched(_ sender: AnyObject) {
        if(commentTv.text != nil && commentTv.text.characters.count > 0) {
            sendComment()
        } else {
            self.view.makeToast(message: "Please write your comment", duration: 1.5, position: "center" as AnyObject)
        }
    }
    
    func sendComment() {
        showLoadingView()
        
        let requestStr = "http://archiveofourown.org/works/" + workId + "/comments"
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        
        params["comment"] = ["pseud_id": pseud_id,
                              "content": commentTv.text,
                              
        ] as AnyObject?
        
        params["controller_name"] = "works" as AnyObject?
        params["view_full_work"] = "true" as AnyObject?
        params["commit"] = "Comment" as AnyObject?
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
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
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                    }
                })
        }
    }
    
    func parseAddCommentResponse(_ data: Data) {
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("the string is: \(dta)")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as! [TFHppleElement]
        if(noticediv.count > 0) {
            self.view.makeToast(message: noticediv[0].content, duration: 3.0, position: "center" as AnyObject, title: "Adding Comment")
            
            //changedSmth = true
        } else {
            var sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']")
            
            if(sorrydiv != nil && (sorrydiv?.count)!>0 && (sorrydiv?[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.view.makeToast(message: (sorrydiv![0] as AnyObject).content, duration: 3.0, position: "center" as AnyObject, title: "Adding Comment")
                return
            }
        }
    }
    
    func clearField() {
        shouldScroll = true
        commentTv.endEditing(true)
        commentTv.text = ""
        
    }
}
