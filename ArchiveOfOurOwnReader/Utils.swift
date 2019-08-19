//
//  Utils.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 5/26/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import UIKit

class Utils {
    
    static func compareKeys(_ obj1:Any, obj2:Any) -> ComparisonResult {
        let p1 = obj1 as! String
        let p2 = obj2 as! String
        let result = p1.compare(p2)
        return result
    }
    
    /// Returns a `UIImage` representing the number of stars from the given star rating; returns `nil`
    /// if the star rating is less than 3.5 stars.
    static func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
        guard let rating = starRating?.doubleValue else {
            return nil
        }
        if rating >= 5 {
            return UIImage(named: "stars_5")
        } else if rating >= 4.5 {
            return UIImage(named: "stars_4_5")
        } else if rating >= 4 {
            return UIImage(named: "stars_4")
        } else if rating >= 3.5 {
            return UIImage(named: "stars_3_5")
        } else {
            return nil
        }
    }
}
