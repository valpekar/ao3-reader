//
//  SidePanelViewController.swift
//  TopTags
//
//  Created by ValeriyaPekar on 2/6/15.
//  Copyright (c) 2015 Simple Soft Alliance. All rights reserved.
//

import UIKit

@objc
protocol SidePanelViewControllerDelegate {
    func selectedControllerAtIndex(_ indexPath:IndexPath)
    func selectedActionAtIndex(_ indexPath:IndexPath)
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var delegate: SidePanelViewControllerDelegate?
    
    let controllers = [NSLocalizedString("Browse", comment: ""),
                       NSLocalizedString("Bookmarks", comment: ""),
                       NSLocalizedString("History", comment: ""),
                       NSLocalizedString("MarkedForLater", comment: ""),
                       NSLocalizedString("Subscriptions", comment: ""),
                       NSLocalizedString("Downloaded", comment: ""),
                       NSLocalizedString("Me", comment: ""),
                       NSLocalizedString("Recommendations", comment: ""),
                       NSLocalizedString("Support", comment: "")
        /*, "Publish"*/]
    
    let sections = ["", ""]
    let secondSectionRows = ["Import From AO3"]
    let secondSectionRowsImgs = ["import"]
    let imgs = ["shortstory", "bmk", "history" , "history", "subscriptions", "download-red", "profile", "shortstory", "support"/*, "shortstory"*/]
    
    struct TableView {
        struct CellIdentifiers {
            static let TagCell = "NavigationCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
        tableView.tableFooterView = UIView()
        
        tableView.backgroundColor = AppDelegate.redColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return controllers.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.TagCell, for: indexPath) as! TagCell
        
        let customColorView : UIView = UIView()
        customColorView.backgroundColor = AppDelegate.redColor
        cell.selectedBackgroundView =  customColorView;
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        
        if (indexPath.section == 0) {
            cell.configureForHeader(controllers[indexPath.row], imageName: imgs[indexPath.row])
        } else {
            cell.configureForHeader(secondSectionRows[indexPath.row], imageName: secondSectionRowsImgs[indexPath.row])
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) {
            delegate?.selectedControllerAtIndex(indexPath)
        } else {
            delegate?.selectedActionAtIndex(indexPath)
        }
    }
    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section:Int) -> UIView?
//    {
//        let dynamicView = UIView(frame: CGRect.zero)
//        return dynamicView
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

}

class TagCell: UITableViewCell {
   
     @IBOutlet weak var headerLabel: UILabel!
     @IBOutlet weak var headerImg: UIImageView!
    
    func configureForHeader(_ tagHeader: String, imageName: String) {
        headerLabel.text = tagHeader
        headerImg.image = UIImage(named: imageName)
    }

}
