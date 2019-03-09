//
//  ViewController.swift
//  notes test grpc
//
//  Created by Рабочий on 04/03/2019.
//  Copyright © 2019 Рабочий. All rights reserved.
//

import UIKit
import Firebase
import MessagesClientGRPC

// MARK: - Messenger screen

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var text: UITextView!
    @IBOutlet weak var receiverId: UITextField!
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var composeViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var messageClient: MessagesClientGRPC!
    var loginData = ""
    var tokenData = ""
    var tryReconnect = true
    
    // MARK: - viewdidload
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Adding keyboard observer
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // MARK: Getting phone and message server token
        
        guard let getPhone = UserDefaults.standard.string(forKey: "authPhone") else { return }
        guard let getToken = UserDefaults.standard.string(forKey: "messangerToken") else { return }
        
        loginData = getPhone
        tokenData = getToken
        
        // MARK: Connect to messages server
        
        connect()
    }
    
    // MARK: - Set constraint for center field while keyboard show

    @objc func keyboardWillShow(notification: Notification) {
        
        let keyboardSize = (notification.userInfo?  [UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardHeight = keyboardSize?.height
        if #available(iOS 11.0, *){
            self.composeViewBottomConstraint.constant = keyboardHeight! - view.safeAreaInsets.bottom
        }
        else {
            self.composeViewBottomConstraint.constant = view.safeAreaInsets.bottom
        }
        
        UIView.animate(withDuration: 0.5){
            
            self.view.layoutIfNeeded()
            self.text.scrollRangeToVisible(NSRange(location: self.text.text.count - 1, length: 0))
        }
        
        
    }
    
    // MARK: - Set constraint for center field while keyboard not show

    @objc func keyboardWillHide(notification: Notification){
        
        self.composeViewBottomConstraint.constant =  15 // or change according to your logic
        UIView.animate(withDuration: 0.5){
            self.view.layoutIfNeeded()
            self.text.scrollRangeToVisible(NSRange(location: self.text.text.count - 1, length: 0))
        }
        
    }
    
    // MARK: - Connect to messages server
    
    func connect() {
        
        // MARK: Creating message token, and perform message data
        
        let messageToken = MCPerformMessageToken(data: tokenData)
        let performMessageData = MCPerformMessageData(phone: loginData, messageClientToken: messageToken)
        
        // MARK: Performing messages stream
        
        messageClient.performMessageStream(data: performMessageData) { (message) in
            
            // MARK: Echo message data
            
            self.text.text += "\n\(message.receiverID) - \(message.senderID) - \(message.text) (\(message.state))"
            self.text.scrollRangeToVisible(NSRange(location: self.text.text.count - 1, length: 0))
            
            // MARK: If user is "kicked" by another user with same phone, setting off trying reconnection
            
            if(message.id == "-1" && (message.text == "Invalid token" || message.text == "User not found")) {
                self.tryReconnect = false
            }
            
            // MARK: Reconnect on disconnect
            
            if(message.text == "Disconnected" && message.id == "-1" && self.tryReconnect) {
                self.text.text += "Trying to reconnect"
                self.connect()
            }
        }
    }
    
    // MARK: - Send button clicked
    
    @IBAction func sendClicked(_ sender: UIButton) {
        guard let text = self.message.text else { return }
        guard let receiverID = receiverId.text else { return }
        
        // MARK: Creating message with text and receiver phone
        
        let message = MCMessage(text: text, receiverID: receiverID)
        
        // MARK: Sending message
        
        messageClient.send(message: message) { (result) in
        }
    }
}

