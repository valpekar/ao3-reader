//
//  MeViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/1/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import Foundation
import StoreKit
import CoreData
import Crashlytics
import SwiftMessages

class MeViewController: LoadingViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var notifSwitch: UISwitch!
    @IBOutlet weak var notifLabel: UILabel!
    @IBOutlet weak var pseudsTableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var supportLabel: UILabel!
    @IBOutlet weak var supportButton: UIButton!
    
    
    var pseuds: [String:String] = [:]
    var currentPseud = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.pseudsTableView.tableFooterView = UIView()
        
        self.pseudsTableView.rowHeight = UITableView.automaticDimension
        self.pseudsTableView.estimatedRowHeight = 44
        
        applyTheme()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UserDefaults.standard.synchronize()
        
        refreshUI()
    }
    
    
    override func applyTheme() {
        super.applyTheme()
        
        self.pseudsTableView.backgroundColor = UIColor(named: "tableViewBg")
        self.notifLabel.textColor = UIColor(named: "textMain")
     //   self.footerView.backgroundColor = UIColor(named: "onlyDarkBlue")
        self.supportLabel.textColor = UIColor(named: "textMain")
        self.supportButton.setTitleColor(UIColor(named: "greenTitle"), for: .normal)
        
    }
    
    //MARK: - log in / out
   
    override func logout() {
        super.logout()
        
        pseuds = [:]
        
        pseudsTableView.reloadData()
    }
    
    func login() {
        
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
        (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
        
        self.present(nav, animated: true, completion: nil)
        
    }
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        let pass = DefaultsManager.getString(DefaultsManager.PSWD)
        
        if (!login.isEmpty && !pass.isEmpty) {
            self.logout()
            refreshUI()
        } else {
            self.login()
        }
    }
    
    override func controllerDidClosed() {
        
    }
    
    @objc func controllerDidClosedWithLogin() {
        refreshUI()
    }
    
    func refreshUI() {
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
       // let pass = DefaultsManager.getString(DefaultsManager.PSWD)
        
        if (login.isEmpty == false) {
            usernameLabel.text = login
            
            //self.title = login
            
            pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String:String] ?? [:]
            currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
            
            if (currentPseud.isEmpty) {
                let keys = Array(pseuds.keys)
                if (keys.count > 0) {
                    currentPseud = keys[0]
                } 
            }
            
            pseudsTableView.reloadData()
            loginButton.setTitle(Localization("LogOut"), for: UIControl.State())
            
            notifSwitch.isEnabled = true
            
            if let notify = DefaultsManager.getBool(DefaultsManager.NOTIFY) {
                if (notify == true) {
                    notifSwitch.setOn(true, animated: true)
                } else {
                    notifSwitch.setOn(false, animated: true)
                }
            }
            
            self.pseudsTableView.reloadData()
            
        } else {
            setNotAuthorizedUI()
        }
        
    }
    
    func setNotAuthorizedUI() {
        usernameLabel.text = Localization("NotAuthorized")
        loginButton.setTitle(Localization("LogIn"), for: UIControl.State())
        
        //self.title = Localization("NotAuthorized")
        
        notifSwitch.isEnabled = false
    }
    
    @IBAction func notifSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.NOTIFY)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NOTIFY)
            UIApplication.shared.cancelAllLocalNotifications()
        }
    }
    
    @IBAction func adultSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.ADULT)
        }
    }
    
    @IBAction func safeSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.SAFE)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.SAFE)
        }
    }
    
    
    
    func showSureClearDialog() {
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: "You want to clear all notifications from this app?", preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            DefaultsManager.putStringArray([], key: DefaultsManager.NOTIF_IDS_ARR)
            self.updateAppBadge()
        }))
        
        deleteAlert.view.tintColor = UIColor(named: "global_tint")
        present(deleteAlert, animated: true, completion: nil)
    }
    
    //Mark: - TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyProfileCell = tableView.dequeueReusableCell(withIdentifier: "pseudCell") as! MyProfileCell
        
        switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.titleLabel.text = Localization("ClearAllNotif")
                cell.accessoryType = .none
            } else {
                cell.titleLabel.text = Localization("ProtectBio")
                cell.accessoryType = .disclosureIndicator
            }
        case 1:
            let curKey = Array(pseuds.keys)[indexPath.row]
            cell.titleLabel.text = pseuds[curKey]
            
            if (curKey == currentPseud) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case 2:
            switch (indexPath.row) {
            case 0:
                cell.titleLabel.text = Localization("MyWorks")
            case 1:
                cell.titleLabel.text = Localization("Inbox")
            case 2:
                cell.titleLabel.text = Localization("MyHighlights")
            case 3:
                cell.titleLabel.text = Localization("History")
            default: break
            }
            cell.accessoryType = .none
        
            
        case 3:
            var langId = ""
            langId = Localisator.sharedInstance.currentLanguage
            
            if (indexPath.row == 0) {
                cell.titleLabel.text = Localization("SystemLanguage")
                
                if (langId == "DeviceLanguage") {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                
            } else if (indexPath.row == 1) {
                cell.titleLabel.text = Localization("English")
                
                if (langId == "DeviceLanguage") {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }
            
        case 4:
            cell.accessoryType = .none
            if (indexPath.row == 0) {
                cell.titleLabel.text = Localization("PPolicy")
            }
            
        default: break
        }
        
        cell.titleLabel.textColor = UIColor(named: "cellTitle")
        cell.backgroundColor = UIColor(named: "greyBg")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 2
        case 1:
            return pseuds.count
        case 2:
            return 4
        case 3:
            return 2
        case 4:
            return 2
        case 5:
            return 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                self.showSureClearDialog()
            } else {
                self.performSegue(withIdentifier: "securitySegue", sender: self)
            }
        case 1:
            let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
            currentPseud = curKey
            DefaultsManager.putString(curKey, key: DefaultsManager.PSEUD_ID)
            
            tableView.reloadData()
        case 2:
            switch indexPath.row  {
            case 0:
                self.performSegue(withIdentifier: "listSegue", sender: self)
            case 1:
                self.performSegue(withIdentifier: "inboxSegue", sender: self)
            case 2:
                self.performSegue(withIdentifier: "showHighlightsSegue", sender: self)
            case 3:
                self.performSegue(withIdentifier: "showHistory", sender: self)
            default: break 
            }
        
        case 3:
            var langID = ""
            if (indexPath.row == 0) {
                langID = "DeviceLanguage"
            } else if (indexPath.row == 1) {
                langID = "English_en"
            }
            
            Answers.logCustomEvent(withName: "ME_Lang", customAttributes: ["lang" : langID])
            
            if (SetLanguage(langID) == true) {
                showSuccess(title: Localization("Language"), message: Localization("LangChanged"))
            } else {
                showError(title: Localization("Language"), message: Localization("ErrLangChanged"))
            }
            tableView.reloadRows(at: [IndexPath(row: 0, section: 4), IndexPath(row: 1, section: 4)], with: UITableView.RowAnimation.automatic)
        case 4:
            if (indexPath.row == 0) {
                if let url = URL(string: "https://riyapekar.blogspot.com/2021/12/app-privacy-policy.html") {
                    UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { (res) in
                        print("open url blogspot.com")
                    })
                }
            }
        default: break
            
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return Localization("SecuritySettings")
        case 1:
            return Localization("MyPseud")
        case 2:
            return Localization("MyAO3")
        case 3:
            return Localization("Language")
        case 4:
            return Localization("About")
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "listSegue") {
            if let cController: WorkListController = segue.destination as? WorkListController {
                let login = DefaultsManager.getString(DefaultsManager.LOGIN)
                cController.tagUrl = "/users/\(login)/works"
                cController.liWorksElement = "own work"
                cController.worksElement = "work"
            }
        }
    }
    
    
    
    @IBAction func smallTipTouched(_ sender: AnyObject) {
        let urlStr = "https://linktr.ee/riyapekar"
        
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { (res) in
                print("open url simpleappalliance.blogspot.com")
            })
        }
    }

    
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
