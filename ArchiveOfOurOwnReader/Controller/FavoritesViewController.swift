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

class FavoritesViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, EditFoldersProtocol {
    
    @IBOutlet weak var tableView:UITableView!
    
    let uncategorized = "Uncategorized"
    
    var downloadedWorkds: [String : [DBWorkItem]] = [:]
    var downloadedFandoms: [DBFandom] = []
    var folders: [Folder] = []
    var filtereddownloadedWorkds: [String : [DBWorkItem]] = [:]
    
    var hidden:[Bool] = []
    
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
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
            controller.searchBar.delegate = self
            
            addDoneButtonOnKeyboardTf(controller.searchBar.value(forKey: "_searchField") as! UITextField)
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        // Reload the table
        //self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        
        hidden.append(false)
        
        for folder in folders {
            hidden.append(true)
        }
        
        filtereddownloadedWorkds = downloadedWorkds
        
       // tableView.reloadData()
        reloadTableView()
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict as? [String : AnyObject]
        self.title = String(downloadedWorkds.values.joined().count) + " " + NSLocalizedString("Downloaded", comment: "")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (self.resultSearchController.isActive) {
            if (section == 0) {
                return filtereddownloadedWorkds[uncategorized]?.count ?? 0
            } else {
                return filtereddownloadedWorkds[folders[section - 1].name ?? "No Name"]?.count ?? 0
            }
        }
        else {
            if (hidden.count > section && hidden[section]) {
                return 0
            } else {
            if (section == 0) {
                return downloadedWorkds[uncategorized]?.count ?? 0
            } else {
                return downloadedWorkds[folders[section - 1].name ?? "No Name"]?.count ?? 0
            }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return folders.count + 1 //1 for uncategorized
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if (self.resultSearchController.isActive) {
            if (section == 0) {
                return "\(uncategorized) (\(filtereddownloadedWorkds[uncategorized]?.count ?? 0))"
            } else {
                let name = folders[section - 1].name ?? "No Name"
                return "\(name) (\(filtereddownloadedWorkds[name]?.count ?? 0))"
            }
        } else {
            if (section == 0) {
                return "\(uncategorized) (\(downloadedWorkds[uncategorized]?.count ?? 0))"
            } else {
                let name = folders[section - 1].name ?? "No Name"
                return "\(name) (\(downloadedWorkds[name]?.count ?? 0))"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:DownloadedCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? DownloadedCell
        
        if (cell == nil) {
            cell = DownloadedCell(reuseIdentifier: cellIdentifier)
        }
        
        var curWork: DBWorkItem?
        
        if (self.resultSearchController.isActive) {
            if (indexPath.section == 0) {
                curWork = (filtereddownloadedWorkds["Uncategorized"])?[indexPath.row]
            } else if (indexPath.section - 1 < folders.count) {
                let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                curWork = (filtereddownloadedWorkds[curFolderName])?[indexPath.row]
            }
        } else {
            if (indexPath.section == 0) {
                curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
            } else if (indexPath.section - 1 < folders.count) {
                let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
            }
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
        
        cell?.deleteButton.btnIndexPath = indexPath
        cell?.folderButton.btnIndexPath = indexPath
        
        
        return cell!
    }
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(FavoritesViewController.tapFunction))
    
    func reloadTableView() {
        tableView.reloadData()
        
//        for section in 0..<folders.count {
//        let vvv = tableView.headerView(forSection: section)
//        vvv?.tag = section
//
//        vvv?.isUserInteractionEnabled = true
//
//            let condition = vvv?.gestureRecognizers?.contains(tap) ?? false
//            if (!condition) {
//                vvv?.addGestureRecognizer(tap)
//            }
//        }
    }
    
    //MARK: - works
    
    func loadWroksFromDB(predicate: NSPredicate?, predicateWFolder: NSPredicate) {
        folders.removeAll()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        var searchPredicate: NSPredicate? = nil
        
        if ( predicate != nil) {
         searchPredicate = predicateWFolder
        } else {
         searchPredicate = predicateWFolder
            downloadedWorkds.removeAll()
        }
        
        fetchRequest.predicate = searchPredicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBWorkItem]
            
            if let results = fetchedResults {
                if (predicate != nil) {
                    filtereddownloadedWorkds["Uncategorized"] = results
                } else {
                    downloadedWorkds["Uncategorized"] = results
                }
            }
        } catch {
            #if DEBUG
            print("cannot fetch favorites.")
            #endif
        }
        
        let fetchfolderRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"Folder")
        fetchfolderRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        do {
            let fetchedResults = try managedContext.fetch(fetchfolderRequest) as? [Folder]
            
            if let results = fetchedResults {
                folders = results
            }
        } catch {
            #if DEBUG
                print("cannot fetch folders.")
            #endif
        }
        
        for folder in folders {
            if (predicate != nil) {
                let array = (folder.works?.allObjects as NSArray?)?.filtered(using: predicate!) as? [DBWorkItem]
                filtereddownloadedWorkds[folder.name ?? "No Name" ] = array
            } else {
                downloadedWorkds[folder.name ?? "No Name" ] = folder.works?.allObjects as? [DBWorkItem]
            }
        }
    }
    
