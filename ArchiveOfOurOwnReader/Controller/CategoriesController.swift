//
//  CategoriesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 11/29/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import TSMessages
import Alamofire

class CategoriesController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var categories: [CategoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        requestCategories()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestCategories()
    }
    
    func requestCategories() {
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: ""))")
        
        Alamofire.request("https://archiveofourown.org/media", method: .get).response(completionHandler: { response in
            print(response.error ?? "")
            if let data = response.data {
                self.parseCookies(response)
                self.parseCategories(data)
                self.showCategories()
            } else {
                self.showCategories()
                TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
            }
        })
    }
    
    func parseCategories(_ data: Data) {
        categories.removeAll(keepingCapacity: false)
        
        #if DEBUG
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(string1 ?? "")
        #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        let historylist : [TFHppleElement]? = doc.search(withXPathQuery: "//ul[@class='media fandom index group']//li") as? [TFHppleElement]
        if let workGroup = historylist {
            
            if (workGroup.count > 0) {
                
                for workListItem in workGroup {
                    var item : CategoryItem = CategoryItem()
                    
                    let titleEl: TFHppleElement? = (workListItem.search(withXPathQuery: "//h3")[0] as? TFHppleElement)
                    item.title = titleEl?.content ?? ""
                    
                    if let attributes : NSDictionary = (workListItem.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.attributes as NSDictionary? {
                        item.url = (attributes["href"] as? String ?? "")
                    }
                    
                    categories.append(item)
                }
                
            }
            
        }
    }
    
    func showCategories() {
        if (categories.count > 0) {
            tableView.isHidden = false
            errView.isHidden = true
        } else {
            tableView.isHidden = true
            errView.isHidden = false
        }
        
        tableView.reloadData()
        
        hideLoadingView()
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "CategoryCell"
        
        let cell:CategoryCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CategoryCell
        
        let curCat:CategoryItem = categories[indexPath.row]
        
        cell.titleLabel.text = curCat.title.replacingOccurrences(of: "\n", with: "")
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.titleLabel.textColor = AppDelegate.nightTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.titleLabel.textColor = AppDelegate.dayTextColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}
