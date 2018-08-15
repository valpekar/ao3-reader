//
//  UpgradesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/27/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import StoreKit
import Crashlytics


class UpgradesController: UserMessagesController, SKPaymentTransactionObserver {
    
    
    @IBOutlet weak var privacybtn:UIButton!
    @IBOutlet weak var restorebtn:UIButton!
    @IBOutlet weak var lbl:UILabel!
    @IBOutlet weak var infoLbl:UILabel!
    
    
    @IBOutlet weak var view1:UIView!
    @IBOutlet weak var view2:UIView!
    @IBOutlet weak var view3:UIView!
    
    @IBOutlet weak var yrbtn:UIButton!
    @IBOutlet weak var m3btn:UIButton!
    @IBOutlet weak var m1btn:UIButton!
    
    @IBOutlet weak var scrollview:UIScrollView!
    
    var donated = false
    
    @IBOutlet weak var navBar:UINavigationBar!
    
    let subTxt = "Application has Auto-Renewable Subscription. Once you have purchased it, the subscription starts. Since then every week you will get digitally generated recommendations of fanfics (fanfiction works) to read. \nThe auto-renewable subscription nature: Get work recommendations every week based on what you have read and liked, no ads, download unlimited works. \nPayment will be charged to iTunes Account at confirmation of purchase. \nSubscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. \nAccount will be charged for renewal within 24-hours prior to the end of the current period, and identify the cost of the renewal. \nSubscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase.\nNo cancellation of the current subscription is allowed during active subscription period. \nAny unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription to that publication. \n\nTo Unsubscribe: \n1. Go to Settings > iTunes & App Store. \n2. Tap your Apple ID at the top of the screen. \n3. Tap View Apple ID. \n4. Tap the subscription that you want to manage. \nIf you don't see a subscription but are still being charged, make sure that you're signed in with the correct Apple ID. \n5. Use the options to manage your subscription. You can tap Cancel Subscription. If you cancel, your subscription will stop at the end of the current billing cycle."
    
    // This list of available in-app purchases
    var products: Array <SKProduct> = [SKProduct]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = " "
        
        lbl.text = "• Get work recommendations every week \n • No ads, premium fonts \n • Unlimited offline reading"
        infoLbl.text = subTxt
        
        view1.layer.cornerRadius = AppDelegate.smallCornerRadius
        view2.layer.cornerRadius = AppDelegate.smallCornerRadius
        view3.layer.cornerRadius = AppDelegate.smallCornerRadius
        
        view1.backgroundColor = AppDelegate.whiteHalfTransparentColor
        view2.backgroundColor = AppDelegate.whiteHalfTransparentColor
        view3.backgroundColor = AppDelegate.whiteHalfTransparentColor
        
        self.yrbtn.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
        self.m3btn.applyGradient(colours: [AppDelegate.redLightColor, AppDelegate.purpleLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
        self.m1btn.applyGradient(colours: [AppDelegate.redLightColor, AppDelegate.purpleLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(UpgradesController.productPurchased(_:)), name: NSNotification.Name(rawValue: IAPHelperProductPurchasedNotification), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.scrollview.flashScrollIndicators()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        SKPaymentQueue.default().remove(self)
    }
    
     @IBAction func closeButtonTouched(_ sender: AnyObject) {
        self.dismiss(animated: true) {
            
        }
    }
    
    @IBAction func aboutSubsTouched(_ sender: AnyObject) {
        if let url = URL(string: "http://simpleappalliance.blogspot.com/2016/05/unofficial-ao3-reader-privacy-policy.html") {
            UIApplication.shared.open(url, options: [ : ], completionHandler: { (res) in
                print("opened privacy policy")
            })
        }
    }
    
    //MARK: - purchases
    
    // Restore purchases to this device.
    @IBAction func restoreTapped(_ sender: AnyObject) {
        SKPaymentQueue.default().remove(self)
        SKPaymentQueue.default().add(self)
        ReaderProducts.store.restoreCompletedTransactions { error in
            if let err = error {
                self.showError(title: NSLocalizedString("Error", comment: ""), message: err.localizedDescription)
            } else {
                
                self.showSuccess(title: NSLocalizedString("Finished", comment: ""), message: NSLocalizedString("RestoreProcess", comment: ""))
                
               // self.refreshUI()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.dismiss(animated: true, completion: {
                        
                    })
                }
                
            }
        }
    }
    
