//
//  XibView.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/4/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit

@IBDesignable
class XibView : UIView {
    
    var contentView: UIView?
    @IBInspectable var nibName: String?
    
    var downloadButtonDelegate: DownloadButtonDelegate?
    
    var rowIndex = 0
    
    @IBOutlet weak var bgView:UIView!
    @IBOutlet weak var ratingImg: UIImageView!
    
    @IBOutlet weak var hitsImg: UIImageView!
    @IBOutlet weak var bmkImg: UIImageView!
   // @IBOutlet weak var commentsImg: UIImageView!
    @IBOutlet weak var chaptersImg: UIImageView!
    @IBOutlet weak var kudosImg: UIImageView!
    @IBOutlet weak var wordImg: UIImageView!
    
    @IBOutlet weak var topicLabel: UILabel!
    
    @IBOutlet weak var languageLabel: UILabel!
    
    @IBOutlet weak var datetimeLabel: UILabel!
    
     @IBOutlet weak var authorLabel: UILabel!
    
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var wordsLabel: UILabel!
    
    @IBOutlet weak var completeLabel: UILabel!
    
    @IBOutlet weak var fandomsLabel: UILabel!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet weak var topicPreviewLabel: UILabel!
    
    @IBOutlet weak var chaptersLabel: UILabel!
    
   // @IBOutlet weak var commentsLabel: UILabel!
    
    @IBOutlet weak var kudosLabel: UILabel!
    
    @IBOutlet weak var bookmarksLabel: UILabel!
    
    @IBOutlet weak var hitsLabel: UILabel!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    func xibSetup() {
        guard let view = loadViewFromNib() else { return }
        view.frame = bounds
        view.autoresizingMask =
            [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        contentView = view
    }
    
    func loadViewFromNib() -> UIView? {
        guard let nibName = nibName else { return nil }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(
            withOwner: self,
            options: nil).first as? UIView
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView?.prepareForInterfaceBuilder()
    }
    
    //MARK: - actions
    
    @IBAction func downloadButtonPressed(sender: AnyObject) {
        downloadButtonDelegate?.downloadTouched(rowIndex: rowIndex)
    }
    
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        downloadButtonDelegate?.deleteTouched(rowIndex: rowIndex)
    }
}



