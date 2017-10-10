//
//  SerieViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/9/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire
import TSMessages

class SerieViewController: LoadingViewController, UITableViewDataSource, UITableViewDelegate {
    
    var serieId: String = ""
    var serieItem: SerieItem = SerieItem()
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var errView:UIView!
    var refreshControl: UIRefreshControl!
    
    var pages : [PageItem] = [PageItem]()
    var works : [NewsFeedItem] = [NewsFeedItem]()
    
    var worksCount = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 240
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(SerieViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        requestSerie()
    }
    
    func refresh(_ sender:AnyObject) {
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
        
        showLoadingView(msg: NSLocalizedString("GettingWorks", comment: ""))
        
        let urlStr = "https://archiveofourown.org\(serieId)"
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                print(response.request ?? "")
                print(response.error ?? "")
                if let d = response.data {
                    self.parseCookies(response)
                    (self.pages, self.works, self.serieItem) = WorksParser.parseSerie(d)
                    self.parseSerie(data: d)
                    self.showSerie()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: "Error", subtitle: "Check your Internet connection", type: .error)
                }
                self.refreshControl.endRefreshing()
            })
    }
    
    func parseSerie(data: Data) {
        
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
    }
    
    //MARK: - tableview
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return works.count
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
            
            let curWork:NewsFeedItem = works[(indexPath as NSIndexPath).row]
            
            cell = fillCell(cell: cell, curWork: curWork)
            
            cell.downloadButton.tag = (indexPath as NSIndexPath).row
            
            return cell
        }
    }
}
