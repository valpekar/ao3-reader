//
//  ImportWorkController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 12/26/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class ImportWorkController : UserMessagesController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var importDelegate: WorkImportDelegate! = nil
    
    var theme = DefaultsManager.THEME_DAY
    
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
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            bgView.backgroundColor = AppDelegate.redDarkColor
            label.textColor = AppDelegate.textLightColor
        } else {
            bgView.backgroundColor = UIColor.white
            label.textColor = AppDelegate.redColor
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ImportWorkController.applicationWillEnter(notification:)), name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)

        let gestureRec = UITapGestureRecognizer()
        gestureRec.numberOfTapsRequired = 1
        gestureRec.addTarget(self, action: #selector(ImportWorkController.viewTapped))
        self.view.addGestureRecognizer(gestureRec)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkPasteboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         NotificationCenter.default.removeObserver(self)
    }
    
    @objc func viewTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func applicationWillEnter(notification: NSNotification) {
        checkPasteboard()
    }
    
    func checkPasteboard() {
        let pasteboardString: String? = UIPasteboard.general.string
        if let theString = pasteboardString {
            print("String is \(theString)")
            if (theString.contains("archiveofourown.org")) {
                
                textField.text = theString
                UIPasteboard.general.string = ""
                
            }
        }
    }
    
    @IBAction func cancelTouched(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func importTouched(_ sender: AnyObject) {
        if var txt: String = textField.text, txt.isEmpty == false {
            if (txt.contains("google")) {
                if let idx = txt.index(of: "url=") {
                    txt = String(txt[idx...]).removingPercentEncoding ?? txt
                }
            }
            
            if (txt.contains(AppDelegate.ao3SiteUrl) || txt.contains("archiveofourown.org")) {
                if (txt.contains(" ")) {
                    let arr = txt.split(separator: " ")
                    if (arr.count > 0) {
                        for arrStr in arr {
                            if (arrStr.contains("http://archiveofourown.org")) {
                                txt = String(arr[arr.count - 1])
                                break
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.importDelegate?.linkPasted(workUrl: txt)
                        }
                }
            } else {
                self.showError(title: Localization("Error"), message: Localization("CheckLink"))
                
            }
        }
    }
}

@objc protocol WorkImportDelegate {
    func linkPasted(workUrl: String)
}
