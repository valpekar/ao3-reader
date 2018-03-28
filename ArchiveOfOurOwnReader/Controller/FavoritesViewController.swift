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

class FavoritesViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, EditFoldersProtocol, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    
    let uncategorized = "Uncategorized"
    
    var downloadedWorkds: [String : [DBWorkItem]] = [:]
    var downloadedFandoms: [DBFandom] = []
    var folders: [Folder] = []
    var filtereddownloadedWorkds: [String : [DBWorkItem]] = [:]
    
    var hidden:[Bool] = []
    
    var resultSearchController = UISearchController()
    
    var sortBy = "folder.name"
    var sortOrderAscendic = false
    
    var defSortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "folder.name", ascending: true)
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<DBWorkItem>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return nil
        }
        
        NSFetchedResultsController<DBWorkItem>.deleteCache(withName: "FavWorks")
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<DBWorkItem> = DBWorkItem.fetchRequest()
        
        if (sortBy.isEmpty == true) {
            sortBy = "folder.name"
            sortOrderAscendic = false
        }
        
        if (sortBy != "dateAdded") {
            fetchRequest.sortDescriptors = [defSortDescriptor, NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic, selector: #selector(NSString.localizedStandardCompare(_:)))]
        } else {
            fetchRequest.sortDescriptors = [defSortDescriptor, NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic)]
        }
        
        fetchRequest.predicate = nil
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "folder.name", cacheName: "FavWorks")
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        
        UserDefaults.standard.synchronize()
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
        if (purchased == false && donated == false) {
            loadAdMobInterstitial()
        }
        
        //search
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.tintColor = AppDelegate.redLightColor
            controller.searchBar.backgroundImage = UIImage()
            controller.searchBar.delegate = self
            
            if let tf = controller.searchBar.value(forKey: "_searchField") as? UITextField {
                addDoneButtonOnKeyboardTf(tf)
            }
            
            self.tableView.tableHeaderView = controller.searchBar
            
            return controller
        })()
        
        // Reload the table
        //self.tableView.reloadData()
        
        
//        if (hasOldSaves() == true) {
//            showOldAlert()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sortBy = DefaultsManager.getString(DefaultsManager.SORT_DWNLD_BY)
        sortOrderAscendic = DefaultsManager.getBool(DefaultsManager.SORT_DWNLD_ASC) ?? false
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        //loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        
        hidden.append(false)
        
        if let count = fetchedResultsController?.sections?.count {
            for _ in 1..<count {
                hidden.append(true)
            }
        }
        
        filtereddownloadedWorkds = downloadedWorkds
        
       // tableView.reloadData()
        reloadTableView()
        
        let titleDict: [NSAttributedStringKey : Any] = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.navigationController!.navigationBar.titleTextAttributes = titleDict
        self.title = "\(self.fetchedResultsController?.fetchedObjects?.count ?? 0) " + NSLocalizedString("Downloaded", comment: "")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showNav()
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
//        if (self.resultSearchController.isActive) {
//            if (section == 0) {
//                return filtereddownloadedWorkds[uncategorized]?.count ?? 0
//            } else {
//                return filtereddownloadedWorkds[folders[section - 1].name ?? "No Name"]?.count ?? 0
//            }
//        }
//        else {
//            if (hidden.count > section && hidden[section]) {
//                return 0
//            } else {
//            if (section == 0) {
//                return downloadedWorkds[uncategorized]?.count ?? 0
//            } else {
//                return downloadedWorkds[folders[section - 1].name ?? "No Name"]?.count ?? 0
//            }
//            }
//        }
        
        if (hidden.count > section && hidden[section]) {
            return 0
        } else {
            if let sections = fetchedResultsController?.sections {
                let currentSection = sections[section]
                if (currentSection.numberOfObjects == 0) {
                    return 0
                } else {
                    return currentSection.numberOfObjects
                }
            }
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
       // return folders.count + 1 //1 for uncategorized
        if let sections = fetchedResultsController?.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
//        if (self.resultSearchController.isActive) {
//            if (section == 0) {
//                return "\(uncategorized) (\(filtereddownloadedWorkds[uncategorized]?.count ?? 0))"
//            } else {
//                let name = folders[section - 1].name ?? "No Name"
//                return "\(name) (\(filtereddownloadedWorkds[name]?.count ?? 0))"
//            }
//        } else {
//            if (section == 0) {
//                return "\(uncategorized) (\(downloadedWorkds[uncategorized]?.count ?? 0))"
//            } else {
//                let name = folders[section - 1].name ?? "No Name"
//                return "\(name) (\(downloadedWorkds[name]?.count ?? 0))"
//            }
//        }
        
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            if (currentSection.name.isEmpty == true) {
                return "\(uncategorized) (\(currentSection.numberOfObjects))"
            } else {
                return "\(currentSection.name) (\(currentSection.numberOfObjects))"
            }
        }
        
        return "No Name"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell:DownloadedCell! = nil
        
        if let c:DownloadedCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DownloadedCell {
            cell = c
        } else {
            cell = DownloadedCell(reuseIdentifier: cellIdentifier)
        }
        
        var curWork: DBWorkItem?
        
        /*if (self.resultSearchController.isActive) {
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
        }*/
        
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[indexPath.section]
            if (currentSection.numberOfObjects == 0) {
                return cell
            }
        }
        
        curWork = fetchedResultsController?.object(at: indexPath)
        
        configureCell(cell: cell, curWork: curWork, indexPath: indexPath)
