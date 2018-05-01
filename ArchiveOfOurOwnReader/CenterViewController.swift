//
//  CenterViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/29/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit

protocol CenterViewControllerDelegate {
    func toggleLeftPanel()
    func collapseSidePanels()
}

class CenterViewController: UIViewController {

    var delegate: CenterViewControllerDelegate?

    var theme: Int = DefaultsManager.THEME_DAY
    
    @IBAction func drawerClicked(_ sender: AnyObject) {
        
        delegate?.toggleLeftPanel()
    }
    
    func applyTheme() {
        if (theme == DefaultsManager.THEME_DAY) {
            self.view.backgroundColor = AppDelegate.greyLightBg
        } else {
            self.view.backgroundColor = AppDelegate.redDarkColor
        }
    }
        
    func createDrawerButton() {
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "drawer"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(CenterViewController.drawerClicked(_:)))
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
    
    func hideBackTitle() {
        
        let backItem = UIBarButtonItem()
        backItem.title = " "
        navigationItem.backBarButtonItem = backItem
        
        self.delegate?.collapseSidePanels()
    }
}
