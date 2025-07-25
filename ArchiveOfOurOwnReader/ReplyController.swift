//
//  ReplyController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/11/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import FirebaseCrashlytics

class ReplyController: LoadingViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    
    var replyUrl = ""
    var commentId = ""
    
    var sendReplyUrl = ""
    
    var commentLimit = 4300
    
    var replyToken = ""
    
    var replyDelegate: ReplyDelegate! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        bgView.layer.cornerRadius = 10
        bgView.layer.shadowColor = UIColor.black.cgColor
        bgView.layer.shadowOffset = CGSize(width: 0, height: 6)
        bgView.layer.shadowOpacity = 0.85
        bgView.layer.shadowRadius = 5
        
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = AppDelegate.greyLightColor.cgColor
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            bgView.backgroundColor = AppDelegate.redDarkColor
            label.textColor = AppDelegate.textLightColor
            leftLabel.textColor = AppDelegate.textLightColor
        } else {
            bgView.backgroundColor = UIColor.white
            label.textColor = UIColor(named: "global_tint")
            leftLabel.textColor = UIColor.black
        }
        
//        let gestureRec = UITapGestureRecognizer()
//        gestureRec.numberOfTapsRequired = 1
//        gestureRec.addTarget(self, action: #selector(ReplyController.viewTapped))
//        self.view.addGestureRecognizer(gestureRec)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            
            requestCommentBox()
        } else if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            openLoginController(force: false)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelTouched(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func replyTouched(_ sender: AnyObject) {
        if let txt: String = textView.text, txt.isEmpty == false, (commentLimit - textView.text.count) >= 0 {
                        
            self.sendReply(text: txt)
        } else {
            self.showError(title: Localization("Error"), message: Localization("CannotSendComment"))
        }
    }
    
    func requestCommentBox() {
        showLoadingView(msg: Localization("GettingInbox"))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        var urlStr: String = replyUrl
        if (urlStr.contains("http") == false) {
            urlStr = "\(AppDelegate.ao3SiteUrl)\(urlStr)"
        }
        
        Alamofire.request(urlStr)
            .response(completionHandler: { response in
                
                #if DEBUG
                    //print(request)
                    print(response.error ?? "")
                #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseCommentBox(d)
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                    
                }
            })
    }
    
    func parseCommentBox(_ data: Data) {
        
        #if DEBUG
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(string1 ?? "")
        #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticeEls: [TFHppleElement] = doc.search(withXPathQuery: "//p[@class='notice']") as? [TFHppleElement] {
            if (noticeEls.count > 0) {
                let titleStr = noticeEls[0].content.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                if (titleStr.isEmpty == false) {
                    label.text = titleStr
                }
            }
        }
        
        if let actionsEls: [TFHppleElement] = doc.search(withXPathQuery: "//form[@class='new_comment']") as? [TFHppleElement] {
            if (actionsEls.count > 0) {
                if let attributes : NSDictionary = actionsEls[0].attributes as NSDictionary? {
                    let actionStr = (attributes["action"] as? String ?? "")
                    if (actionStr.isEmpty == false) {
                        sendReplyUrl = actionStr
                    }
                }
            }
        }
        
        if let tokenIdEls = doc.search(withXPathQuery: "//div[@class='post comment']") as? [TFHppleElement],
            tokenIdEls.count > 0 {
            if let formEls = tokenIdEls[0].search(withXPathQuery: "//form[@class='new_comment']") as? [TFHppleElement],
                formEls.count > 0 {
                if let inputTokenEls = formEls[0].search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement],
                    inputTokenEls.count > 0 {
                    if let attrs : NSDictionary = inputTokenEls[0].attributes as NSDictionary?  {
                        self.replyToken = (attrs["value"] as? String ?? "")
                    }
                }
            }
            
        }
        
        self.hideLoadingView()
    }
    
    func sendReply(text: String) {
        showLoadingView(msg: Localization("SendingReply"))
        
        var urlStr: String = sendReplyUrl
        if (urlStr.contains("http") == false) {
            urlStr = "\(AppDelegate.ao3SiteUrl)\(urlStr)"
        }
        
        let pseud_id = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject
        params["authenticity_token"] = self.replyToken
        params["comment"] = ["pseud_id": pseud_id,
                             "comment_content": text
        ]
        params["controller_name"] = "inbox"
        params["commit"] = "Comment"
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.request(urlStr, method: .post, parameters: params, encoding:URLEncoding.httpBody)
                .response(completionHandler: { response in
                    #if DEBUG
                        print(response.request ?? "")
                        // print(response.response ?? "")
                        print(response.error ?? "")
                    #endif
                    
                    if let d = response.data {
                        self.parseCookies(response)
                        self.parseSendReply(d)
                        self.hideLoadingView()
                        
                    } else {
                        self.hideLoadingView()
                        
                        self.showError(title: Localization("Error"), message: Localization("CouldNotReply"))

                    }
                })
            
        } else {
            
            self.hideLoadingView()
           
            self.showError(title: Localization("Error"), message: Localization("CouldNotReply"))

        }
    }
    
    func parseSendReply(_ data: Data) {
        #if DEBUG
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(string1 ?? "")
        #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticeEls = doc.search(withXPathQuery: "//div[@class='flash comment_notice']") as? [TFHppleElement], noticeEls.count > 0,
            let noticeStr = noticeEls[0].content, (noticeStr.contains("created") || noticeStr.contains("received")) {
            
            self.showSuccess(title: Localization("Success"), message: Localization("CommentCreated"))

            
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.dismiss(animated: true, completion: {
                    self.replyDelegate.replySent()
                })
            }
        } else {
            self.showError(title: Localization("Error"), message: Localization("CouldNotReply"))
            
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        }
    }
    
}

extension ReplyController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        leftLabel.text = "\(commentLimit - textView.text.count) characters left"
    }
}

@objc protocol ReplyDelegate {
    func replySent()
}

