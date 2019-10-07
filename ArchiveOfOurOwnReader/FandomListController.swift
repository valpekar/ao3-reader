//
//  FandomListController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 11/30/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import Crashlytics

class FandomListController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var listUrl = ""
    var listName = ""
    
    var fandomList: [String: [FandomItem]] = [:]
    var keys: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.title = listName
        
        Answers.logCustomEvent(withName: "Fandom list: open", customAttributes: ["name":listName])
        
        if (!listUrl.contains("archiveofourown.org")) {
            listUrl = "https://archiveofourown.org\(listUrl)"
        }
        
        requestCategories()
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestCategories()
    }
    
    func requestCategories() {
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        showLoadingView(msg: "\(Localization("LoadingPage"))")
        
        Alamofire.request(listUrl, method: .get).response(completionHandler: { response in
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
        fandomList.removeAll()
        
        #if DEBUG
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(string1 ?? "")
        #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        if let list : [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='alphabet fandom index group ']//li") as? [TFHppleElement] {
        
                for workListItem in list {
                    
                    if let titleEl: [TFHppleElement] = (workListItem.search(withXPathQuery: "//h3") as? [TFHppleElement]) {
                        
                        if (titleEl.count == 0) {
                            continue
                        }
                        var keyword = titleEl[0].content.replacingOccurrences(of: "↑", with: "")
                        keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if let childEls = workListItem.search(withXPathQuery: "//ul[@class='tags index group']//li") as? [TFHppleElement] {
                                for childEl in childEls {
                                    var childItem : FandomItem = FandomItem()
                                    
                                    childItem.title = childEl.content.condenseWhitespace()
                                    
                                    if let attributesEl : [TFHppleElement] = (childEl.search(withXPathQuery: "//a") as? [TFHppleElement]),
                                        attributesEl.count > 0,
                                        let attributes: NSDictionary = attributesEl[0].attributes as NSDictionary? {
                                        childItem.url = (attributes["href"] as? String ?? "")
                                    }
                                    
                                    var fandoms: [FandomItem] = []
                                    if let fandomsArr = fandomList[keyword] {
                                        fandoms = fandomsArr
                                    }
                                    fandoms.append(childItem)
                                    fandomList[keyword] = fandoms
                                }
                            }
                }
            }
        }
        
        keys = fandomList.keys.sorted()
    }
    
    func showCategories() {
        if (fandomList.keys.count > 0) {
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
        let curKey = keys[section]
        return fandomList[curKey]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return keys[section] as String
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "CategoryCell"
        
        let cell:CategoryCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CategoryCell
        
        let curKey = keys[indexPath.section]
        if let curCat: FandomItem = fandomList[curKey]?[ indexPath.row ] {
        
        cell.titleLabel.text = curCat.title.replacingOccurrences(of: "\n", with: "")
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.titleLabel.textColor = AppDelegate.dayTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.titleLabel.textColor = AppDelegate.nightTextColor
        }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "workListSegue", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return keys
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let temp = keys as NSArray
        return temp.index(of: title)
    }
    
    //MARK: - navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "workListSegue") {
            if let indexPath = tableView.indexPathForSelectedRow {
                let curKey = keys[indexPath.section]
                let curCat: FandomItem = fandomList[curKey]![indexPath.row]
                
                Answers.logCustomEvent(withName: "Fandom list: select", customAttributes: ["name":curCat.title])
                
                if let cController: WorkListController = segue.destination as? WorkListController {
                    cController.tagUrl = curCat.url
                }
            }
        }
    }
}

