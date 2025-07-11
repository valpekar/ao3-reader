//
//  WorkDetailsAuthorCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 10/4/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit

class WorkDetailsAuthorCell: UITableViewCell {
    
    @IBOutlet weak var downloadTrashButton: UIButton!
    
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var langLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var ratingImg: UIImageView!
    
    @IBOutlet weak var authorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.downloadTrashButton.accessibilityLabel = NSLocalizedString("StoryOptions", comment: "")
        self.authorView.accessibilityLabel = NSLocalizedString("AuthorView", comment: "")
    }
    
    func setup(with downloadedWorkItem:WorkItem, and theme: Int) {
        
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.cornerRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        self.authorView.layer.shadowRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.shadowOffset = CGSize(width: 2.0, height: 1.5)
        self.authorView.layer.shadowOpacity = 0.7
        authorView.layer.shadowColor = UIColor(named: "shadowColor")?.cgColor
        
        self.backgroundColor = UIColor.clear
        
        downloadTrashButton.setImage(UIImage(named: "edit"), for: UIControl.State.normal)
        authorView.backgroundColor = UIColor(named: "transparentBg")
        titleLabel.textColor = UIColor(named: "textMain")
        authorLabel.textColor = UIColor(named: "textSecondary")
        dateLabel.textColor = UIColor(named: "textThirdLevel")
        
        
        let auth = downloadedWorkItem.author
        authorLabel.text = "\(auth)" // = underlineAttributedString
        langLabel.text = downloadedWorkItem.language
        dateLabel.text = downloadedWorkItem.datetime
        
        let title = downloadedWorkItem.workTitle
        let trimmedTitle = title.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        
        titleLabel.text = trimmedTitle
        
        categoryLabel.text = downloadedWorkItem.category
        completeLabel.text = downloadedWorkItem.complete
        
        switch (downloadedWorkItem.ratingTags ).trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            ratingImg.image = UIImage(named: "R")
        case "Explicit":
            ratingImg.image = UIImage(named: "NC17")
        default:
            ratingImg.image = UIImage(named: "NotRated")
        }
    }
    
    func setupDwnl(with downloadedWorkItem:DBWorkItem, and theme: Int) {
        
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.cornerRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        self.authorView.layer.shadowRadius = AppDelegate.smallCornerRadius
        self.authorView.layer.shadowOffset = CGSize(width: 2.0, height: 1.5)
        self.authorView.layer.shadowOpacity = 0.7
        self.authorView.layer.shadowColor = UIColor(named: "shadowColor")?.cgColor
        
        self.backgroundColor = UIColor.clear
        
        downloadTrashButton.setImage(UIImage(named: "edit"), for: UIControl.State.normal)
        
        authorView.backgroundColor = UIColor(named: "transparentBg")
        titleLabel.textColor = UIColor(named: "textMain")
        authorLabel.textColor = UIColor(named: "textSecondary")
        dateLabel.textColor = UIColor(named: "textThirdLevel")
        
        let auth = downloadedWorkItem.author ?? ""
        authorLabel.text = "\(auth)" // = underlineAttributedString
        langLabel.text = downloadedWorkItem.language
        dateLabel.text = downloadedWorkItem.datetime
        
        let title = downloadedWorkItem.workTitle ?? ""
        let trimmedTitle = title.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        
        titleLabel.text = trimmedTitle
        
        categoryLabel.text = downloadedWorkItem.category
        completeLabel.text = downloadedWorkItem.complete
        
        switch (downloadedWorkItem.ratingTags ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            ratingImg.image = UIImage(named: "R")
        case "Explicit":
            ratingImg.image = UIImage(named: "NC17")
        default:
            ratingImg.image = UIImage(named: "NotRated")
        }
    }
}

