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
import Firebase

class FavoritesViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, EditFoldersProtocol {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var sortButtonItem: UIBarButtonItem!
        
    var downloadedFandoms: [DBFandom] = []
    
    var selectedWork: DBWorkItem? = nil
    
    var showUpdatesOnly = false
    
    var resultSearchController = UISearchController()
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<DBWorkItem>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<DBWorkItem> = DBWorkItem.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
        
        if (showUpdatesOnly == true) {
            let predicate = NSPredicate(format: "needsUpdate == 1")
            fetchRequest.predicate = predicate
        }
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    var sortBy = "dateAdded"
    var sortOrderAscendic = false
    
    var folderName = LoadingViewController.uncategorized
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // self.createDrawerButton()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        
        //search
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.obscuresBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.tintColor =  UIColor(named: "global_tint")
            controller.searchBar.backgroundImage = UIImage()
            controller.searchBar.delegate = self
            
            if let tf = controller.searchBar.textField {
                addDoneButtonOnKeyboardTf(tf)
            }
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        sortBy = DefaultsManager.getString(DefaultsManager.SORT_DWNLD_BY)
        sortOrderAscendic = DefaultsManager.getBool(DefaultsManager.SORT_DWNLD_ASC) ?? false
        
        if (sortBy.isEmpty) {
            sortBy = "dateAdded"
        }
        
        var folderPredicate: NSPredicate = NSPredicate(format: "folder = nil")
       
        if (folderName != LoadingViewController.uncategorized) {
            folderPredicate = NSPredicate(format: "folder.name = %@", folderName)
        } else if (showUpdatesOnly == true) {
            folderPredicate = NSPredicate(format: "needsUpdate == 1")
        }
        self.fetchedResultsController?.fetchRequest.predicate = folderPredicate
        
        if (sortBy != "dateAdded" && sortBy != "progress") {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic, selector: #selector(NSString.localizedStandardCompare(_:)))]
        } else {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic)]
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        // Reload the table
        //self.tableView.reloadData()
        
        setupAccessibility()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showNav()
        
//        if (self.folderName == FavoritesViewController.uncategorized) {
//            loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
//        } else {
//            loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder.name = \(folderName)"))
//        }
        
       // tableView.reloadData()
        
        let titleDict: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict
        self.title = String(self.fetchedResultsController?.fetchedObjects?.count ?? 0) + " " + Localization("Downloaded")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.resultSearchController.isActive = false
        searchBarCancelButtonClicked(self.resultSearchController.searchBar)
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
    }
    
    func setupAccessibility() {
        self.sortButtonItem.accessibilityLabel = NSLocalizedString("SortBy", comment: "")
    }
    
