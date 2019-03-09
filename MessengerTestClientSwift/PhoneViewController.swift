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

class PhoneViewController: UIViewController {
    @IBOutlet weak var phoneTextView: UITextField!
    
    @IBAction func getCodeClicked(_ sender: UIButton) {
        sender.isEnabled = false
        guard let phone = phoneTextView.text else { return }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
                return
            }
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            DispatchQueue.main.async {
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
                    withIdentifier: "verificationViewController") as UIViewController
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
}
