//
//  UserMessagesController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 6/12/18.
//  Copyright © 2018 Sergei Pekar. All rights reserved.
//

import UIKit
import SwiftMessages

class UserMessagesController: UIViewController {
    
    
    
    func showSuccess(title: String, message: String) {
        
        let success = MessageView.viewFromNib(layout: .cardView)
        success.configureTheme(.success)
        success.configureDropShadow()
        success.configureContent(title: title, body: message)
        success.button?.isHidden = true
        var successConfig = SwiftMessages.defaultConfig
        successConfig.presentationStyle = .top
     //   successConfig.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        successConfig.duration = .seconds(seconds: 1.5)
        
        SwiftMessages.show(config: successConfig, view: success)
    }
    
    func showError(title: String, message: String) {
        let error = MessageView.viewFromNib(layout: .tabView)
        error.configureTheme(.error)
        error.configureContent(title: title, body: message)
        error.button?.isHidden = true
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
     //   config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        
        SwiftMessages.show(config: config, view: error)
    }
    
    func showWarning(title: String, message: String) {
        let warn = MessageView.viewFromNib(layout: .cardView)
        warn.configureTheme(.warning)
        warn.button?.isHidden = true
        warn.configureContent(title: title, body: message)
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
    //    config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        
        SwiftMessages.show(config: config, view: warn)
    }
    
    func showInfo(title: String, message: String) {
        let warn = MessageView.viewFromNib(layout: .messageView)
        warn.configureTheme(.info)
        warn.configureContent(title: title, body: message)
        warn.button?.isHidden = true
        
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .top
       // config.presentationContext = .window(windowLevel: UIWindowLevelNormal)
        config.duration = .seconds(seconds: 1.5)
        
        SwiftMessages.show(config: config, view: warn)
    }
}
