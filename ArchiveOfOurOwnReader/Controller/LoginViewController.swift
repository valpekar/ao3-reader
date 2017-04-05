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

//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l < r
//  case (nil, _?):
//    return true
//  default:
//    return false
//  }
//}
//
//fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l > r
//  default:
//    return rhs < lhs
//  }
//}


class LoginViewController : LoadingViewController, UITextFieldDelegate {
    
    var token = ""
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var controllerDelegate: ModalControllerDelegate!
    //var purchased = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.cornerRadius = 10.0
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
            showLoadingView()
            getLoginParams()
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
        
        underlineTextField(loginTextField)
        underlineTextField(passTextField)
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
        Alamofire.request("http://archiveofourown.org/", method: .get)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                self.parseParams(response.data!)
                self.tryLogin() //Uncomment!
               // self.hideLoadingView()
            })
    }
    
    func tryLogin() {
        guard let login = loginTextField.text,
            let pass = passTextField.text else {
                return
        }
        
        if (!login.isEmpty && !pass.isEmpty) {
            sendLoginRequest()
        }

    }
    
    func sendLoginRequest() {
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = token as AnyObject?
        
        guard let login = loginTextField.text,
            let pass = passTextField.text else {
                TSMessage.showNotification(in: self, title: "Cannot login", subtitle: "Please fill user name and password", type: .error)
                return
        }
        
        DefaultsManager.putString(login, key: DefaultsManager.LOGIN)
        DefaultsManager.putString(pass, key: DefaultsManager.PSWD)
        
        params["user_session"] = ["login": login,
            "password": pass]
        
     //   showLoadingView()
        
        Alamofire.request("http://archiveofourown.org/user_sessions/", method: .post, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.response ?? "")
                print(response.error ?? "")
                
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
                        TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
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
        
        showLoadingView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        Alamofire.request("http://archiveofourown.org/works/new", method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    self.parsePseudId(d)
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
            })
    }
    
    func parseParams(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        let logindiv : [TFHppleElement]? = doc.search(withXPathQuery: "//div[@id='login']") as? [TFHppleElement]
        if (logindiv?.count ?? 0 > 0) {
            let authtoken: [TFHppleElement]? = (logindiv![0] as TFHppleElement).search(withXPathQuery: "//input[@name='authenticity_token']") as? [TFHppleElement]
            if (authtoken?.count ?? 0 > 0) {
                let loginEl: TFHppleElement = authtoken![0]
                token = loginEl.attributes["value"] as! String
                (UIApplication.shared.delegate as! AppDelegate).token = token
            }

        }
    }
    
    func parseResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        guard let flashnoticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] else {
            showError()
            return
        }
        if (flashnoticediv.count > 0) {
            let noticeTxt = flashnoticediv[0].content as String
            if (noticeTxt == "Successfully logged in.") {
                TSMessage.showNotification(in: self, title: "Log In", subtitle: "Successfully logged in!", type: .success)
                let delayTime = DispatchTime.now() + Double(Int64(1.500 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                
                DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
                
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
        TSMessage.showNotification(in: self, title: "Error", subtitle: "Cannot log in", type: .error)
        
        self.dismiss(animated: true, completion: {
            self.controllerDelegate.controllerDidClosed()
        })
    }
    
    func parsePseudId(_ data: Data) {
        
        print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var workActions: [TFHppleElement] = doc.search(withXPathQuery: "//select[@id='work_author_attributes_ids_']") as! [TFHppleElement]
        if (workActions.count > 0) {
            print(workActions[0].raw)
            
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
                    DefaultsManager.putObject(pseud_id as AnyObject, key: DefaultsManager.PSEUD_ID)
                }
                
                DefaultsManager.putObject(pseuds as AnyObject, key: DefaultsManager.PSEUD_IDS)
            }
            
        }
    }
    
    @IBAction func loginTouched(_ sender: UIButton) {
        sendLoginRequest()
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
        let refreshAlert = UIAlertController(title: "Do I need to tell you my password?", message: "AO3 web site doesn't use OAuth technology which allows you to authorize without requiring you to share your password. So to get the data from your AO3 account this app uses your credentials to log in into the AO3 web site on your behalf. If you're not comfortable sharing your password, we would completely understand. However, your password is NEVER sent to nor stored on my server. Your password is saved securely on your iPhone or iPad in the iOS Keychain.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            refreshAlert.dismiss(animated: true, completion: nil)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
}

