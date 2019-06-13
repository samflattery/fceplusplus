//
//  NewCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/11/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse

class NewCommentTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    var courseNumber: String!
    var commentObj: PFObject!
    
    @IBAction func postButtonPressed(_ sender: Any) {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        
        let timePosted = formatter.string(from: currentDateTime)
        
        if let comment = commentObj {
            comment.fetchInBackground()
        }
        
        let commentData = ["commentText": textView.text!, "timePosted": timePosted, "poster": "Anonymous"] as [String : Any]
        var comments = commentObj["comments"] as! [[String : Any]]
        comments.insert(commentData, at: 0)
        commentObj["comments"] = comments
        
        
        commentObj.saveInBackground {
            (success: Bool, error: Error?) in
            if (success) {
                print("saved")
                let tableView = self.superview! as! UITableView
                tableView.reloadData()
            } else {
                print("not saved")
                print(error ?? "Failed to save w/o error")
            }
        }
        
        textView.resignFirstResponder()
        textView.text = "Leave a comment!"
        textView.textColor = .lightGray
        postButton.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
        textView.textColor = .lightGray
        
        postButton.isHidden = true
        
        let buttonHeight: CGFloat = 44
        let contentInset: CGFloat = 8
        
        textView.textContainerInset = UIEdgeInsets(top: contentInset, left: contentInset, bottom: contentInset, right: buttonHeight + (contentInset*2))
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            postButton.isHidden = false
        }
    }

    
    //MARK:- Text Field Delegates
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView.text == "Leave a comment!" && textView.textColor == .lightGray) {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder() //Optional
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        postButton.isHidden = true
        if (textView.text == "") {
            textView.text = "Leave a comment!"
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }

}
