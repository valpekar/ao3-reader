//
//  PlainTextController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/21/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit

class PlainTextController: LoadingViewController {
    
    @IBOutlet weak var textView: UITextView!
    var plainTextDelegate: PlainTextDelegate?
    var textToEdit = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        
        addDoneButtonOnKeyboard(self.textView)
        
        textView.delegate = self
        
        if (self.textToEdit.isEmpty == false) {
            self.textView.text = self.textToEdit
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.backgroundColor = UIColor(named: "global_tint")
    
        if (theme == DefaultsManager.THEME_NIGHT) {
            self.textView.backgroundColor = AppDelegate.nightBgColor
            self.textView.textColor = AppDelegate.nightTextColor
        } else {
             self.textView.backgroundColor = AppDelegate.dayBgColor
             self.textView.textColor = AppDelegate.dayTextColor
        }
    }
    
    @IBAction func checkTouched(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: { () -> Void in
            if let txt = self.textView.text, txt.isEmpty == false {
                self.plainTextDelegate?.plainTextSelected(text: txt)
            }
        })
    }
    
    @IBAction func closeTouched(_ sender: AnyObject) {
        //show sure dialog
    }
    
        override func doneButtonAction() {
            textView.endEditing(true)
        }
}

extension PlainTextController : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == "Type here...") {
            textView.text = ""
        }
    }
}


protocol PlainTextDelegate {
    func plainTextSelected(text: String)
}