    func loadFandomsFromWorks() {
        downloadedFandoms.removeAll()
        
        for wArrItem in Array(downloadedWorkds.values) {
            for wItem in wArrItem {
                if let wFandoms: [DBFandom] = wItem.fandoms?.allObjects as? [DBFandom] {
                    downloadedFandoms.append(contentsOf: wFandoms)
                }
            }
        }
    }
    
    func numOfWorksInFandom(fandom: String) -> Int {
        var res = 0
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ LIMIT 1", fandom)
        let array = (Array(downloadedWorkds.values.joined()) as NSArray).filtered(using: searchPredicate)
        res = array.count
        
        return res
    }
    
    func getWorksInFandom(fandom: String) -> [NSManagedObject] {
        var res: [NSManagedObject] = []
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ ", fandom)
        if let array = (Array(downloadedWorkds.values.joined()) as NSArray).filtered(using: searchPredicate) as? [NSManagedObject] {
            res = array
        }
        
        return res
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "offlineWorkDetail") {
    
            let workDetail: UINavigationController = segue.destination as! UINavigationController
            let indexPath = tableView.indexPathForSelectedRow! as IndexPath
            
            var curWork: DBWorkItem?
            
            if (self.resultSearchController.isActive) {
                if (indexPath.section == 0) {
                    curWork = (filtereddownloadedWorkds["Uncategorized"])?[indexPath.row]
                } else if (indexPath.section - 1 < folders.count) {
                    let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                    curWork = (filtereddownloadedWorkds[curFolderName])?[indexPath.row]
                }
//                if ((tableView.indexPathForSelectedRow! as NSIndexPath).row < filtereddownloadedWorkds.count ) {
//                    curWork = filtereddownloadedWorkds[(tableView.indexPathForSelectedRow! as NSIndexPath).row]
//                }
            } else {
                if (indexPath.section == 0) {
                    curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
                } else if (indexPath.section - 1 < folders.count) {
                    let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                    curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
                }
            }
            
            (workDetail.viewControllers[0] as! WorkDetailViewController).downloadedWorkItem = curWork
             (workDetail.viewControllers[0] as! WorkDetailViewController).modalDelegate = self
        } else if (segue.identifier == "editFoldersSegue") {
            let editController: EditFoldersController = segue.destination as! EditFoldersController
            editController.editFoldersProtocol = self
            editController.folders = folders
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
                
                if let idx = (sender as? ButtonWithSection)?.btnIndexPath {
                    self.deleteItemFromDownloaded(idx)
                }
                
                self.dismiss(animated: true, completion: { () -> Void in
                })
            }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        
            present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromDownloaded(_ indexPath: IndexPath) {
        let appDel:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var curWork: DBWorkItem?
        if (indexPath.section == 0) {
            curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
        } else if (indexPath.section - 1 < folders.count) {
            let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
            curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
        }
        
        if let c = curWork {
            context.delete(c)
            //downloadedWorkds.remove(at: index)
        
            do {
                try context.save()
            } catch _ {
            }
            
            loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
            
            self.tableView.reloadData()
            // self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
            self.title = String(downloadedWorkds.count) + " " + NSLocalizedString("Downloaded", comment: "")
        }
    }
    
    override func controllerDidClosed() {
        if (!purchased && !donated) {
            showAdMobInterstitial()
        }
    }
    
    func controllerDidClosedWithChange() {
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        filtereddownloadedWorkds = downloadedWorkds
    }
    
    //MARK: - UISearchResultsUpdating delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let text = searchController.searchBar.text else {
            self.tableView.reloadData()
            return
        }
        
        if text.isEmpty {
            self.tableView.reloadData()
            return
        }
        
        filtereddownloadedWorkds.removeAll(keepingCapacity: false)
        
        let searchPredicate = NSPredicate(format: "topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@", text, text, text, text, text)
        
        let predicateWFolder = NSPredicate(format: "folder = nil AND (topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@)", text, text, text, text, text)
