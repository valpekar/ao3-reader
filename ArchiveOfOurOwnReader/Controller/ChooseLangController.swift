//
//  ChooseLangController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/26/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit

@objc protocol ItemChooseDelegate {
    func itemChosen(itemId: String, itemVal: String)
}

class ChooseItemCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
}


class ChooseLangController: CenterViewController, UITableViewDelegate, UITableViewDataSource {
    
     @IBOutlet weak var tableView:UITableView!
    
    var itemChooseDelegate: ItemChooseDelegate! = nil
    var dict:NSDictionary! = nil
    var keys: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        self.applyTheme()
        
        tableView.tableFooterView = UIView()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        
        keys = dict.keysSortedByValue(comparator: Utils.compareKeys ) as? [String] ?? []
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "ChooseItemCell"
        
        let cell:ChooseItemCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ChooseItemCell
        
        let curKey = keys[indexPath.row]
        cell.nameLabel.text = curKey
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.nameLabel.textColor = AppDelegate.dayTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.nameLabel.textColor = AppDelegate.nightTextColor
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chosenKey = self.keys[indexPath.row]
        let chosenId = self.dict[chosenKey] as? String ?? ""
        
      //  self.itemChooseDelegate.itemChosen(itemId: chosenId, itemVal: chosenKey)
        
        self.dismiss(animated: true) {
            self.itemChooseDelegate.itemChosen(itemId: chosenId, itemVal: chosenKey)
        }
    }
}
