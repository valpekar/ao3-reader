//
//  PublishWorkController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/24/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire

class PublishWorkController: LoadingViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var workTextTv: UITextView!
    @IBOutlet weak var ratingPicker: UIPickerView!
    
    var pickerDataSource = ["Not Rated", "General Audiences", "Teen and Up Audiences", "Mature", "Excplicit"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        
        let screenSize: CGRect = UIScreen.main.bounds
        scrollView.contentSize = CGSize(width: screenSize.width - 40, height: 1300)
        
        workTextTv.layer.cornerRadius = 5.0
        workTextTv.layer.borderColor = UIColor.purple.cgColor
        workTextTv.layer.borderWidth = 1
        
        addDoneButtonOnKeyboard(workTextTv);
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "http://archiveofourown.org"), mainDocumentURL: nil)
            //requestFavs()
        } else {
            openLoginController() //openLoginController()
        }
    }
    
    @IBAction func closeClicked(_ sender: AnyObject) {
        
        
        self.dismiss(animated: true, completion: { () -> Void in
            
            NSLog("closeClicked")
        })
    }
    
    override func doneButtonAction() {
        workTextTv.endEditing(true)
    }
    
    //MARK: - UIPickerViewDataSource, UIPickerViewDelegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if(row == 0) {
            
        }
    }
}
