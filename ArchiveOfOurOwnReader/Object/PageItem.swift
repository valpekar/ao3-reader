//
//  PageItem.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 8/25/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation

struct PageItem {

    var url: String = ""
    var name = ""
    var isCurrent = false

}

extension PageItem {
    init(name: String) {
        self.name = name
    }
}
