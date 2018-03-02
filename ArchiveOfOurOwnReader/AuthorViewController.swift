//
//  AuthorViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/1/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire
import AlamofireImage
import TSMessages

class AuthorViewController: LoadingViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var picImg: UIImageView!
    
    var authorName: String = ""
    var imgUrl: String = ""
    var tagUrl: String = ""
    var mainEl = "works"
    
    var bio: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        
        getUserProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            nameLabel.textColor = AppDelegate.redColor
            bioLabel.textColor = AppDelegate.greyColor
            
            self.tableView.backgroundColor = AppDelegate.greyLightBg
        
        } else {
            nameLabel.textColor = AppDelegate.purpleLightColor
            bioLabel.textColor = AppDelegate.textLightColor
            
            self.tableView.backgroundColor = AppDelegate.greyDarkBg
        }
    }
    
    func getUserProfile() {
        if let del = UIApplication.shared.delegate as? AppDelegate {
            if (del.cookies.count > 0) {
                guard let cStorage = Alamofire.SessionManager.default.session.configuration.httpCookieStorage else {
                    return
                }
                cStorage.setCookies(del.cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
            }
        }
        
        showLoadingView(msg: NSLocalizedString("GettingAuthorInfo", comment: ""))
        
        let urlStr = "\(AppDelegate.ao3SiteUrl)/users/\(authorName)/profile"
        
        Answers.logCustomEvent(withName: "Author",
                               customAttributes: [
                                "urlStr": urlStr])
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseAuthorProfileResponse(d)
                    self.showProfile()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    TSMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("CheckInternet", comment: ""), type: .error)
                }
            })
    }
    
    func parseAuthorProfileResponse(_ data: Data) {
        #if DEBUG
            let dta = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print("the string is: \(String(describing: dta))")
        #endif
        let doc : TFHpple = TFHpple(htmlData: data)
        
        if let biodiv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='user home profile']//div[@class='bio module']//blockquote[@class='userstuff']") as? [TFHppleElement] {
            if(biodiv.count > 0) {
                self.bio = biodiv[0].content
            }
        }
        
        if let picdiv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@class='user home profile']//div[@class='primary header module']//img[@class='icon']") as? [TFHppleElement] {
            if(picdiv.count > 0) {
                if let imgAttributes : NSDictionary = picdiv[0].attributes as NSDictionary? {
                    if let imgAttr: String = imgAttributes["src"] as? String, imgAttr.isEmpty == false {
                        self.imgUrl = imgAttr
                    }
                }
            }
        }
    }
    
    func showProfile() {
        bioLabel.text = self.bio
        nameLabel.text = self.authorName
        
        if let url = URL(string: self.imgUrl) {
        picImg.af_setImage(
            withURL: url,
            placeholderImage: UIImage(named: "user_pic"),
            filter: AspectScaledToFillSizeCircleFilter(size: CGSize(width: 80, height: 80)),
            imageTransition: .crossDissolve(0.2)
        )
        }
    }
    
    func authorWorksTouched(uri: String) {
        
        Answers.logCustomEvent(withName: "Author: author \(uri) touched",
                               customAttributes: [
                                "author": authorName])
        
        if (authorName.contains(" ") && !authorName.contains(",")) {
            let nameArr = authorName.split{$0 == " "}.map(String.init)
            var an = nameArr[1].replacingOccurrences(of: "(", with: "")
            an = an.replacingOccurrences(of: ")", with: "")
            tagUrl = "https://archiveofourown.org/users/\(an)/pseuds/\(nameArr[0])/\(uri)"
        } else if (authorName.contains(",")) {
            let nameArr = authorName.split{$0 == ","}.map(String.init)
            tagUrl = "https://archiveofourown.org/users/\(nameArr[0])/\(uri))"
        } else {
            tagUrl = "https://archiveofourown.org/users/\(authorName)/\(uri)"
        }
        
        performSegue(withIdentifier: "listSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "listSegue") {
            if let cController: WorkListController = segue.destination as? WorkListController {
                cController.tagUrl = tagUrl
                cController.worksElement = mainEl
                cController.liWorksElement = mainEl
            }
        }
        
        hideBackTitle()
    }
}

//MARK: Tableview

extension AuthorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyProfileCell = tableView.dequeueReusableCell(withIdentifier: "pseudCell") as! MyProfileCell
        
        switch (indexPath.row) {
        case 0:
            cell.titleLabel.text = "Works"
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.titleLabel.text = "Series"
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.titleLabel.text = "Bookmarks"
            cell.accessoryType = .disclosureIndicator
            
        default: break
        }
        
        if (theme == DefaultsManager.THEME_DAY) {
            cell.backgroundColor = AppDelegate.greyLightBg
            cell.titleLabel.textColor = AppDelegate.redTextColor
        } else {
            cell.backgroundColor = AppDelegate.greyDarkBg
            cell.titleLabel.textColor = AppDelegate.textLightColor
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.row) {
        case 0:
            self.mainEl = "work"
            self.authorWorksTouched(uri: "works")
        case 1:
            self.mainEl = "series"
            self.authorWorksTouched(uri: "series")
        case 2:
            self.mainEl = "bookmark"
            self.authorWorksTouched(uri: "bookmarks")
            
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
