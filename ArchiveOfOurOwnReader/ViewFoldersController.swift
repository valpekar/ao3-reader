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

class ViewFoldersController: BaseFolderController {
    
    @IBOutlet weak var unCatButton:UIButton!
    
    
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
        
        var unCatCount = 0
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let managedContext = appDelegate.managedObjectContext else {
            return
        }
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBWorkItem")
        fetchRequest.predicate = NSPredicate(format: "folder = nil")
        
        do {
            let count = try managedContext.count(for:fetchRequest)
            unCatCount = count
        } catch let error as NSError {
            print("updateView Error: \(error.localizedDescription)")
            unCatCount = 0
        }
        
        unCatButton.setTitle("\(FavoritesViewController.uncategorized) (\(unCatCount))", for: UIControlState.normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showFolderSegue") {
            
            if let favsController: FavoritesViewController = segue.destination as? FavoritesViewController {
                favsController.folderName = selectedFolderName
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



