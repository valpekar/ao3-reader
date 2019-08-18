//
//  NativeAdTableViewCell.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 8/18/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit
import Firebase

class NativeAdTableViewCell: UITableViewCell {
    
    @IBOutlet weak var adView: GADUnifiedNativeAdView!
    
    var mediaAspectRatioConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.adView.layer.cornerRadius = 5
        
        //if (theme == DefaultsManager.THEME_DAY) {
            contentView.backgroundColor = AppDelegate.greyLightBg
            backgroundColor = AppDelegate.greyLightBg
            adView.backgroundColor = UIColor.white
        //} else {
//            contentView.backgroundColor = AppDelegate.greyDarkBg
//            workCellView.backgroundColor = AppDelegate.greyDarkBg
//            workCellView.bgView.backgroundColor = AppDelegate.greyBg
        //}
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
        
        (adView.callToActionView as? UILabel)?.text = nativeAd.callToAction//setTitle(nativeAd.callToAction, for: .normal)
        adView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil
        
        (adView.starRatingView as? UIImageView)?.image = nil//imageOfStars(from: nativeAd.starRating)
        adView.starRatingView?.isHidden = nativeAd.starRating == nil
        
        (adView.storeView as? UILabel)?.text = nativeAd.store
        adView.storeView?.isHidden = nativeAd.store == nil
        
        (adView.priceView as? UILabel)?.text = nativeAd.price
        adView.priceView?.isHidden = nativeAd.price == nil
        
        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        adView.advertiserView?.isHidden = nativeAd.advertiser == nil
        
        // In order for the SDK to process touch events properly, user interaction
        // should be disabled.
        adView.callToActionView?.isUserInteractionEnabled = false
        
//        if (theme == "Pink") {
//            (adView.headlineView as! UILabel).textColor = AppDelegate.PINK_GLOWING_COLOR
//            adView.backgroundColor = AppDelegate.PINK_BG_COLOR
//            (adView.advertiserView as! UILabel).textColor = AppDelegate.PINK_GLOWING_COLOR
//            (adView.bodyView as! UILabel).textColor = AppDelegate.PINK_GLOWING_COLOR
//            (adView.priceView as! UILabel).textColor = AppDelegate.PINK_GLOWING_COLOR
//            adView.callToActionView?.backgroundColor = AppDelegate.PINK_LIGHT_COLOR
//            (adView.callToActionView as! UIButton).setTitleColor(AppDelegate.PINK_GLOWING_COLOR, for: UIControl.State.normal)
//        } else if (theme == "Black") {
//            (adView.headlineView as! UILabel).textColor = AppDelegate.BLACK_GLOWING_COLOR
//            adView.backgroundColor = AppDelegate.BLACK_BG_COLOR
//            (adView.advertiserView as! UILabel).textColor = AppDelegate.BLACK_GLOWING_COLOR
//            (adView.bodyView as! UILabel).textColor = AppDelegate.BLACK_GLOWING_COLOR
//            (adView.priceView as! UILabel).textColor = AppDelegate.BLACK_GLOWING_COLOR
//            adView.callToActionView?.backgroundColor = AppDelegate.BLACK_LIGHT_COLOR
//            (adView.callToActionView as! UIButton).setTitleColor(AppDelegate.BLACK_GLOWING_COLOR, for: UIControl.State.normal)
//        } else {
//            (adView.headlineView as! UILabel).textColor = AppDelegate.BLUE_GLOWING_COLOR
//            adView.backgroundColor = AppDelegate.BLUE_BG_COLOR
//            (adView.advertiserView as! UILabel).textColor = AppDelegate.BLUE_GLOWING_COLOR
//            (adView.bodyView as! UILabel).textColor = AppDelegate.BLUE_GLOWING_COLOR
//            (adView.priceView as! UILabel).textColor = AppDelegate.BLUE_GLOWING_COLOR
//            adView.callToActionView?.backgroundColor = AppDelegate.BLUE_LIGHT_COLOR
//            (adView.callToActionView as! UIButton).setTitleColor(AppDelegate.BLUE_GLOWING_COLOR, for: UIControl.State.normal)
//        }
    }
}
