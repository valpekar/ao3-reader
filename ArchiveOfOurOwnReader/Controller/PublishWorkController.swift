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
    }
    
    @IBAction func closeClicked(_ sender: AnyObject) {
        
        
        self.dismiss(animated: true, completion: { () -> Void in
            
            NSLog("closeClicked")
        })
    }
    
    
}

extension PublishWorkController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "CategoryCell"
        
        let cell:CategoryCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CategoryCell
        
        let curCat:String = tableItems[indexPath.row]
        
        cell.titleLabel.text = curCat
        
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
        
    }
}
