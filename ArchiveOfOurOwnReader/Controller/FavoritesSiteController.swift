//
//  FavoritesSiteController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/25/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import RMessage
import Alamofire
import Crashlytics

class FavoritesSiteController : ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    @IBOutlet weak var errLabel:UILabel!
    
    var searched = false
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.worksElement = "bookmark"
        self.itemsCountHeading = "h2"
        
        self.createDrawerButton()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(FavoritesSiteController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.foundItems = NSLocalizedString("Bookmarks", comment: "")
        
        self.title = NSLocalizedString("Bookmarks", comment: "")
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
        
        showNav()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (works.count == 0) {
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            requestFavs()
        } else if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            openLoginController(force: false) //openLoginController()
            requestFavs()
        }
        }
    }
    
    @objc func refresh(_ sender:AnyObject) {
        requestFavs()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestFavs()
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.tableView.backgroundColor = AppDelegate.greyLightBg
            self.collectionView.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
            self.collectionView.backgroundColor = AppDelegate.redDarkColor
        }
        
        if let tf = searchBar.value(forKey: "_searchField") as? UITextField {
            addDoneButtonOnKeyboardTf(tf)
            
            if (theme == DefaultsManager.THEME_DAY) {
                tf.textColor = AppDelegate.redColor
                tf.backgroundColor = UIColor.white
                
            } else {
                tf.textColor = AppDelegate.textLightColor
                tf.backgroundColor = AppDelegate.greyBg
            }
        }
    }
    
    
    override func doneButtonAction() {
        super.doneButtonAction()
        self.searchBar.endEditing(true)
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableViewRowAnimation.automatic)
    }
    
    //MARK: - login
    
