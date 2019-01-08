//
//  HighlightsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import Crashlytics
import Firebase

class HighlightsController: LoadingViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var messageView:UIView!
        
    var sortBy = "date"
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<DBHighlightItem>? = {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<DBHighlightItem> = DBHighlightItem.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: appDelegate.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Highlights"
        
        if let th = DefaultsManager.getInt(DefaultsManager.THEME_APP) {
            theme = th
        } else {
            theme = DefaultsManager.THEME_DAY
        }
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            self.view.backgroundColor = AppDelegate.redDarkColor
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.messageView.backgroundColor = AppDelegate.greyDarkBg
            self.messageLabel.textColor = AppDelegate.nightTextColor
        } else {
            self.view.backgroundColor = AppDelegate.greyLightBg
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.messageView.backgroundColor = AppDelegate.greyLightBg
            self.messageLabel.textColor = AppDelegate.redColor
        }
        
        self.sortBy = DefaultsManager.getString(DefaultsManager.SORT_HIGHLIGHTS)
        if (self.sortBy.isEmpty) {
            self.sortBy = "date"
        }
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.tableView.tableFooterView = UIView()
        
       // self.highlights = self.getAllHighlights()
       // self.tableView.reloadData()
       // self.updateView()
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        
         self.updateView()
        
        Answers.logCustomEvent(withName: "Highlights", customAttributes: ["count" : fetchedResultsController?.fetchedObjects?.count ?? 0])
        Analytics.logEvent("Highlights", parameters: ["count" : fetchedResultsController?.fetchedObjects?.count ?? 0 as NSObject])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
