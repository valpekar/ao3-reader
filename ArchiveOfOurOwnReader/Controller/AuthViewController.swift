//
//  AuthViewController.swift
//  ArchiveOfOurOwnReader
//
//  Created by Valeriya Pekar on 10/11/17.
//  Copyright © 2017 Sergei Pekar. All rights reserved.
//

import UIKit
import RMessage
import LocalAuthentication

class AuthViewController: UIViewController {
    
    var authDelegate:AuthProtocol?
    
    @IBOutlet weak var passTextField:UITextField!
    @IBOutlet weak var touchIDButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Authentication"
        
        let onlyPass = DefaultsManager.getBool(DefaultsManager.NEEDS_PASS) ?? false
        if (onlyPass == false) {
            touchIDdDone(passTextField)
        } else if (!DefaultsManager.getString(DefaultsManager.USER_PASS).isEmpty) {
            touchIDButton.isHidden = true
        }
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
                        RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                            
                        })
                        return
                    }
                    
                    switch Errcode {
                        
                    case LAError.systemCancel.rawValue:
                        RMessage.showNotification(in: self, title: NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the system", comment: ""), type: RMessageType.warning, customTypeName: "", callback: {
                            
                        })
                        
                    case LAError.userCancel.rawValue:
                        RMessage.showNotification(in: self, title: NSLocalizedString("Warning", comment: ""), subtitle: NSLocalizedString("Authentication was cancelled by the user", comment: ""), type: RMessageType.warning, customTypeName: "", callback: {
                            
                        })
                        
                    case LAError.userFallback.rawValue:
                        print("User selected to enter custom password")
                        
                    default:
                        RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Authentication failed", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
                    }
                }
            })]
        }  else {
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
                
            case LAError.biometryNotEnrolled.rawValue:
                RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Touch/Face is not enrolled", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                })
                
            case LAError.passcodeNotSet.rawValue:
                RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("A passcode has not been set", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                })
                
            default:
                // The LAError.TouchIDNotAvailable case.
                RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Touch/Face ID not available", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                })
            }
            
            // Optionally the error description can be displayed on the console.
            print(error?.localizedDescription ?? "")
            
        }
    }
    
    @IBAction func passwordDone(_ sender: AnyObject) {
        if let txt: String = passTextField.text {
            if (txt.isEmpty) {
                RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Please type your passcode!", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                    
                })
            } else {
                let userPass: String = DefaultsManager.getString(DefaultsManager.USER_PASS);
                if (userPass == txt) {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.authDelegate?.authFinished(success: true)
                        }
                    }
                } else {
                    RMessage.showNotification(in: self, title: NSLocalizedString("Error", comment: ""), subtitle: NSLocalizedString("Incorrect password!", comment: ""), type: RMessageType.error, customTypeName: "", callback: {
                        
                    })
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

