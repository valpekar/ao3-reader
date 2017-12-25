//
//  PageCollectionReusableView.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit

class PageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel:UILabel!
    
    override func draw(_ rect: CGRect) {
        
        if (self.titleLabel.text == AppDelegate.gapString) {
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: rect.maxX * 0.75, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.75))
        context.addLine(to: CGPoint(x: (rect.maxX), y: rect.maxY))
        context.closePath()
        
        context.setFillColor(AppDelegate.greyColor.cgColor)
        context.fillPath()
        }
        super.draw(rect)
    }
    
}
