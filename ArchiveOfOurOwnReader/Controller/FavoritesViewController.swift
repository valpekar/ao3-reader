//
//  FavoritesViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/1/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import TSMessages

class FavoritesViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView:UITableView!
    
    var downloadedWorkds: [DBWorkItem] = []
    var downloadedFandoms: [DBFandom] = []
    var folders: [Folder] = []
    var filtereddownloadedWorkds: [DBWorkItem] = []
    
    var hidden:[Bool] = []
    
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
        if (!purchased || !donated) {
            loadAdMobInterstitial()
        }
        
        //search
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.tintColor = UIColor(red: 255/255, green: 77/255, blue: 80/255, alpha: 1.0)
            
            addDoneButtonOnKeyboardTf(controller.searchBar.value(forKey: "_searchField") as! UITextField)
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        // Reload the table
        //self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadWroksFromDB()
        //loadFandomsFromWorks()
        tableView.reloadData()
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [String : AnyObject]
        self.title = String(downloadedWorkds.count) + " " + NSLocalizedString("Downloaded", comment: "")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.resultSearchController.isActive) {
            return self.filtereddownloadedWorkds.count
        }
        else {
            if (section < downloadedFandoms.count) {
                let curFandom: NSManagedObject = downloadedFandoms[section]
                return numOfWorksInFandom(fandom: curFandom.value(forKey: "fandomName") as? String ?? "")
            } else {
                return self.downloadedWorkds.count
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return folders.count + 1 //1 for uncategorized
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Uncategorized"
        } else {
            return folders[section - 1].name ?? ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:FeedTableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? FeedTableViewCell
        
        if (cell == nil) {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        var curWork: NSManagedObject?
        
        if (indexPath.section < downloadedFandoms.count) {
            let curFandom: NSManagedObject = downloadedFandoms[indexPath.section]
            var sectionWorks = getWorksInFandom(fandom: curFandom.value(forKey: "fandomName") as? String ?? "")
            curWork = sectionWorks[indexPath.row]
        } else {
        
            curWork = downloadedWorkds[indexPath.row]
        }
        
        if (self.resultSearchController.isActive) {
            curWork = filtereddownloadedWorkds[indexPath.row]
        }
        
        if let wTitle = curWork?.value(forKey: "workTitle") as? String {
            if let wAuthor = curWork?.value(forKey: "author") as? String {
                cell?.topicLabel.text = wTitle + " \(NSLocalizedString("by", comment: "")) " + wAuthor
            } else {
                cell?.topicLabel.text = ""
            }
        } else {
            cell?.topicLabel.text = ""
        }
        
        var fandomsStr = ""
        if let downloadedFandoms = curWork?.mutableSetValue(forKey: "fandoms").allObjects as? [DBFandom] {
        for i in 0..<downloadedFandoms.count {
            let fandom = downloadedFandoms[i]
            fandomsStr += fandom.value(forKey: "fandomName") as! String
            if (i < downloadedFandoms.count - 1) {
                fandomsStr += " | "
            }
        }
        }
        cell?.fandomsLabel.text = NSLocalizedString("Fandoms_", comment: "") + fandomsStr
        
        if (curWork?.value(forKey: "topicPreview") as? String != nil) {
            cell?.topicPreviewLabel.text = curWork?.value(forKey: "topicPreview") as? String
        }
        else {
            cell?.topicPreviewLabel.text = ""
        }
        
        let chaptersCountStr = (curWork?.value(forKey: "chaptersCount") as? String) ?? ""
        
        cell?.datetimeLabel.text = curWork?.value(forKey: "datetime") as? String
        cell?.languageLabel.text = curWork?.value(forKey: "language") as? String
        cell?.wordsLabel.text = curWork?.value(forKey: "words") as? String
        cell?.chaptersLabel.text = "\(NSLocalizedString("Chapters_", comment: "")) \(chaptersCountStr)"
        cell?.commentsLabel.text = curWork?.value(forKey: "comments") as? String
        cell?.kudosLabel.text = curWork?.value(forKey: "kudos") as? String
        cell?.bookmarksLabel.text = curWork?.value(forKey: "bookmarks") as? String
        cell?.hitsLabel.text = curWork?.value(forKey: "hits") as? String
        /*cell?.completeLabel.text = curWork.valueForKey("complete") as? String
        cell?.categoryLabel.text = curWork.valueForKey("category") as? String
        cell?.ratingLabel.text = curWork.valueForKey("ratingTags") as? String*/
        
        cell?.tagsLabel.text = curWork?.value(forKey: "tags") as? String
        
        cell?.deleteButton.tag = (indexPath as NSIndexPath).row
        
        
        return cell!
    }
    
    func loadWroksFromDB() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let results = fetchedResults {
                downloadedWorkds = results
            }
        } catch {
            #if DEBUG
            print("cannot fetch favorites.")
            #endif
        }
        
        let fetchfolderRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"Folder")
        fetchfolderRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [Folder]
            
            if let results = fetchedResults {
                folders = results
            }
        } catch {
            #if DEBUG
                print("cannot fetch folders.")
            #endif
        }
    }
    
    func loadFandomsFromWorks() {
        downloadedFandoms.removeAll()
        
        for wItem in downloadedWorkds {
            if let wFandoms: [DBFandom] = wItem.mutableSetValue(forKey: "fandoms").allObjects as? [DBFandom] {
                downloadedFandoms.append(contentsOf: wFandoms)
            }
        }
    }
    
    func numOfWorksInFandom(fandom: String) -> Int {
        var res = 0
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ LIMIT 1", fandom)
        let array = (downloadedWorkds as NSArray).filtered(using: searchPredicate)
        res = array.count
        
        return res
    }
    
    func getWorksInFandom(fandom: String) -> [NSManagedObject] {
        var res: [NSManagedObject] = []
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ ", fandom)
        if let array = (downloadedWorkds as NSArray).filtered(using: searchPredicate) as? [NSManagedObject] {
            res = array
        }
        
        return res
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "offlineWorkDetail") {
    
            let workDetail: UINavigationController = segue.destination as! UINavigationController
            var curWork = downloadedWorkds[(tableView.indexPathForSelectedRow! as NSIndexPath).row]
            if (self.resultSearchController.isActive) {
                if ((tableView.indexPathForSelectedRow! as NSIndexPath).row < filtereddownloadedWorkds.count ) {
                    curWork = filtereddownloadedWorkds[(tableView.indexPathForSelectedRow! as NSIndexPath).row]
                }
            }
            
            (workDetail.viewControllers[0] as! WorkDetailViewController).downloadedWorkItem = curWork
             (workDetail.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
        }
    }
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
            
            let deleteAlert = UIAlertController(title: "Are you sure?", message: "Are you sure you would like to delete this work from Downloaded?", preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
                #if DEBUG
                print("Cancel")
                #endif
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction) in
                
                let index = sender.tag
                self.deleteItemFromDownloaded(index)
                
                self.dismiss(animated: true, completion: { () -> Void in
                })
            }))
            
            present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromDownloaded(_ index: Int) {
        let appDel:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        context.delete(downloadedWorkds[index] as NSManagedObject)
        downloadedWorkds.remove(at: index)
        do {
            try context.save()
        } catch _ {
        }
        
        self.tableView.reloadData()
       // self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
        self.title = String(downloadedWorkds.count) + " " + NSLocalizedString("Downloaded", comment: "")
    }
    
    override func controllerDidClosed() {
        if (!purchased && !donated) {
            showAdMobInterstitial()
        }
    }
    
    func controllerDidClosedWithChange() {
    }
    
    //MARK: - UISearchResultsUpdating delegate
    
    func updateSearchResults(for searchController: UISearchController)
    {
        filtereddownloadedWorkds.removeAll(keepingCapacity: false)
        
        guard let text = searchController.searchBar.text else {
            self.tableView.reloadData()
            return
        }
        
        if text.isEmpty {
            self.tableView.reloadData()
            return
        }
        
        let searchPredicate = NSPredicate(format: "topic CONTAINS[c] %@ OR topicPreview CONTAINS[c] %@  OR tags CONTAINS[c] %@ OR author CONTAINS[c] %@ OR workTitle CONTAINS[c] %@", text, text, text, text, text)
        let array = (downloadedWorkds as NSArray).filtered(using: searchPredicate)
        filtereddownloadedWorkds = array as! [DBWorkItem]
        
        self.tableView.reloadData()
    }

    
    override func doneButtonAction() {
        self.tableView.endEditing(true)
        self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction override func drawerClicked(_ sender: AnyObject) {
        
        super.drawerClicked(sender)
        
        self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - folders
    
    @IBAction func addFolder(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Folder", message: "Add New Folder", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.text = "Folder \(self.folders.count + 1)"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if let txt = textField?.text {
            
                self.addNewFolder(name: txt)
                Answers.logCustomEvent(withName: "New_folder",
                                   customAttributes: [
                                    "name": txt])
            } else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderNameEmpty", comment: ""), type: .error)
            }
            
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewFolder(name: String) {
        
    }
    
    //https://codebasecamp.com/2016/12/02/Expandable-TableView/
    //https://www.appcoda.com/expandable-table-view/
    //https://newfivefour.com/swift-ios-expanding-uitableview-sections.html
    //https://github.com/HuyVuong1121/TreeTableView/tree/master/无级级树状TableView/YSTreeTableView/YSTreeTableView
    //https://github.com/younatics/YNExpandableCell
}
