//
//  CategoriesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 11/29/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import FirebaseCrashlytics

class CategoriesController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    
    var categories: [CategoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        
        
        requestCategories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
    }
    
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestCategories()
    }
    
    func requestCategories() {
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        showLoadingView(msg: "\(Localization("LoadingPage"))")
        
        Alamofire.request("https://archiveofourown.org/media", method: .get).response(completionHandler: { response in
            print(response.error ?? "")
            if let data = response.data {
                self.parseCookies(response)
                self.parseCategories(data)
                self.showCategories()
            } else {
                self.showCategories()
                self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
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
                    
                    if let titleEl: [TFHppleElement] = (workListItem.search(withXPathQuery: "//h3") as? [TFHppleElement]) {
                        
                        var item : CategoryItem = CategoryItem()
                        
                        if (titleEl.count > 0) {
                            item.title = titleEl[0].content ?? ""
                            item.isParent = true
                            
                            if let attributes : NSDictionary = (workListItem.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.attributes as NSDictionary? {
                                item.url = (attributes["href"] as? String ?? "")
                            }
                            
                            categories.append(item)
                            
                            if let childEls = workListItem.search(withXPathQuery: "//ol[@class='index group']//li") as? [TFHppleElement] {
                                for childEl in childEls {
                                    var childItem : CategoryItem = CategoryItem()
                                    
                                    childItem.title = childEl.content.condenseWhitespace()
                                    childItem.isParent = false
                                    
                                    if let attributes : NSDictionary = (childEl.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.attributes as NSDictionary? {
                                        childItem.url = (attributes["href"] as? String ?? "")
                                    }
                                    
                                    categories.append(childItem)
                                }
                            }
                        }
                    }
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
        
        if (curCat.isParent == true) {
            cell.titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.bold)
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.titleLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular)
            cell.accessoryType = .none
        }
        
        cell.backgroundColor = UIColor(named: "tableViewBg")
        cell.tintColor = UIColor(named: "global_tint")
        cell.titleLabel.textColor = UIColor(named: "textColorMedium")
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let curCat: CategoryItem = categories[indexPath.row]
        if (curCat.isParent == false) {
            performSegue(withIdentifier: "workListSegue", sender: self)
        } else {
            performSegue(withIdentifier: "fandomListSegue", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "workListSegue") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let curCat: CategoryItem = categories[indexPath.row]
            
                if let cController: WorkListController = segue.destination as? WorkListController {
                    cController.tagUrl = curCat.url
                }
            }
        } else if (segue.identifier == "fandomListSegue") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let curCat: CategoryItem = categories[indexPath.row]
                
                if let fController: FandomListController = segue.destination as? FandomListController {
                    fController.listUrl = curCat.url
                    fController.listName = curCat.title
                }
            }
        }
        
        hideBackTitle()
    }
}

extension String {
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
