//
//  HighlightsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/22/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import CoreData
import TSMessages
import Crashlytics

class HighlightsController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var messageView:UIView!
    
    var theme = DefaultsManager.THEME_DAY
    
    var highlights: [DBHighlightItem] = []
    
    var sortBy = "date"
    
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
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        self.tableView.tableFooterView = UIView()
        
        self.highlights = self.getAllHighlights()
        self.tableView.reloadData()
        self.updateView()
        
        Answers.logCustomEvent(withName: "Highlights", customAttributes: ["count" : highlights.count])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func sortHighlightsTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: NSLocalizedString("Sort Options", comment: ""), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        let dateAction = UIAlertAction(title: NSLocalizedString("By Date Added", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "date"
            
            self.saveSortOptionsAndReload()
        })
        
        let azAction = UIAlertAction(title: NSLocalizedString("By Work Title", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "workName"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(azAction)
        optionMenu.addAction(dateAction)
        
        let authorAction = UIAlertAction(title: NSLocalizedString("By Author", comment: ""), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.sortBy = "author"
            
            self.saveSortOptionsAndReload()
        })
        optionMenu.addAction(authorAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.view
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func deleteAllHighlights(_ sender: AnyObject) {
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("You want to delete all your highlights?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.deleteAllHighlights()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    private func updateView() {
        let hasQuotes = highlights.count > 0
        
        self.tableView.isHidden = !hasQuotes
        self.messageView.isHidden = hasQuotes
        
        self.messageLabel.text = "You don't have any quotes yet. \nDo add a highlight: \n   Open any work, select text and touch quotes icon. "
    }
    
    func getAllHighlights() -> [DBHighlightItem] {
        var res: [DBHighlightItem] = []
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return res
        }
        
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return
        }
        
        managedContext.delete(highlightItem as NSManagedObject)
        do {
            try managedContext.save()
        } catch _ {
            NSLog("Cannot delete notif item")
        }
        
        TSMessage.showNotification(in: self, title: "Success", subtitle: "Highlight was successfully deleted!", type: TSMessageNotificationType.success)
        
    }
    
    func deleteAllHighlights() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let managedContext = appDelegate.managedObjectContext else {
                return
        }
        
        Answers.logCustomEvent(withName: "Highlights", customAttributes: ["deleteAll,count" : highlights.count])
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "DBHighlightItem")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try managedContext.execute(request)
        } catch _ {
            NSLog("Cannot delete all notif items")
        }
    }
    
    func shareHighlight(highlightItem: DBHighlightItem) {
        let textToShare = [ "\(highlightItem.content ?? "") \n- \(highlightItem.author ?? ""), \"\(highlightItem.workName ?? "")\"" ]
        
        Answers.logCustomEvent(withName: "Highlights: Share", customAttributes: ["text" : textToShare])
        
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func showDeleteDialog(highlightItem: DBHighlightItem) {
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("You want to delete the highlight?", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.deleteHighlight(highlightItem: highlightItem)
            
            self.highlights = self.getAllHighlights()
            self.tableView.reloadData()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    //MARK: - sort
    
    func saveSortOptionsAndReload() {
        DefaultsManager.putString(self.sortBy, key: DefaultsManager.SORT_HIGHLIGHTS)
        
        self.highlights = self.getAllHighlights()
        self.tableView.reloadData()
        self.updateView()
        
        Answers.logCustomEvent(withName: "Highlights: Sort", customAttributes: ["sortBy" : self.sortBy])
    }
}

//MARK: Tableview

extension HighlightsController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return highlights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: HighlightCell = tableView.dequeueReusableCell(withIdentifier: "HighlightCell") as! HighlightCell
        
        let highlightItem = highlights[indexPath.row]

        cell.contentLabel.text = highlightItem.content
        cell.authorLabel.text = "- \(highlightItem.author ?? ""), \"\(highlightItem.workName ?? "")\""
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.contentLabel.textColor = AppDelegate.redDarkColor
            cell.authorLabel.textColor = AppDelegate.redTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.contentLabel.textColor = AppDelegate.textLightColor
            cell.authorLabel.textColor = AppDelegate.purpleLightColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedHighlight = highlights[indexPath.row]
        
        showQuoteDialog(selectedHighlight: selectedHighlight)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func showQuoteDialog(selectedHighlight: DBHighlightItem) {
        let deleteAlert = UIAlertController(title: NSLocalizedString("Highlight Options", comment: ""), message: selectedHighlight.workName, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.showDeleteDialog(highlightItem: selectedHighlight)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Share", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            self.shareHighlight(highlightItem: selectedHighlight)
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        deleteAlert.popoverPresentationController?.sourceView = self.tableView
        deleteAlert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.navigationController?.navigationBar.bounds.height ?? 64, width: 1.0, height: 1.0)
        
        present(deleteAlert, animated: true, completion: nil)
    }
}
