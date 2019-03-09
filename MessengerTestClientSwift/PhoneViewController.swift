//
//  PhoneViewController.swift
//  notes test grpc
//
//  Created by Рабочий on 07/03/2019.
//  Copyright © 2019 Рабочий. All rights reserved.
//

import Foundation
import UIKit
import Firebase

// MARK: - Phone enter screen

class PhoneViewController: UIViewController {
    
    // MARK: - outlets
    
    @IBOutlet weak var phoneTextView: UITextField!
    @IBOutlet weak var phoneTextViewCenterYConstraint: NSLayoutConstraint!
    
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
            self.phoneTextViewCenterYConstraint.constant = -(keyboardHeight! - view.safeAreaInsets.bottom)
        }
        else {
            self.phoneTextViewCenterYConstraint.constant = -view.safeAreaInsets.bottom
        }
        
        UIView.animate(withDuration: 0.5){
            
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    // MARK: - Set constraint for center field while keyboard not show
    
    @objc func keyboardWillHide(notification: Notification){
        
        self.phoneTextViewCenterYConstraint.constant =  0 // or change according to your logic
        UIView.animate(withDuration: 0.5){
            self.view.layoutIfNeeded()
        }
        
    }
    
    // MARK: - Closing keyboard if touched somewhere
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    // MARK: - Get code event
    
    @IBAction func getCodeClicked(_ sender: UIButton) {
        sender.isEnabled = false
        guard let phone = phoneTextView.text else { return }
        
        // MARK: Test phone number with regular expression
        
        do {
            let range = NSRange(location: 0, length: phone.utf16.count)
            let regex = try NSRegularExpression(pattern: "^(\\(?\\+?[0-9]*\\)?)?[0-9_\\- \\(\\)]*$")
            if (regex.firstMatch(in: phone, options: [], range: range) == nil) {
                print("Phone number is invalid")
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
                return
            }
        } catch {
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
            return
        }
            
        // MARK: Firebase verify phone
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
                return
            }
            
            // MARK: Remembering verification id
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            DispatchQueue.main.async {
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
                    withIdentifier: "verificationViewController") as UIViewController
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
}
