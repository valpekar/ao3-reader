//
//  SubscriptionsController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/21/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import RMessage

class SubscriptionsViewController: ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var subsAddedStr = Localization("Subscriptions")

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.title = Localization("Subscriptions")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: Localization("PullToRefresh"))
        self.refreshControl.addTarget(self, action: #selector(SubscriptionsViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
        
        showNav()
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
    }
    
    //MARK: - login
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        openLoginController()
    }
    
    //MARK: - request
    
    func requestFavs() {
        let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        showLoadingView(msg: Localization("GettingSubs"))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        let urlStr: String = "https://archiveofourown.org/users/" + username + "/subscriptions"
        
        Alamofire.request(urlStr) //default is .get
            .response(completionHandler: { response in
                
                #if DEBUG
                //print(request)
                print(response.error ?? "")
                    #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseSubs(d)
                    self.refreshControl.endRefreshing()
                    self.showSubs()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                    
                }
            })
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableView.RowAnimation.automatic)
    }
    
    func parseSubs(_ data: Data) {
        works.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        #if DEBUG
        let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print(string1 ?? "")
            #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        let historylist : [TFHppleElement]? = doc.search(withXPathQuery: "//dl[@class='subscription index group']//dt") as? [TFHppleElement]
        if let workGroup = historylist {
            
            if (workGroup.count > 0) {
                    
                    for workListItem in workGroup {
                        
                        var item : NewsFeedItem = NewsFeedItem()
                        
                        let topic = workListItem.content ?? ""
                        
                        item.topic = topic.replacingOccurrences(of: "\n", with:"").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
                        
                        
                        //parse work ID
                        
                        if let attributes : NSDictionary = (workListItem.search(withXPathQuery: "//a")[0] as? TFHppleElement)?.attributes as NSDictionary? {
                            item.workId = (attributes["href"] as? String ?? "").replacingOccurrences(of: "/works/", with: "")
                        }
                        
                            works.append(item)
                        
                }
                            //parse pages
                        if let paginationActions = doc.search(withXPathQuery: "//ol[@class='pagination actions']") {
                            if(paginationActions.count > 0) {
                                guard let paginationArr = (paginationActions[0] as AnyObject).search(withXPathQuery: "//li") else {
                                    return
                                }
                                
                                for i in 0..<paginationArr.count {
                                    let page: TFHppleElement = paginationArr[i] as! TFHppleElement
                                    var pageItem: PageItem = PageItem()
                                    
                                    if (page.content.contains("Previous")) {
                                        pageItem.name = "←"
                                    } else if (page.content.contains("Next")) {
                                        pageItem.name = "→"
                                    } else {
                                        pageItem.name = page.content
                                    }
                                    
                                    var attrs = page.search(withXPathQuery: "//a") as! [TFHppleElement]
                                    
                                    if (attrs.count > 0) {
                                        
                                        let attributesh : NSDictionary? = attrs[0].attributes as NSDictionary
                                        if (attributesh != nil) {
                                            pageItem.url = attributesh!["href"] as! String
                                        }
                                    }
                                    
                                    let current = page.search(withXPathQuery: "//span") as! [TFHppleElement]
                                    if (current.count > 0) {
                                        pageItem.isCurrent = true
                                    }
                                    
                                    if (!pages.contains(where: { (pItem) -> Bool in
                                        if (pItem.name == pageItem.name) {
                                            return true
                                        } else {
                                            return false
                                        }
                                    })) {
                                        pages.append(pageItem)
                                    }
                                }
                            }
                        }
                    
            }
        }
    }
    
    func showSubs() {
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
        self.navigationItem.title = subsAddedStr
        
        tableView.setContentOffset(CGPoint.zero, animated:true)
    }
    
    override func controllerDidClosed() {}
    
    @objc func controllerDidClosedWithLogin() {
        requestFavs()
    }
    
    @objc func controllerDidClosedWithChange() {
    }
    
    //MARK: - download work
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        
        if (sender.tag >= works.count) {
            return
        }
        
        if (purchased || donated) {
            #if DEBUG
            print("premium")
            #endif
        } else {
            if (countWroksFromDB() > 29) {
                self.showError(title: Localization("Error"), message: Localization("Only30Stories"))
                
                return
            }
        }
        
        let curWork:NewsFeedItem = works[sender.tag]
        
        showLoadingView(msg: "\(Localization("DwnloadingWrk")) \(curWork.title)")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        request("https://archiveofourown.org/works/" + curWork.workId, method: .get, parameters: params)
            .response(completionHandler: { response in
                print(response.request ?? "")
                //  println(response)
                print(response.error ?? "")
                self.parseCookies(response)
                if let d = response.data {
                    let _ = self.downloadWork(d, curWork: curWork)
                    self.hideLoadingView()
                } else {
                    RMessage.showNotification(in: self, title: Localization("Error"), subtitle: Localization("CannotDwnldWrk"), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                    self.hideLoadingView()
                }
            })
    }
    
    
    func saveWork() {
        hideLoadingView()
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "SubsCell"
        
        var cell:SubsCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? SubsCell
        
        if (cell == nil) {
            cell = SubsCell(reuseIdentifier: cellIdentifier)
        }
        
        let curWork:NewsFeedItem = works[indexPath.row]
        
        cell?.topicLabel.text = curWork.topic.replacingOccurrences(of: "\n", with: "")
        cell?.downloadButton.tag = indexPath.row
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell?.backgroundColor = AppDelegate.greyLightBg
        } else {
            cell?.backgroundColor = AppDelegate.greyDarkBg
        }
        
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
        
        cell.titleLabel.text = pages[indexPath.row].name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            showLoadingView(msg: "\(Localization("LoadingPage")) \(page.name)")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.error ?? "")
                if let data = response.data {
                    self.parseCookies(response)
                    self.parseSubs(data)
                    self.showSubs()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
            
        }
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
            
        } else if (segue.identifier == "serieDetail") {
            if let row = tableView.indexPathForSelectedRow?.row {
                
                if (row < works.count) {
                    selectedSerieDetail(segue: segue, row: row, newsItem: works[row])
                }
            }
            
        }
        
        hideBackTitle()
    }
}
