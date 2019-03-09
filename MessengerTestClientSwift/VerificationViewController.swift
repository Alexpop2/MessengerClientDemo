//
//  VerificationVIewController.swift
//  notes test grpc
//
//  Created by Рабочий on 07/03/2019.
//  Copyright © 2019 Рабочий. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MessagesClientGRPC

// MARK: - Verification code check screen

class VerificationViewController: UIViewController {
    
    // MARK: - outlets
    
    @IBOutlet weak var codeTextView: UITextField!
    @IBOutlet weak var codeTextViewCenterYConstraint: NSLayoutConstraint!
    
    // MARK: - properties
    
    let messagesClient = MessagesClientGRPC()
    
    // MARK: - adding keyboard observer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Set constraint for center field while keyboard show
    
    @objc func keyboardWillShow(notification: Notification) {
        
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height
        if #available(iOS 11.0, *){
            self.codeTextViewCenterYConstraint.constant = -(keyboardHeight! - view.safeAreaInsets.bottom)
        }
        else {
            self.codeTextViewCenterYConstraint.constant = -view.safeAreaInsets.bottom
        }
        
        UIView.animate(withDuration: 0.5){
            
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    // MARK: - Set constraint for center field while keyboard not show
    
    @objc func keyboardWillHide(notification: Notification){
        
        self.codeTextViewCenterYConstraint.constant =  0 // or change according to your logic
        UIView.animate(withDuration: 0.5){
            self.view.layoutIfNeeded()
        }
        
    }
    
    // MARK: - Closing keyboard if touched somewhere
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    // MARK: - Verify code check
    
    @IBAction func authorizeClicked(_ sender: UIButton) {
        sender.isEnabled = false
        
        // MARK: Getting verification id and verification code
        
        guard let verificationCode = codeTextView.text else { return }
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        
        // MARK: Create credential (struct for verification data)
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode)
        
        // MARK: Firebase check verification data
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
                return
            }
            
            // MARK: If verified, getting user token from firebase
            
            let currentUser = Auth.auth().currentUser
            currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        sender.isEnabled = true
                    }
                    return
                }
                
                guard let token = idToken else { return }
                
                // MARK: Remembering user phone
                
                UserDefaults.standard.set(currentUser?.phoneNumber, forKey: "authPhone")
                
                // MARK: Create authorization data for MessageClientGRPC
                
                let authData = MCAuthorizationData(firebaseToken: token)
                
                // MARK: Authorization on MessageServer
                
                self.messagesClient.authorize(with: authData, completion: { (result, callResult) in
                    if(result?.data == "Successful") {
                        
                        // MARK: Remembering MessageServer token
                        
                        UserDefaults.standard.set(result?.token.data, forKey: "messangerToken")
                        DispatchQueue.main.async {
                            let viewController = UIStoryboard(name: "Main", bundle: nil)
                                .instantiateViewController(withIdentifier: "messengerViewController") as! ViewController
                            viewController.messageClient = self.messagesClient
                            self.present(viewController, animated: true, completion: nil)
                        }
                    } else {
                        print(result?.data ?? callResult ?? "Unknown error")
                        DispatchQueue.main.async {
                            sender.isEnabled = true
                        }
                        return
                    }
                })
            }
        }
    }
}
