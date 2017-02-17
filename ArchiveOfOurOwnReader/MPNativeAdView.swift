//
//  MPNativeAdView.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 4/6/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit

class MPNativeAdView : UIView {
    
    @IBOutlet weak var  titleLabel: UILabel!
    @IBOutlet weak var  mainTextLabel: UILabel!
    @IBOutlet weak var  callToActionLabel: UILabel!
    @IBOutlet weak var  iconImageView: UIImageView!
    @IBOutlet weak var  mainImageView: UIImageView!
    @IBOutlet weak var  privacyInformationIconImageView: UIImageView!
}

//extension MPNativeAdView: MPNativeAdRendering {
//    
//    static func sizeWithMaximumWidth(maximumWidth: CGFloat) -> CGSize {
//        return CGSize(width: maximumWidth, height: 280)
//    }
//    
//    func layoutAdAssets(adObject: MPNativeAd!) {
//        adObject.loadIconIntoImageView(iconImageView)
//        adObject.loadTitleIntoLabel(titleLabel)
//        adObject.loadCallToActionTextIntoButton(callToActionButton)
//        adObject.loadImageIntoImageView(mainImageView)
//        adObject.loadTextIntoLabel(mainTextLabel)
//    }
//}