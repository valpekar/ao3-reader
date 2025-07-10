//
//  UpgradesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/27/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import StoreKit
import FirebaseCrashlytics
import Firebase

class UpgradesController: UserMessagesController {
    
    
    @IBOutlet weak var privacybtn:UIButton!
    @IBOutlet weak var restorebtn:UIButton!
    @IBOutlet weak var lbl:UILabel!
    @IBOutlet weak var infoLbl:UILabel!
    
    
    @IBOutlet weak var view1:UIView!
    @IBOutlet weak var view2:UIView!
    @IBOutlet weak var view3:UIView!
    
    @IBOutlet weak var yrbtn:UIButton!
    @IBOutlet weak var m3btn:UIButton!
    @IBOutlet weak var m1btn:UIButton!
    
    @IBOutlet weak var scrollview:UIScrollView!
    
    var donated = false
    
    @IBOutlet weak var navBar:UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = " "
        
        
        
    }
    
}
