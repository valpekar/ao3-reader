//
//  AuthorViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/1/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import FirebaseCrashlytics
import Alamofire
import AlamofireImage
import ExpandableLabel
import CoreData

class AuthorViewController: LoadingViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var bioLabel: ExpandableLabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var picImg: UIImageView!
    
    var authorName: String = ""
    var imgUrl: String = ""
    var tagUrl: String = ""
    var mainEl = "works"
    
    var bmkCount = "0"
    var worksCount = "0"
    var seriesCount = "0"
    
    var bio: String = ""
    
    var authorIsFav = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = false
        
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        
        self.bioLabel.collapsedAttributedLink = NSAttributedString(string: "More")
        //self.bioLabel.expandedAttributedLink = NSAttributedString(string: "Less")
        self.bioLabel.numberOfLines = 5
        
        getUserProfile()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        nameLabel.textColor = UIColor(named: "global_tint")
        favButton.setTitleColor(UIColor(named: "global_tint"), for: UIControl.State.normal)
        
        bioLabel.textColor = UIColor(named: "textAdditionalInfo")
        
        self.tableView.backgroundColor = UIColor(named: "cellBgColor")
        
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
        
        showLoadingView(msg: Localization("GettingAuthorInfo"))
        
        let urlStr = "\(AppDelegate.ao3SiteUrl)/users/\(authorName)/profile"
        
        Alamofire.request(urlStr) //default is get
            .response(completionHandler: { response in
                #if DEBUG
                    print(response.request ?? "")
                    print(response.error ?? "")
                #endif
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseAuthorProfileResponse(d)
                    self.checkAuthorFav()
                    self.showProfile()
                    self.hideLoadingView()
                } else {
                    self.hideLoadingView()
                    self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
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
        
        if let navDiv: [TFHppleElement] = doc.search(withXPathQuery: "//div[@id='dashboard']//ul[@class='navigation actions']//li") as? [TFHppleElement] {
            for liEl in navDiv {
                if (liEl.content.contains("Works")) {
                    if let number = Int(liEl.content.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        self.worksCount = "\(number)"
                    }
                } else if (liEl.content.contains("Series")) {
                    if let number = Int(liEl.content.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        self.seriesCount = "\(number)"
                    }
                } else if (liEl.content.contains("Bookmarks")) {
                    if let number = Int(liEl.content.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        self.bmkCount = "\(number)"
                    }
                }
            }
        }
    }
    
    func checkAuthorFav() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DBFavAuthor")
        let predicate = NSPredicate(format: "name == %@", self.authorName)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        do{
            let count = try appDelegate.persistentContainer.viewContext.count(for: fetchRequest)
            if(count == 0){
                authorIsFav = false
            }
            else{
                authorIsFav = true
            }
        }
        catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
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
        self.setIsFavButton()
        
        self.tableView.reloadData()
    }
    
    func setIsFavButton() {
        if (authorIsFav == true) {
            favButton.setTitle(Localization("RemAuthFromFav"), for: .normal)
        } else {
            favButton.setTitle(Localization("AddAuthToFav"), for: .normal)
        }
    }
    
    func authorWorksTouched(uri: String) {
        
        if (authorName.contains(" ") && !authorName.contains(",")) {
            let nameArr = authorName.split{$0 == " "}.map(String.init)
            var an = nameArr[1].replacingOccurrences(of: "(", with: "")
            an = an.replacingOccurrences(of: ")", with: "")
            
            var val = nameArr[0]
            if let encodedPseud = val.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)  {
                val = encodedPseud
            }
            
            tagUrl = "https://archiveofourown.org/users/\(an)/pseuds/\(val)/\(uri)"
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
    
    func addAuthorToFav() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "DBFavAuthor",  in: managedContext) else {
                return
            }
            let authorItem = DBFavAuthor(entity: entity, insertInto:managedContext)
            authorItem.name = self.authorName
            authorItem.priority = 0
            authorItem.authorId = ""
            
            do {
                try managedContext.save()
                authorIsFav = true
                
                self.showSuccess(title: Localization("Success"), message: "Suceesfuly added \(self.authorName) to favorites!")
                
            } catch let error as NSError {
                print("Could not save \(String(describing: error.userInfo))")
                self.showError(title: Localization("Error"), message: "Cannot add to favorites")
            }
        self.setIsFavButton()
    }
    
    func removeAuthorFromFav() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "DBFavAuthor")
        fetchRequest.predicate = NSPredicate(format: "name = %@", self.authorName)
        if let authors = (try? managedContext.fetch(fetchRequest)) as? [DBFavAuthor], authors.count > 0 {
        
            let currentAuthor = authors[0]
            managedContext.delete(currentAuthor)
            do {
                try managedContext.save()
                
                authorIsFav = false
                
                 self.showSuccess(title: Localization("Success"), message: "Suceesfuly deleted \(self.authorName) from favorites!")
                
            } catch _ {
                NSLog("Cannot delete fav author")
                self.showError(title: Localization("Error"), message: "Cannot delete from favorites")
            }
        }
        self.setIsFavButton()
        
    }
    
    @IBAction func addToFavTouched(_ sender: AnyObject) {
        if (authorIsFav == false) {
            self.addAuthorToFav()
        }  else {
            self.removeAuthorFromFav()
        }
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
            cell.titleLabel.text = "\(Localization("Works")) (\(self.worksCount))"
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.titleLabel.text = "\(Localization("Series")) (\(self.seriesCount))"
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.titleLabel.text = "\(Localization("Bookmarks")) (\(self.bmkCount))"
            cell.accessoryType = .disclosureIndicator
            
        default: break
        }
        
        cell.backgroundColor = UIColor(named: "cellBgColor")
        cell.titleLabel.textColor = UIColor(named: "textTitleColor")
        
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
