//
//  AuthViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/11/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import TSMessages
import LocalAuthentication

class AuthViewController: UIViewController {
    
    var authDelegate:AuthProtocol?
    
    @IBOutlet weak var passTextField:UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Authentication"
    }
    
    //MARK: - authenticate
    
    func authenticateUser() {
        // Get the local authentication context.
        let context : LAContext = LAContext()
        
        var error: NSError?
        
        // Set the reason string that will appear on the authentication alert.
        var reasonString = "Authentication is needed to access your stories."
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                
                if success {
                    self.dismiss(animated: true) {
                        self.authDelegate?.authFinished(success: true)
                    }
                }
                else{
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
                    print(evalPolicyError?.localizedDescription ?? "")
                    guard let Errcode = evalPolicyError?._code else {
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: .error, duration: 2.0)
                        return
                    }
                    
                    switch Errcode {
                        
                    case LAError.systemCancel.rawValue:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the system", comment: ""), type: .warning, duration: 2.0)
                        
                    case LAError.userCancel.rawValue:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the user", comment: ""), type: .warning, duration: 2.0)
                        
                    case LAError.userFallback.rawValue:
                        print("User selected to enter custom password")
                        
                    default:
                        TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: .error, duration: 2.0)
                    }
                }
            })]
        }  else {
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
                
            case LAError.touchIDNotEnrolled.rawValue:
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("TouchID is not enrolled", comment: ""), type: .error, duration: 2.0)
                
            case LAError.passcodeNotSet.rawValue:
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("A passcode has not been set", comment: ""), type: .error, duration: 2.0)
                
            default:
                // The LAError.TouchIDNotAvailable case.
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("TouchID not available", comment: ""), type: .error, duration: 2.0)
            }
            
            // Optionally the error description can be displayed on the console.
            print(error?.localizedDescription ?? "")
            
        }
    }
    
    @IBAction func passwordDone(_ sender: AnyObject) {
        if let txt: String = passTextField.text {
            if (txt.isEmpty) {
                TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Please type your password!", comment: ""), type: .error, duration: 2.0)
            } else {
                let userPass: String = DefaultsManager.getString(DefaultsManager.USER_PASS);
                if (userPass == txt) {
                    self.dismiss(animated: true) {
                        self.authDelegate?.authFinished(success: true)
                    }
                } else {
                    TSMessage.showNotification(in: self, title:  NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Incorrect password!", comment: ""), type: .error, duration: 2.0)
                }
            }
        }
    }
    
    @IBAction func touchIDdDone(_ sender: AnyObject) {
        self.authenticateUser()
    }
}

protocol AuthProtocol {
    func authFinished(success: Bool)
}

