//
//  LoginViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/25/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices

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
        
      // makeRoundButton(button: loginButton)
        makeRoundView(view: bgView)
        
        
        loginTextField.delegate = self
        passTextField.delegate = self
        addDoneButtonOnKeyboardTf(loginTextField)
        addDoneButtonOnKeyboardTf(passTextField)
        
        loginTextField.text = DefaultsManager.getString(DefaultsManager.LOGIN)
        passTextField.text = DefaultsManager.getString(DefaultsManager.PSWD)
        
        //if (purchased) {
        
        if let login = loginTextField.text,
            let pass = passTextField.text {
            
            if (!login.isEmpty && !pass.isEmpty) {
                showLoadingView(msg: Localization("PleaseWait"))
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
        if let colorDark = UIColor(named: "onlyDarkBlue"),
        let colorLight = UIColor(named: "onlyLightBlue") {
            
            self.loginButton.applyGradient(colours: [colorDark, colorLight], cornerRadius: AppDelegate.mediumCornerRadius)
        }
        self.loginButton.setTitle(NSLocalizedString("Login", comment: ""), for: .normal)

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
        Alamofire.request("https://archiveofourown.org/users/login", method: .get)
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseParams(d)
                    self.tryLogin() //Uncomment!
                } else {
                    var err = Localization("CheckInternet")
                    if let errMsg = response.error {
                        err = "\(response.response?.statusCode ?? -1): \(errMsg.localizedDescription)"
                    }
                    self.showError(title: Localization("Error"), message: err)
                }
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
                self.showError(title:  Localization("CannotLogin"), message: Localization("FillUnamePass"))
                return
        }
        
        DefaultsManager.putString(login, key: DefaultsManager.LOGIN)
        DefaultsManager.putString(pass, key: DefaultsManager.PSWD)
        
        params["user"] = ["login": login,
            "password": pass,
            "remember_me": "1"]
        
        params["commit"] = "Log In"
        
     //   showLoadingView()
        
        Alamofire.request("https://archiveofourown.org/users/login", method: .post, parameters: params)
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
                    
                    if let d = response.data, response.response?.statusCode == 200 {
                        
                        self.parseCookies(response)
                        self.parseResponse(d)
                        self.hideLoadingView()
                        if (DefaultsManager.getString(DefaultsManager.PSEUD_ID).isEmpty ||
                            (DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String : String])?.keys.count ?? 0 == 0) {
                            self.sendPseudIdRequest()
                        }
                        
                    } else {
                        self.hideLoadingView()
                        var err = Localization("CheckInternet")
                        if let errMsg = response.error {
                            err = "\(response.response?.statusCode ?? -1): \(errMsg.localizedDescription)"
                        }
                        self.showError(title: Localization("Error"), message: err)
                        
                        self.logout()
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
        
        showLoadingView(msg: Localization("PleaseWait"))
        
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
                    var err = Localization("CheckInternet")
                    if let errMsg = response.error {
                        err = "\(response.response?.statusCode ?? -1): \(errMsg.localizedDescription)"
                    }
                    self.showError(title: Localization("Error"), message: err)
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
                token = loginEl.attributes["value"] as? String ?? ""
                (UIApplication.shared.delegate as! AppDelegate).token = token
            }

        //}
    }
    
    func parseResponse(_ data: Data) {
        let doc : TFHpple = TFHpple(htmlData: data)
        
        let dta = String(data: data, encoding: .utf8)
        print("the string is: \(dta)")
        
        let flashnoticediv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement]
        let flashalertdiv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash alert']") as? [TFHppleElement]
        
        if (flashnoticediv == nil || flashalertdiv == nil){
            showError()
            self.showError()
            return
        }
        var flashRes: [TFHppleElement] = [TFHppleElement]()
        if (flashnoticediv != nil) {
            flashRes = flashnoticediv!
        } else {
            flashRes = flashalertdiv!
        }
        
        if (flashRes.count > 0) {
             let noticeTxt = flashRes[0].content as String
             if (noticeTxt.contains("Successfully logged") || noticeTxt.contains("already signed") || noticeTxt.contains("just logged into")) {
        
                let login = DefaultsManager.getString(DefaultsManager.LOGIN)
                if (login.contains("@")) {
                
                if let menudiv: [TFHppleElement] = doc.search(withXPathQuery: "//ul[@class='user navigation actions']//li[@class='dropdown']//a") as? [TFHppleElement],
                    let firstToggle = menudiv.first {
                    let attributes : NSDictionary = firstToggle.attributes as NSDictionary
                    let loginAttr = (attributes["href"] as? String)?.replacingOccurrences(of: "/users/", with: "") ?? ""
                    
                    if (loginAttr.count > 0) {
                        DefaultsManager.putString(loginAttr, key: DefaultsManager.LOGIN)
                    }
                }
                }
                
                self.showSuccess(title: Localization("LogIn"), message: Localization("LoggedInScs"))
                
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
            self.logout()
        }
    }
    
    func showError() {
        self.showError(title: Localization("Error"), message: Localization("CannotLogin"))
        
        self.dismiss(animated: true, completion: {
            self.controllerDelegate.controllerDidClosed()
        })
    }
    
    func parsePseudId(_ data: Data) {
        
        #if DEBUG
        print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
            #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var workActions: [TFHppleElement] = doc.search(withXPathQuery: "//select[@id='work_author_attributes_ids']") as! [TFHppleElement]
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
                    
                    
                    let range = NSMakeRange(0, optionE.raw.count)
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
            
        } else {
            var pseuds: [String:String] = [:]
            pseuds["1"] = DefaultsManager.getString(DefaultsManager.LOGIN)
            DefaultsManager.putString("1", key: DefaultsManager.PSEUD_ID)
            DefaultsManager.putObject(pseuds as AnyObject, key: DefaultsManager.PSEUD_IDS)
            
            let delayTime = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
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
                self.showError(title: Localization("FieldsCannotBeEmpty"), message: Localization("FillUnamePass"))
                return
        }
        
        if (pass.isEmpty || login.isEmpty) {
            self.showError(title: Localization("FieldsCannotBeEmpty"), message: Localization("FillUnamePass"))
            return
        }
        
        self.view.endEditing(true)
        showLoadingView(msg: Localization("PleaseWait"))
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
        let refreshAlert = UIAlertController(title: Localization("DoINeedToTellMyPass"), message: Localization("TellPassExplain"), preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: Localization("OK"), style: .default, handler: { (action: UIAlertAction!) in
            refreshAlert.dismiss(animated: true, completion: nil)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func inviteTouched(_ sender: AnyObject) {
        if let requestUrl = URL(string: "https://archiveofourown.org/invite_requests") {
            let svc = SFSafariViewController(url: requestUrl)
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    @IBAction func forgotPassTouched(_ sender: AnyObject) {
        if let requestUrl = URL(string: "https://archiveofourown.org/passwords/new") {
            let svc = SFSafariViewController(url: requestUrl)
            self.present(svc, animated: true, completion: nil)
        }
        
    }
}

