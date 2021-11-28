//
//  NativeAdView.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 10/1/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit
import GoogleMobileAds

class NativeAdView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var adView: GADUnifiedNativeAdView!
    @IBOutlet weak var googleAdsLabel: UILabel!
    
    var mediaAspectRatioConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadXib()
    }
    
    fileprivate func loadXib() {
        Bundle.main.loadNibNamed("NativeAdView", owner: self, options: [:])
        self.addSubview(self.contentView)
        
        // 1
        let views: [String: Any] = ["contentView": self.contentView]
        var allConstraints: [NSLayoutConstraint] = []
        
        // 3
        allConstraints += NSLayoutConstraint.constraints(
          withVisualFormat: "V:|-[contentView]-|",
          metrics: nil,
          views: views)

        // 4
        allConstraints += NSLayoutConstraint.constraints(
          withVisualFormat: "H:|-[contentView]-|",
          metrics: nil,
          views: views)
        
        NSLayoutConstraint.activate(allConstraints)

        
//        self.contentView.frame = self.bounds
//        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.adView.layer.cornerRadius = 5
    }
    
    func setup(with nativeAd: GADUnifiedNativeAd, and theme: Int) {
        
        if let constraint = mediaAspectRatioConstraint {
            adView.mediaView?.removeConstraint(constraint)
        }
        
        let newConstraint = NSLayoutConstraint(item: adView.mediaView!,
                                                attribute: NSLayoutConstraint.Attribute.width,
                                                relatedBy: NSLayoutConstraint.Relation.equal,
                                                toItem: adView.mediaView!,
                                                attribute: NSLayoutConstraint.Attribute.height,
                                                multiplier: nativeAd.mediaContent.aspectRatio,
                                                constant: 0)
        
        newConstraint.identifier = "Media View Aspect"
        
        mediaAspectRatioConstraint = newConstraint
        
        adView.mediaView?.addConstraint(newConstraint)
        
        
        adView.nativeAd = nativeAd
        // Set the mediaContent on the GADMediaView to populate it with available
        // video/image asset.
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        
        // Populate the native ad view with the native ad assets.
        // The headline is guaranteed to be present in every native ad.
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        
        // These assets are not guaranteed to be present. Check that they are before
        // showing or hiding them.
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        adView.bodyView?.isHidden = nativeAd.body == nil
        
        (adView.callToActionView as? UILabel)?.text = nativeAd.callToAction
        adView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil
        
        (adView.starRatingView as? UIImageView)?.image = Utils.imageOfStars(from: nativeAd.starRating)
        adView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (adView.storeView as? UILabel)?.text = nativeAd.store
        adView.storeView?.isHidden = nativeAd.store == nil
        
        (adView.priceView as? UILabel)?.text = nativeAd.price
        //adView.priceView?.isHidden = nativeAd.price == nil
        
        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        adView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        // In order for the SDK to process touch events properly, user interaction
        // should be disabled.
        adView.callToActionView?.isUserInteractionEnabled = false
        
        if (theme == DefaultsManager.THEME_DAY) {
            backgroundColor = AppDelegate.greyLightBg
            self.backgroundColor = AppDelegate.greyLightBg
            
            googleAdsLabel.textColor = UIColor(named: "global_tint")
            
            adView.backgroundColor = UIColor.white
            (adView.headlineView as? UILabel)?.textColor = UIColor(named: "global_tint")
            (adView.bodyView as? UILabel)?.textColor = AppDelegate.darkerGreyColor
            (adView.storeView as? UILabel)?.textColor = UIColor(named: "global_tint")
            (adView.priceView as? UILabel)?.textColor = UIColor(named: "global_tint")
        } else {
            backgroundColor = AppDelegate.greyDarkBg
            self.backgroundColor = AppDelegate.greyDarkBg
            
            googleAdsLabel.textColor = AppDelegate.greyLightColor
            
            adView.backgroundColor = AppDelegate.greyBg
            (adView.headlineView as? UILabel)?.textColor = AppDelegate.textLightColor
            (adView.bodyView as? UILabel)?.textColor = AppDelegate.greyLightColor
            (adView.storeView as? UILabel)?.textColor = AppDelegate.greyLightColor
            (adView.priceView as? UILabel)?.textColor = AppDelegate.greyLightColor
        }
    }
}

