//
//  AboutSubscriptionController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class AboutSubscriptionController: UIViewController {
    
    @IBOutlet weak var btn:UIButton!
    @IBOutlet weak var lbl:UILabel!
    
    var theme: Int = DefaultsManager.THEME_DAY
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.view.backgroundColor = AppDelegate.greyLightBg
            self.lbl.textColor = UIColor.black
            self.btn.setTitleColor(AppDelegate.redColor, for: .normal)
        } else {
            self.view.backgroundColor = AppDelegate.greyDarkBg
            self.lbl.textColor = AppDelegate.nightTextColor
            self.btn.setTitleColor(AppDelegate.purpleLightColor, for: .normal)
        }
    }
    
     @IBAction func aboutSubsTouched(_ sender: AnyObject) {
        if let url = URL(string: "http://simpleappalliance.blogspot.com/2016/05/unofficial-ao3-reader-privacy-policy.html") {
            UIApplication.shared.openURL(url)
        }
    }
}
