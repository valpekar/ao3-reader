//
//  FeedTableViewCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var bgView:UIView!
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var topicLabel: UILabel!
    
    @IBOutlet weak var languageLabel: UILabel!
    
    @IBOutlet weak var datetimeLabel: UILabel!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var wordsLabel: UILabel!
    
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var fandomsLabel: UILabel!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet weak var topicPreviewLabel: UILabel!
    
    @IBOutlet weak var chaptersLabel: UILabel!
    
    @IBOutlet weak var commentsLabel: UILabel!
    
    @IBOutlet weak var kudosLabel: UILabel!
    
    @IBOutlet weak var bookmarksLabel: UILabel!
    
    @IBOutlet weak var hitsLabel: UILabel!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var deleteButton: ButtonWithSection!
    
    convenience init(reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    override func layoutSubviews() {
        self.bgView.layer.cornerRadius = 5
        
        self.fandomsLabel.textColor = AppDelegate.greenColor
    }
}
