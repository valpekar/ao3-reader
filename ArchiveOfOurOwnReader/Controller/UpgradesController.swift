//
//  UpgradesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/27/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit


class UpgradesController: UIViewController {
    
    @IBOutlet weak var privacybtn:UIButton!
    @IBOutlet weak var lbl:UILabel!
    
    
    @IBOutlet weak var view1:UIView!
    @IBOutlet weak var view2:UIView!
    @IBOutlet weak var view3:UIView!
    
    @IBOutlet weak var yrbtn:UIButton!
    @IBOutlet weak var m3btn:UIButton!
    @IBOutlet weak var m1btn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lbl.text = "Premium Subscription offers: \n Get work recommendations every week based on what you have read and liked \n No ads \n Unlimited number of works to download for offline reading"
        
        view1.layer.cornerRadius = AppDelegate.smallCornerRadius
        view2.layer.cornerRadius = AppDelegate.smallCornerRadius
        view3.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        self.yrbtn.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
    }
    
     @IBAction func closeButtonTouched(_ sender: AnyObject) {
        self.dismiss(animated: true) {
            
        }
    }
    
    @IBAction func aboutSubsTouched(_ sender: AnyObject) {
        if let url = URL(string: "http://simpleappalliance.blogspot.com/2016/05/unofficial-ao3-reader-privacy-policy.html") {
            UIApplication.shared.open(url, options: [ : ], completionHandler: { (res) in
                print("opened privacy policy")
            })
        }
    }
}
