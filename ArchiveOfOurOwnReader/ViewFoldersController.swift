//
//  ViewFoldersController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/11/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import TSMessages

class ViewFoldersController: LoadingViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var unCatButton:UIButton!
    @IBOutlet weak var searchBar:UISearchBar!
    
    var sortBy = "date"
    
    var selectedFolderName = FavoritesViewController.uncategorized
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Folder>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return nil
        }
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Folder> = Folder.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            self.view.backgroundColor = AppDelegate.redDarkColor
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.unCatButton.setTitleColor(AppDelegate.textLightColor, for: UIControlState.normal)
        } else {
            self.view.backgroundColor = AppDelegate.greyLightBg
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.unCatButton.setTitleColor(AppDelegate.redDarkColor, for: UIControlState.normal)
        }
        
        self.sortBy = DefaultsManager.getString(DefaultsManager.SORT_FOLDERS)
        if (self.sortBy.isEmpty) {
            self.sortBy = "date"
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.tableFooterView = UIView()
        
        unCatButton.setTitle(FavoritesViewController.uncategorized, for: UIControlState.normal)
        unCatButton.contentHorizontalAlignment = .left
        
        // self.highlights = self.getAllHighlights()
        // self.tableView.reloadData()
        // self.updateView()
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        self.updateView()
        
        Answers.logCustomEvent(withName: "View Folders", customAttributes: ["count" : fetchedResultsController?.fetchedObjects?.count ?? 0])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateView()
    }
    
    private func updateView() {
        var fl = "Groups"
        let count = fetchedResultsController?.fetchedObjects?.count ?? 0
        if (count == 1) {
            fl = "Group"
        }
        self.title = "\(count) \(fl)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showFolderSegue") {
            
            if let favsController: FavoritesViewController = segue.destination as? FavoritesViewController {
                favsController.folderName = selectedFolderName
            }
            
        } else if (segue.identifier == "editFoldersSegue") {
            if let editController: EditFoldersController = segue.destination as? EditFoldersController {
                //editController.editFoldersProtocol = self
                editController.folders = fetchedResultsController?.fetchedObjects ?? []
            }
        }
    }
    
    @IBAction func editTouched(_ sender: AnyObject) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        performSegue(withIdentifier: "editFoldersSegue", sender: self)
    }
    
    @IBAction func unCatTouched(_ sender: AnyObject) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        selectedFolderName = FavoritesViewController.uncategorized
        performSegue(withIdentifier: "showFolderSegue", sender: self)
    }
    
    @IBAction func sortFoldersTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("Sort Options", comment: ""), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        let dateAction = UIAlertAction(title: NSLocalizedString("By Date Added", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "date"
            
            self.saveSortOptionsAndReload()
        })
        
        let azAction = UIAlertAction(title: NSLocalizedString("By Name", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "name"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        optionMenu.addAction(dateAction)
        
//        let authorAction = UIAlertAction(title: NSLocalizedString("By Works Count", comment: ""), style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            self.sortBy = "works.count"
//
//            self.saveSortOptionsAndReload()
//        })
//        optionMenu.addAction(authorAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: - sort
    
    func saveSortOptionsAndReload() {
        DefaultsManager.putString(self.sortBy, key: DefaultsManager.SORT_FOLDERS)
        
        self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("View Folders: saveSortOptionsAndReload An error occurred")
        }
        
        self.tableView.reloadData()
        
        Answers.logCustomEvent(withName: "View Folders: Sort", customAttributes: ["sortBy" : self.sortBy])
    }
    
    //MARK: - folders
    
    @IBAction func addFolder(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Folder", message: "Add New Group", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.text = "Folder \((self.fetchedResultsController?.fetchedObjects?.count ?? 0) + 1)"
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
        
//        tableView.reloadData()
    }
    
    override func doneButtonAction() {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        //self.tableView.endEditing(true)
        //self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
}

//MARK: Tableview

extension ViewFoldersController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Groups"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderCell")!
        
        let folder = fetchedResultsController?.object(at: indexPath)
        configureCell(cell: cell, folder: folder, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: UITableViewCell, folder: Folder?, indexPath: IndexPath) {
        cell.textLabel?.text = folder?.name ?? ""
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.textLabel?.textColor = AppDelegate.redDarkColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.textLabel?.textColor = AppDelegate.textLightColor
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        if let selectedFolder = fetchedResultsController?.object(at: indexPath) {
            selectedFolderName = selectedFolder.name ?? FavoritesViewController.uncategorized
            performSegue(withIdentifier: "showFolderSegue", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    
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
                let folder = fetchedResultsController?.object(at: indexPath)
                guard let cell = tableView.cellForRow(at: indexPath) else { break }
                configureCell(cell: cell, folder: folder, indexPath: indexPath)
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

extension ViewFoldersController: UISearchResultsUpdating, UISearchBarDelegate {
    
    //MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }
    
    //MARK: - UISearchResultsUpdating delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        
        var searchPredicate: NSPredicate? = nil
        
        if let text = searchController.searchBar.text, text.isEmpty == false {
           searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        }
        
        self.fetchedResultsController?.fetchRequest.predicate = searchPredicate
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("View Folders: updateSearchResults An error occurred")
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        self.tableView.endEditing(true)
        
        tableView.reloadData()
    }
}

