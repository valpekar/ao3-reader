//
//  SerieViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/9/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import RMessage
import Crashlytics
import Firebase

class SerieViewController: ListViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var serieId: String = ""
    var serieItem: SerieItem = SerieItem()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    var refreshControl: UIRefreshControl!
    
    var lastAction = ""
    
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomButtonsConstraint: NSLayoutConstraint!
    
    
    var worksCount = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(SerieViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        Answers.logCustomEvent(withName: "Serie_opened",
                               customAttributes: [
                                "serieId": serieId])
        
        requestSerie()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let navVC = self.navigationController else {
            return
        }
        navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = false
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
    
    @IBAction func editTouched(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: Localization("WrkOptions"), preferredStyle: .actionSheet)
        optionMenu.view.tintColor = AppDelegate.redColor
        
        if (serieItem.subscribed == false) {
            let shareAction = UIAlertAction(title: Localization("Subscribe"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.subscribeToSerie(action: "Subscribe")
            })
            optionMenu.addAction(shareAction)
        } else {
            let unSubAction = UIAlertAction(title: Localization("Unsubscribe"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.subscribeToSerie(action: "Unsubscribe")
            })
            optionMenu.addAction(unSubAction)
        }
        
        let cancelAction = UIAlertAction(title: Localization("Cancel"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView =  self.tableView
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.tableView.bounds.size.width / 2.0, y: self.tableView.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        optionMenu.view.tintColor = AppDelegate.redColor
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @objc func refresh(_ sender:AnyObject) {
        requestSerie()
    }
    
    func requestSerie() {
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
        }
        
        let checkItems = self.getDownloadedStats()
        
        showLoadingView(msg: Localization("GettingWorks"))
        
        let urlStr = "https://archiveofourown.org\(serieId)"
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    
                    (self.pages, self.works, self.serieItem) = WorksParser.parseSerie(d, downloadedCheckItems: checkItems)
                    self.showSerie()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: Localization("Error"), subtitle: Localization("CheckInternet"), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
                self.refreshControl.endRefreshing()
            })
    }
    
    func showSerie() {
        if (works.count > 0 || !serieItem.title.isEmpty) {
            tableView.isHidden = false
            errView.isHidden = true
        } else {
            tableView.isHidden = true
            errView.isHidden = false
        }
        
        tableView.reloadData()
        collectionView.reloadData()
        
        hideLoadingView()
        self.navigationItem.title = serieItem.title
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if (self.tableView.numberOfSections > 0 && self.tableView.numberOfRows(inSection: 0) > 0) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        collectionView.flashScrollIndicators()
        
        if (pages.count == 0) {
            stackHeightConstraint.isActive = false
            bottomButtonsConstraint.isActive = false
            bottomViewConstraint.isActive = true
        } else {
            stackHeightConstraint.isActive = true
            bottomButtonsConstraint.isActive = true
            bottomViewConstraint.isActive = false
        }
    }
    
    func subscribeToSerie(action: String) {
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            openLoginController()
            self.lastAction = action
            return
        }
        
        showLoadingView(msg: Localization("Subscribing"))
        
        let requestStr = "https://archiveofourown.org\(serieItem.subscribeActionUrl)"
        
        Answers.logCustomEvent(withName: "Serie: Subscribe",
                               customAttributes: [
                                "serieId": serieItem.serieId])
        Analytics.logEvent("Serie_Subscribe", parameters: ["serieId": serieItem.serieId as NSObject])
        
        var params:[String:Any] = [String:Any]()
        params["utf8"] = "✓" as AnyObject?
        params["authenticity_token"] = serieItem.subscribeAuthToken
        
        params["subscription"] = ["subscribable_id": serieItem.subscribableId,
                              "subscribable_type": serieItem.subscribableType
            ]  as AnyObject?
        
        params["commit"] = action as AnyObject?
        
        if (action.contains("Unsubscribe")) {
            params["_method"] = "delete"
        }
        
        let headers: HTTPHeaders = [
            "Referer": "https://archiveofourown.org/series/\(serieItem.subscribableId)",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            }
            
            if (del.cookies.count > 0) {
                Alamofire.request(requestStr, method: .post, parameters: params, encoding: URLEncoding.httpBody /*ParameterEncoding.Custom(encodeParams)*/, headers: headers)
                    .response(completionHandler: { response in
                        #if DEBUG
                        print(response.request ?? "")
                        // print(response)
                        print(response.error ?? "")
                        #endif
                        
                        if let d = response.data {
                            self.parseCookies(response)
                            self.parseSubscribeSerieResponse(d)
                            self.hideLoadingView()
                            
                        } else {
                            self.hideLoadingView()
                            self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                        }
                    })
            }
        }
    }
    
    func controllerDidClosedWithLogin() {
        self.subscribeToSerie(action: self.lastAction)
    }
    
    func parseSubscribeSerieResponse(_ data: Data) {
        #if DEBUG
        let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print("the string is: \(String(describing: dta))")
        #endif
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let noticediv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='flash notice']") as? [TFHppleElement] {
            if(noticediv.count > 0) {
                self.showSuccess(title: Localization("Subscribing"), message: noticediv[0].content)
                
                if (noticediv[0].content.contains("following")) {
                    self.serieItem.subscribed = true
                } else if (noticediv[0].content.contains("successfully unsubscribed")) {
                    self.serieItem.subscribed = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.refresh(self.tableView)
                }
            }
        }
        
        if let sorrydiv = doc.search(withXPathQuery: "//div[@class='flash error']") {
            
            if(sorrydiv.count>0 && (sorrydiv[0] as! TFHppleElement).text().range(of: "Sorry") != nil) {
                self.showError(title: Localization("Subscribing"), message: (sorrydiv[0] as AnyObject).content ?? "")
                return
            }
        }
        
        if (data.isEmpty) {
            self.showError(title: Localization("CannotSubscribe"), message: "Response Is Empty")
        }
        return
    }
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        if (sender.tag >= works.count) {
            return
        }
        
        let curWork:NewsFeedItem = works[sender.tag]
        showLoadingView(msg: "\(Localization("DwnloadingWrk")) \(curWork.title)")
        
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
                print(response.error ?? "")
                    #endif
                if let d = response.data {
                    self.parseCookies(response)
                    let _ = self.downloadWork(d, curWork: curWork)
                    //self.saveWork()
                } else {
                    self.hideLoadingView()
                    RMessage.showNotification(in: self, title: Localization("Error"), subtitle: Localization("CheckInternet"), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                }
            })
    }
    
    override func downloadTouched(rowIndex: Int) {
        super.downloadTouched(rowIndex: rowIndex - 1)
    }
    
    override func reload(row: Int) {
        self.tableView.reloadRows(at: [ IndexPath(row: row, section: 0)], with: UITableView.RowAnimation.automatic)
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.row == 0) {
            let cellIdentifier = "SerieInfoCell"
            
            var cell: SerieInfoCell! = nil
            if let c:SerieInfoCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SerieInfoCell {
                cell = c
            } else {
                cell = SerieInfoCell(reuseIdentifier: cellIdentifier)
            }
            
            cell.titleLabel.text = serieItem.title
            cell.authorLabel.text = serieItem.author
            cell.descLabel.text = serieItem.desc
            cell.notesLabel.text = serieItem.notes
            cell.begunLabel.text = "Series Begun \(serieItem.serieBegun)"
            cell.endedLabel.text = "Series Updated \(serieItem.serieUpdated)"
            cell.statsLabel.text = "Stats: \(serieItem.stats)"
            
            if (theme == DefaultsManager.THEME_DAY) {
                cell.backgroundColor = AppDelegate.greyLightBg
                cell.titleLabel.textColor = UIColor.black
                cell.authorLabel.textColor = UIColor.black
                cell.descLabel.textColor = UIColor.black
                cell.notesLabel.textColor = UIColor.black
                cell.begunLabel.textColor = UIColor.black
                cell.endedLabel.textColor = UIColor.black
                cell.statsLabel.textColor = AppDelegate.redColor
                
            } else {
                cell.backgroundColor = AppDelegate.greyDarkBg
                cell.titleLabel.textColor = AppDelegate.textLightColor
                cell.authorLabel.textColor = AppDelegate.textLightColor
                cell.descLabel.textColor = AppDelegate.textLightColor
                cell.notesLabel.textColor = AppDelegate.textLightColor
                cell.begunLabel.textColor = AppDelegate.textLightColor
                cell.endedLabel.textColor = AppDelegate.textLightColor
                cell.statsLabel.textColor = AppDelegate.purpleLightColor
            }
            
            return cell
            
        } else {
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
            
            let curWork:NewsFeedItem = works[indexPath.row - 1]
            
            cell = fillCellXib(cell: cell, curWork: curWork, needsDelete: false, index: indexPath.row)
            
            cell.workCellView.tag = indexPath.row - 1
            cell.workCellView.downloadButtonDelegate = self
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row > 0) {
            selectCell(row: indexPath.row - 1, works: works)
        }
    }
    
    //MARK: - collectionview
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier: String = "PageCell"
        
        let cell: PageCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PageCollectionViewCell
        
        cell.titleLabel.text = pages[indexPath.row].name
        
        if (pages[(indexPath as NSIndexPath).row].url.isEmpty) {
            cell.titleLabel.textColor = UIColor(red: 169/255, green: 164/255, blue: 164/255, alpha: 1)
        } else {
            cell.titleLabel.textColor = UIColor.black
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let page: PageItem = pages[indexPath.row]
        if (!page.url.isEmpty) {
            
            if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: "https://archiveofourown.org"), mainDocumentURL: nil)
            }
            
            let checkItems = self.getDownloadedStats()
            
            showLoadingView(msg: "\(Localization("GettingWorks")) \(page.name)")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d: Data = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.serieItem) = WorksParser.parseSerie(d, downloadedCheckItems: checkItems)
                    self.showSerie()
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
                if (row - 1 < works.count) {
                    selectedWorkDetail(segue: segue, row: row, modalDelegate: self, newsItem: works[row - 1])
                }
            }
            
        }
        
        hideBackTitle()
    }
    
    override func controllerDidClosed() {
    }
    
}
