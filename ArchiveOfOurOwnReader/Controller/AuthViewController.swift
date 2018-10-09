//
//  AuthViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/11/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import LocalAuthentication

class AuthViewController: UserMessagesController {
    
    var authDelegate:AuthProtocol?
    
    @IBOutlet weak var passTextField:UITextField!
    @IBOutlet weak var touchIDButton:UIButton!
    @IBOutlet weak var okButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Authentication"
        
        let onlyPass = DefaultsManager.getBool(DefaultsManager.NEEDS_PASS) ?? false
        if (onlyPass == false) {
            touchIDdDone(passTextField)
        } else if (!DefaultsManager.getString(DefaultsManager.USER_PASS).isEmpty) {
            touchIDButton.isHidden = true
        }
        
        self.touchIDButton.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
        self.okButton.applyGradient(colours: [AppDelegate.redDarkColor, AppDelegate.redLightColor], cornerRadius: AppDelegate.mediumCornerRadius)
    }
    
    //MARK: - authenticate
    
    func authenticateUser() {
        // Get the local authentication context.
        let context : LAContext = LAContext()
        
        var error: NSError?
        
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Authentication is needed to access your stories."
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) -> Void in
                
                if success {
                    DispatchQueue.main.async {
                    
                        self.dismiss(animated: true) {
                            self.authDelegate?.authFinished(success: true)
                        }
                    }
                }
                else {
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
                    print(evalPolicyError?.localizedDescription ?? "")
                    guard let Errcode = evalPolicyError?._code else {
                        self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Authentication failed", comment: ""))
                        return
                    }
                    
                    switch Errcode {
                        
                    case LAError.systemCancel.rawValue:
                        self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Authentication was cancelled by the system", comment: ""))
                        
                    case LAError.userCancel.rawValue:
                        self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Authentication was cancelled by the user", comment: ""))
                        
                    case LAError.userFallback.rawValue:
                        print("User selected to enter custom password")
                        
                    default:
                        self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Authentication failed", comment: ""))
                    }
                }
            })]
        }  else {
            // If the security policy cannot be evaluated then show a short message depending on the error.
            if #available(iOS 11.0, *) {
                switch error!.code{
                    
                case LAError.biometryNotEnrolled.rawValue:
                    self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Touch/Face is not enrolled", comment: ""))
                    
                case LAError.passcodeNotSet.rawValue:
                    self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("A passcode has not been set", comment: ""))
                    
                default:
                    // The LAError.TouchIDNotAvailable case.
                    self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Touch/Face ID not available", comment: ""))
                }
            } else {
                self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Touch/Face ID not available", comment: ""))
            }
            
            // Optionally the error description can be displayed on the console.
            print(error?.localizedDescription ?? "")
            
        }
    }
    
    @IBAction func passwordDone(_ sender: AnyObject) {
        if let txt: String = passTextField.text {
            if (txt.isEmpty) {
                self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Please type your passcode!", comment: ""))
            } else {
                let userPass: String = DefaultsManager.getString(DefaultsManager.USER_PASS);
                if (userPass == txt) {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.authDelegate?.authFinished(success: true)
                        }
                    }
                } else {
                    self.showError(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Incorrect password!", comment: ""))
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

