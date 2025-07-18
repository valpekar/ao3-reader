//
//  MarkedForLaterController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 12/21/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire

class MarkedForLaterController: ListViewController , UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //https://medium.com/zenchef-tech-and-product/how-to-visualize-reusable-xibs-in-storyboards-using-ibdesignable-c0488c7f525d
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var refreshControl: RefreshControl!
    
    var authToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createDrawerButton()
        
        self.worksElement = "reading work"
        self.itemsCountHeading = "h2"
        self.foundItems = Localization("MarkedForLater")
        
        self.title = Localization("MarkedForLater")
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.refreshControl = RefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: Localization("PullToRefresh"))
        refreshControl.backgroundColor = UIColor(named: "tableViewBg")
        self.refreshControl.addTarget(self, action: #selector(MarkedForLaterController.refresh(_:)), for: UIControl.Event.valueChanged)
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
        
        self.tableView.backgroundColor = UIColor(named: "tableViewBg")
        self.collectionView.backgroundColor = UIColor(named: "tableViewBg")
    }
    
    //MARK: - login
    
    
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        openLoginController()
    }
    
    //MARK: - request
    
    func requestFavs() {
        
        let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        showLoadingView(msg: Localization("GettingHistory"))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        
        let urlStr: String = "https://archiveofourown.org/users/" + username + "/readings"
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["show"] = "to-read" as AnyObject?
        
        Alamofire.request(urlStr, method: .get, parameters: params) //default is .get
            .response(completionHandler: { response in
                #if DEBUG
                    //print(request)
                    print(response.error ?? "")
                #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    let checkItems = self.getDownloadedStats()
                    (self.pages, self.works, self.foundItems, self.authToken) = WorksParser.parseWorks(d, itemsCountHeading: self.itemsCountHeading, worksElement: self.worksElement, downloadedCheckItems: checkItems)
                    //self.parseHistory(d)
                    self.refreshControl.endRefreshing()
                    self.showWorks()
                } else {
                    self.hideLoadingView()
                    
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))

                }
            })
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableView.RowAnimation.automatic)
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
        self.navigationItem.title = "\(Localization("MarkedForLater"))"
        
        if (tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        collectionView.flashScrollIndicators()
    }
    
    override func controllerDidClosed() {}
    
    @objc func controllerDidClosedWithLogin() {
        requestFavs()
    }
    
    @objc func controllerDidClosedWithChange() {
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "FeedCell"
        
        var cell: FeedTableViewCell! = nil
        if let c:FeedTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FeedTableViewCell {
            cell = c
        } else {
            cell = FeedTableViewCell(reuseIdentifier: cellIdentifier)
        }
        
        let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
        
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
        showLoadingView(msg: "\(Localization("DwnloadingWrk")) \(curWork.title)")
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["view_adult"] = "true" as AnyObject?
        
        let urlStr: String = "https://archiveofourown.org/works/" + curWork.workId
        
        Alamofire.request(urlStr, parameters: params) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let _ = self.downloadWork(d, curWork: curWork)
                } else {
                    self.hideLoadingView()
                   
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))

                }
            })
        
    }
    
    //MARK: - delete work from history
    
    @IBAction func deleteButtonTouched(_ sender: UIButton) {
        
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("SureDeleteFromHistory"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            #if DEBUG
                print("Cancel")
            #endif
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[sender.tag]
            self.deleteItemFromHistory(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
        
    }
    
    func deleteItemFromHistory(_ curWork: NewsFeedItem) {
        showLoadingView(msg: Localization("DeletingFromMarked"))
        
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
        
        guard let curPeudId = pseuds[currentPseud] else {
            return
        }
        
        var params:[String:AnyObject] = [String:AnyObject]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = self.authToken as AnyObject?
        params["_method"] = "delete" as AnyObject?
        params["reading"] = curWork.readingId as AnyObject?
        
        let urlStr: String = "https://archiveofourown.org/users/" + curPeudId + "/readings/" + curWork.readingId
        
        Alamofire.request(urlStr, method: .post, parameters: params)
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseDeleteResponse(d, curWork: curWork)
                    self.tableView.reloadData()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))

                }
            })
    }
    
    func parseDeleteResponse(_ data: Data, curWork: NewsFeedItem) {
        /*#if DEBUG
         let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
         print("the string is: \(dta)")
         #endif */
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        var noticediv: [TFHppleElement]? = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement]
        if(noticediv?.count ?? 0 > 0) {
            if let index = self.works.firstIndex( where: {$0.workId == curWork.workId}) {
                self.works.remove(at: index)
            }
            self.showSuccess(title: Localization("DeletingFromMarked"), message: noticediv?[0].content ?? "")
        } else {
            if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") as? [TFHppleElement] {
                
                if(sorrydiv.count>0 && sorrydiv[0].text().range(of: "Sorry") != nil) {
                    
                    self.showError(title: Localization("DeletingFromMarked"), message: sorrydiv[0].content)
                    return
                }
            }
        }
    }
    
    
    override func deleteTouched(rowIndex: Int) {
        let deleteAlert = UIAlertController(title: Localization("AreYouSure"), message: Localization("SureDeleteFromHistory"), preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: { (action: UIAlertAction) in
            #if DEBUG
                print("Cancel")
            #endif
        }))
        
        deleteAlert.addAction(UIAlertAction(title: Localization("Yes"), style: .default, handler: { (action: UIAlertAction) in
            
            let curWork:NewsFeedItem = self.works[rowIndex]
            self.deleteItemFromHistory(curWork)
            
            self.dismiss(animated: true, completion: { () -> Void in
            })
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }
}

