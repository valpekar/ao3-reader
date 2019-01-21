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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.layer.cornerRadius = 5.0
        textView.layer.borderColor = UIColor.purple.cgColor
        textView.layer.borderWidth = 0.7
        
        addDoneButtonOnKeyboard(self.textView)
        
        textView.delegate = self
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
