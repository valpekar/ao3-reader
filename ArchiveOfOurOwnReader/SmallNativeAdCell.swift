//
//  SmallNativeAdCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 10/4/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit
import Firebase

class SmallNativeAdCell: UITableViewCell {
    
    @IBOutlet weak var nativeAdView: GADUnifiedNativeAdView!
    
    func setup(with nativeAd: GADUnifiedNativeAd, and theme: Int) {
        nativeAdView.nativeAd = nativeAd
        // Set the mediaContent on the GADMediaView to populate it with available
        // video/image asset.
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        // Populate the native ad view with the native ad assets.
        // The headline is guaranteed to be present in every native ad.
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // These assets are not guaranteed to be present. Check that they are before
        // showing or hiding them.
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        (nativeAdView.starRatingView as? UIImageView)?.image = Utils.imageOfStars(from: nativeAd.starRating)
        nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        nativeAdView.storeView?.isHidden = nativeAd.store == nil
        
        (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
        nativeAdView.priceView?.isHidden = nativeAd.price == nil
        
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        // In order for the SDK to process touch events properly, user interaction
        // should be disabled.
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        
        if (theme == DefaultsManager.THEME_DAY) {
            (nativeAdView.headlineView as? UILabel)?.textColor = AppDelegate.redColor
            (nativeAdView.bodyView as? UILabel)?.textColor = AppDelegate.redColor
            (nativeAdView.storeView as? UILabel)?.textColor = AppDelegate.redColor
            (nativeAdView.priceView as? UILabel)?.textColor = AppDelegate.redColor
            (nativeAdView.advertiserView as? UILabel)?.textColor = AppDelegate.redColor
        } else {
            (nativeAdView.headlineView as? UILabel)?.textColor = AppDelegate.nightTextColor
            (nativeAdView.bodyView as? UILabel)?.textColor = AppDelegate.nightTextColor
            (nativeAdView.storeView as? UILabel)?.textColor = AppDelegate.nightTextColor
            (nativeAdView.priceView as? UILabel)?.textColor = AppDelegate.nightTextColor
            (nativeAdView.advertiserView as? UILabel)?.textColor = AppDelegate.nightTextColor
        }
        
        (nativeAdView.callToActionView as? UIButton)?.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.smallCornerRadius)
    }
}
