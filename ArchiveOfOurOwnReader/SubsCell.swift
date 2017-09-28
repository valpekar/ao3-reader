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
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.frame = CGRect(origin: CGPoint.zero, size: self.bgView.frame.size)//self.bgView.bounds
        //gradient.startPoint = CGPoint(x: 1.0, y: 0.5)
        //gradient.endPoint = CGPoint(x: 0.0, y:0.5)
        gradient.colors = [AppDelegate.redLightColor.cgColor, AppDelegate.purpleLightColor.cgColor]
        
        self.bgView.layer.insertSublayer(gradient, at: 0)
    }
}
