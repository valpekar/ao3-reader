//
//  PagesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 12/22/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit

class PagesController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var baseUrl: String = "" {
        didSet {
            self.pagedUrl = URL(string: baseUrl, relativeTo: siteUrl)
            if (pagedUrl != nil) {
                self.components = URLComponents(url: pagedUrl!, resolvingAgainstBaseURL: false)
            
                if components != nil {
                    var page = components?.queryItems?.filter({item in item.name == "page"}).first
                    self.lastPage = Int((page?.value) ?? "") ?? 0
                
                }
            }
        }
    }
    
    var theme = DefaultsManager.THEME_DAY
    
    fileprivate let siteUrl = URL(string: AppDelegate.ao3SiteUrl)
    fileprivate var pagedUrl: URL?
    fileprivate var components: URLComponents?
    
    fileprivate var lastPage: Int = 0
    
    var modalDelegate: PageSelectDelegate! = nil
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lastPage
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "contentsCell"
        
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellIdentifier)
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell?.backgroundColor = AppDelegate.greyLightBg
            cell?.textLabel?.textColor = AppDelegate.redColor
        } else {
            cell?.backgroundColor = AppDelegate.greyDarkBg
            cell?.textLabel?.textColor = AppDelegate.textLightColor
        }
        cell?.textLabel?.textAlignment = .center
        cell?.textLabel?.text = "\(indexPath.row + 1)"
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if components != nil {
            var page = components?.queryItems?.filter({item in item.name == "page"}).first
            page?.value = "\(indexPath.row + 1)"
            
            var oldItems = components?.queryItems?.filter({item in item.name != "page" })
            oldItems?.append(page!)
            
            components?.queryItems = oldItems
            
            let newUrl = components?.url(relativeTo: siteUrl)
//            modalDelegate.pageSelected(pageUrl: newUrl?.absoluteString.replacingOccurrences(of: AppDelegate.ao3SiteUrl, with: "") ?? "")
            modalDelegate.pageSelected(pageUrl: newUrl!.relativeString)
            
        } else {
            print("Nil")
        }
        
        
        self.dismiss(animated: true, completion: nil)
    }
    
}

@objc protocol PageSelectDelegate {
    func pageSelected(pageUrl: String)
}