//    @IBAction func restoreTouched(_ sender: AnyObject) {
//
//        DispatchQueue.global().async(execute: {
//            DispatchQueue.main.sync {
//                self.copyOldHighlights()
//            }
//        })
//    }
    
    @IBAction func sortHighlightsTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: Localization("Sort Options"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        let dateAction = UIAlertAction(title: Localization("By Date Added"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "date"
            
            self.saveSortOptionsAndReload()
        })
        
        let azAction = UIAlertAction(title: Localization("By Work Title"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "workName"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        optionMenu.addAction(dateAction)
        
        let authorAction = UIAlertAction(title: Localization("By Author"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "author"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(authorAction)
        
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func deleteAllHighlights(_ sender: AnyObject) {
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("You want to delete all your highlights?"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            self.deleteAllHighlights()
            self.tableView.reloadData()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    private func updateView() {
        let hasQuotes = fetchedResultsController?.fetchedObjects?.count ?? 0 > 0
        
        self.tableView.isHidden = !hasQuotes
        self.messageView.isHidden = hasQuotes
        
        self.messageLabel.text = "You don't have any quotes yet. \nTo add a highlight: \n   Open any work, select text and touch quotes icon. "
        
        self.title = "Highlights (\(fetchedResultsController?.fetchedObjects?.count ?? 0))"
    }
    
    func getAllHighlights() -> [DBHighlightItem] {
        var res: [DBHighlightItem] = []
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return res
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBHighlightItem")
//        if (sortBy != "date") {
//            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
//        } else {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
//        }
        
        do {
            if let fetchedResults = try managedContext.fetch(fetchRequest) as? [DBHighlightItem]  {
                res = fetchedResults
            }
        } catch {
            #if DEBUG
                print("cannot fetch favorites.")
            #endif
        }
        
        return res
    }
    
    func deleteHighlight(highlightItem: DBHighlightItem) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(highlightItem as NSManagedObject)
        do {
            try managedContext.save()
        } catch _ {
            NSLog("Cannot delete notif item")
        }

        self.showSuccess(title: Localization("Success"), message: "Highlight was successfully deleted!")
        
    }
    
    func deleteAllHighlights() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        Answers.logCustomEvent(withName: "Highlights", customAttributes: ["deleteAll_count" : fetchedResultsController?.fetchedObjects?.count ?? 0])
        Analytics.logEvent("Highlights_Delete_All", parameters: ["count" : fetchedResultsController?.fetchedObjects?.count ?? 0 as NSObject])
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DBHighlightItem")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try managedContext.execute(request)
        } catch _ {
            NSLog("Cannot delete all notif items")
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not delete all \(String(describing: error.userInfo))")
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("An error occurred")
        }
        
        self.updateView()
    }
    
    func shareHighlight(highlightItem: DBHighlightItem) {
        let textToShare = [ "\(highlightItem.content ?? "") \n- \(highlightItem.author ?? ""), \"\(highlightItem.workName ?? "")\"" ]
        
        Answers.logCustomEvent(withName: "Highlights: Share", customAttributes: ["text" : textToShare])
        Analytics.logEvent("Highlights_Share", parameters: ["text" : textToShare as NSObject])
        
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func showDeleteDialog(highlightItem: DBHighlightItem) {
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("You want to delete the highlight?"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            self.deleteHighlight(highlightItem: highlightItem)
            
//            self.highlights = self.getAllHighlights()
//            self.tableView.reloadData()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    //MARK: - sort
    
    func saveSortOptionsAndReload() {
        DefaultsManager.putString(self.sortBy, key: DefaultsManager.SORT_HIGHLIGHTS)
        
        self.fetchedResultsController?.fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortBy, ascending: true)]
    
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Highlights: saveSortOptionsAndReload An error occurred")
        }
        
//        self.highlights = self.getAllHighlights()
        self.tableView.reloadData()
//        self.updateView()
        
        Answers.logCustomEvent(withName: "Highlights: Sort", customAttributes: ["sortBy" : self.sortBy])
        Analytics.logEvent("Highlights_Sort", parameters: ["sortBy" : self.sortBy as NSObject])
    }
    
    //MARK: - copy olds
    
//    func copyOldHighlights() {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//            let managedContextOld = appDelegate.managedObjectContextOld else {
//                return
//        }
//        let managedContext = appDelegate.persistentContainer.viewContext
//        
//        var items: [DBHighlightItem] = []
//        
//        let fetchRequest: NSFetchRequest <NSFetchRequestResult> = NSFetchRequest(entityName:"DBHighlightItem")
//        do {
//            if let fetchedResults = try managedContextOld.fetch(fetchRequest) as? [DBHighlightItem] {
//                items = fetchedResults
//            }
//        } catch {
//            #if DEBUG
//            print("cannot fetch favorites.")
//            #endif
//        }
//        
//        
//        for item in items {
//            
//            var shouldCopy = false
//            
//            let predicate = NSPredicate(format: "content == %@", item.content ?? "")
//            if let array = (fetchedResultsController?.fetchedObjects as NSArray?)?.filtered(using: predicate) as? [DBHighlightItem] {
//                if array.count == 0  {
//                    shouldCopy = true
//                }
//            } else if fetchedResultsController?.fetchedObjects?.count ?? 0 > 0 {
//                shouldCopy = true
//            }
//            
//            if (shouldCopy == false) {
//                let deleteAlert = UIAlertController(title: "Restore Highlights", message: "Cannot find any lost highlights.", preferredStyle: UIAlertControllerStyle.alert)
//                
//                deleteAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction) in
//                    print("Cancel")
//                }))
//                
//                deleteAlert.view.tintColor = AppDelegate.redColor
//                
//                self.present(deleteAlert, animated: true, completion: nil)
//            } else if (shouldCopy == true) {
//                
//            guard let entity = NSEntityDescription.entity(forEntityName: "DBHighlightItem",  in: managedContext) else {
//                return
//            }
//            
//            let nItem = DBHighlightItem(entity: entity, insertInto: managedContext)
//            nItem.workId = item.workId
//            nItem.workName = item.workName
//            nItem.author = item.author
//            nItem.content = item.content
//            nItem.date = item.date
//            
//            Answers.logCustomEvent(withName: "Highlights: save highlight from old", customAttributes: ["workName" : nItem.workName ?? "", "content": nItem.content ?? ""])
//            
//            do {
//                try managedContext.save()
//            } catch let error as NSError {
//                print("Could not save \(String(describing: error.userInfo))")
//            }
//                
//                managedContextOld.delete(item)
//                
//                do {
//                    try managedContextOld.save()
//                } catch let error as NSError {
//                    print("Could not save \(String(describing: error.userInfo))")
//                }
//        }
//        }
//    }
}

//MARK: Tableview

extension HighlightsController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HighlightCell = tableView.dequeueReusableCell(withIdentifier: "HighlightCell") as! HighlightCell
        
        let highlightItem = fetchedResultsController?.object(at: indexPath)
        configureCell(cell: cell, highlightItem: highlightItem, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: HighlightCell, highlightItem: DBHighlightItem?, indexPath: IndexPath) {
        cell.contentLabel.text = highlightItem?.content
        cell.authorLabel.text = "- \(highlightItem?.author ?? ""), \"\(highlightItem?.workName ?? "")\""
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.contentLabel.textColor = AppDelegate.redDarkColor
            cell.authorLabel.textColor = AppDelegate.redTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.contentLabel.textColor = AppDelegate.textLightColor
            cell.authorLabel.textColor = AppDelegate.purpleLightColor
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let selectedHighlight = fetchedResultsController?.object(at: indexPath) {
            showQuoteDialog(selectedHighlight: selectedHighlight)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showQuoteDialog(selectedHighlight: DBHighlightItem) {
        let deleteAlert = UIAlertController(title: Localization("Highlight Options"), message: selectedHighlight.workName, preferredStyle: UIAlertController.Style.actionSheet)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Delete"), style: .default, handler: { (action: UIAlertAction) in
            self.showDeleteDialog(highlightItem: selectedHighlight)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Share"), style: .default, handler: { (action: UIAlertAction) in
            self.shareHighlight(highlightItem: selectedHighlight)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        deleteAlert.popoverPresentationController?.sourceView = self.tableView
        deleteAlert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.navigationController?.navigationBar.bounds.height ?? 64, width: 1.0, height: 1.0)
        
        present(deleteAlert, animated: true, completion: nil)
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
        case .update:
            if let indexPath = indexPath {
                let workItem = fetchedResultsController?.object(at: indexPath)
                guard let cell = tableView.cellForRow(at: indexPath) as? HighlightCell else { break }
                configureCell(cell: cell, highlightItem: workItem, indexPath: indexPath)
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
