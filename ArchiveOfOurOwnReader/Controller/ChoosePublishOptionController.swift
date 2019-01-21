//
//  ChoosePublishOptionController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/21/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit

class ChoosePublishOptionController: LoadingViewController {
    
    static var typeTitle: Int = 0
    static var typeRatings: Int = 1
    
    var ratings = ["Not Rated", "General Audiences", "Teen and Up Audiences", "Mature", "Excplicit"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
