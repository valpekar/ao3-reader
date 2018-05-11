//
//  BaseFolderController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/12/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import RMessage

class BaseFolderController: LoadingViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var searchBar:UISearchBar!
    
    var sortBy = "date"
    
    var selectedFolderName = FavoritesViewController.uncategorized
    
    lazy var fetchedResultsController: NSFetchedResultsController<Folder>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
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
        
        if let tf = self.searchBar.value(forKey: "_searchField") as? UITextField {
            addDoneButtonOnKeyboardTf(tf)
        }
        
        self.searchBar.delegate = self
    }
    
    override func doneButtonAction() {
        self.searchBar.endEditing(true)
        
        updateSearchResults()
    }
    
    func configureCell(cell: UITableViewCell, folder: Folder?, indexPath: IndexPath) {
        cell.textLabel?.text = "\(folder?.name ?? "") (\(folder?.works?.count ?? 0) works)"
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.textLabel?.textColor = AppDelegate.redDarkColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.textLabel?.textColor = AppDelegate.textLightColor
        }
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

//MARK: Tableview

extension BaseFolderController: UITableViewDelegate, UITableViewDataSource {
    
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        if let selectedFolder = fetchedResultsController?.object(at: indexPath) {
            selectedFolderName = selectedFolder.name ?? FavoritesViewController.uncategorized
            performSegue(withIdentifier: "showFolderSegue", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}


extension BaseFolderController: UISearchBarDelegate {
    
    //MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        updateSearchResults()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults()
    }
        
    func updateSearchResults() {
        
        var searchPredicate: NSPredicate? = nil
        
        if let text = self.searchBar.text, text.isEmpty == false {
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
