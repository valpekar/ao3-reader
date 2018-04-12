//
//  EditFoldersController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 7/21/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import TSMessages
import Crashlytics

class EditFoldersController: BaseFolderController {
    
    var editFoldersProtocol: EditFoldersProtocol?
    
    var selectedFolderIdx: IndexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Edit Folders"
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
        
        self.tableView.tableFooterView = UIView()
        
//        self.loadAllFolders()
//        self.tableView.reloadData()
        
        fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        Answers.logCustomEvent(withName: "Edit Folders", customAttributes: ["folders_count" : self.fetchedResultsController?.fetchedObjects?.count ?? 0])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (editFoldersProtocol != nil) {
            self.selectedFolderIdx = indexPath
            self.navigationController?.popViewController(animated: true)
        } else {
            
            if let folder = fetchedResultsController?.object(at: indexPath) {
                folderTouched(folder: folder)
            } else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderNotFound", comment: ""), type: .error)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - folders
    
    func folderTouched(folder: Folder) {
        let alert = UIAlertController(title: "Edit Folder", message: "Do you want to delete or rename the folder?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Rename Folder", style: .default, handler: { (action) in
            self.renameFolderTouched(folder: folder)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete Folder", style: .default, handler: { (action) in
            self.deleteFolderTouched(folder: folder)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
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
    
    func deleteFolderTouched(folder: Folder) {
        
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("Do you want to delete works too?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete folder, keep works", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            self.deleteFolder(folder: folder, withWorks: false)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete with works", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            self.deleteFolder(folder: folder, withWorks: true)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        
        present(deleteAlert, animated: true, completion: nil)
    }
    
    func deleteFolder(folder: Folder, withWorks: Bool) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        if (withWorks == true) {
            if let works = folder.works {
                for work in works {
                    managedContext.delete(work as! NSManagedObject)
                }
            }
        }
        
        managedContext.delete(folder)
        
        do {
            try managedContext.save()
        } catch _ {
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Could not delete the folder!", comment: ""), type: .error)
        }
        
        self.tableView.reloadData()
    }
    
    func renameFolderTouched(folder: Folder) {
        renameFolderDialog(folder: folder)
    }
    
    func renameFolderDialog(folder: Folder) {
        let alert = UIAlertController(title: "Folder", message: "Rename Folder", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .whileEditing
            textField.text = folder.name ?? "No Name"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if let txt = textField?.text {
                
                self.doRenameFolder(folder: folder, newName: txt)
                Answers.logCustomEvent(withName: "Rename_folder",
                                       customAttributes: [
                                        "name_new": txt,
                                        "name_old": folder.name ?? "No Name"])
            } else {
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderNameEmpty", comment: ""), type: .error)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (action) in
            #if DEBUG
            print("cancel")
            #endif
        }))
        
        alert.view.tintColor = AppDelegate.redColor
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func doRenameFolder(folder: Folder, newName: String) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let managedContext = appDelegate.managedObjectContext else {
            return
        }
        
        let req: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Folder")
        let predicate = NSPredicate(format: "name == %@", newName)
        req.predicate = predicate
        do {
            if let fetchedWorks = try managedContext.fetch(req) as? [Folder] {
                if (fetchedWorks.count > 0) {
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("FolderAlreadyExists", comment: ""), type: .error)
                    return
                } else {
                    folder.name = newName
                }
            }
        } catch {
            fatalError("Failed to fetch folders: \(error)")
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            #if DEBUG
                print("Could not save \(String(describing: error.userInfo))")
            #endif
            TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Could not rename the folder!", comment: ""), type: .error)
        }
        
        tableView.reloadData()
        
    }
    
    //MARK: - back
    
    override func viewWillDisappear(_ animated: Bool) {
        if let folder = fetchedResultsController?.object(at: selectedFolderIdx) {
            editFoldersProtocol?.folderSelected(folder: folder)
        }
    }
}

protocol EditFoldersProtocol {
    func folderSelected(folder: Folder)
}
