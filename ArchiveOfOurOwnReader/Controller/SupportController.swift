//
//  SupportController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/18/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import MessageUI
import UIKit

class SupportController: LoadingViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var explainButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createDrawerButton()
        
       /* ZDKConfig.instance().initializeWithAppId("b0908975e3c38b9ddb268f1787636737310adc5b595dd52c",
            zendeskUrl: "https://simplesoftalliance.zendesk.com",
            clientId: "mobile_sdk_client_fb84d9049912f9580c88",
            onSuccess: nil,
            onError: nil
        )
        
        let anonymousIdentity = ZDKAnonymousIdentity()
        ZDKConfig.instance().userIdentity = anonymousIdentity
        ZDKLogger.enable(true)
         */
        self.title = NSLocalizedString("Support", comment: "")
    }
    
    override func applyTheme() {
        super.applyTheme()
        
        if (theme == DefaultsManager.THEME_DAY) {
            self.explainButton.setTitleColor(UIColor.black, for: .normal)
        } else {
            self.explainButton.setTitleColor(AppDelegate.textLightColor, for: .normal) 
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
//    @IBAction func doneTouched(_ sender: AnyObject) {
//        guard let text = codeTv.text else {
//            showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: "Promo code cannot be empty", type: .error)
//            return
//        }
//
//        if (text == "ZpRzBIRDA2") {
//            UserDefaults.standard.synchronize()
//            UserDefaults.standard.set(true, forKey: "donated")
//            UserDefaults.standard.synchronize()
//
//            showNotification(in: self, title: NSLocalizedString("Success", comment: ""), subtitle: "Promo Key Accepted!", type: .success)
//
//            codeTv.text = ""
//        } else {
//            showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: "No Such Promo Key!", type: .error)
//        }
//    }
    
//    @IBAction func WebLink(_ sender: AnyObject) {
//        if let url = URL(string: "http://indiefics.com") {
//            UIApplication.shared.openURL(url)
//        }
//    }
    
    
    @IBAction func mailTouched(_ sender:AnyObject) {
        let email = "info.catapps@gmail.com"
        if let url = URL(string: "mailto:\(email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                if MFMailComposeViewController.canSendMail() {
                    
                    
                    // Use the iOS Mail app
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    composeVC.setToRecipients([email])
                    composeVC.setSubject("")
                    composeVC.setMessageBody("", isHTML: false)
                    
                    // Present the view controller modally.
                    self.present(composeVC, animated: true, completion: nil)
                }
            }
        }
    }
    
}