//
//        cell?.topicLabel.text = curWork?.workTitle ?? "-"
//
//        var fandomsStr = ""
//        if let downloadedFandoms = curWork?.mutableSetValue(forKey: "fandoms").allObjects as? [DBFandom] {
//        for i in 0..<downloadedFandoms.count {
//            let fandom = downloadedFandoms[i]
//            fandomsStr += fandom.value(forKey: "fandomName") as? String ?? ""
//            if (i < downloadedFandoms.count - 1) {
//                fandomsStr += " | "
//            }
//        }
//        }
//        cell?.fandomsLabel.text = NSLocalizedString("Fandoms_", comment: "") + fandomsStr
//
//        cell?.wordsLabel.text = curWork?.words ?? "-"
//
//        switch (curWork?.ratingTags ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
//        case "General Audiences":
//            cell?.ratingImg.image = UIImage(named: "G")
//        case "Teen And Up Audiences":
//            cell?.ratingImg.image = UIImage(named: "PG13")
//        case "Mature":
//            cell?.ratingImg.image = UIImage(named: "NC17")
//        case "Explicit":
//            cell?.ratingImg.image = UIImage(named: "R")
//        default:
//            cell?.ratingImg.image = UIImage(named: "NotRated")
//        }
//
//        if (curWork?.topicPreview != nil) {
//            cell?.topicPreviewLabel.text = curWork?.topicPreview
//        }
//        else {
//            cell?.topicPreviewLabel.text = ""
//        }
//
//        cell?.authorLabel.text = curWork?.author ?? "-"
//
//        cell?.datetimeLabel.text = curWork?.value(forKey: "datetime") as? String
//        cell?.languageLabel.text = curWork?.value(forKey: "language") as? String
//        cell?.chaptersLabel.text = curWork?.chaptersCount ?? "-"
//
//        if let kudosNum: Float = Float(curWork?.value(forKey: "kudos") as? String ?? "0") {
//            cell?.kudosLabel.text =  kudosNum.formatUsingAbbrevation()
//        } else {
//            cell?.kudosLabel.text = curWork?.value(forKey: "kudos") as? String
//        }
//
//        if let bookmarksNum: Float = Float(curWork?.value(forKey: "bookmarks") as? String ?? "0") {
//            cell?.bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
//        } else {
//            cell?.bookmarksLabel.text = curWork?.value(forKey: "bookmarks") as? String
//        }
//
//        if let hitsNum: Float = Float(curWork?.value(forKey: "hits") as? String ?? "0") {
//            cell?.hitsLabel.text =  hitsNum.formatUsingAbbrevation()
//        } else {
//            cell?.hitsLabel.text = curWork?.value(forKey: "hits") as? String
//        }
//
//        /*cell?.completeLabel.text = curWork.valueForKey("complete") as? String
//        cell?.categoryLabel.text = curWork.valueForKey("category") as? String
//        cell?.ratingLabel.text = curWork.valueForKey("ratingTags") as? String*/
//
//        if let tags = curWork?.tags, tags.isEmpty == false {
//            cell?.tagsLabel.text = tags
//        } else {
//            var allTags = curWork?.archiveWarnings ?? ""
//            if (allTags.isEmpty == false) {
//                allTags.append(", ")
//            }
//
//            if let rels = curWork?.relationships {
//                for case let rel as DBRelationship in rels  {
//                    if let relName = rel.relationshipName, relName.isEmpty == false {
//                        allTags.append(relName)
//                        allTags.append(", ")
//                    }
//                }
//            }
//
//            if let characters = curWork?.characters {
//                for case let character as DBCharacterItem in characters  {
//                    if let charName = character.characterName, charName.isEmpty == false {
//                        allTags.append(charName)
//                        allTags.append(", ")
//                    }
//                }
//            }
//
//            if let freeTags = curWork?.freeform, freeTags.isEmpty == false {
//                allTags.append(freeTags)
//            }
//
//            let lastChars = allTags.suffix(2)
//            if lastChars == ", " {
//                let index = allTags.index(allTags.endIndex, offsetBy: -2)
//                allTags = String(allTags[..<index])
//            }
//
//            cell?.tagsLabel.text = allTags
//        }
//
//        cell?.deleteButton.btnIndexPath = indexPath
//        cell?.folderButton.btnIndexPath = indexPath
//
//        if (theme == DefaultsManager.THEME_DAY) {
//            cell.backgroundColor = AppDelegate.greyLightBg
//            cell.bgView.backgroundColor = UIColor.white
//            cell.topicLabel.textColor = AppDelegate.redColor
//            cell.languageLabel.textColor = AppDelegate.redColor
//            cell.datetimeLabel.textColor = AppDelegate.redColor
//            cell.chaptersLabel.textColor = AppDelegate.redColor
//            cell.authorLabel.textColor = AppDelegate.redColor
//            cell.topicPreviewLabel.textColor = UIColor.black
//            cell.tagsLabel.textColor = AppDelegate.darkerGreyColor
//            cell.kudosLabel.textColor = AppDelegate.redColor
//            cell.chaptersLabel.textColor = AppDelegate.redColor
//            cell.bookmarksLabel.textColor = AppDelegate.redColor
//            cell.hitsLabel.textColor = AppDelegate.redColor
//            cell.wordsLabel.textColor = AppDelegate.redColor
//
//            cell.wordImg.image = UIImage(named: "word")
//            cell.chaptersImg.image = UIImage(named: "chapters")
//            cell.kudosImg.image = UIImage(named: "likes")
//            cell.bmkImg.image = UIImage(named: "bookmark")
//            cell.hitsImg.image = UIImage(named: "hits")
//
//            cell.deleteButton.setImage(UIImage(named: "trash"), for: .normal)
//            cell.folderButton.setImage(UIImage(named: "folder"), for: .normal)
//
//        } else {
//            cell.backgroundColor = AppDelegate.greyDarkBg
//            cell.bgView.backgroundColor = AppDelegate.greyBg
//            cell.topicLabel.textColor = AppDelegate.textLightColor
//            cell.languageLabel.textColor = AppDelegate.greyLightColor
//            cell.datetimeLabel.textColor = AppDelegate.greyLightColor
//            cell.chaptersLabel.textColor = AppDelegate.greyLightColor
//            cell.authorLabel.textColor = AppDelegate.greyLightColor
//            cell.topicPreviewLabel.textColor = AppDelegate.textLightColor
//            cell.tagsLabel.textColor = AppDelegate.redTextColor
//            cell.tagsLabel.textColor = AppDelegate.greyLightColor
//            cell.kudosLabel.textColor = AppDelegate.darkerGreyColor
//            cell.chaptersLabel.textColor = AppDelegate.darkerGreyColor
//            cell.bookmarksLabel.textColor = AppDelegate.darkerGreyColor
//            cell.hitsLabel.textColor = AppDelegate.darkerGreyColor
//            cell.wordsLabel.textColor = AppDelegate.darkerGreyColor
//
//            cell.wordImg.image = UIImage(named: "word_light")
//            cell.chaptersImg.image = UIImage(named: "chapters_light")
//            cell.kudosImg.image = UIImage(named: "likes_light")
//            cell.bmkImg.image = UIImage(named: "bookmark_light")
//            cell.hitsImg.image = UIImage(named: "hits_light")
//
//            cell.deleteButton.setImage(UIImage(named: "trash_light"), for: .normal)
//            cell.folderButton.setImage(UIImage(named: "folder_light"), for: .normal)
//        }
//
//        cell.fandomsLabel.textColor = AppDelegate.greenColor
        
        return cell!
    }
    
    func configureCell(cell: DownloadedCell?, curWork: DBWorkItem?, indexPath: IndexPath) {
        
        cell?.topicLabel.text = curWork?.workTitle ?? "-"
        
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
        cell?.fandomsLabel.text = NSLocalizedString("Fandoms_", comment: "") + fandomsStr
        
        cell?.wordsLabel.text = curWork?.words ?? "-"
        
        switch (curWork?.ratingTags ?? "").trimmingCharacters(in: .whitespacesAndNewlines) {
        case "General Audiences":
            cell?.ratingImg.image = UIImage(named: "G")
        case "Teen And Up Audiences":
            cell?.ratingImg.image = UIImage(named: "PG13")
        case "Mature":
            cell?.ratingImg.image = UIImage(named: "NC17")
        case "Explicit":
            cell?.ratingImg.image = UIImage(named: "R")
        default:
            cell?.ratingImg.image = UIImage(named: "NotRated")
        }
        
        if (curWork?.topicPreview != nil) {
            cell?.topicPreviewLabel.text = curWork?.topicPreview
        }
        else {
            cell?.topicPreviewLabel.text = ""
        }
        
        cell?.authorLabel.text = curWork?.author ?? "-"
        
        cell?.datetimeLabel.text = curWork?.value(forKey: "datetime") as? String
        cell?.languageLabel.text = curWork?.value(forKey: "language") as? String
        cell?.chaptersLabel.text = curWork?.chaptersCount ?? "-"
        
        if let kudosNum: Float = Float(curWork?.value(forKey: "kudos") as? String ?? "0") {
            cell?.kudosLabel.text =  kudosNum.formatUsingAbbrevation()
        } else {
            cell?.kudosLabel.text = curWork?.value(forKey: "kudos") as? String
        }
        
        if let bookmarksNum: Float = Float(curWork?.value(forKey: "bookmarks") as? String ?? "0") {
            cell?.bookmarksLabel.text =  bookmarksNum.formatUsingAbbrevation()
        } else {
            cell?.bookmarksLabel.text = curWork?.value(forKey: "bookmarks") as? String
        }
        
        if let hitsNum: Float = Float(curWork?.value(forKey: "hits") as? String ?? "0") {
            cell?.hitsLabel.text =  hitsNum.formatUsingAbbrevation()
        } else {
            cell?.hitsLabel.text = curWork?.value(forKey: "hits") as? String
        }
        
        /*cell?.completeLabel.text = curWork.valueForKey("complete") as? String
         cell?.categoryLabel.text = curWork.valueForKey("category") as? String
         cell?.ratingLabel.text = curWork.valueForKey("ratingTags") as? String*/
        
        if let tags = curWork?.tags, tags.isEmpty == false {
            cell?.tagsLabel.text = tags
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
            
            cell?.tagsLabel.text = allTags
        }
        
        cell?.deleteButton.btnIndexPath = indexPath
        cell?.folderButton.btnIndexPath = indexPath
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell?.backgroundColor = AppDelegate.greyLightBg
            cell?.bgView.backgroundColor = UIColor.white
            cell?.topicLabel.textColor = AppDelegate.redColor
            cell?.languageLabel.textColor = AppDelegate.redColor
            cell?.datetimeLabel.textColor = AppDelegate.redColor
            cell?.chaptersLabel.textColor = AppDelegate.redColor
            cell?.authorLabel.textColor = AppDelegate.redColor
            cell?.topicPreviewLabel.textColor = UIColor.black
            cell?.tagsLabel.textColor = AppDelegate.darkerGreyColor
            cell?.kudosLabel.textColor = AppDelegate.redColor
            cell?.chaptersLabel.textColor = AppDelegate.redColor
            cell?.bookmarksLabel.textColor = AppDelegate.redColor
            cell?.hitsLabel.textColor = AppDelegate.redColor
            cell?.wordsLabel.textColor = AppDelegate.redColor
            
            cell?.wordImg.image = UIImage(named: "word")
            cell?.chaptersImg.image = UIImage(named: "chapters")
            cell?.kudosImg.image = UIImage(named: "likes")
            cell?.bmkImg.image = UIImage(named: "bookmark")
            cell?.hitsImg.image = UIImage(named: "hits")
            
            cell?.deleteButton.setImage(UIImage(named: "trash"), for: .normal)
            cell?.folderButton.setImage(UIImage(named: "folder"), for: .normal)
            
        } else {
            cell?.backgroundColor = AppDelegate.greyDarkBg
            cell?.bgView.backgroundColor = AppDelegate.greyBg
            cell?.topicLabel.textColor = AppDelegate.textLightColor
            cell?.languageLabel.textColor = AppDelegate.greyLightColor
            cell?.datetimeLabel.textColor = AppDelegate.greyLightColor
            cell?.chaptersLabel.textColor = AppDelegate.greyLightColor
            cell?.authorLabel.textColor = AppDelegate.greyLightColor
            cell?.topicPreviewLabel.textColor = AppDelegate.textLightColor
            cell?.tagsLabel.textColor = AppDelegate.redTextColor
            cell?.tagsLabel.textColor = AppDelegate.greyLightColor
            cell?.kudosLabel.textColor = AppDelegate.darkerGreyColor
            cell?.chaptersLabel.textColor = AppDelegate.darkerGreyColor
            cell?.bookmarksLabel.textColor = AppDelegate.darkerGreyColor
            cell?.hitsLabel.textColor = AppDelegate.darkerGreyColor
            cell?.wordsLabel.textColor = AppDelegate.darkerGreyColor
            
            cell?.wordImg.image = UIImage(named: "word_light")
            cell?.chaptersImg.image = UIImage(named: "chapters_light")
            cell?.kudosImg.image = UIImage(named: "likes_light")
            cell?.bmkImg.image = UIImage(named: "bookmark_light")
            cell?.hitsImg.image = UIImage(named: "hits_light")
            
            cell?.deleteButton.setImage(UIImage(named: "trash_light"), for: .normal)
            cell?.folderButton.setImage(UIImage(named: "folder_light"), for: .normal)
        }
        
        cell?.fandomsLabel.textColor = AppDelegate.greenColor
    }
    
    //MARK: - NSFetchedResultsController
    
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
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                let workItem = fetchedResultsController?.object(at: indexPath)
                guard let cell = tableView.cellForRow(at: indexPath) as? DownloadedCell else { break }
                configureCell(cell: cell, curWork: workItem, indexPath: indexPath)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
            if let newIndexPath = newIndexPath {
                if (hidden.count > newIndexPath.section && hidden[newIndexPath.section] == false) {
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                tableView.reloadSections([newIndexPath.section], with: .none)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
        }
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
    
    func showOldAlert() {
        let deleteAlert = UIAlertController(title: "Lost Downloads ", message: "You have some lost downloaded works. What should I do with them?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Delete Them All", style: .default, handler: { (action: UIAlertAction) in
            print("Delete olds")
            self.deleteOldSaves()
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Restore Them", style: .default, handler: { (action: UIAlertAction) in
            self.showLoadingView(msg: "Restoring...")
            self.copyOldWorksFromDB()
            self.deleteOldSaves()
            self.hideLoadingView()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteOldSaves() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContextOld = appDelegate.managedObjectContextOld else {
                return
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managedContextOld.execute(request)
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
    }
    
    func hasOldSaves() -> Bool {
        var res = false
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContextOld = appDelegate.managedObjectContextOld else {
                return res
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        do {
            if let fetchedResults = try managedContextOld.fetch(fetchRequest) as? [DBWorkItem] {
                if fetchedResults.count > 0 {
                    res = true
                }
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
                
        return res
    }
    
    func copyOldWorksFromDB() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContextOld = appDelegate.managedObjectContextOld,
            let managedContextNew = appDelegate.managedObjectContext else {
                return
        }
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        do {
            if let fetchedResults = try managedContextOld.fetch(fetchRequest) as? [DBWorkItem] {
            
            for resultItem in fetchedResults {
                let entity = NSEntityDescription.entity(forEntityName: "DBWorkItem",  in: managedContextNew)
                let newObj: NSManagedObject = NSManagedObject(entity: entity!, insertInto: managedContextNew)
                
                let entityDescription = resultItem.entity
                let attrs = entityDescription.attributesByName
                
                for attr in attrs {
                    newObj.setValue(resultItem.value(forKey: attr.key), forKey: attr.key)
                }
                
                var chaptersSet = [NSManagedObject]()
                
                if let chaptersOld = resultItem.chapters {
                    for chapterOld in chaptersOld {
                        let entityC = NSEntityDescription.entity(forEntityName: "DBChapter",  in: managedContextNew)
                        let newChapter: NSManagedObject = NSManagedObject(entity: entityC!, insertInto: managedContextNew)
                    
                        let entityDescriptionC = (chapterOld as? DBChapter)?.entity
                        if let attrsC = entityDescriptionC?.attributesByName {
                    
                        for attr in attrsC {
                            newChapter.setValue((chapterOld as? DBChapter)?.value(forKey: attr.key), forKey: attr.key)
                        }
                        chaptersSet.append(newChapter)
                        }
                    }
                }
                
                newObj.setValue(NSSet(array: chaptersSet), forKey: "chapters")
                
                var fandomssSet = [NSManagedObject]()
                
                if let fandomsOld = resultItem.fandoms {
                    for fandomOld in fandomsOld {
                        let entityF = NSEntityDescription.entity(forEntityName: "DBFandom",  in: managedContextNew)
                        let newFandom: NSManagedObject = NSManagedObject(entity: entityF!, insertInto: managedContextNew)
                        
                        let entityDescriptionF = (fandomOld as? DBFandom)?.entity
                        if let attrsF = entityDescriptionF?.attributesByName {
                            
                            for attr in attrsF {
                                newFandom.setValue((fandomOld as? DBFandom)?.value(forKey: attr.key), forKey: attr.key)
                            }
                        }
                        fandomssSet.append(newFandom)
                    }
                }
                
                newObj.setValue(NSSet(array: fandomssSet), forKey: "fandoms")
                
                var charsSet = [NSManagedObject]()
                
                if let charactersOld = resultItem.characters {
                    for characterOld in charactersOld {
                        let entityCh = NSEntityDescription.entity(forEntityName: "DBCharacterItem",  in: managedContextNew)
                        let newChar: NSManagedObject = NSManagedObject(entity: entityCh!, insertInto: managedContextNew)
                        
                        let entityDescriptionCh = (characterOld as? DBCharacterItem)?.entity
                        if let attrsCh = entityDescriptionCh?.attributesByName {
                            
                            for attr in attrsCh {
                                newChar.setValue((characterOld as? DBCharacterItem)?.value(forKey: attr.key), forKey: attr.key)
                            }
                        }
                        charsSet.append(newChar)
                    }
                }
                
                newObj.setValue(NSSet(array: charsSet), forKey: "characters")
                
                var relsSet = [NSManagedObject]()
                
                if let relsOld = resultItem.relationships {
                    for relOld in relsOld {
                        let entityR = NSEntityDescription.entity(forEntityName: "DBRelationship",  in: managedContextNew)
                        let newRel: NSManagedObject = NSManagedObject(entity: entityR!, insertInto: managedContextNew)
                        
                        let entityDescriptionR = (relOld as? DBRelationship)?.entity
                        if let attrsR = entityDescriptionR?.attributesByName {
                            
                            for attr in attrsR {
                                newRel.setValue((relOld as? DBRelationship)?.value(forKey: attr.key), forKey: attr.key)
                            }
                        }
                        relsSet.append(newRel)
                    }
                }
                
                newObj.setValue(NSSet(array: relsSet), forKey: "relationships")
            }
                
                //delete old!
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        do {
            try managedContextNew.save()
            hideLoadingView()
        } catch let error as NSError {
            #if DEBUG
                print("Could not save \(String(describing: error.userInfo))")
            #endif
            
        }
    }
    
    func loadWroksFromDB(predicate: NSPredicate?, predicateWFolder: NSPredicate) {
        folders.removeAll()
        
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
    
            guard let workDetail: WorkDetailViewController = segue.destination as? WorkDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow else {
                    return
            }
            
            let curWork: DBWorkItem? = self.fetchedResultsController?.object(at: indexPath)
            
   /*         if (self.resultSearchController.isActive) {
                if (indexPath.section == 0) {
                    curWork = (filtereddownloadedWorkds["Uncategorized"])?[indexPath.row]
                } else if (indexPath.section - 1 < folders.count) {
                    let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                    curWork = (filtereddownloadedWorkds[curFolderName])?[indexPath.row]
                }
//                if ((tableView.indexPathForSelectedRow!.row < filtereddownloadedWorkds.count ) {
//                    curWork = filtereddownloadedWorkds[tableView.indexPathForSelectedRow!.row]
//                }
            } else {
                if (indexPath.section == 0) {
                    curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
                } else if (indexPath.section - 1 < folders.count) {
                    let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
                    curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
                }
            } */
            
            
            
            workDetail.downloadedWorkItem = curWork
             workDetail.modalDelegate = self
        } else if (segue.identifier == "editFoldersSegue") {
            let editController: EditFoldersController = segue.destination as! EditFoldersController
            editController.editFoldersProtocol = self
           // editController.folders =
            
        }
        
        hideBackTitle()
        
        self.resultSearchController.isActive = false
        searchBarCancelButtonClicked(self.resultSearchController.searchBar)
    }
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
            
            let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("DeleteFromDownloaded", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
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
        
//        var curWork: DBWorkItem?
//        if (indexPath.section == 0) {
//            curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
//        } else if (indexPath.section - 1 < folders.count) {
//            let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
//            curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
//        }
        
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
            
           // loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
            
           // self.tableView.reloadData()
           // // self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
            self.title = "\(self.fetchedResultsController?.fetchedObjects?.count ?? 0) " + NSLocalizedString("Downloaded", comment: "")
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
        filtereddownloadedWorkds = downloadedWorkds
    }
    
    //MARK: - UISearchResultsUpdating delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        
        var searchPredicate: NSPredicate? = nil
        
        if let text = searchController.searchBar.text, text.isEmpty == false {
            searchPredicate = NSPredicate(format: "topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@ OR fandoms.fandomName CONTAINS[cd] %@ OR folder.name CONTAINS[cd] %@", text, text, text, text, text, text , text)
        }
        
        filtereddownloadedWorkds.removeAll(keepingCapacity: false)
        
        
 //       let predicateWFolder = NSPredicate(format: "folder = nil AND (topic CONTAINS[cd] %@ OR topicPreview CONTAINS[cd] %@ OR tags CONTAINS[cd] %@ OR author CONTAINS[cd] %@ OR workTitle CONTAINS[cd] %@ OR fandoms.fandomName CONTAINS[cd] %@)", text, text, text, text, text, text)
//        let array = (Array(downloadedWorkds.values.joined()) as NSArray).filtered(using: searchPredicate)
//        filtereddownloadedWorkds = array as! [DBWorkItem]
        
        self.fetchedResultsController?.fetchRequest.predicate = searchPredicate
        
        NSFetchedResultsController<DBWorkItem>.deleteCache(withName: "FavWorks")
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        //loadWroksFromDB(predicate: searchPredicate, predicateWFolder: predicateWFolder)
        
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
        
        if (sortBy != "dateAdded") {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [defSortDescriptor, NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic, selector: #selector(NSString.localizedStandardCompare(_:)))]
        } else {
            self.fetchedResultsController?.fetchRequest.sortDescriptors = [defSortDescriptor, NSSortDescriptor(key: sortBy, ascending: sortOrderAscendic)]
        }
        
        NSFetchedResultsController<DBWorkItem>.deleteCache(withName: "FavWorks")
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
//        self.loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
        self.tableView.reloadData()
        
        Answers.logCustomEvent(withName: "Downloaded: Sort", customAttributes: ["sortBy" : self.sortBy])
    }
    
    @IBAction func sortClicked(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("Sort Options", comment: ""), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        let azAction = UIAlertAction(title: NSLocalizedString("Alphabetically", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "workTitle"
            self.sortOrderAscendic = true
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        
        let dateAction = UIAlertAction(title: NSLocalizedString("By Date Added", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "dateAdded"
            self.sortOrderAscendic = false
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(dateAction)
        
        let authorAction = UIAlertAction(title: NSLocalizedString("By Author", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "author"
            self.sortOrderAscendic = true
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(authorAction)
        
        //!!!!https://stackoverflow.com/questions/23005107/sort-descriptors-not-sorting-numbers-in-the-form-of-string-iphone !!!
        let kudosAction = UIAlertAction(title: NSLocalizedString("Kudos Count", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "kudos"
            self.sortOrderAscendic = true
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(kudosAction)
        
        let chaptersAction = UIAlertAction(title: NSLocalizedString("Word Count", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "words"
            self.sortOrderAscendic = true
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(chaptersAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: - folders
    
    func addFolder(curWork: DBWorkItem) {
        let alert = UIAlertController(title: "Group", message: "Add New Group", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.text = "Folder \(self.folders.count + 1)"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if let txt = textField?.text {
                
                if let folder = self.addNewFolder(name: txt) {
                    self.moveToFolder(folder: folder, curWork: curWork)
                }
                Answers.logCustomEvent(withName: "New_folder",
                                   customAttributes: [
                                    "name": txt])
                
                do {
                    try self.fetchedResultsController?.performFetch()
                } catch {
                    print("An error occurred")
                }
                
                self.tableView.reloadData()
                
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
    
    func addNewFolder(name: String) -> Folder? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return nil
        }
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Folder")
        let predicate = NSPredicate(format: "name == %@", name)
        req.predicate = predicate
        do {
            if let fetchedWorks = try managedContext.fetch(req) as? [Folder] {
                if (fetchedWorks.count > 0) {
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderAlreadyExists", comment: ""), type: .error)
                    return nil
                }
            }
        } catch {
            fatalError("Failed to fetch folders: \(error)")
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Folder",  in: managedContext) else {
                return nil
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
        
        return newFolder
        
       // loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
       // tableView.reloadData()
    }
    
    @IBAction func folderTouched(sender: ButtonWithSection) {
        
        if (self.fetchedResultsController?.sections?.count == 0) {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("NoFolders", comment: ""), type: .error)
            return
        }
        
        let indexPath = sender.btnIndexPath
        
//        var curWork: DBWorkItem?
//
//        if (indexPath.section == 0) {
//            curWork = (downloadedWorkds["Uncategorized"])?[indexPath.row]
//        } else if (indexPath.section - 1 < folders.count) {
//            let curFolderName: String = folders[indexPath.section - 1].name ?? "No Name"
//            curWork = (downloadedWorkds[curFolderName])?[indexPath.row]
//        }
//
        
        let curWork = fetchedResultsController?.object(at: indexPath)
        
        guard let _ = curWork else {
            return
        }
        
        var delay = 0
        if (self.resultSearchController.isActive == true) {
            self.searchBarCancelButtonClicked(self.resultSearchController.searchBar)
            delay = 200
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
            let alert = UIAlertController(title: NSLocalizedString("MoveWork", comment: ""), message: NSLocalizedString("ChooseFolder", comment: ""), preferredStyle: .actionSheet)
            
            if let sections = self.fetchedResultsController?.sections {
                for section in sections {
                    if section.name.isEmpty {
                        alert.addAction(UIAlertAction(title: "\(self.uncategorized)", style: .default, handler: { (action) in
                            self.moveToFolder(folder: nil, curWork: curWork!)
                        }))
                    } else if let object = section.objects?.first as? DBWorkItem, let folder = object.folder {
                        alert.addAction(UIAlertAction(title: folder.name ?? "No Name", style: .default, handler: { (action) in
                            self.moveToFolder(folder: folder, curWork: curWork!)
                        }))
                    }
                }
            }
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Add New Group...", comment: ""), style: .default, handler: { (action) in
                self.addFolder(curWork: curWork!)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                #if DEBUG
                    print("cancel")
                #endif
            }))
            alert.view.tintColor = AppDelegate.redColor
            
            alert.popoverPresentationController?.sourceView = self.tableView
            alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.navigationController?.navigationBar.bounds.height ?? 64, width: 1.0, height: 1.0)
            
            self.present(alert, animated: true) {
                //code to execute once the alert is showing
            }
        }
                
    }
    
    func moveToFolder(folder: Folder?, curWork: DBWorkItem) {
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
        
       // loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
       // tableView.reloadData()
    }
    
    //MARK: - EditFoldersProtocol
    
     func foldersEdited() {
//        loadWroksFromDB(predicate: nil, predicateWFolder: NSPredicate(format: "folder = nil"))
//        tableView.reloadData()
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
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        guard let section = sender.view?.tag else {
            return
        }
//        var folderName = ""
//        if (section == 0) {
//            folderName = uncategorized
//        } else if (section - 1 < folders.count) {
//            folderName = folders[section - 1].name ?? "No Name"
//        } else {
//            return
//        }
//        guard let count = downloadedWorkds[folderName]?.count else {
//            return
//        }
        
        guard let sections = fetchedResultsController?.sections else {
            return
        }
        
        let currentSection = sections[section]
        let count = currentSection.numberOfObjects
        
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
