//
//  PublishWorkController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/24/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire

class PublishWorkController: LoadingViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveItem: UIBarButtonItem!
    @IBOutlet weak var publishItem: UIBarButtonItem!
    
    var publishWork: PublishWork?
    
    var lastSelectedIndex = 0
    
    var tableItems: [String] = ["Title", "Summary", "Rating", "Archive Warnings", "Fandoms", "Category", "Relationships", "Characters", "Additional Tags"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        
        if (theme == DefaultsManager.THEME_NIGHT) {
            self.view.backgroundColor = AppDelegate.redDarkColor
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        } else {
            self.view.backgroundColor = AppDelegate.greyLightBg
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        }
        
        self.tableView.tableFooterView = UIView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        } else {
            openLoginController() //openLoginController()
        }
        
        self.createNewPublishWork()
    }
    
    @IBAction func closeClicked(_ sender: AnyObject) {
        
        self.showSureDialog()
        
    }
    
    @IBAction func saveDraftTouched(_ sender: AnyObject) {
       self.saveDraft()
    }
    
    func saveDraft() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func deletePublishWork() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
        let _ = self.publishWork else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        context.delete(self.publishWork!)
        self.publishWork = nil
        
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func showSureDialog() {
        let refreshAlert = UIAlertController(title: "Are you sure?", message: "You want to delete this draft?", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction!) in
            self.deletePublishWork()
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Save As Draft", style: .default, handler: { (action: UIAlertAction!) in
            self.saveDraft()
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    func createNewPublishWork() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        /*let entityDes=NSEntityDescription.entity(forEntityName: "TestEntity", in: context) let entity=TestEntity(entity: entityDes!, insertInto: context) entity.testAtt="test attribute"*/
        
        publishWork = PublishWork(context: context)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "plainTextSegue") {
            let controller: PlainTextController = segue.destination as! PlainTextController
            controller.plainTextDelegate = self
            
            var txt = ""
            
            switch (self.lastSelectedIndex) {
            case 0:
                txt = self.publishWork?.title ?? ""
            default: break
            }
            
            if (txt.isEmpty == false) {
                controller.textToEdit = txt
            }
        }
    }
}

extension PublishWorkController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "PublishItemCell"
        
        let cell:PublishItemCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! PublishItemCell
        
        let curCat:String = tableItems[indexPath.row]
        cell.titleLabel.text = curCat
        
        switch (indexPath.row) {
        case 0:
            cell.contentLabel.text = publishWork?.title ?? ""
        default:
            cell.contentLabel.text = ""
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.titleLabel.textColor = AppDelegate.dayTextColor
            cell.tintColor = AppDelegate.redColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.titleLabel.textColor = AppDelegate.nightTextColor
            cell.tintColor = AppDelegate.purpleLightColor
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.lastSelectedIndex = indexPath.row
        
        if (indexPath.row < 1) {
            performSegue(withIdentifier: "plainTextSegue", sender: self)
        } else {
            performSegue(withIdentifier: "publishOptionSegue", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PublishWorkController: PlainTextDelegate {
    
    func plainTextSelected(text: String) {
        switch (self.lastSelectedIndex) {
        case 0:
           publishWork?.title = text
        default: break
        }
        
        self.tableView.reloadRows(at: [IndexPath(row: self.lastSelectedIndex, section: 0)], with: .none)
    }
}
