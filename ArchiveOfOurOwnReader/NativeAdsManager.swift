//
//  NativeAdsManager.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 8/12/19.
//  Copyright © 2019 Simple Soft Alliance. All rights reserved.
//

import Foundation
import Firebase

protocol NativeAdsManagerDelegate: class {
    func nativeAdsManagerDidReceivedAds(_ adsManager: NativeAdsManager)
}

class NativeAdsManager: NSObject {
    
    weak var delegate: NativeAdsManagerDelegate?
    
    #if DEBUG
    /// The ad unit ID from the AdMob UI.
    fileprivate let adUnitID = "ca-app-pub-3940256099942544/8407707713"
    #else
    /// Release Ad Unit
    fileprivate let adUnitID = "ca-app-pub-8760316520462117/4563802093"
    #endif
    
    /// The number of native ads to load (between 1 and 5 for this example).
    fileprivate let numAdsToLoad = 5
    
    /// The native ads.
    var nativeAds = [GADUnifiedNativeAd]()
    
    /// The ad loader that loads the native ads.
    fileprivate var adLoader: GADAdLoader!
    
    init(viewController: UIViewController) {
        let options = GADMultipleAdsAdLoaderOptions()
        options.numberOfAds = numAdsToLoad
        
        // Prepare the ad loader and start loading ads.
        adLoader = GADAdLoader(adUnitID: adUnitID,
                               rootViewController: viewController,
                               adTypes: [.unifiedNative],
                               options: [options])
        
        super.init()
        
        adLoader.delegate = self
        
        UserDefaults.standard.synchronize()
        if let isPro = UserDefaults.standard.value(forKey: "pro") as? Bool,
            isPro == true {
            // Do nothing because we use pro version
        } else {
            let request:GADRequest = GADRequest()
            let extras = GADExtras();
            extras.additionalParameters = ["max_ad_content_rating": "MA"]
            request.register(extras)
            
            adLoader.load(request)
        }
    }
}

extension NativeAdsManager: GADAdLoaderDelegate, GADUnifiedNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader,
                  didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        print("Received native ad: \(nativeAd)")
        
        // Add the native ad to the list of native ads.
        nativeAds.append(nativeAd)
        
        self.delegate?.nativeAdsManagerDidReceivedAds(self)
    }
    
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        print("Did finish loading all native ads")
//        enableMenuButton()
    }
}
