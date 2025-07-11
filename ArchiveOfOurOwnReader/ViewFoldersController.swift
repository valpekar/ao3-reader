//
//  ViewFoldersController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/11/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import FirebaseCrashlytics

class ViewFoldersController: BaseFolderController {
    
    @IBOutlet weak var unCatButton:UIButton!
    @IBOutlet weak var updButton:UIButton!
    
    @IBOutlet weak var editFButtonItem: UIBarButtonItem!
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    @IBOutlet weak var sortButtonItem: UIBarButtonItem!
    
    var showUpdates = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.view.backgroundColor = UIColor(named: "tableViewBg")
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
        
        if let textColor = UIColor(named: "textTitleColor") {
            self.unCatButton.setTitleColor(textColor, for: UIControl.State.normal)
            self.updButton.setTitleColor(textColor, for: UIControl.State.normal)
        }
        
        self.sortBy = DefaultsManager.getString(DefaultsManager.SORT_FOLDERS)
        if (self.sortBy.isEmpty) {
            self.sortBy = "date"
        }
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.tableFooterView = UIView()
        
        unCatButton.setTitle(LoadingViewController.uncategorized, for: UIControl.State.normal)
        unCatButton.contentHorizontalAlignment = .left
        
        updButton.contentHorizontalAlignment = .left
        
        // self.highlights = self.getAllHighlights()
        // self.tableView.reloadData()
        // self.updateView()
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        self.updateView()
           
        setupAccessibility()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showUpdates = false
        
        updateView()
    }
    
    func setupAccessibility() {
        self.searchBar.accessibilityLabel = NSLocalizedString("Search", comment: "")
        self.sortButtonItem.accessibilityLabel = NSLocalizedString("SortBy", comment: "")
        self.addButtonItem.accessibilityLabel = NSLocalizedString("AddFolder", comment: "")
        self.editFButtonItem.accessibilityLabel = NSLocalizedString("EditFolders", comment: "")
    }
    
    private func updateView() {
        var fl = "Groups"
        let count = fetchedResultsController?.fetchedObjects?.count ?? 0
        if (count == 1) {
            fl = "Group"
        }
        self.title = "\(count) \(fl)"
        
        var unCatCount = 0
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "folder = nil")
        
        do {
            let count = try managedContext.count(for:fetchRequest)
            unCatCount = count
        } catch let error as NSError {
            print("updateView Error: \(error.localizedDescription)")
            unCatCount = 0
        }
        
        unCatButton.setTitle("\(LoadingViewController.uncategorized) (\(unCatCount) works) →", for: UIControl.State.normal)
        
        var needUpdatesCount = 0
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            needUpdatesCount = appDelegate.getNeedReloadWorksCount()
        }
        if (needUpdatesCount == 0) {
            updButton.isEnabled = false
        } else {
            updButton.isEnabled = true
        }
        updButton.setTitle("Latest Updates (\(needUpdatesCount))", for: UIControl.State.normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showFolderSegue") {
            
            if let favsController: FavoritesViewController = segue.destination as? FavoritesViewController {
                favsController.folderName = selectedFolderName
                favsController.showUpdatesOnly = showUpdates
            }
            
        } /*else if (segue.identifier == "editFoldersSegue") {
            if let editController: EditFoldersController = segue.destination as? EditFoldersController {
                
            }
        }*/
        
        self.hideBackTitle()
    }
    
    @IBAction func editTouched(_ sender: AnyObject) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        performSegue(withIdentifier: "editFoldersSegue", sender: self)
    }
    
    @IBAction func unCatTouched(_ sender: AnyObject) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        selectedFolderName = LoadingViewController.uncategorized
        performSegue(withIdentifier: "showFolderSegue", sender: self)
    }
    
    @IBAction func updCatTouched(_ sender: AnyObject) {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        
        showUpdates = true
        
        selectedFolderName = LoadingViewController.uncategorized
        performSegue(withIdentifier: "showFolderSegue", sender: self)
    }
    
    @IBAction func sortFoldersTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: Localization("Sort Options"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = UIColor(named: "global_tint")
        
        let dateAction = UIAlertAction(title: Localization("By Date Added"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "date"
            
            self.saveSortOptionsAndReload()
        })
        
        let azAction = UIAlertAction(title: Localization("By Name"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "name"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        optionMenu.addAction(dateAction)
        
//        let authorAction = UIAlertAction(title: Localization("By Works Count"), style: .default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            self.sortBy = "works.count"
//
//            self.saveSortOptionsAndReload()
//        })
//        optionMenu.addAction(authorAction)
        
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
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
    }
    
    //MARK: - folders
    
    @IBAction func addFolder(_ sender: AnyObject) {
        let folderName = "Folder \((self.fetchedResultsController?.fetchedObjects?.count ?? 0) + 1)"
        showAddFolder(folderName: folderName)
    }
        
    override func doneButtonAction() {
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        //self.tableView.endEditing(true)
        //self.resultSearchController.dismiss(animated: true, completion: nil)
    }
    
}



