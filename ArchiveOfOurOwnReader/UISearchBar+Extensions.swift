//
//  UISearchBar+Extensions.swift
//  ArchiveOfOurOwnReader
//
//  Created by Sergey Pekar on 10/1/19.
//  Copyright © 2019 Sergei Pekar. All rights reserved.
//

import Foundation

extension UISearchBar {

    var textField : UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            // Fallback on earlier versions
            return value(forKey: "_searchField") as? UITextField
        }
    }
}
