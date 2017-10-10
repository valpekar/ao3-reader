//
//  LoginViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/25/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import TSMessages

class LoginViewController : LoadingViewController, UITextFieldDelegate {
    
    var token = ""
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    var controllerDelegate: ModalControllerDelegate!
    //var purchased = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       makeRoundButton(button: loginButton)
        makeRoundView(view: bgView)
        loginTextField.delegate = self
        passTextField.delegate = self
        addDoneButtonOnKeyboardTf(loginTextField)
        addDoneButtonOnKeyboardTf(passTextField)
        
        loginTextField.text = DefaultsManager.getString(DefaultsManager.LOGIN)
        passTextField.text = DefaultsManager.getString(DefaultsManager.PSWD)
        
//        UserDefaults.standard.synchronize()
//        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
//            purchased = pp
//        }
        
        //if (purchased) {
        
        if let login = loginTextField.text,
            let pass = passTextField.text {
            
            if (!login.isEmpty && !pass.isEmpty) {
                showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
                getLoginParams()
            }
        }
        
       /* } else {
            self.view.makeToast(message: "Login is a Premium feature!", duration: 1.0, position: "center" as AnyObject, title: "Cannot login")
            
            let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.dismiss(animated: true, completion: {
                    self.controllerDelegate.controllerDidClosedWithLogin!()
                })
            }
        }*/
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //underlineTextField(loginTextField)
        //underlineTextField(passTextField)
    }
    
    func underlineTextField(_ textField: UITextField) {
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor(red: 179/255, green: 174/255, blue: 174/255, alpha: 1).cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    }
    
    func getLoginParams() {
        Alamofire.request("https://archiveofourown.org/user_sessions/new", method: .get)
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                self.parseParams(response.data!)
                self.tryLogin() //Uncomment!
               // self.hideLoadingView()
            })
    }
    
    func tryLogin() {
        guard let login = loginTextField.text,
            let pass = passTextField.text else {
                hideLoadingView()
                return
        }
        
        if (!login.isEmpty && !pass.isEmpty) {
            sendLoginRequest()
        } else {
            hideLoadingView()
        }

    }
    
    func sendLoginRequest() {
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = token as AnyObject?
        
        guard let login = loginTextField.text,
            let pass = passTextField.text else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("CannotLogin", comment: ""), subtitle: NSLocalizedString("FillUnamePass", comment: ""), type: .error)
                return
        }
        
        DefaultsManager.putString(login, key: DefaultsManager.LOGIN)
        DefaultsManager.putString(pass, key: DefaultsManager.PSWD)
        
        params["user_session"] = ["login": login,
            "password": pass,
            "remember_me": "1"]
        
     //   showLoadingView()
        
        Alamofire.request("https://archiveofourown.org/user_sessions/", method: .post, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.response ?? "")
                print(response.error ?? "")
                    #endif
                
                if (response.error != nil) {
                    self.hideLoadingView()
                    self.dismiss(animated: true, completion: {})
                } else {
                    
                    if let d = response.data {
                        
                        self.parseCookies(response)
                        self.parseResponse(d)
                        self.hideLoadingView()
                        if (DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) == nil ||
                            (DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String : String]).keys.count == 0) {
                            self.sendPseudIdRequest()
                        }
                        
                    } else {
                        self.hideLoadingView()
                        TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                    }
                }
            })
    }
    
    func sendPseudIdRequest() {
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        if (login.isEmpty) {
            return
        }
        
        showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        Alamofire.request("https://archiveofourown.org/works/new", method: .get, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    self.parsePseudId(d)
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
    
    func parseParams(_ data: Data) {
        #if DEBUG
        let datastring = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print(datastring ?? "")
            #endif

        let doc : TFHpple = TFHpple(htmlData: data)
       // let logindiv : [TFHppleElement]? = doc.search(withXPathQuery: "//div[@id='login']") as? [TFHppleElement]
       // if (logindiv?.count ?? 0 > 0) {
            let authtoken: [TFHppleElement]? = doc.search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement]
            if (authtoken?.count ?? 0 > 0) {
                let loginEl: TFHppleElement = authtoken![0]
                token = loginEl.attributes["value"] as! String
                (UIApplication.shared.delegate as! AppDelegate).token = token
            }

        //}
    }
    
    func parseResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        guard let flashnoticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] else {
            showError()
            return
        }
        if (flashnoticediv.count > 0) {
            let noticeTxt = flashnoticediv[0].content as String
            if (noticeTxt.contains("Successfully logged")) {
                TSMessage.showNotification(in: self, title: NSLocalizedString("LogIn", comment: ""), subtitle: NSLocalizedString("LoggedInScs", comment: ""), type: .success)
                let delayTime = DispatchTime.now() + Double(Int64(1.500 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                
                DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
                DefaultsManager.putString(token, key: DefaultsManager.TOKEN)
                DefaultsManager.putDate(Date(), key: DefaultsManager.COOKIES_DATE)
                
                DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.dismiss(animated: true, completion: {
                    self.controllerDelegate.controllerDidClosedWithLogin!()
                })
                }
            }
        } else {
           showError()
        }
    }
    
    func showError() {
        TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotLogin", comment: ""), type: .error)
        
        self.dismiss(animated: true, completion: {
            self.controllerDelegate.controllerDidClosed()
        })
    }
    
    func parsePseudId(_ data: Data) {
        
        #if DEBUG
        print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
            #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var workActions: [TFHppleElement] = doc.search(withXPathQuery: "//select[@id='work_author_attributes_ids_']") as! [TFHppleElement]
        if (workActions.count > 0) {
            #if DEBUG
            print(workActions[0].raw)
                #endif
            
            let optionEl: [TFHppleElement] = workActions[0].search(withXPathQuery: "//option") as! [TFHppleElement]
            if (optionEl.count > 0) {
 
                var pseuds: [String:String] = [:]
                for optionE in optionEl {
                    
                    let attrs = optionE.attributes
                    let pseud_id = attrs?["value"] as! String
                    
                    let regex:NSRegularExpression = try! NSRegularExpression(pattern: "<.*?>", options: NSRegularExpression.Options.caseInsensitive)
                    
                    
                    let range = NSMakeRange(0, optionE.raw.characters.count)
                    let htmlLessString :String = regex.stringByReplacingMatches(in: optionE.raw,
                                                                                        options: [],
                                                                                        range:range ,
                                                                                        withTemplate: "")
                    
                    pseuds[pseud_id] = htmlLessString
                    DefaultsManager.putString(pseud_id, key: DefaultsManager.PSEUD_ID)
                }
                
                DefaultsManager.putObject(pseuds as AnyObject, key: DefaultsManager.PSEUD_IDS)
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(1.500 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.dismiss(animated: true, completion: {
                    self.controllerDelegate.controllerDidClosedWithLogin!()
                })
            }
            
        }
    }
    
    @IBAction func loginTouched(_ sender: UIButton) {
        
        guard let login = loginTextField.text,
            let pass = passTextField.text else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("FieldsCannotBeEmpty", comment: ""), subtitle: NSLocalizedString("FillUnamePass", comment: ""), type: .error)
                return
        }
        
        if (pass.isEmpty || login.isEmpty) {
            TSMessage.showNotification(in: self, title: NSLocalizedString("FieldsCannotBeEmpty", comment: ""), subtitle: NSLocalizedString("FillUnamePass", comment: ""), type: .error)
            return
        }
        
        showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
        getLoginParams()
        
        //sendLoginRequest()
    }
    
    @IBAction func cancelTouched(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - textfield
//    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
//        if (textField.text == "\n") {
//            textField.resignFirstResponder()
//            return true
//        }
//        return false
//    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool  {
        textField.resignFirstResponder()
        return true
    }
    
    
    override func doneButtonAction() {
        loginTextField.resignFirstResponder()
        passTextField.resignFirstResponder()
    }
    
    @IBAction func infoTouched(_ sender:AnyObject) {
        let refreshAlert = UIAlertController(title: NSLocalizedString("DoINeedToTellMyPass", comment: ""), message: NSLocalizedString("TellPassExplain", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
            refreshAlert.dismiss(animated: true, completion: nil)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func inviteTouched(_ sender: AnyObject) {
        if let requestUrl = URL(string: "https://archiveofourown.org/invite_requests") {
            UIApplication.shared.openURL(requestUrl)
        }
    }
    
    @IBAction func forgotPassTouched(_ sender: AnyObject) {
        if let requestUrl = URL(string: "https://archiveofourown.org/passwords/new") {
            UIApplication.shared.openURL(requestUrl)
        }
        
    }
}