//        let array = (Array(downloadedWorkds.values.joined()) as NSArray).filtered(using: searchPredicate)
//        filtereddownloadedWorkds = array as! [DBWorkItem]
        
        loadWroksFromDB(predicate: searchPredicate, predicateWFolder: predicateWFolder)
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.tableView.endEditing(true)
        self.resultSearchController.dismiss(animated: true, completion: nil)
        
        tableView.reloadData()
    }

    
    override func doneButtonAction() {
        resultSearchController.searchBar.endEditing(true)
        //self.tableView.endEditing(true)
        //self.resultSearchController.dismiss(animated: true, completion: nil)
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
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: { (action) in
            #if DEBUG
            print("cancel")
            #endif
        }))
        
        alert.view.tintColor = AppDelegate.redColor
        self.present(alert, animated: true, completion: nil)
    }
    
    func addNewFolder(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Folder")
        let predicate = NSPredicate(format: "name == %@", name)
        req.predicate = predicate
        do {
            if let fetchedWorks = try managedContext.fetch(req) as? [Folder] {
                if (fetchedWorks.count > 0) {
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderAlreadyExists", comment: ""), type: .error)
                    return
                }
            }
        } catch {
            fatalError("Failed to fetch folders: \(error)")
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Folder",  in: managedContext) else {
                return
        }
        let newFolder = Folder(entity: entity, insertInto:managedContext)
        newFolder.name = name
        
        //save to DB
        do {
            try managedContext.save()
        } catch let error as NSError {
            #if DEBUG
                print("Could not save \(String(describing: error.userInfo))")
            #endif
        }
        
        loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        tableView.reloadData()
    }
    
    @IBAction func folderTouched(sender: ButtonWithSection) {
        if (folders.count == 0) {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("NoFolders", comment: ""), type: .error)
            return
        }
        
        let indexPath = sender.btnIndexPath
        
        var curWork: DBWorkItem?
        
        if (indexPath.section == 0) {
            curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
        } else if (indexPath.section - 1 < folders.count) {
            let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
            curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
        }
        
        guard let cWork = curWork else {
            return
        }
        
        let alert = UIAlertController(title: "Move Work", message: "Please Choose Folder", preferredStyle: .actionSheet)
        
        for folder in folders {
            alert.addAction(UIAlertAction(title: folder.name ?? "No Name", style: .default, handler: { (action) in
                self.moveToFolder(folder: folder, curWork: cWork)
            }))
        }
        alert.view.tintColor = AppDelegate.redColor
        self.present(alert, animated: true) {
            //code to execute once the alert is showing
        }
        
    }
    
    func moveToFolder(folder: Folder, curWork: DBWorkItem) {
        curWork.folder = folder
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            #if DEBUG
                print("Could not save \(String(describing: error.userInfo))")
            #endif
        }
        
        loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        tableView.reloadData()
    }
    
    //MARK: - EditFoldersProtocol
    
     func foldersEdited() {
        loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        tableView.reloadData()
    }
    
    //MARK: - expanding
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        /*let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 21))
        label.textAlignment = .left
        label.tag = section
        label.textColor = AppDelegate.redColor
        
        if (section == 0) {
            label.text = "\(uncategorized) (\(downloadedWorkds[uncategorized]?.count ?? 0))"
        } else {
            let name = folders[section - 1].name ?? "No Name"
            label.text = "\(name) (\(downloadedWorkds[name]?.count ?? 0))"
        }*/
        
//        let vvv = tableView.headerView(forSection: section)
//        vvv?.tag = section
//
//        let tap = UITapGestureRecognizer(target: self, action: #selector(FavoritesViewController.tapFunction))
//        vvv?.isUserInteractionEnabled = true
//        vvv?.addGestureRecognizer(tap)
        
        let vvv = UITableViewHeaderFooterView()
        vvv.tag = section
        
                let tap = UITapGestureRecognizer(target: self, action: #selector(FavoritesViewController.tapFunction))
                vvv.isUserInteractionEnabled = true
                vvv.addGestureRecognizer(tap)
        
        return vvv
    }
    
    func tapFunction(sender:UITapGestureRecognizer) {
        let section = sender.view!.tag
        var folderName = ""
        if (section == 0) {
            folderName = uncategorized
        } else {
         folderName = folders[section - 1].name ?? "No Name"
        }
        let count = downloadedWorkds[folderName]?.count ?? 0
        let indexPaths = (0..<count).map { i in return IndexPath(item: i, section: section)  }
        
        hidden[section] = !hidden[section]
        
        tableView?.beginUpdates()
        if hidden[section] {
            tableView?.deleteRows(at: indexPaths, with: .fade)
        } else {
            tableView?.insertRows(at: indexPaths, with: .fade)
        }
        tableView?.endUpdates()
    }
    
    //https://codebasecamp.com/2016/12/02/Expandable-TableView/
    //https://www.appcoda.com/expandable-table-view/
    //https://newfivefour.com/swift-ios-expanding-uitableview-sections.html
    //https://github.com/HuyVuong1121/TreeTableView/tree/master/无级级树状TableView/YSTreeTableView/YSTreeTableView
    //https://github.com/younatics/YNExpandableCell
}
