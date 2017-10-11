//
//  SerieInfoCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/9/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class SerieInfoCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var begunLabel: UILabel!
    @IBOutlet weak var endedLabel: UILabel!
    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    
    convenience init(reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
}
