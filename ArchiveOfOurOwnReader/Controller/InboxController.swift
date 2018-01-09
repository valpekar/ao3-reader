//
//  InboxController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/9/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import TSMessages

class InboxController : ListViewController  {
    
    var titleStr = NSLocalizedString("Inbox", comment: "")
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    
    var inboxItemsRead: [InboxItem] = [InboxItem]()
    var inboxItemsUnread: [InboxItem] = [InboxItem]()
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Inbox", comment: "")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("PullToRefresh", comment: ""))
        self.refreshControl.addTarget(self, action: #selector(HistoryViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 80
        
        self.tableView.tableFooterView = UIView()
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            
            requestInbox()
        } else if ((UIApplication.shared.delegate as! AppDelegate).cookies.count == 0 || (UIApplication.shared.delegate as! AppDelegate).token.isEmpty) {
            
            openLoginController()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    func refresh(_ sender:AnyObject) {
        requestInbox()
    }
    
    @IBAction func tryAgainTouched(_ sender:AnyObject) {
        requestInbox()
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
    
    //MARK: - request Inbox
    
    func requestInbox() {
        let username = DefaultsManager.getString(DefaultsManager.LOGIN)
        
        showLoadingView(msg: NSLocalizedString("GettingInbox", comment: ""))
        
        if ((UIApplication.shared.delegate as! AppDelegate).cookies.count > 0) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies((UIApplication.shared.delegate as! AppDelegate).cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        let urlStr: String = "https://archiveofourown.org/users/" + username + "/inbox"
        
        Alamofire.request(urlStr) //default is .get
            .response(completionHandler: { response in
                
                #if DEBUG
                    //print(request)
                    print(response.error ?? "")
                #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseInbox(d)
                    self.refreshControl.endRefreshing()
                    self.showInbox()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                    
                }
            })
    }
    
    func parseInbox(_ data: Data) {
        inboxItemsUnread.removeAll(keepingCapacity: false)
        inboxItemsRead.removeAll(keepingCapacity: false)
        pages.removeAll(keepingCapacity: false)
        
        #if DEBUG
            let string1 = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(string1 ?? "")
        #endif
        
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let headerEls: [TFHppleElement] = doc.search(withXPathQuery: "//h2[@class='heading']") as? [TFHppleElement] {
            if (headerEls.count > 0) {
                titleStr = headerEls[0].content
            }
        }
        
        if let inboxlist : [TFHppleElement] = doc.search(withXPathQuery: "//ol[@class='comment index group']//li") as? [TFHppleElement] {
            
            if (inboxlist.count > 0) {
                
                for commentItem in inboxlist {
                    parseItem(commentItem)
                }
                
            }
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
    
    func parseItem(_ commentItem: TFHppleElement) {
        var item = InboxItem()
        var isRead = false
        
        guard let attributes : NSDictionary = commentItem.attributes as NSDictionary? else { return }
        let classStr = (attributes["class"] as? String ?? "")
        if (classStr.contains("unread") && classStr.contains("comment")) {
            isRead = false
        } else if (classStr.contains("read") && classStr.contains("comment")) {
            isRead = true
        } else {
            return
        }
        
        if let linkEls = commentItem.search(withXPathQuery: "//a") as? [TFHppleElement] {
            for linkEl in linkEls {
                if let attributes : NSDictionary = linkEl.attributes as NSDictionary? {
                    let linkStr = (attributes["href"] as? String ?? "")
                    
                    if (linkStr.contains("/users/") && linkEl.raw.contains("img") == false && linkStr.contains("reply") == false) {
                        item.userUrl = linkStr
                        item.userName = linkEl.content
                    } else if (linkStr.contains("works")) {
                        item.workUrl = linkStr
                        item.workName = linkEl.content
                    }
                }
            }
        }
        
        if let userStuffEl = commentItem.search(withXPathQuery: "//blockquote[@class='userstuff']") as? [TFHppleElement] {
            if (userStuffEl.count > 0) {
                item.text = userStuffEl[0].content.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
            }
        }
        
        if let actionsEls = commentItem.search(withXPathQuery: "//ul[@class='actions']//li//input") as? [TFHppleElement] {
            for actionsEl in actionsEls {
                if let attributes : NSDictionary = actionsEl.attributes as NSDictionary? {
                    let val = (attributes["value"] as? String ?? "")
                    if (val.isEmpty == false) {
                        item.commentId = val
                    }
                }
            }
        }
        
        if (isRead == true) {
            inboxItemsRead.append(item)
        } else {
            inboxItemsUnread.append(item)
        }
    }
    
    func showInbox() {
        if (inboxItemsUnread.count > 0 || inboxItemsRead.count > 0) {
            tableView.isHidden = false
            errView.isHidden = true
        } else {
            tableView.isHidden = true
            errView.isHidden = false
        }
        
        tableView.reloadData()
        collectionView.reloadData()
        
        hideLoadingView()
        self.navigationItem.title = titleStr
        
        tableView.setContentOffset(CGPoint.zero, animated:true)
    }
}

//MARK: - tableview

extension InboxController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return inboxItemsUnread.count
        case 1:
            return inboxItemsRead.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "Unread"
        case 1:
            return "Read"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "InboxItemCell"
        
        let cell:InboxItemCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! InboxItemCell
        
        var curItem:InboxItem = InboxItem()
        if (indexPath.section == 0) {
            curItem = inboxItemsUnread[indexPath.row]
        } else if (indexPath.section == 1) {
            curItem = inboxItemsRead[indexPath.row]
        }
        
        cell.titleLabel.text = "\(curItem.userName) on \(curItem.workName)"
        cell.dateLabel.text = "\(curItem.date)"
        cell.contentLabel.text = "\(curItem.text)"
        
        cell.tag = indexPath.row
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.titleLabel.textColor = UIColor.black
            cell.dateLabel.textColor = UIColor.black
            cell.titleLabel.textColor = UIColor.black
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.titleLabel.textColor = AppDelegate.nightTextColor
            cell.dateLabel.textColor = AppDelegate.nightTextColor
            cell.titleLabel.textColor = AppDelegate.nightTextColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch(indexPath.section) {
        case 0:
            if (indexPath.row < inboxItemsUnread.count) {
                selectItem(inboxItem: inboxItemsUnread[indexPath.row])
            }
        case 1:
            if (indexPath.row < inboxItemsRead.count) {
                selectItem(inboxItem: inboxItemsRead[indexPath.row])
            }
            
        default: break
        }
        
    }
    
    func selectItem(inboxItem: InboxItem) {
        
    }
}

//MARK: - collectionview

extension InboxController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
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
            
            showLoadingView(msg: "\(NSLocalizedString("LoadingPage", comment: "")) \(page.name)")
            
            Alamofire.request("https://archiveofourown.org" + page.url, method: .get).response(completionHandler: { response in
                print(response.error ?? "")
                if let data = response.data {
                    self.parseCookies(response)
                    self.parseInbox(data)
                    self.showInbox()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: AppDelegate.smallCollCellWidth, height: 28)
    }
}
