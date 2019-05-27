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
}
