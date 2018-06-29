//
//  MeViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/1/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import Foundation
import StoreKit
import CoreData
import RMessage
import Crashlytics
import SwiftMessages

class MeViewController: LoadingViewController, UITableViewDelegate, UITableViewDataSource, SKPaymentTransactionObserver {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var notifSwitch: UISwitch!
    @IBOutlet weak var notifLabel: UILabel!
    @IBOutlet weak var pseudsTableView: UITableView!
    
    let subTxt = "Application has Auto-Renewable Subscription (Prosub) named Pro Subscription. The subscription price is 1.99$ per month, 4.99$ for quarter (3 month), 19.99$ for year. \nOnce you have purchased it, the subscription starts. Since then every week you will get digitally generated recommendations of fanfics (fanfiction works) to read. \nThe auto-renewable subscription nature: Get work recommendations every week based on what you have read and liked, no ads, download unlimited works. \nSubscription length is 1 month and it is auto-renewable. \n\nPayment will be charged to iTunes Account at confirmation of purchase. \nSubscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. \nAccount will be charged for renewal within 24-hours prior to the end of the current period, and identify the cost of the renewal. \nSubscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase.\nNo cancellation of the current subscription is allowed during active subscription period. \n\nAny unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication. \n\nTo Unsubscribe: \n1. Go to Settings > iTunes & App Store. \n2. Tap your Apple ID at the top of the screen. \n3. Tap View Apple ID. \n4. Tap the subscription that you want to manage. \nIf you don't see a subscription but are still being charged, make sure that you're signed in with the correct Apple ID. \n5. Use the options to manage your subscription. You can tap Cancel Subscription. If you cancel, your subscription will stop at the end of the current billing cycle."
    
    var pseuds: [String:String] = [:]
    var currentPseud = ""
    
    // This list of available in-app purchases
    var products: Array <SKProduct> = [SKProduct]()
    
    @IBOutlet weak var removeAdsItem: UIBarButtonItem!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        self.pseudsTableView.tableFooterView = UIView()
        
        self.pseudsTableView.rowHeight = UITableViewAutomaticDimension
        self.pseudsTableView.estimatedRowHeight = 44
        
