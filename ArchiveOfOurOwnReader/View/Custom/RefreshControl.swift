//
//  RefreshControl.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5.12.21.
//  Copyright © 2021 Sergei Pekar. All rights reserved.
//

import Foundation
import UIKit

class RefreshControl: UIRefreshControl {

    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set(hiding) {
            if hiding {
                guard frame.origin.y >= 0 else { return }
                super.isHidden = hiding
            } else {
                guard frame.origin.y < 0 else { return }
                super.isHidden = hiding
            }
        }
    }

    override var frame: CGRect {
        didSet {
            if frame.origin.y < 0 {
                isHidden = false
            } else {
                isHidden = true
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var originalFrame = frame
        frame = originalFrame
    }
}
