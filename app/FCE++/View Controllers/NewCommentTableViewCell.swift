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
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var anonymousLabel: UILabel!
    
    var courseNumber: String!
    var commentObj: PFObject!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
        textView.textColor = .lightGray
        
        postButton.isHidden = true
        anonymousSwitch.isHidden = true
        anonymousLabel.isHidden = true
        
        let switchResizeRatio: CGFloat = 0.75
        
        anonymousSwitch.transform = CGAffineTransform(scaleX: switchResizeRatio, y: switchResizeRatio)
        
        let buttonHeight: CGFloat = 44
        let switchHeight: CGFloat = 31 * switchResizeRatio
        let contentInset: CGFloat = 8
        
        textView.textContainerInset = UIEdgeInsets(top: contentInset, left: contentInset, bottom: switchHeight + (contentInset*2), right: buttonHeight + (contentInset*2))
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        
        let timePosted = formatter.string(from: currentDateTime)
        
        if let comment = commentObj {
            comment.fetchInBackground()
        }
        
        let user = PFUser.current()!
        
        let commentData = ["commentText": textView.text!, "timePosted": timePosted, "poster": user.username!, "anonymous": anonymousSwitch.isOn] as [String : Any]
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

    //MARK:- Text Field Delegates
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            postButton.isHidden = false
            anonymousSwitch.isHidden = false
            anonymousLabel.isHidden = false
        } else {
            postButton.isHidden = true
            anonymousSwitch.isHidden = true
            anonymousLabel.isHidden = true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Leave a comment!" && textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder() //Optional
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        postButton.isHidden = true
        anonymousSwitch.isHidden = true
        anonymousLabel.isHidden = true
        if textView.text == "" {
            textView.text = "Leave a comment!"
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }

}