        UserDefaults.standard.synchronize()
        
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
            isPurchased = purchased
        }
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
        
        if (purchased == false && donated == false) {
            reload(false, productId: "")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MeViewController.productPurchased(_:)), name: NSNotification.Name(rawValue: IAPHelperProductPurchasedNotification), object: nil)
        //SKPaymentQueue.default().add(self)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        UserDefaults.standard.synchronize()
        
        if let pp = UserDefaults.standard.value(forKey: "pro") as? Bool {
            purchased = pp
        }
        if let dd = UserDefaults.standard.value(forKey: "donated") as? Bool {
            donated = dd
        }
        
        if ((purchased || donated)  && DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        }
        
        UserDefaults.standard.synchronize()
        
        refreshUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        SKPaymentQueue.default().remove(self)
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.pseudsTableView.backgroundColor = AppDelegate.greyLightBg
            self.notifLabel.textColor = UIColor.black
           // loginButton.setTitleColor(AppDelegate.redColor, for: .normal)
        } else {
            self.pseudsTableView.backgroundColor = AppDelegate.greyDarkBg
            self.notifLabel.textColor = AppDelegate.textLightColor
          //  loginButton.setTitleColor(AppDelegate.purpleLightColor, for: .normal)
        }
        
        self.pseudsTableView.reloadData()
    }
    
    //MARK: - log in / out
    func logout() {
        let s: [String:String] = [:]
        
        DefaultsManager.putString("", key: DefaultsManager.LOGIN)
        DefaultsManager.putString("", key: DefaultsManager.PSWD)
        DefaultsManager.putString("", key: DefaultsManager.PSEUD_ID)
        DefaultsManager.putString("", key: DefaultsManager.TOKEN)
        DefaultsManager.putObject(s as AnyObject, key: DefaultsManager.PSEUD_IDS)
        
        pseuds = s
        
        (UIApplication.shared.delegate as! AppDelegate).cookies = [HTTPCookie]()
        DefaultsManager.putObject([HTTPCookie]() as AnyObject, key: DefaultsManager.COOKIES)
        
        pseudsTableView.reloadData()
    }
    
    func login() {
        
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "navLoginViewController") as! UINavigationController
        (nav.viewControllers[0] as! LoginViewController).controllerDelegate = self
        
        self.present(nav, animated: true, completion: nil)
        
    }
    
    @IBAction func loginTouched(_ sender: AnyObject) {
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
        let pass = DefaultsManager.getString(DefaultsManager.PSWD)
        
        if (!login.isEmpty && !pass.isEmpty) {
            logout()
            refreshUI()
        } else {
            self.login()
        }
    }
    
    override func controllerDidClosed() {
        
    }
    
    func controllerDidClosedWithLogin() {
        refreshUI()
    }
    
    func refreshUI() {
        
        let login = DefaultsManager.getString(DefaultsManager.LOGIN)
       // let pass = DefaultsManager.getString(DefaultsManager.PSWD)
        
        if (login.isEmpty == false) {
            usernameLabel.text = login
            
            self.title = login
            
            pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as? [String:String] ?? [:]
            currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
            
            if (currentPseud.isEmpty) {
                let keys = Array(pseuds.keys)
                if (keys.count > 0) {
                    currentPseud = keys[0]
                } 
            }
            
            pseudsTableView.reloadData()
            loginButton.setTitle(NSLocalizedString("LogOut", comment: ""), for: UIControlState())
            
            notifSwitch.isEnabled = true
            
            if let notify = DefaultsManager.getBool(DefaultsManager.NOTIFY) {
                if (notify == true) {
                    notifSwitch.setOn(true, animated: true)
                } else {
                    notifSwitch.setOn(false, animated: true)
                }
            }
            
            self.pseudsTableView.reloadData()
            
        } else {
            setNotAuthorizedUI()
        }
        
        if (purchased == false && donated == false) {
            print("refreshUI: not purchased")
        } else {
            print("refreshUI: purchased = \(purchased), donated = \(donated)")
            removeAdsItem.isEnabled = false
            removeAdsItem.title = ""
        }
    }
    
    func setNotAuthorizedUI() {
        usernameLabel.text = NSLocalizedString("NotAuthorized", comment: "")
        loginButton.setTitle(NSLocalizedString("LogIn", comment: ""), for: UIControlState())
        
        self.title = NSLocalizedString("NotAuthorized", comment: "")
        
        notifSwitch.isEnabled = false
    }
    
    @IBAction func notifSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.NOTIFY)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.NOTIFY)
            UIApplication.shared.cancelAllLocalNotifications()
        }
    }
    
    @IBAction func adultSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.ADULT)
        }
    }
    
    @IBAction func safeSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putBool(true, key: DefaultsManager.SAFE)
        } else {
            DefaultsManager.putBool(false, key: DefaultsManager.SAFE)
        }
    }
    
    @IBAction func nightSwitchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            DefaultsManager.putInt(DefaultsManager.THEME_NIGHT, key: DefaultsManager.THEME_APP)
            Answers.logCustomEvent(withName: "ME_Theme", customAttributes: ["theme" : "night"])
        } else {
            DefaultsManager.putInt(DefaultsManager.THEME_DAY, key: DefaultsManager.THEME_APP)
            Answers.logCustomEvent(withName: "ME_Theme", customAttributes: ["theme" : "day"])
        }
    }
    
    func showSureClearDialog() {
        let deleteAlert = UIAlertController(title: NSLocalizedString("AreYouSure", comment: ""), message: "You want to clear all notifications from this app?", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction) in
            print("Cancel")
        }))
        
        deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action: UIAlertAction) in
            DefaultsManager.putStringArray([], key: DefaultsManager.NOTIF_IDS_ARR)
            self.updateAppBadge()
        }))
        
        deleteAlert.view.tintColor = AppDelegate.redColor
        present(deleteAlert, animated: true, completion: nil)
    }
    
    //Mark: - TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyProfileCell = tableView.dequeueReusableCell(withIdentifier: "pseudCell") as! MyProfileCell
        
        switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.titleLabel.text = "Clear All Notifications"
                cell.accessoryType = .none
            } else {
                cell.titleLabel.text = "Protect with Biometric ID or passcode"
                cell.accessoryType = .disclosureIndicator
            }
        case 1:
            let curKey = Array(pseuds.keys)[indexPath.row]
            cell.titleLabel.text = pseuds[curKey]
            
            if (curKey == currentPseud) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case 2:
            if (indexPath.row == 0) {
                cell.titleLabel.text = "My Works"
            } else if (indexPath.row == 1) {
                cell.titleLabel.text = "Inbox"
            } else {
                cell.titleLabel.text = "My Highlights"
            }
            cell.accessoryType = .none
        case 3:
            if (indexPath.row == 0) {
                cell.titleLabel.text = "Night"
                
                if (theme == DefaultsManager.THEME_DAY) {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
                
            } else if (indexPath.row == 1) {
                cell.titleLabel.text = "Day"
                
                if (theme == DefaultsManager.THEME_DAY) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
            
        case 4:
            cell.accessoryType = .none
            if (indexPath.row == 0) {
                cell.titleLabel.text = subTxt
            } else if (indexPath.row == 1) {
                cell.titleLabel.text = "Privacy Policy and Terms of Use"
            }
            
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 2
        case 1:
            return pseuds.count
        case 2:
            return 3
        case 3:
            return 2
        case 4:
            return 2
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                self.showSureClearDialog()
            } else {
                self.performSegue(withIdentifier: "securitySegue", sender: self)
            }
        case 1:
            let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
            currentPseud = curKey
            DefaultsManager.putString(curKey, key: DefaultsManager.PSEUD_ID)
            
            tableView.reloadData()
        case 2:
            if (indexPath.row == 0) {
                self.performSegue(withIdentifier: "listSegue", sender: self)
            } else if (indexPath.row == 1) {
                self.performSegue(withIdentifier: "inboxSegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "showHighlightsSegue", sender: self)
            }
        case 3:
            if (indexPath.row == 0) {
                theme = DefaultsManager.THEME_NIGHT
                DefaultsManager.putInt(DefaultsManager.THEME_NIGHT, key: DefaultsManager.THEME_APP)
                Answers.logCustomEvent(withName: "ME_Theme", customAttributes: ["theme" : "night"])
            
            } else if (indexPath.row == 1) {
                
                theme = DefaultsManager.THEME_DAY
                DefaultsManager.putInt(DefaultsManager.THEME_DAY, key: DefaultsManager.THEME_APP)
                Answers.logCustomEvent(withName: "ME_Theme", customAttributes: ["theme" : "day"])
            }
            
            applyTheme()
        case 4:
            if (indexPath.row == 1) {
                if let url = URL(string: "http://simpleappalliance.blogspot.com/2016/05/unofficial-ao3-reader-privacy-policy.html") {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (res) in
                        print("open url simpleappalliance.blogspot.com")
                    })
                }
            }
        default: break
            
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "Security Settings"
        case 1:
            return "Pseud for bookmarks, history etc"
        case 2:
            return "My AO3 Account"
        case 3:
            return "Theme"
        case 4:
            return "About Subscription"
        default: return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "listSegue") {
            if let cController: WorkListController = segue.destination as? WorkListController {
                let login = DefaultsManager.getString(DefaultsManager.LOGIN)
                cController.tagUrl = "/users/\(login)/works"
                cController.liWorksElement = "own work"
                cController.worksElement = "work"
            }
        } else if (segue.identifier == "upgradesSegue") {
            if let uController = segue.destination as? UpgradesController {
                uController.products = self.products
                uController.donated = donated
            }
        }
    }
    
    
    // MARK: - InApp
    
    @IBAction func removeAdsTouched(_ sender: AnyObject) {
        
        showLoadingView(msg: NSLocalizedString("RequestingData", comment: ""))
        
        products = []
        
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == "prosub") {
                            product = p
                        }
                    }
                    self.hideLoadingView()
                    self.showBuyAlert(product, restore: true)
                }
            } else {
                self.hideLoadingView()
                self.showErrorAlert(productId: "prosub")
            }
        }
    }
    
    @IBAction func smallTipTouched(_ sender: AnyObject) {
        
        showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
        
        products = []
        
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == "tip.small") {
                            product = p
                        }
                    }
                    self.hideLoadingView()
                    self.showBuyAlert(product, restore: false)
                }
            } else {
                self.hideLoadingView()
                self.showErrorAlert(productId: "tip.small")
            }
        }
    }
    
    @IBAction func mediumTipTouched(_ sender: AnyObject) {
        
        showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
        
        products = []
        
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == "tip.medium") {
                            product = p
                        }
                    }
                    self.hideLoadingView()
                    self.showBuyAlert(product, restore: false)
                }
            } else {
                self.hideLoadingView()
                self.showErrorAlert(productId: "tip.medium")
            }
        }
    }
    
    @IBAction func largeTipTouched(_ sender: AnyObject) {
        showLoadingView(msg: NSLocalizedString("PleaseWait", comment: ""))
        
        products = []
        
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == "tip.large") {
                            product = p
                        }
                    }
                    self.hideLoadingView()
                    self.showBuyAlert(product, restore: false)
                }
            } else {
                self.hideLoadingView()
                self.showErrorAlert(productId: "tip.large")
            }
        }
    }
    
    func showErrorAlert(productId: String) {
        let refreshAlert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: "Cannot get product list. Please check your Internet connection", preferredStyle: UIAlertControllerStyle.alert)
        refreshAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (action: UIAlertAction!) in
            self.reload(true, productId: productId)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    // Fetch the products from iTunes connect, redisplay the table on successful completion
    func reload(_ tryToBuy: Bool, productId: String) {
        products = []
        //tableView.reloadData()
        
        ReaderProducts.store.requestProductsWithCompletionHandler { success, products in
            if success {
                self.products = products
                self.reloadUI()
                
                if (tryToBuy && products.count > 0) {
                    var product = products[products.startIndex]
                    for p in products {
                        if (p.productIdentifier == productId) {
                            product = p
                        }
                    }
                    var restore = false
                    if (productId.contains("pro")) {
                        restore = true
                    }
                    self.showBuyAlert(product, restore: restore)
                }
            } else {
                if (tryToBuy) {
                    self.showErrorAlert(productId: productId)
                }
            }
        }
    }
    
    
    // Restore purchases to this device.
    func restoreTapped(_ sender: AnyObject) {
        SKPaymentQueue.default().remove(self)
        SKPaymentQueue.default().add(self)
        ReaderProducts.store.restoreCompletedTransactions { error in
            if let err = error {
                self.showError(title: NSLocalizedString("Error", comment: ""), message: err.localizedDescription)
            } else {
//                RMessage.showNotification(in: self, title: NSLocalizedString("Finished", comment: ""), subtitle: NSLocalizedString("RestoreProcess", comment: ""), type: RMessageType.success, customTypeName: "", callback: {
//
//                })
                
                self.showSuccess(title: NSLocalizedString("Finished", comment: ""), message: NSLocalizedString("RestoreProcess", comment: ""))
                
                self.refreshUI()
                
            }
        }
    }
    
    /// Initiates purchase of a product.
    func purchaseProduct(_ product: SKProduct) {
       // self.view.makeToast(message: NSLocalizedString("NeedToRestart", comment: ""), duration: 1, position: "center" as AnyObject, title: NSLocalizedString("Attention", comment: ""))
        
        let success = MessageView.viewFromNib(layout: .messageView)
        success.configureTheme(.info)
        success.configureDropShadow()
        success.configureContent(title: NSLocalizedString("Attention", comment: ""), body: NSLocalizedString("NeedToRestart", comment: ""))
        success.button?.isHidden = true
        var successConfig = SwiftMessages.defaultConfig
        successConfig.presentationStyle = .top
        successConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    
    var isPurchased = false
    
    func reloadUI() {
        if (products.count > 0) {
            
            for product in products {
                
                if (product.productIdentifier == "prosub" || product.productIdentifier == "sergei.pekar.ArchiveOfOurOwnReader.pro") {
                    isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(isPurchased, forKey: "pro")
                    UserDefaults.standard.synchronize()
                    
                    purchased = isPurchased
                    
                } else if (product.productIdentifier == "tip.small" ||
                    product.productIdentifier == "tip.medium" ||
                    product.productIdentifier == "tip.large") {
                    donated = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(donated, forKey: "donated")
                    UserDefaults.standard.synchronize()
                }
                
                if ((purchased || donated)  && DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
                    DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
                }
            }
            
            
        } else {
            purchased = false
            isPurchased = false
        }
        
        if (isPurchased || donated) {
            removeAdsItem.isEnabled = false
            removeAdsItem.title = ""
            
            refreshUI()
        } else {
            removeAdsItem.isEnabled = true
            removeAdsItem.title = NSLocalizedString("Upgrade", comment: "")
        }
    }
    
    func showBuyAlert(_ product: SKProduct, restore: Bool) {
        let alertController = UIAlertController(title: product.localizedTitle, message:
            product.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Buy", comment: ""), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.purchaseProduct(product)
        } ))
        if (restore) {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Restore", comment: ""), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
                self.restoreTapped(self)
            } ))
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // When a product is purchased, this notification fires, redraw the correct row
    @objc func productPurchased(_ notification: Notification) {
        let productIdentifier = notification.object as! String
        for (_, product) in products.enumerated() {
            if product.productIdentifier == productIdentifier {
               // reload(false, productId: "")
                
                if (product.productIdentifier == "prosub" || product.productIdentifier == "sergei.pekar.ArchiveOfOurOwnReader.pro") {
                    isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(isPurchased, forKey: "pro")
                    UserDefaults.standard.synchronize()
                    
                    purchased = isPurchased
                    Answers.logCustomEvent(withName: "ProSub", customAttributes: ["donated" : donated])
                    
                    if (purchased == true) {
                        self.showSuccess(title: NSLocalizedString("ThankYou", comment: ""), message: NSLocalizedString("ThankYouForSub", comment: ""))
                    }
                    
                } else if (product.productIdentifier == "tip.small" ||
                    product.productIdentifier == "tip.medium" ||
                    product.productIdentifier == "tip.large") {
                    
                    Answers.logCustomEvent(withName: "Tip", customAttributes: ["donated" : donated, "purchased" : isPurchased])
                    
                    donated = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(donated, forKey: "donated")
                    UserDefaults.standard.synchronize()
                    
                    self.showSuccess(title: NSLocalizedString("ThankYou", comment: ""), message: NSLocalizedString("ThankYouForTip", comment: ""))
                    
                }
                
                if ((purchased || donated ) && DefaultsManager.getBool(DefaultsManager.ADULT) == nil) {
                    DefaultsManager.putBool(true, key: DefaultsManager.ADULT)
                }
                
                refreshUI()
                break
            }
        }
    }
    
    //restore protocol
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Received Payment Transaction Response from Apple");
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .purchased, .restored:
                    print("Purchased purchase/restored")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                case .failed:
                    print("Purchased Failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                default:
                    print("default")
                    break
                }
            }
            
        }
    }
}
