//
//  AboutSubscriptionController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class AboutSubscriptionController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
     @IBAction func aboutSubsTouched(_ sender: AnyObject) {
        UIApplication.shared.openURL(URL(string: "http://simpleappalliance.blogspot.com/2016/05/unofficial-ao3-reader-privacy-policy.html")!)
    }
}
