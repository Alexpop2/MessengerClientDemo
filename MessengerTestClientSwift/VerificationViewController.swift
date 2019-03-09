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

class VerificationViewController: UIViewController {
    
    @IBOutlet weak var codeTextView: UITextField!
    
    @IBAction func authorizeClicked(_ sender: UIButton) {
        sender.isEnabled = false
        guard let verificationCode = codeTextView.text else { return }
        
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
                return
            }
            
            let currentUser = Auth.auth().currentUser
            currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                UserDefaults.standard.set(currentUser?.phoneNumber, forKey: "authPhone")
                if let error = error {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        sender.isEnabled = true
                    }
                    return
                }
                guard let token = idToken else { return }
                var authToken = Authorizationservice_FirebaseToken()
                authToken.data = token
                DataRepository.shared.authorize(token: authToken, completion: { (result, callResult) in
                    if(result?.data == "Successful") {
                        UserDefaults.standard.set(result?.token.data, forKey: "messangerToken")
                        DispatchQueue.main.async {
                            let viewController = UIStoryboard(name: "Main", bundle: nil)
                                .instantiateViewController(withIdentifier: "messengerViewController") as UIViewController
                            self.present(viewController, animated: true, completion: nil)
                        }
                    } else {
                        print(result?.data)
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
