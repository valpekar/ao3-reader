//
//  ChoosePrefController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/30/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCrashlytics

class ChoosePrefController : LoadingViewController {
    
    var chosenFandoms: String = ""
    var chosenDelegate: ChoosePrefProtocol! = nil
    
    @IBOutlet var ipadHeightLayoutConstraint: NSLayoutConstraint?
    @IBOutlet var iphoneHeightLayoutConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var nextButton:UIButton!
    @IBOutlet weak var textField:UITextField!
    @IBOutlet weak var label:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        nextButton.layer.borderWidth = 1.0
//        nextButton.layer.borderColor = UIColor(named: "global_tint").cgColor
        
        if let colorDark = UIColor(named: "onlyDarkBlue"),
        let colorLight = UIColor(named: "onlyLightBlue") {
            
            self.nextButton.applyGradient(colours: [colorDark, colorLight], cornerRadius: AppDelegate.mediumCornerRadius)
        }
        
        addDoneButtonOnKeyboardTf(textField)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChoosePrefController.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(ChoosePrefController.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        label.text = Localization("ChoosePrefWarn")
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
    }
    
    @IBAction func closeTouched(sender: AnyObject) {
        self.dismiss(animated: true) { 
            print(self.chosenFandoms)
        }
    }
    
    @IBAction func nextTouched(sender: AnyObject) {
        
        guard let txt = textField.text, !txt.isEmpty else {
            self.showError(title: Localization("Error"), message: Localization("AtLeastOneFandom"))
            return
        }
        Analytics.logEvent("ChoosePref_Chosen", parameters: ["fandom" : txt as NSObject])
        
        self.dismiss(animated: true) {
            print(self.chosenFandoms)
            self.chosenDelegate.prefChosen(pref: txt)
        }
    }
    
    override func doneButtonAction() {
        textField.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        //let _: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.ipadHeightLayoutConstraint?.constant = 1
        self.iphoneHeightLayoutConstraint?.constant = 1
        
        UIView.animate(withDuration: info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 1.0, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        //var _: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.ipadHeightLayoutConstraint?.constant = 420
        self.iphoneHeightLayoutConstraint?.constant = 220
        
        UIView.animate(withDuration: info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 1.0, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}

protocol ChoosePrefProtocol {
    func prefChosen(pref: String)
}
