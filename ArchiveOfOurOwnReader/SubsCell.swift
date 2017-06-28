//
//  SubsCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/21/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class SubsCell : UITableViewCell {
    
    @IBOutlet weak var bgView:UIView!
    @IBOutlet weak var topicLabel: UILabel!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    convenience init(reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    override func layoutSubviews() {
        self.bgView.layer.cornerRadius = 5
    }
}