//    override func openLoginController() {
//        let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
//        (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
//        
//        self.present(nav, animated: true, completion: nil)
//    }
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        openLoginController()
    }
    
    //MARK: - request
    
    func requestFavs() {
        
        searched = false
        
        //let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
        if (del.cookies.count > 0) {
            guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                return
            }
            cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        }
        
        showLoadingView(msg: NSLocalizedString("GettingBmks", comment: ""))
        
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            } else {
                RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("LoginToViewBmks", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                })
                showWorks()
                return
            }
        }
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        guard let curPs = pseuds[currentPseud] else {
            return
        }
        var curPseud = curPs
        if let encodedPseud = curPseud.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)  {
            curPseud = encodedPseud
        }
        
        let urlStr = "https://archiveofourown.org/users/\(login)/pseuds/\(curPseud)/bookmarks" // + pseuds[currentPseud]! + "/bookmarks"
       
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "bookmark", downloadedCheckItems: checkItems)
                    //self.parseBookmarks(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
                self.refreshControl.endRefreshing()
            })
        }
    
    override func showWorks() {
        if (works.count > 0) {
            tableView.isHidden = false
            errView.isHidden = true
        } else {
            tableView.isHidden = true
            errView.isHidden = false
        }
        
        tableView.reloadData()
        collectionView.reloadData()
        
        hideLoadingView()
        self.navigationItem.title = foundItems
        
        if(foundItems.contains("0")) {
            errLabel.text = "Nothing found! \nTry searching something else"
        } else {
            errLabel.text = "Cannot obtain data. \nPlease check your Internet connection and also make sure you are logged into your AO3 account (try to log in again)."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if (self.tableView.numberOfSections > 0 && self.tableView.numberOfRows(inSection: 0) > 0) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        collectionView.flashScrollIndicators()
    }
    
    override func controllerDidClosed() {}
    
    func controllerDidClosedWithLogin() {
        requestFavs()
    }
    
    func controllerDidClosedWithChange() {
        refresh(tableView)
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell: FeedTableViewCell! = nil
        if let c:FeedTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FeedTableViewCell {
            cell = c
        } else {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        if (works.count == 0) {
            return cell
        }
        
        let curWork:NewsFeedItem = works[indexPath.row]
        
        cell = fillCellXib(cell: cell, curWork: curWork, needsDelete: true, index: indexPath.row)
        
        cell.workCellView.tag = indexPath.row
        cell.workCellView.downloadButtonDelegate = self
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCell(row: indexPath.row, works: works)
    }
    
    //MARK: - collectionview
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        var cell: PageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PageCollectionViewCell
        
        cell = fillCollCell(cell: cell, page: pages[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCollCell(indexPath: indexPath, sender: self.collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: AppDelegate.smallCollCellWidth, height: 28)
    }
    
    // MARK: - navigation
    override func  prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "workDetail") {
            if let row = tableView.indexPathForSelectedRow?.row {
                if (row < works.count) {
                    selectedWorkDetail(segue: segue, row: row, modalDelegate: self, newsItem: works[row])
                    
                }
            }
            
        } else if (segue.identifier == "serieDetail" ) {
            if let row = tableView.indexPathForSelectedRow?.row {
                
                if (row < works.count) {
                    selectedSerieDetail(segue: segue, row: row, newsItem: works[row])
                }
            }
        }
        
        hideBackTitle()
    }
    
    //MARK: - SAVE WORK TO DB
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView(msg: "\(NSLocalizedString("DwnloadingWrk", comment: "")) \(curWork.title)")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let urlStr =  "https://archiveofourown.org/works/" + curWork.workId
        
        Alamofire.request(urlStr, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                //  println(response ?? "")
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let _ = self.downloadWork(d, curWork: curWork)
                    //self.saveWork()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
            })
    }

    //MARK: - delete work from bookmarks
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
        
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteWrkFromBmks", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[sender.tag]
            self.deleteItemFromBookmarks(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromBookmarks(_ curWork: NewsFeedItem) {
        showLoadingView(msg: NSLocalizedString("DeletingFromBmks", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        //let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            }
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = (UIApplication.shared.delegate as! AppDelegate).token as AnyObject?
        params["_method"] = "delete" as AnyObject?
        
        let urlStr = "https://archiveofourown.org" + curWork.readingId
        
        Alamofire.request(urlStr, method: .post, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d, curWork: curWork)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
            })
    }
    
    func parseDeleteResponse(_ data: Data, curWork: NewsFeedItem) {
        // let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        // print("the string is: \(dta)")
        let doc : TFHpple = TFHpple(htmlData: data)
        
        let noticediv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement]
        if(noticediv != nil && (noticediv?.count)! > 0) {
            if let index = self.works.index( where: {$0.workId == curWork.workId}) {
                self.works.remove(at: index)
            }
            RMessage.showNotification(in: self, title: NSLocalizedString("DeleteFromBmk", comment: ""), subtitle: noticediv?[0].content ?? "", type: RMessageType.success, customTypeName: "", callback: {
                
            })
        } else {
            if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
                if(sorrydiv.count>0 && (sorrydiv[0] as? TFHppleElement)?.text().range(of: "Sorry") != nil) {
                    RMessage.showNotification(in: self, title: NSLocalizedString("DeleteFromBmk", comment: ""), subtitle: (sorrydiv[0] as AnyObject).content, type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                    return
                }
            }
        }
    }
    
    override func deleteTouched(rowIndex: Int) {
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: NSLocalizedString("SureDeleteWrkFromBmks", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[rowIndex]
            self.deleteItemFromBookmarks(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }

}

//MARK: - search

extension FavoritesSiteController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if (searchBar.text != nil && searchBar.text?.isEmpty == false) {
            doSearch(searchBar.text!)
            
            self.searchBar.endEditing(true)
        } else {
            RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CannotBeEmpty", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                
            })
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.searchBar.endEditing(true)
        
        if (searched == true) {
            requestFavs()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if (searchBar.text != nil && searchBar.text?.isEmpty == false) {
            doSearch(searchBar.text!)
        } else {
           requestFavs()
        }
        self.searchBar.endEditing(true)
    }
    
    func doSearch(_ query: String) {
        
        searched = true
        
        Answers.logCustomEvent(withName: "Bookmarks: search", customAttributes: ["query" : query])
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
        }
        
        showLoadingView(msg: NSLocalizedString("GettingBmks", comment: ""))
        
        let pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
        var currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
        
        if (currentPseud.isEmpty) {
            let keys = Array(pseuds.keys)
            if (keys.count > 0) {
                currentPseud = keys[0]
            } else {
                self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("LoginToViewBmks", comment: ""))
                showWorks()
                return
            }
        }
        
        //http://archiveofourown.org/bookmarks?utf8=✓&bookmark_search%5Bsort_column%5D=created_at&bookmark_search%5Bother_tag_names%5D=&bookmark_search%5Bquery%5D=witcher&bookmark_search%5Brec%5D=0&bookmark_search%5Bwith_notes%5D=0&commit=Sort+and+Filter&user_id=ssaria
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)

        let urlStr = "https://archiveofourown.org/bookmarks" // + pseuds[currentPseud]! + "/bookmarks"
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["user_id"] = login as AnyObject?
        
        params["bookmark_search"] = ["sort_column": "created_at",
                                     "with_notes" : "0",
                                     "rec" : "0",
                                     "other_tag_names" : "",
                                     "other_bookmark_tag_names": "",
                                     "excluded_tag_names": "",
                                     "excluded_bookmark_tag_names": "",
                                     "bookmark_query" : "",
                                     "bookmarkable_query" : query] as AnyObject?
        
        params["commit"] = "Sort and Filter" as AnyObject?
        
        Alamofire.request(urlStr, method: .get, parameters: params) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.foundItems) = WorksParser.parseWorks(d, itemsCountHeading: "h2", worksElement: "bookmark", downloadedCheckItems: checkItems)
                    //self.parseBookmarks(d)
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
                self.refreshControl.endRefreshing()
            })
    }
}

