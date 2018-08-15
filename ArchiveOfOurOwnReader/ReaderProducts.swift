//
//  TopTagsProducts.swift
//  TopTags
//
//  Created by Valeriya Pekar on 12/16/15.
//  Copyright © 2015 Simple Soft Alliance. All rights reserved.
//

import Foundation

// Use enum as a simple namespace.  (It has no cases so you can't instantiate it.)
public enum ReaderProducts {
    
    /// TODO:  Change this to whatever you set on iTunes connect
    fileprivate static let Prefix = "sergei.pekar.ArchiveOfOurOwnReader."
    
    /// MARK: - Supported Product Identifiers
    public static let ProVersion = Prefix + "pro"
    
    // All of the products assembled into a set of product identifiers.
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [ReaderProducts.ProVersion, "prosub", "yearly_sub", "quarter_sub", "tip.small", "tip.medium", "tip.large"]
    
    /// Static instance of IAPHelper that for rage products.
    public static let store = IAPHelper(productIdentifiers: ReaderProducts.productIdentifiers)
}

/// Return the resourcename for the product identifier.
func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