//    @IBAction func restoreTouched(_ sender: AnyObject) {
//
//        DispatchQueue.global().async(execute: {
//            DispatchQueue.main.sync {
//                if (self.hasOldSaves(workItems: (self.fetchedResultsController?.fetchedObjects)!) == true) {
//                    self.showOldAlert()
//                } else {
//                    let deleteAlert = UIAlertController(title: "Restore Downloads", message: "Cannot find any lost downloads.", preferredStyle: UIAlertControllerStyle.alert)
//
//                    deleteAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction) in
//                        print("Cancel")
//                    }))
//
//                    deleteAlert.view.tintColor = UIColor(named: "global_tint")
//
//                    self.present(deleteAlert, animated: true, completion: nil)
//                }
//            }
//        })
//    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 46
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.folderName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        let cell:DownloadedCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! DownloadedCell
        
        let curWork: DBWorkItem? = self.fetchedResultsController?.object(at: indexPath)
        
        configureCell(curWork: curWork, cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(curWork: DBWorkItem?, cell: DownloadedCell, indexPath: IndexPath) {
        var title = curWork?.workTitle ?? "-"
        if (curWork?.needsUpdate ?? 0 == 1) {
            title = "🔄 \(title)"
        }
        cell.topicLabel.text = title
        
        var fandomsStr = ""
        if let downloadedFandoms = curWork?.mutableSetValue(forKey: "fandoms").allObjects as? [DBFandom] {
            for i in 0..<downloadedFandoms.count {
                let fandom = downloadedFandoms[i]
                fandomsStr += fandom.value(forKey: "fandomName") as? String ?? ""
                if (i < downloadedFandoms.count - 1) {
                    fandomsStr += " | "
                }
            }
        }
        cell.fandomsLabel.text = Localization("Fandoms_") + fandomsStr
        
        cell.wordsLabel.text = curWork?.words ?? "-"
        
        switch (curWork?.ratingTags ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            cell.ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            cell.ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            cell.ratingImg.image = UIImage(named: "R")
        case "Explicit":
            cell.ratingImg.image = UIImage(named: "NC17")
        default:
            cell.ratingImg.image = UIImage(named: "NotRated")
        }
        
        if (curWork?.topicPreview != nil) {
            cell.topicPreviewLabel.text = curWork?.topicPreview
        }
        else {
            cell.topicPreviewLabel.text = ""
        }
        
        cell.authorLabel.text = curWork?.author ?? "-"
        
        cell.datetimeLabel.text = curWork?.value(forKey: "datetime") as? String
        cell.languageLabel.text = curWork?.value(forKey: "language") as? String
        cell.chaptersLabel.text = curWork?.chaptersCount ?? "-"
        
        if let kudosNum: Float = Float(curWork?.value(forKey: "kudos") as? String ?? "0") {
            cell.kudosLabel.text =  kudosNum.formatUsingAbbrevation()
        } else {
            cell.kudosLabel.text = curWork?.value(forKey: "kudos") as? String
        }
        
        if let bookmarksNum: Float = Float(curWork?.value(forKey: "bookmarks") as? String ?? "0") {
            cell.bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
        } else {
            cell.bookmarksLabel.text = curWork?.value(forKey: "bookmarks") as? String
        }
        
        if let hitsNum: Float = Float(curWork?.value(forKey: "hits") as? String ?? "0") {
            cell.hitsLabel.text =  hitsNum.formatUsingAbbrevation()
        } else {
            cell.hitsLabel.text = curWork?.value(forKey: "hits") as? String
        }
        
        /*cell?.completeLabel.text = curWork.valueForKey("complete") as? String
         cell?.categoryLabel.text = curWork.valueForKey("category") as? String
         cell?.ratingLabel.text = curWork.valueForKey("ratingTags") as? String*/
        
        if let tags = curWork?.tags, tags.isEmpty == false {
            cell.tagsLabel.text = tags
        } else {
            var allTags = curWork?.archiveWarnings ?? ""
            if (allTags.isEmpty == false) {
                allTags.append(", ")
            }
            
            if let rels = curWork?.relationships {
                for case let rel as DBRelationship in rels  {
                    if let relName = rel.relationshipName, relName.isEmpty == false {
                        allTags.append(relName)
                        allTags.append(", ")
                    }
                }
            }
            
            if let characters = curWork?.characters {
                for case let character as DBCharacterItem in characters  {
                    if let charName = character.characterName, charName.isEmpty == false {
                        allTags.append(charName)
                        allTags.append(", ")
                    }
                }
            }
            
            if let freeTags = curWork?.freeform, freeTags.isEmpty == false {
                allTags.append(freeTags)
            }
            
            let lastChars = allTags.suffix(2)
            if lastChars == ", " {
                let index = allTags.index(allTags.endIndex, offsetBy: -2)
                allTags = String(allTags[..<index])
            }
            
            cell.tagsLabel.text = allTags
        }
        
        cell.deleteButton.btnIndexPath = indexPath
        cell.folderButton.btnIndexPath = indexPath
        
        cell.contentView.backgroundColor = UIColor(named: "cellBgColor")
        cell.backgroundColor = UIColor(named: "cellBgColor")
        cell.bgView.backgroundColor = UIColor(named: "bgViewColor")
        cell.topicLabel.textColor = UIColor(named: "textTitleColor")
        
        cell.languageLabel.textColor = UIColor(named: "textTagsColor")
        cell.datetimeLabel.textColor = UIColor(named: "textTagsColor")
        cell.chaptersLabel.textColor = UIColor(named: "textTagsColor")
        cell.authorLabel.textColor = UIColor(named: "textTagsColor")
        
        cell.topicPreviewLabel.textColor = UIColor(named: "textTopicColor")
        
        cell.kudosLabel.textColor = UIColor(named: "textWorkInfo")
        cell.chaptersLabel.textColor = UIColor(named: "textWorkInfo")
        cell.bookmarksLabel.textColor = UIColor(named: "textWorkInfo")
        cell.hitsLabel.textColor = UIColor(named: "textWorkInfo")
        cell.wordsLabel.textColor = UIColor(named: "textWorkInfo")
         
        cell.tagsLabel.textColor = UIColor(named: "textAdditionalInfo")
        
        cell.fandomsLabel.textColor = AppDelegate.greenColor
        
        cell.deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        cell.folderButton.setImage(UIImage(named: "folder"), for: .normal)
        
        let currentPosition = curWork?.progress ?? NSNumber(value:0)
        cell.readProgress.setProgress(currentPosition.floatValue, animated: false)
    }
    
    
    //MARK: - works
    
//    func showOldAlert() {
//        let deleteAlert = UIAlertController(title: "Lost Downloads ", message: "You have some lost downloaded works. What should I do with them?", preferredStyle: UIAlertControllerStyle.alert)
//
//        deleteAlert.addAction(UIAlertAction(title: "Delete Them All", style: .default, handler: { (action: UIAlertAction) in
//            print("Delete olds")
//            self.deleteOldSaves()
//        }))
//
//        deleteAlert.addAction(UIAlertAction(title: "Restore Them", style: .default, handler: { (action: UIAlertAction) in
//            self.showLoadingView(msg: "Restoring...")
//            self.copyOldWorksFromDB()
//            //self.deleteOldSaves()
//            self.hideLoadingView()
//            self.title = String(self.fetchedResultsController?.fetchedObjects?.count ?? 0) + " " + Localization("Downloaded")
//        }))
//
//        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
//            print("Cancel")
//        }))
//
//        deleteAlert.view.tintColor = UIColor(named: "global_tint")
//
//        present(deleteAlert, animated: true, completion: nil)
//    }
    
//    func deleteOldSaves() {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//            let managedContextOld = appDelegate.managedObjectContextOld else {
//                return
//        }
//
//        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
//        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//        do {
//            try managedContextOld.execute(request)
//        } catch {
//            #if DEBUG
//                print("cannot fetch favorites.")
//            #endif
//        }
//    }
    
//    func hasOldSaves(workItems: [DBWorkItem]) -> Bool {
//        var res = false
//
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//            let managedContextOld = appDelegate.managedObjectContextOld else {
//                return res
//        }
//
//        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
//        do {
//            if let fetchedResults = try managedContextOld.fetch(fetchRequest) as? [DBWorkItem] {
//                if fetchedResults.count > 0 {
//                    for fRes in fetchedResults {
//                        let predicate = NSPredicate(format: "workId == %@", fRes.workId ?? "")
//                        if let array = (workItems as NSArray?)?.filtered(using: predicate) as? [DBWorkItem] {
//                            if array.count == 0  {
//                            res = true
//                            }
//                        } else {
//                            res = true
//                        }
//                    }
//                }
//            }
//        } catch {
//            #if DEBUG
//                print("cannot fetch favorites.")
//            #endif
//        }
//
//        return res
//    }
//
//    func copyOldWorksFromDB() {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//            let managedContextOld = appDelegate.managedObjectContextOld else {
//                return
//        }
//        let managedContextNew = appDelegate.persistentContainer.viewContext
//
//        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
//        do {
//            if let fetchedResults = try managedContextOld.fetch(fetchRequest) as? [DBWorkItem] {
//
//            for resultItem in fetchedResults {
//                let entity = NSEntityDescription.entity(forEntityName: "DBWorkItem",  in: managedContextNew)
//                let newObj: NSManagedObject = NSManagedObject(entity: entity!, insertInto: managedContextNew)
//
//                let entityDescription = resultItem.entity
//                let attrs = entityDescription.attributesByName
//
//                for attr in attrs {
//                    newObj.setValue(resultItem.value(forKey: attr.key), forKey: attr.key)
//                }
//
//                var chaptersSet = [NSManagedObject]()
//
//                if let chaptersOld = resultItem.chapters {
//                    for chapterOld in chaptersOld {
//                        let entityC = NSEntityDescription.entity(forEntityName: "DBChapter",  in: managedContextNew)
//                        let newChapter: NSManagedObject = NSManagedObject(entity: entityC!, insertInto: managedContextNew)
//
//                        let entityDescriptionC = (chapterOld as? DBChapter)?.entity
//                        if let attrsC = entityDescriptionC?.attributesByName {
//
//                        for attr in attrsC {
//                            newChapter.setValue((chapterOld as? DBChapter)?.value(forKey: attr.key), forKey: attr.key)
//                        }
//                        chaptersSet.append(newChapter)
//                        }
//                    }
//                }
//
//                newObj.setValue(nil, forKey: "folder")
//
//                newObj.setValue(NSSet(array: chaptersSet), forKey: "chapters")
//
//                var fandomssSet = [NSManagedObject]()
//
//                if let fandomsOld = resultItem.fandoms {
//                    for fandomOld in fandomsOld {
//                        let entityF = NSEntityDescription.entity(forEntityName: "DBFandom",  in: managedContextNew)
//                        let newFandom: NSManagedObject = NSManagedObject(entity: entityF!, insertInto: managedContextNew)
//
//                        let entityDescriptionF = (fandomOld as? DBFandom)?.entity
//                        if let attrsF = entityDescriptionF?.attributesByName {
//
//                            for attr in attrsF {
//                                newFandom.setValue((fandomOld as? DBFandom)?.value(forKey: attr.key), forKey: attr.key)
//                            }
//                        }
//                        fandomssSet.append(newFandom)
//                    }
//                }
//
//                newObj.setValue(NSSet(array: fandomssSet), forKey: "fandoms")
//
//                var charsSet = [NSManagedObject]()
//
//                if let charactersOld = resultItem.characters {
//                    for characterOld in charactersOld {
//                        let entityCh = NSEntityDescription.entity(forEntityName: "DBCharacterItem",  in: managedContextNew)
//                        let newChar: NSManagedObject = NSManagedObject(entity: entityCh!, insertInto: managedContextNew)
//
//                        let entityDescriptionCh = (characterOld as? DBCharacterItem)?.entity
//                        if let attrsCh = entityDescriptionCh?.attributesByName {
//
//                            for attr in attrsCh {
//                                newChar.setValue((characterOld as? DBCharacterItem)?.value(forKey: attr.key), forKey: attr.key)
//                            }
//                        }
//                        charsSet.append(newChar)
//                    }
//                }
//
//                newObj.setValue(NSSet(array: charsSet), forKey: "characters")
//
//                var relsSet = [NSManagedObject]()
//
//                if let relsOld = resultItem.relationships {
//                    for relOld in relsOld {
//                        let entityR = NSEntityDescription.entity(forEntityName: "DBRelationship",  in: managedContextNew)
//                        let newRel: NSManagedObject = NSManagedObject(entity: entityR!, insertInto: managedContextNew)
//
//                        let entityDescriptionR = (relOld as? DBRelationship)?.entity
//                        if let attrsR = entityDescriptionR?.attributesByName {
//
//                            for attr in attrsR {
//                                newRel.setValue((relOld as? DBRelationship)?.value(forKey: attr.key), forKey: attr.key)
//                            }
//                        }
//                        relsSet.append(newRel)
//                    }
//                }
//
//                newObj.setValue(NSSet(array: relsSet), forKey: "relationships")
//            }
//
//                //delete old!
//            }
//        } catch {
//            #if DEBUG
//                print("cannot fetch favorites.")
//            #endif
//        }
//
//        appDelegate.saveContext()
//        hideLoadingView()
//
//    }
    
    /*func loadWroksFromDB(predicate: NSPredicate?, predicateWFolder: NSPredicate) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let managedContext = appDelegate.managedObjectContext else {
            return
        }
        if (sortBy.isEmpty == true) {
            sortBy = "dateAdded"
            sortOrderAscendic = false
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        
        if (sortBy != "dateAdded") {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic, selector: #selector(NSString.localizedStandardCompare(_:)))]
        } else {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic)]
        }
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
        
    }*/
    
    func loadFandomsFromWorks() {
        downloadedFandoms.removeAll()
        
        for wItem: DBWorkItem in (self.fetchedResultsController?.fetchedObjects!)! {
                if let wFandoms: [DBFandom] = wItem.fandoms?.allObjects as? [DBFandom] {
                    downloadedFandoms.append(contentsOf: wFandoms)
                }
        }
    }
    
    func numOfWorksInFandom(fandom: String) -> Int {
        var res = 0
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ LIMIT 1", fandom)
        let array = (self.fetchedResultsController?.fetchedObjects as NSArray?)?.filtered(using: searchPredicate)
        res = array?.count ?? 0
        
        return res
    }
    
    func getWorksInFandom(fandom: String) -> [NSManagedObject] {
        var res: [NSManagedObject] = []
        
        let searchPredicate = NSPredicate(format: "fandoms.fandomName CONTAINS[c] %@ ", fandom)
        if let array = (self.fetchedResultsController?.fetchedObjects as NSArray?)?.filtered(using: searchPredicate) as? [NSManagedObject] {
            res = array
        }
        
        return res
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                
        if(segue.identifier == "offlineWorkDetail") {
    
            guard let workDetail: WorkDetailViewController = segue.destination as? WorkDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow else {
                    return
            }
            
            let curWork: DBWorkItem? = self.fetchedResultsController?.object(at: indexPath)
            
            workDetail.downloadedWorkItem = curWork
             workDetail.modalDelegate = self
        } else if (segue.identifier == "editFoldersSegue") {
            let editController: EditFoldersController = segue.destination as! EditFoldersController
            if (self.selectedWork != nil) {
                editController.editFoldersProtocol = self
            }
          //  editController.folders = folders
        }
        
        hideBackTitle()
        
        self.resultSearchController.isActive = false
        searchBarCancelButtonClicked(self.resultSearchController.searchBar)
    }
    
    @IBAction func editTouched(_ sender: AnyObject) {
        self.selectedWork = nil
        self.performSegue(withIdentifier: "editFoldersSegue", sender: self)
    }
    
    @IBAction func addFolder(_ sender: AnyObject) {
        let fName = "Folder \(self.folderName) 1"
        showAddFolder(folderName: fName)
    }
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
            
            let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("DeleteFromDownloaded"), preferredStyle: UIAlertController.Style.alert)
            
            deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .default, handler: { (action: UIAlertAction) in
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
        
        deleteAlert.view.tintColor = UIColor(named: "global_tint")
        
            present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromDownloaded(_ indexPath: IndexPath) {
        guard let appDel:AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
         let context = appDel.persistentContainer.viewContext
        
        let curWork: DBWorkItem? = self.fetchedResultsController?.object(at: indexPath)
        
        let wId = curWork?.workId ?? "0"
        
        if let c = curWork {
            context.delete(c)
            //downloadedWorkds.remove(at: index)
        
            do {
                try context.save()
            } catch _ {
            }
            
            self.saveWorkNotifItem(workId: wId, wasDeleted: NSNumber(booleanLiteral: true))
            self.sendAllNotSentForDelete()
            
            //self.tableView.reloadData()
            // self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
            self.title = String(fetchedResultsController?.fetchedObjects?.count ?? 0) + " " + Localization("Downloaded")
        }
    }
    
    
    func controllerDidClosedWithChange() {
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    //MARK: - UISearchResultsUpdating delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let text = searchController.searchBar.text else {
            //self.tableView.reloadData()
            return
        }
        
        if text.isEmpty {
            //self.tableView.reloadData()
            return
        }
        
        
        let searchPredicate = NSPredicate(format: "topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@ OR fandoms.fandomName CONTAINS[cd] %@", text, text, text, text, text, text)
        
       // let predicateWFolder = NSPredicate(format: "folder = nil AND (topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@ OR fandoms.fandomName CONTAINS[cd] %@)", text, text, text, text, text, text)
//        let array = (Array(downloadedWorkds.values.joined()) as NSArray).filtered(using: searchPredicate)
//        filtereddownloadedWorkds = array as! [DBWorkItem]
        
        self.fetchedResultsController?.fetchRequest.predicate = searchPredicate
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("View Folders: updateSearchResults An error occurred")
        }
        
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
    
    func saveSortOptionsAndReload() {
        DefaultsManager.putBool(self.sortOrderAscendic, key: DefaultsManager.SORT_DWNLD_ASC)
        DefaultsManager.putString(self.sortBy, key: DefaultsManager.SORT_DWNLD_BY)
        
        if (sortBy != "dateAdded" && sortBy != "progress") {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic, selector: #selector(NSString.localizedStandardCompare(_:)))]
        } else {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic)]
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Downloaded: saveSortOptionsAndReload An error occurred")
        }
        self.tableView.reloadData()
        
        Answers.logCustomEvent(withName: "Downloaded: Sort", customAttributes: ["sortBy" : self.sortBy])
        Analytics.logEvent("Downloaded_Sort", parameters: ["sortBy" : self.sortBy as NSObject])
    }
    
    @IBAction func sortClicked(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: Localization("Sort Options"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        
        let azAction = UIAlertAction(title: Localization("Alphabetically"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "workTitle"
            self.sortOrderAscendic = true
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        
        let dateAction = UIAlertAction(title: Localization("Date Added"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "dateAdded"
            self.sortOrderAscendic = false
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(dateAction)
        
        let authorAction = UIAlertAction(title: Localization("Author"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "author"
            self.sortOrderAscendic = true
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(authorAction)
        
        
        //!!!!https://stackoverflow.com/questions/23005107/sort-descriptors-not-sorting-numbers-in-the-form-of-string-iphone !!!
        let kudosAction = UIAlertAction(title: Localization("Kudos Count"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "kudos"
            self.sortOrderAscendic = true
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(kudosAction)
        
        let chaptersAction = UIAlertAction(title: Localization("Word Count"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "words"
            self.sortOrderAscendic = true
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(chaptersAction)
        
//        let fandomsAction = UIAlertAction(title: Localization("Fandom"), style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            self.sortBy = kp// "fandoms.name"
//            self.sortOrderAscendic = true
//            
//            self.saveSortOptionsAndReload()
//        })
//        optionMenu.addAction(fandomsAction)
        
        let rpAction = UIAlertAction(title: Localization("Read Progress"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "progress"
            self.sortOrderAscendic = false
            
            debugLog(message: "Sort order set \(self.sortBy), asc \(self.sortOrderAscendic)")
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(rpAction)
        
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
    @IBAction func folderTouched(sender: ButtonWithSection) {
        /*if (folders.count == 0) {
            showNotification(in: self, title: Localization("Error"), subtitle: Localization("NoFolders"), type: .error)
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
        
        let alert = UIAlertController(title: Localization("MoveWork"), message: Localization("ChooseFolder"), preferredStyle: .actionSheet)
        
        for folder in folders {
            alert.addAction(UIAlertAction(title: folder.name ?? "No Name", style: .default, handler: { (action) in
                self.moveToFolder(folder: folder, curWork: cWork)
            }))
        }
        alert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action) in
            #if DEBUG
                print("cancel")
            #endif
        }))
        alert.view.tintColor = UIColor(named: "global_tint")
        
        alert.popoverPresentationController?.sourceView = self.tableView
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.navigationController?.navigationBar.bounds.height ?? 64, width: 1.0, height: 1.0)
        
        self.present(alert, animated: true) {
            //code to execute once the alert is showing
        }
        */
        
        let indexPath = sender.btnIndexPath
        let curWork: DBWorkItem? = self.fetchedResultsController?.object(at: indexPath)
        self.selectedWork = curWork
        
        performSegue(withIdentifier: "editFoldersSegue", sender: self)
    }
    
    func folderSelected(folder: Folder) {
        if (self.selectedWork != nil) {
            self.moveToFolder(folder: folder, curWork: self.selectedWork!)
        }
    }
    
    func moveToFolder(folder: Folder, curWork: DBWorkItem) {
        curWork.folder = folder
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
         let managedContext = appDelegate.persistentContainer.viewContext
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            #if DEBUG
                print("Could not save \(String(describing: error.userInfo))")
            #endif
        }
        
//        do {
//            try fetchedResultsController?.performFetch()
//        } catch {
//            print("Downloaded: saveSortOptionsAndReload An error occurred")
//        }
//
//        tableView.reloadData()
    }
    
    //https://codebasecamp.com/2016/12/02/Expandable-TableView/
    //https://www.appcoda.com/expandable-table-view/
    //https://newfivefour.com/swift-ios-expanding-uitableview-sections.html
    //https://github.com/HuyVuong1121/TreeTableView/tree/master/无级级树状TableView/YSTreeTableView/YSTreeTableView
    //https://github.com/younatics/YNExpandableCell
}

//MARK: - NSFetchedResultsControllerDelegate

extension FavoritesViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet([sectionIndex]), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet([sectionIndex]), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .update:
            if let indexPath = indexPath {
                let work = fetchedResultsController?.object(at: indexPath)
                guard let cell = tableView.cellForRow(at: indexPath) as? DownloadedCell else { break }
                configureCell(curWork: work, cell: cell, indexPath: indexPath)
            }
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                tableView.reloadSections([newIndexPath.section], with: .none)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
        }
    }
    
}

extension DBWorkItem {
    
    public func isEqualToItem(_ workItem: DBWorkItem?) -> Bool {
        if let rhs = workItem {
            return self.workId == rhs.workId
        }
        return false
    }
}
