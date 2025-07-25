//
//  FeedTableViewCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergei Pekar on 7/9/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit

class DownloadedCell: UITableViewCell {
    @IBOutlet weak var bgView:UIView!
    @IBOutlet weak var ratingImg: UIImageView!
    
    @IBOutlet weak var hitsImg: UIImageView!
    @IBOutlet weak var bmkImg: UIImageView!
    @IBOutlet weak var chaptersImg: UIImageView!
    @IBOutlet weak var kudosImg: UIImageView!
    @IBOutlet weak var wordImg: UIImageView!
    
    @IBOutlet weak var wordsLabel: UILabel!
    
    @IBOutlet weak var topicLabel: UILabel!
    
    @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var languageLabel: UILabel!
    
    @IBOutlet weak var datetimeLabel: UILabel!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var fandomsLabel: UILabel!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet weak var topicPreviewLabel: UILabel!
    
    @IBOutlet weak var chaptersLabel: UILabel!
    
    @IBOutlet weak var kudosLabel: UILabel!
    
    @IBOutlet weak var bookmarksLabel: UILabel!
    
    @IBOutlet weak var hitsLabel: UILabel!
    
    @IBOutlet weak var folderButton: ButtonWithSection!
    @IBOutlet weak var deleteButton: ButtonWithSection!
    
    @IBOutlet weak var readProgress: UIProgressView!
    
    convenience init(reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    override func layoutSubviews() {
        self.bgView.layer.cornerRadius = 5
        
        self.deleteButton.accessibilityLabel = NSLocalizedString("DeleteWrk", comment: "")
        self.folderButton.accessibilityLabel = NSLocalizedString("WorkFolder", comment: "")
    }
}

