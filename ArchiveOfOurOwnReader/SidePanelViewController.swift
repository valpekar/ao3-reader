//
//  SidePanelViewController.swift
//  TopTags
//
//  Created by ValeriyaPekar on 2/6/15.
//  Copyright (c) 2015 Simple Soft Alliance. All rights reserved.
//

import UIKit
import CoreData

@objc
protocol SidePanelViewControllerDelegate {
    func selectedControllerAtIndex(_ indexPath:IndexPath)
    func selectedActionAtIndex(_ indexPath:IndexPath)
}

class SidePanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var delegate: SidePanelViewControllerDelegate?
    
    let controllers = [Localization("Browse"),
                       Localization("Bookmarks"),
                       Localization("MarkedForLater"),
                       Localization("Subscriptions"),
                       Localization("Downloaded"),
                       Localization("Me"),
                       Localization("Recommendations"),
                       Localization("FavoriteAuthors"),
                       Localization("Support"),
                       Localization("Reading Now"),
                      /* Localization("Publish")*/
        /*, "Publish"*/]
    
    let sections = ["", ""]
    let secondSectionRows = [Localization("ImportFrm")]
    let secondSectionRowsImgs = ["import"]
    let imgs = ["browse", "bmk", "history" , "subscriptions", "downloaded", "profile", "recomm", "star", "support", "book_open", "shortstory"]
    
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
            if (indexPath.row == 4) {
                let downloadedCount = getDownloadedWorksCount()
                var title = "\(controllers[indexPath.row])  (\(downloadedCount))"
                
                let worksToReload = DefaultsManager.getStringArray(DefaultsManager.NOTIF_IDS_ARR)
                if (worksToReload.count > 0) {
                    title = "\(title) 🔄"
                }
                cell.configureForHeader(title, imageName: imgs[indexPath.row])
            } else if (indexPath.row == 7) {
                let favAuthorsCount = getFavAuthorsCount()
                let title = "\(controllers[indexPath.row])  (\(favAuthorsCount))"
                cell.configureForHeader(title, imageName: imgs[indexPath.row])
            } else {
                cell.configureForHeader(controllers[indexPath.row], imageName: imgs[indexPath.row])
            }
        }  else {
            cell.configureForHeader(secondSectionRows[indexPath.row], imageName: secondSectionRowsImgs[indexPath.row])
        }
        
        return cell
    }
    
    func getDownloadedWorksCount() -> Int {
        var res = 0
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return res
        }
        res = appDelegate.getDownloadedWorksCount()
        
        return res
    }
    
    func getFavAuthorsCount() -> Int {
        var res = 0
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return res
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBFavAuthor")
        do {
            let countReq = try managedContext.count(for: fetchRequest)
            if countReq != NSNotFound {
                res = countReq
            }
        } catch {
            #if DEBUG
            print("cannot count favorites.")
            #endif
        }
        
        return res
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
