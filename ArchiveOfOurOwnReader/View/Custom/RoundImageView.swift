//
//  RoundImageView.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/10/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class RoundImageView : UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius: CGFloat = self.bounds.size.width / 2.0
        
        self.layer.cornerRadius = radius
    }
}

