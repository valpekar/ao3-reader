//
//  ChoosePrefController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/30/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import TSMessages

class ChoosePrefController : LoadingViewController {
    
    var chosenFandoms: String = ""
    var chosenDelegate: ChoosePrefProtocol! = nil
    
    @IBOutlet var ipadHeightLayoutConstraint: NSLayoutConstraint?
    @IBOutlet var iphoneHeightLayoutConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var nextButton:UIButton!
    @IBOutlet weak var textField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.layer.borderWidth = 1.0
        nextButton.layer.borderColor = AppDelegate.redColor.cgColor
        nextButton.layer.cornerRadius = 5.0
        
        addDoneButtonOnKeyboardTf(textField)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChoosePrefController.keyboardWillShow(notification:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(ChoosePrefController.keyboardWillHide(notification:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
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
            TSMessage.showNotification(in: self, title: "Error", subtitle: "Please type at least one fandom name!", type: .error, duration: 2.0)
            return
        }
        
        self.dismiss(animated: true) {
            print(self.chosenFandoms)
            self.chosenDelegate.prefChosen(pref: txt)
        }
    }
    
    override func doneButtonAction() {
        textField.resignFirstResponder()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        //let _: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.ipadHeightLayoutConstraint?.constant = 1
        self.iphoneHeightLayoutConstraint?.constant = 1
        
        UIView.animate(withDuration: info?[UIKeyboardAnimationDurationUserInfoKey] as? Double ?? 1.0, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        //var _: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.ipadHeightLayoutConstraint?.constant = 420
        self.iphoneHeightLayoutConstraint?.constant = 220
        
        UIView.animate(withDuration: info?[UIKeyboardAnimationDurationUserInfoKey] as? Double ?? 1.0, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}

protocol ChoosePrefProtocol {
    func prefChosen(pref: String)
}
