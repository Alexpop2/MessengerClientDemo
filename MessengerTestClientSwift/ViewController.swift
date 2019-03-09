//
//  ViewController.swift
//  notes test grpc
//
//  Created by Рабочий on 04/03/2019.
//  Copyright © 2019 Рабочий. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var login: UITextField!
    @IBOutlet weak var token: UITextField!
    @IBOutlet weak var text: UITextView!
    
    var loginData = ""
    var tokenData = ""
    
    @IBOutlet weak var receiverId: UITextField!
    @IBOutlet weak var message: UITextField!
    
    var tokenReceived = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let getPhone = UserDefaults.standard.string(forKey: "authPhone") else { return }
        guard let getToken = UserDefaults.standard.string(forKey: "messangerToken") else { return }
        
        loginData = getPhone
        tokenData = getToken
        
        connect()
    }
    
    func connect() {
        DataRepository.shared.performMessageStream(login: loginData, token: tokenData, completion: { (message) in
            if(message.id == "-1" && message.text == "Connected") {
                self.tokenReceived = message.token
            }
            self.text.text += "\n\(message.receiverID) - \(message.senderID) - \(message.text) (\(message.state))"
            /*let point = CGPoint(x: 0.0, y: (self.text.contentSize.height - self.text.bounds.height))
             self.text.setContentOffset(point, animated: false)*/
            self.text.scrollRangeToVisible(NSRange(location: self.text.text.count - 1, length: 0))
        })
    }

    @IBAction func connectClicked(_ sender: UIButton) {
        connect()
        //guard let userID = Auth.auth().currentUser?.uid else { return }
        
        /*
        
        DataRepository.shared.performMessageStream(login: self.login.text!, token: self.token.text!, completion: { (message) in
            if(message.id == "-1" && message.text == "Connected") {
                self.tokenReceived = message.token
            }
            self.text.text += "\n\(message.receiverID) - \(message.senderID) - \(message.text) (\(message.state))"
            /*let point = CGPoint(x: 0.0, y: (self.text.contentSize.height - self.text.bounds.height))
            self.text.setContentOffset(point, animated: false)*/
            self.text.scrollRangeToVisible(NSRange(location: self.text.text.count - 1, length: 0))
        }) */
        
//        var connectionData = Connectionservice_ConnectionData();
//        connectionData.login = login.text!
//        connectionData.token = token.text!
//
//        DataRepository.shared.connect(data: connectionData) { (state, result) in
//            guard let stateUnwrapped = state else { return }
//            self.authCode = stateUnwrapped.authCode
//            self.text.text = self.authCode
//            DataRepository.shared.performMessageStream(login: self.login.text!, token: self.authCode, completion: { (message) in
//                self.text.text += "\n\(message.receiverID) - \(message.senderID) - \(message.text)"
//            })
//        }
    }
    
    @IBAction func sendClicked(_ sender: UIButton) {
        var message = Messageservice_Message();
        message.receiverID = receiverId.text!;
        message.text = self.message.text!
        message.token = self.tokenReceived
        message.senderID = loginData
        DataRepository.shared.send(message: message) { (state, result) in
        }
    }
}

