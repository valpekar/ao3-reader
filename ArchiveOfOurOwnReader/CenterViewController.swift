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

class CenterViewController: ListViewController {

    var delegate: CenterViewControllerDelegate?
    
    
    @IBAction func drawerClicked(_ sender: AnyObject) {
        
        delegate?.toggleLeftPanel()
    }
        
    func createDrawerButton() {
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "drawer"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(CenterViewController.drawerClicked(_:)))
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
}
