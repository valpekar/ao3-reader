//
//  PopOverViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 1/31/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit
import Alamofire

class PopOverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectionProtocol: SelectionProtocol?
    
    @IBOutlet weak var tokenView: NWSTokenView!
    
    @IBOutlet weak var tokenViewHeightConstraint: NSLayoutConstraint!
    
    var sectionNameToSearch = "fandom"
    
    let tokenViewMinHeight: CGFloat = 40.0
    let tokenViewMaxHeight: CGFloat = 150.0
    
    var fandoms: [FandomObject] = []
    var selectedFandoms: [FandomObject] = []
    
    var isSearching = false
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust tableView offset for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(PopOverViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PopOverViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // TokenView
        tokenView.layoutIfNeeded()
        tokenView.dataSource = self
        tokenView.delegate = self
        tokenView.reloadData()
        
        tokenView.layer.borderColor = AppDelegate.redColor.cgColor
        tokenView.layer.borderWidth = 0.5
        tokenView.layer.cornerRadius = 5.0
        
        self.tableView.tableFooterView = UIView()
        
        self.tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tokenView.textView.becomeFirstResponder()
    }
    
    
    // Returns count of items in tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fandoms.count
    }
    
    
    // Select item from tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! NWSTokenViewCell
        cell.isSelected = false
        
        // Check if already selected
        if (selectedFandoms.filter{$0.sectionName == cell.object.sectionName}.count == 0)
        {
            cell.object.isSelected = true
            self.selectedFandoms.append(cell.object)
            isSearching = false
            tokenView.textView.text = ""
            tokenView.reloadData()
            tableView.reloadData()
        }
        
    }
    
    //Assign values for tableView
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: NWSTokenViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NWSTokenViewCell
        
        let obj = fandoms[indexPath.row]
        cell.nameLabel.text = obj.sectionName
        
        cell.object = obj
        
        return cell
    }
    
    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if let view = touch.view
        {
            if view.isDescendant(of: tableView)
            {
                return false
            }
        }
        return true
    }
    
    // MARK: Keyboard
    @objc func keyboardWillShow(_ notification: Notification)
    {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
            
        }
    }
    
    @objc func keyboardWillHide(_ notification: NotificationCenter)
    {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    @IBAction func didTapView(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    func dismissKeyboard()
    {
        tokenView.resignFirstResponder()
        tokenView.endEditing(true)
    }
    
    // Close PopUpr
    @IBAction func cancelTouched(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func okTouched(_ sender: Any) {
        
        self.dismiss(animated: true, completion: {
            self.selectionProtocol?.itemsSelected(items: self.selectedFandoms)
        })
    }
}

extension PopOverViewController: NWSTokenDelegate, NWSTokenDataSource {
    
    func tokenView(_ tokenView: NWSTokenView, didSelectTokenAtIndex index: Int) {
        let token = tokenView.tokenForIndex(index) as! NWSSelToken
        token.backgroundColor = UIColor.gray
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int) {
        let token = tokenView.tokenForIndex(index) as! NWSSelToken
        token.backgroundColor = UIColor.clear
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int) {
        // Ensure index is within bounds
        if index < self.selectedFandoms.count
        {
            var object = self.selectedFandoms[index] as FandomObject
            object.isSelected = false
            self.selectedFandoms.remove(at: index)
            
            tokenView.reloadData()
            tableView.reloadData()
            tokenView.layoutIfNeeded()
            tokenView.textView.becomeFirstResponder()
            
            // Check if search text exists, if so, reload table (i.e. user deleted a selected token by pressing an alphanumeric key)
//            if tokenView.textView.text != ""
//            {
//                self.searchContacts(tokenView.textView.text)
//            }
        }
    }
    
    func tokenView(_ tokenViewDidBeginEditing: NWSTokenView) {
        
    }
    
    func tokenViewDidEndEditing(_ tokenView: NWSTokenView) {
        
    }
    
    func tokenView(_ tokenView: NWSTokenView, didChangeText text: String) {
        if text.isEmpty == false {
            timer.invalidate()
            
            let timeinterval: TimeInterval = TimeInterval(exactly: 0.5)!
            timer = Timer.scheduledTimer(withTimeInterval: timeinterval, repeats: false, block: { (timer) in
                print("go get after timer")
                self.getFandomByText(text: text, listener: self)
            })
            
        }
    }
    
    func tokenView(_ tokenView: NWSTokenView, didEnterText text: String) {
        
    }
    
    func tokenView(_ tokenView: NWSTokenView, contentSizeChanged size: CGSize) {
        self.tokenViewHeightConstraint.constant = max(tokenViewMinHeight,min(size.height, self.tokenViewMaxHeight))
        self.view.layoutIfNeeded()
    }
    
    func tokenView(_ tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int) {
        
    }
    
    func insetsForTokenView(_ tokenView: NWSTokenView) -> UIEdgeInsets? {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int {
        return selectedFandoms.count
    }
    
    func titleForTokenViewLabel(_ tokenView: NWSTokenView) -> String? {
        return ""
    }
    
    func titleForTokenViewPlaceholder(_ tokenView: NWSTokenView) -> String? {
        return ""
    }
    
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView? {
        let fandomObject = selectedFandoms[index]
        if let token = NWSSelToken.initWithTitle(title: fandomObject.sectionName)
        {
            return token
        }
        return nil
    }
    
    
}

protocol SelectionProtocol {
    func itemsSelected(items: [FandomObject])
}

open class NWSSelToken: NWSToken
{
    @IBOutlet weak var titleLabel: UILabel!
    
    public class func initWithTitle(title: String) -> NWSSelToken?
    {
        if let token = UINib(nibName: "NWSSelToken", bundle:nil).instantiate(withOwner: nil, options: nil)[0] as? NWSSelToken
        {
            token.backgroundColor = UIColor(red: 194.0/255.0, green: 196.0/255.0, blue: 248.0/255.0, alpha: 1.0)
            let oldTextWidth = token.titleLabel.bounds.width
            token.titleLabel.text = title
            token.titleLabel.sizeToFit()
            token.titleLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            let newTextWidth = token.titleLabel.bounds.width
            
            token.layer.cornerRadius = 5.0
            token.clipsToBounds = true
            
            // Resize to fit text
            token.frame.size = CGSize(width: token.frame.size.width+(newTextWidth-oldTextWidth), height: token.frame.height)
            token.setNeedsLayout()
            token.frame = token.frame
            
            return token
        }
        return nil
    }
}

extension PopOverViewController: GetFandomsProtocol {
    
    func fandomsGot(fandoms: [FandomObject]) {
        self.fandoms = fandoms
        self.tableView.reloadData()
    }
}

extension PopOverViewController {
    
    func getFandomByText(text: String, listener: GetFandomsProtocol) {
        let requestStr = "https://archiveofourown.org/autocomplete/\(self.sectionNameToSearch)"
        
        var params:[String:Any] = [String:Any]()
        params["term"] = text
        
        if let cookies = (UIApplication.shared.delegate as? AppDelegate)?.cookies,
            cookies.count > 0 {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookies(cookies, for:  URL(string: AppDelegate.ao3SiteUrl), mainDocumentURL: nil)
        }
        
        let headers: HTTPHeaders = [
            "Referer": "https://archiveofourown.org/works/search?edit_search=true&utf8=%E2%9C%93&work_search%5Bquery%5D=",
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "X-Requested-With" : "XMLHttpRequest",
            "content-type": "application/x-www-form-urlencoded",
            "Accept-Encoding" : "br, gzip, deflate"
        ]
        
        Alamofire.request(requestStr, method: .get, parameters: params, encoding:URLEncoding.queryString /*ParameterEncoding.Custom(encodeParams)*/, headers: headers)
            .response(completionHandler: { response in
                #if DEBUG
                print(response.request ?? "")
                // print(response.response ?? "")
                print(response.error ?? "")
                #endif
                
                if let d = response.data {
                    self.parseCookies(response)
                    self.parseGetFandomResponse(d, listener: listener)
                    //  self.hideLoadingView()
                    
                } else {
                    //  self.hideLoadingView()
                    // self.showError(title: Localization("Error"), message: Localization("CheckInternet"))
                }
            })
        
    }
    
    func parseGetFandomResponse(_ data: Data, listener: GetFandomsProtocol) {
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                var fandoms: [FandomObject] = []
                
                for jsonItem in json {
                    if let dictionary = jsonItem as? [String: Any] {
                        if let id = dictionary["id"] as? String, let name = dictionary["name"] as? String {
                            fandoms.append(FandomObject(sectionName: name, sectionObject: id, isSelected: false))
                        }
                    }
                }
                
                listener.fandomsGot(fandoms: fandoms)
            }
            
        } catch {
            print("Error: Couldn't parse JSON. \(error.localizedDescription)")
        }
    }
    
    func parseCookies(_ response: DefaultDataResponse) {
        // let headers = response.allHeaderFields
        guard let resp = response.response else {
            return
        }
        guard var allHeaders = resp.allHeaderFields as? [String: String] else {
            return
        }
        
        allHeaders["user_credentials"] = "1"
        
        let cookiesH: [HTTPCookie] = HTTPCookie.cookies(withResponseHeaderFields: allHeaders, for: URL(string: AppDelegate.ao3SiteUrl)!)
        //let cookies = headers["Set-Cookie"]
        if (cookiesH.count > 0) {
            (UIApplication.shared.delegate as! AppDelegate).cookies = cookiesH
            DefaultsManager.putObject(cookiesH as AnyObject, key: DefaultsManager.COOKIES)
        }
        
        // print(cookies)
    }
}

class NWSTokenViewCell: UITableViewCell
{
    @IBOutlet weak var nameLabel: UILabel!
    
    var object: FandomObject!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
    }
}
