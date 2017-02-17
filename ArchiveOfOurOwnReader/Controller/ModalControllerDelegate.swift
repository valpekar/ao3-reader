//
//  ModalControllerDelegate.swift
//  ArchiveOfOurOwnReader
//
//  Created by ValeriyaPekar on 10/7/15.
//  Copyright (c) 2015 Sergei Pekar. All rights reserved.
//

import Foundation

@objc protocol ModalControllerDelegate {
    func controllerDidClosed()
    @objc optional func controllerDidClosedWithChapter(_ chapter: Int)
    @objc optional func controllerDidClosedWithLogin()
    @objc optional func controllerDidClosedWithChange()
}
