
//
//  File.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/12/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Crashlytics
import TSMessages

class SecuritySettingsController: LoadingViewController {
    
    @IBOutlet weak var authSwitch: UISwitch!
    @IBOutlet weak var passSwitch: UISwitch!
    @IBOutlet weak var passTextView: UITextField!
    @IBOutlet weak var passrepTextView: UITextField!
    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var authLabel: UILabel!
    @IBOutlet weak var passLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshUI ()
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.explainLabel.textColor = UIColor.black
            self.authLabel.textColor = UIColor.black
            self.passLabel.textColor = UIColor.black
        } else {
            self.explainLabel.textColor = AppDelegate.textLightColor
            self.authLabel.textColor = AppDelegate.textLightColor
            self.passLabel.textColor = AppDelegate.textLightColor
        }
    }
    
    func refreshUI () {
        let userPass: String = DefaultsManager.getString(DefaultsManager.USER_PASS)
        if (!userPass.isEmpty) {
            passTextView.text = userPass
            passrepTextView.text = userPass
        }
        
        if let auth = DefaultsManager.getBool(DefaultsManager.NEEDS_AUTH) {
            if (auth == true) {
                authSwitch.setOn(true, animated: false)
            } else {
                authSwitch.setOn(false, animated: false)
            }
        }
        
        if let pass = DefaultsManager.getBool(DefaultsManager.NEEDS_PASS) {
            if (pass == true) {
                passSwitch.setOn(true, animated: false)
            } else {
                passSwitch.setOn(false, animated: false)
            }
        }
        
        addDoneButtonOnKeyboardTf(passTextView)
        addDoneButtonOnKeyboardTf(passrepTextView)
    }
    
    override func doneButtonAction() {
        passTextView.resignFirstResponder()
        passrepTextView.resignFirstResponder()
    }
    
    @IBAction func passcodeTouched(_ sender: AnyObject) {
        if let txt: String = passTextView.text,
            let txt1: String = passrepTextView.text {
            if (txt.isEmpty || txt1.isEmpty) {
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Please type your passcode", comment: ""), type: .error, duration: 2.0)
            } else if (txt != txt1) {
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Passcodes do not match", comment: ""), type: .error, duration: 2.0)
            } else {
                
                doneButtonAction()
                
                DefaultsManager.putString(txt, key: DefaultsManager.USER_PASS)
                
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Success", comment: ""), subtitle: NSLocalizedString("Passcode successfully set", comment: ""), type: .success, duration: 2.0)
            }
        }
    }
    
    @IBAction func authSwitchChanged(_ sender: UISwitch) {
        Answers.logCustomEvent(withName: "authSwitchChanged",
                               customAttributes: [
                                "state": String(sender.isOn)])
        
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.NEEDS_AUTH)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NEEDS_AUTH)
        }
    }
    
    @IBAction func passSwitchChanged(_ sender: UISwitch) {
        Answers.logCustomEvent(withName: "passSwitchChanged",
                               customAttributes: [
                                "state": String(sender.isOn)])
        
        if (sender.isOn) {
            if (!DefaultsManager.getString(DefaultsManager.USER_PASS).isEmpty) {
                DefaultsManager.putBool(true, key: DefaultsManager.NEEDS_PASS)
            } else {
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Please type your passcode", comment: ""), type: .error, duration: 2.0)
                sender.setOn(false, animated: true)
            }
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NEEDS_PASS)
        }
    }
}
