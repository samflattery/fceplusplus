//
//  NewCommentViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/18/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

protocol NewCommentViewControllerDelegate {
    func didPostComment(withData data: [String: Any])
}

class NewCommentViewController: UIViewController, UITextViewDelegate {
    
    var delegate: NewCommentViewControllerDelegate!
    
    @IBOutlet weak var headerTextView: UITextView!
    @IBOutlet weak var commentTextView: UITextView!
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var anonymousSwitch: UISwitch! // or some other switch control
    
    var courseNumber: String!
    var commentObj: PFObject!
    var reachability: Reachability!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextViews()
    }
    
    func configureTextViews() {
        // sets up delegates, default text, colors and borders
        headerTextView.delegate = self
        commentTextView.delegate = self
        
        headerTextView.textColor = .lightGray
        commentTextView.textColor = .lightGray
        
        headerTextView.text = "Title"
        commentTextView.text = "Body (optional)"
        postButton.isEnabled = false
        
        let borderColor = UIColor.init(red: 212/255, green: 212/255, blue: 212/255, alpha: 0.5)
        
        self.headerTextView.layer.borderColor = borderColor.cgColor
        self.headerTextView.layer.borderWidth = 0.8
        self.headerTextView.layer.cornerRadius = 5
        
        self.commentTextView.layer.borderColor = borderColor.cgColor
        self.commentTextView.layer.borderWidth = 0.8
        self.commentTextView.layer.cornerRadius = 5
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        // posts the comment to the server when post button is pressed
        reachability = Reachability()!
        
        // if there's no internet connection, inform the user with an alert
        if reachability.connection == .none {
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        
        // get the date and time of posting in a readable format
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        let timePosted = formatter.string(from: currentDateTime)
        
        let user = PFUser.current()! // the user will never be nil if this segue happens
        
        // format the comment data as it is in the database
        let commentData = ["commentText": commentTextView.text!,
                           "timePosted": timePosted,
                           "andrewID": user.username!,
                           "anonymous": anonymousSwitch.isOn,
                           "header": headerTextView.text!,
                           "courseNumber": courseNumber!,
                           "replies": []] as [String : Any]
        
        self.navigationController?.popViewController(animated: true)
        delegate.didPostComment(withData: commentData)
    }
    
    //MARK:- Text Field Delegates
    func textViewDidChange(_ textView: UITextView) {
        if textView == headerTextView && textView.text != "" {
            postButton.isEnabled = true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // remove the default text
        if (textView.text == "Title" || textView.text == "Body (optional)") && textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // put back the default text if nothing has been typed
        if textView.text == "" {
            if textView == headerTextView {
                textView.text = "Title"
                postButton.isEnabled = false
            } else {
                textView.text = "Body (optional)"
            }
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
}

