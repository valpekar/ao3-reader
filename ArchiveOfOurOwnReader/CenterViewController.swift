//
//  CenterViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 2/29/16.
//  Copyright © 2016 Sergei Pekar. All rights reserved.
//

import UIKit
import SwiftMessages

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
    
    func showSuccess(title: String, message: String) {
        
        let success = MessageView.viewFromNib(layout: .cardView)
        success.configureTheme(.success)
        success.configureDropShadow()
        success.configureContent(title: title, body: message)
        success.button?.isHidden = true
        var successConfig = SwiftMessages.defaultConfig
        successConfig.presentationStyle = .top
        successConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        successConfig.duration = .seconds(seconds: 1.5)
        
        SwiftMessages.show(config: successConfig, view: success)
    }
    
    func showError(title: String, message: String) {
        let error = MessageView.viewFromNib(layout: .tabView)
        error.configureTheme(.error)
        error.configureContent(title: title, body: message)
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        
        SwiftMessages.show(config: config, view: error)
    }
    
    func showWarning(title: String, message: String) {
        let warn = MessageView.viewFromNib(layout: .cardView)
        warn.configureTheme(.warning)
        warn.configureContent(title: title, body: message)
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        
        SwiftMessages.show(config: config, view: warn)
    }
    
    func showInfo(title: String, message: String) {
        let warn = MessageView.viewFromNib(layout: .messageView)
        warn.configureTheme(.info)
        warn.configureContent(title: title, body: message)
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        infoConfig.duration = .seconds(seconds: 1.5)
        
        SwiftMessages.show(config: config, view: warn)
    }
}

extension UIView {
    func applyGradient(colours: [UIColor], cornerRadius: CGFloat) -> Void {
        self.applyGradient(colours: colours, locations: nil, cornerRadius: cornerRadius)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?, cornerRadius: CGFloat) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        
        //if case .horizontal = direction {
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 0.0)
       // }
        
        gradient.bounds = self.bounds
        gradient.frame = self.bounds
        gradient.anchorPoint = CGPoint.zero
        gradient.position = CGPoint(x: 0, y: 0)
        self.layer.addSublayer(gradient)
        
       // self.layer.insertSublayer(gradient, at: 0)
        
        gradient.cornerRadius = cornerRadius
    }
}
