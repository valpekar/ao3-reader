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
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var delegate: SidePanelViewControllerDelegate?
    
    let controllers = [NSLocalizedString("Browse", comment: ""),
                       NSLocalizedString("Bookmarks", comment: ""),
                       NSLocalizedString("History", comment: ""),
                       NSLocalizedString("Downloaded", comment: ""),
                       NSLocalizedString("Me", comment: ""),
                       NSLocalizedString("Recommendations", comment: ""),
                       NSLocalizedString("Support", comment: "")
        /*, "Publish"*/]
    let imgs = ["shortstory", "bmk", "history" ,"download-100", "profile", "shortstory", "support"/*, "shortstory"*/]
    
    struct TableView {
        struct CellIdentifiers {
            static let TagCell = "NavigationCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controllers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.TagCell, for: indexPath) as! TagCell
        
        let customColorView : UIView = UIView()
        customColorView.backgroundColor = UIColor.init(red: 154/255, green: 30/255, blue: 64/255, alpha: 0.5)
        cell.selectedBackgroundView =  customColorView;
        
        cell.configureForHeader(controllers[(indexPath as NSIndexPath).row], imageName: imgs[(indexPath as NSIndexPath).row])
        return cell
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.selectedControllerAtIndex(indexPath)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section:Int) -> UIView?
    {
        let dynamicView = UIView(frame: CGRect.zero)
        return dynamicView
    }
    
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
