//
//  MeViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/1/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import Foundation

class MeViewController: CenterViewController, ModalControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var notifSwitch: UISwitch!
    @IBOutlet weak var adultSwitch: UISwitch!
    @IBOutlet weak var adultLabel: UILabel!
    @IBOutlet weak var pseudsTableView: UITableView!
    
    var pseuds: [String:String] = [:]
    var currentPseud = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        pseudsTableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshUI()
    }
    
    //MARK: - log in / out
    func logout() {
        let s: [String:String] = [:]
        
        DefaultsManager.putString("", key: DefaultsManager.LOGIN)
        DefaultsManager.putString("", key: DefaultsManager.PSWD)
        DefaultsManager.putString("", key: DefaultsManager.PSEUD_ID)
        DefaultsManager.putObject(s as AnyObject, key: DefaultsManager.PSEUD_IDS)
        
        pseuds = s
        
        (UIApplication.shared.delegate as! AppDelegate).cookies = [HTTPCookie]()
        
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
            logout()
            refreshUI()
        } else {
            self.login()
        }
    }
    
    func controllerDidClosed() {
        
    }
    
    func controllerDidClosedWithLogin() {
        refreshUI()
    }
    
    func refreshUI() {
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
       // let pass = DefaultsManager.getString(DefaultsManager.PSWD)
        
        if (!login.isEmpty) {
            usernameLabel.text = login
            
            pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
            currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
            
            if (currentPseud.isEmpty) {
                let keys = Array(pseuds.keys)
                if (keys.count > 0) {
                    currentPseud = keys[0]
                } 
            }
            
            pseudsTableView.reloadData()
            loginButton.setTitle("Log Out", for: UIControlState())
            
            adultSwitch.isEnabled = true
            notifSwitch.isEnabled = true
            
            if let isAdult = DefaultsManager.getObject(DefaultsManager.ADULT) as? Bool {
                if (isAdult == true) {
                    adultSwitch.setOn(true, animated: true)
                } else {
                    adultSwitch.setOn(false, animated: true)
                }
            }
            
            if let notify = DefaultsManager.getObject(DefaultsManager.NOTIFY) as? Bool {
                if (notify == true) {
                    notifSwitch.setOn(true, animated: true)
                } else {
                    notifSwitch.setOn(false, animated: true)
                }
            }
            
        } else {
            setNotAuthorizedUI()
        }
    }
    
    func setNotAuthorizedUI() {
        usernameLabel.text = "Not Authorized"
        loginButton.setTitle("Log In", for: UIControlState())
        
        notifSwitch.isEnabled = false
        adultSwitch.isEnabled = false
    }
    
    @IBAction func notifSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putObject(true as AnyObject, key: DefaultsManager.NOTIFY)
        } else {
            DefaultsManager.putObject(false as AnyObject, key: DefaultsManager.NOTIFY)
            UIApplication.shared.cancelAllLocalNotifications()
        }
    }
    
    @IBAction func adultSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putObject(true as AnyObject, key: DefaultsManager.ADULT)
        } else {
            DefaultsManager.putObject(false as AnyObject, key: DefaultsManager.ADULT)
        }
    }
    
    //Mark: - TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "pseudCell")
        let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
        cell?.textLabel?.text = pseuds[curKey]
        
        if (curKey == currentPseud) {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pseuds.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
        currentPseud = curKey
        DefaultsManager.putString(curKey, key: DefaultsManager.PSEUD_ID)
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "PSEUDS"
    }
}
