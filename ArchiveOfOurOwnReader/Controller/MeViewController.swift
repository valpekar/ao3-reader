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
import TSMessages

class MeViewController: LoadingViewController, UITableViewDelegate, UITableViewDataSource, SKPaymentTransactionObserver {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var notifSwitch: UISwitch!
    @IBOutlet weak var adultSwitch: UISwitch!
    @IBOutlet weak var adultLabel: UILabel!
    @IBOutlet weak var pseudsTableView: UITableView!
    
    var pseuds: [String:String] = [:]
    var currentPseud = ""
    
    var purchased = false
    var donated = false
    
    // This list of available in-app purchases
    var products: Array <SKProduct> = [SKProduct]()
    
    @IBOutlet weak var removeAdsItem: UIBarButtonItem!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
        pseudsTableView.tableFooterView = UIView()
        
        //reload(false, productId: "")
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
        
        if (!login.isEmpty) {
            usernameLabel.text = login
            
            pseuds = DefaultsManager.getObject(DefaultsManager.PSEUD_IDS) as! [String:String]
            currentPseud = DefaultsManager.getString(DefaultsManager.PSEUD_ID)
            
            if (currentPseud.isEmpty) {
                let keys = Array(pseuds.keys)
                if (keys.count > 0) {
                    currentPseud = keys[0]
                } 
            }
            
            pseudsTableView.reloadData()
            loginButton.setTitle("Log Out", for: UIControlState())
            
            adultSwitch.isEnabled = true
            notifSwitch.isEnabled = true
            
            if let isAdult = DefaultsManager.getBool(DefaultsManager.ADULT)  {
                if (isAdult == true) {
                    adultSwitch.setOn(true, animated: true)
                } else {
                    adultSwitch.setOn(false, animated: true)
                }
            }
            
            if let notify = DefaultsManager.getBool(DefaultsManager.NOTIFY) {
                if (notify == true) {
                    notifSwitch.setOn(true, animated: true)
                } else {
                    notifSwitch.setOn(false, animated: true)
                }
            }
            
        } else {
            setNotAuthorizedUI()
        }
        
        if (!purchased && !donated) {
            print("not purchased")
        } else {
            removeAdsItem.isEnabled = false
            removeAdsItem.title = ""
        }
    }
    
    func setNotAuthorizedUI() {
        usernameLabel.text = "Not Authorized"
        loginButton.setTitle("Log In", for: UIControlState())
        
        notifSwitch.isEnabled = false
        adultSwitch.isEnabled = false
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
   
    
    //Mark: - TableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "pseudCell")
        let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
        cell?.textLabel?.text = pseuds[curKey]
        
        if (curKey == currentPseud) {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pseuds.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let curKey = Array(pseuds.keys)[(indexPath as NSIndexPath).row]
        currentPseud = curKey
        DefaultsManager.putString(curKey, key: DefaultsManager.PSEUD_ID)
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "PSEUDS"
    }
    
    
    // MARK: - InApp
    
    @IBAction func removeAdsTouched(_ sender: AnyObject) {
        
        showLoadingView(msg: "Requesting data")
        
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
        
        showLoadingView(msg: "Please wait")
        
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
        
        showLoadingView(msg: "Please wait")
        
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
        showLoadingView(msg: "Please wait")
        
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
        let refreshAlert = UIAlertController(title: "Error", message: "Cannot get product list. Please check your Internet connection", preferredStyle: UIAlertControllerStyle.alert)
        refreshAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { (action: UIAlertAction!) in
            self.reload(true, productId: productId)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
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
                TSMessage.showNotification(in: self, title: "Error", subtitle: err.localizedDescription, type: .error)
            } else {
                TSMessage.showNotification(in: self, title: "Finished", subtitle: "Restore Process", type: .success)
            }
        }
    }
    
    /// Initiates purchase of a product.
    func purchaseProduct(_ product: SKProduct) {
        self.view.makeToast(message: "You will ned to restart the app for changes with native ads to take effect!", duration: 1, position: "center" as AnyObject, title: "Attention!")
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
            removeAdsItem.title = "Upgrade"
        }
    }
    
    func showBuyAlert(_ product: SKProduct, restore: Bool) {
        let alertController = UIAlertController(title: product.localizedTitle, message:
            product.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Buy", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.purchaseProduct(product)
        } ))
        if (restore) {
            alertController.addAction(UIAlertAction(title: "Restore", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
                self.restoreTapped(self)
            } ))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // When a product is purchased, this notification fires, redraw the correct row
    func productPurchased(_ notification: Notification) {
        let productIdentifier = notification.object as! String
        for (_, product) in products.enumerated() {
            if product.productIdentifier == productIdentifier {
               // reload(false, productId: "")
                
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
                    
                    TSMessage.showNotification(in: self, title: "Thank you!", subtitle: "Thank you for leaving a tip! Thanks to you the app will become better!", type: .success)
                    
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
