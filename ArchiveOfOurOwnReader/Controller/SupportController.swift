//
//  SupportController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 3/18/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit

class SupportController: CenterViewController {
    
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
        
    }
    
    
    @IBAction func WebLink(_ sender: AnyObject) {
        if let url = URL(string: "http://indiefics.com") {
            UIApplication.shared.openURL(url)
        }
    }
    
    
    @IBAction func mailTouched(_ sender:AnyObject) {
        let email = "info.catapps@gmail.com"
        let url = URL(string: "mailto:\(email)")
        UIApplication.shared.openURL(url!)
    }
    
}
