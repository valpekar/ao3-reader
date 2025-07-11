
//
//  File.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/12/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import FirebaseCrashlytics

class SecuritySettingsController: LoadingViewController {
    
    @IBOutlet weak var authSwitch: UISwitch!
    @IBOutlet weak var passSwitch: UISwitch!
    @IBOutlet weak var passTextView: UITextField!
    @IBOutlet weak var passrepTextView: UITextField!
    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var authLabel: UILabel!
    @IBOutlet weak var passLabel: UILabel!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var bgView: UIView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshUI ()
        
        self.setButton.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
        makeRoundView(view: bgView)
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
                self.showError(title: Localization("Error"), message: Localization("Please type your passcode"))
            } else if (txt != txt1) {
                self.showError(title: Localization("Error"), message: Localization("Passcodes do not match"))
            } else {
                
                doneButtonAction()
                
                DefaultsManager.putString(txt, key: DefaultsManager.USER_PASS)
                
                self.showSuccess(title: Localization("Success"), message: "Passcode successfully set")
            }
        }
    }
    
    @IBAction func authSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.NEEDS_AUTH)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NEEDS_AUTH)
        }
    }
    
    @IBAction func passSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            if (!DefaultsManager.getString(DefaultsManager.USER_PASS).isEmpty) {
                DefaultsManager.putBool(true, key: DefaultsManager.NEEDS_PASS)
            } else {
                self.showError(title: Localization("Error"), message: Localization("Please type your passcode"))
                
                sender.setOn(false, animated: true)
            }
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NEEDS_PASS)
        }
    }
}