    func showSuccessAndClose() {
        self.showSuccess(title: NSLocalizedString("ThankYou", comment: ""), message: NSLocalizedString("ThankYouForSub", comment: ""))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismiss(animated: true, completion: {
                
            })
        }
    }
    
    @IBAction func yrTouched(_ sender: AnyObject) {
        if (products.count > 0) {
            var product = products[products.startIndex]
            for p in products {
                if (p.productIdentifier == "yearly_sub") {
                    product = p
                }
            }
            if (product.productIdentifier == "yearly_sub") {
                self.purchaseProduct(product)
            } else {
                self.showWarning(title: "Cannot Find", message: "Yearly Subscription is not available on AppStore")
            }
        }
    }
    
    @IBAction func quarterTouched(_ sender: AnyObject) {
        if (products.count > 0) {
            var product = products[products.startIndex]
            for p in products {
                if (p.productIdentifier == "quarter_sub") {
                    product = p
                }
            }
            if (product.productIdentifier == "quarter_sub") {
                self.purchaseProduct(product)
            } else {
                self.showWarning(title: "Cannot Find", message: "Quarterly Subscription is not available on AppStore")
            }
            
        }
    }
    
    @IBAction func monthTouched(_ sender: AnyObject) {
        if (products.count > 0) {
            var product = products[products.startIndex]
            for p in products {
                if (p.productIdentifier == "prosub") {
                    product = p
                }
            }
            self.purchaseProduct(product)
        }
    }
    
    /// Initiates purchase of a product.
    func purchaseProduct(_ product: SKProduct) {
        // self.view.makeToast(message: NSLocalizedString("NeedToRestart", comment: ""), duration: 1, position: "center" as AnyObject, title: NSLocalizedString("Attention", comment: ""))
        
      //  self.showSuccess(title: NSLocalizedString("Attention", comment: ""), message: NSLocalizedString("NeedToRestart", comment: ""))
        
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // When a product is purchased, this notification fires, redraw the correct row
    @objc func productPurchased(_ notification: Notification) {
        let productIdentifier = notification.object as! String
        for (_, product) in products.enumerated() {
            if product.productIdentifier == productIdentifier {
                // reload(false, productId: "")
                
                if (product.productIdentifier == "prosub" || product.productIdentifier == "sergei.pekar.ArchiveOfOurOwnReader.pro" ) {
                    let isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(isPurchased, forKey: "pro")
                    UserDefaults.standard.synchronize()
                    
                    Answers.logCustomEvent(withName: "ProSub", customAttributes: ["donated" : donated])
                    
                    if (isPurchased == true) {
                        showSuccessAndClose()
                    }
                    
                } else if (product.productIdentifier == "yearly_sub") {
                    let isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(isPurchased, forKey: "pro")
                    UserDefaults.standard.synchronize()
                    
                    Answers.logCustomEvent(withName: "ProSub", customAttributes: ["donated" : donated, "length": "year"])
                    
                    if (isPurchased == true) {
                        showSuccessAndClose()
                    }
                    
                } else if (product.productIdentifier == "quarter_sub") {
                    let isPurchased = ReaderProducts.store.isProductPurchased(product.productIdentifier)
                    UserDefaults.standard.set(isPurchased, forKey: "pro")
                    UserDefaults.standard.synchronize()
                    
                    Answers.logCustomEvent(withName: "ProSub", customAttributes: ["donated" : donated, "length": "quarter"])
                    
                    if (isPurchased == true) {
                        showSuccessAndClose()
                    }
                }
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
