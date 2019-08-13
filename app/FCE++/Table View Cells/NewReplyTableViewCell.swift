//
//  NewCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/11/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

protocol NewReplyTableViewCellDelegate {
    func didPostReply(withData data: [String: Any], wasEdited edited: Bool, toIndex index: Int)
    func askToSave(withData data: [String: Any], toIndex index: Int)
    func askToCancel(atIndex index: Int)
    func didCancelReply(atIndex index: Int)
}

class NewReplyTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var anonymousLabel: UILabel!
    
    var delegate: NewReplyTableViewCellDelegate!
    
    var isEditingReply: Bool = false
    var editingIndex: Int!
    var replyText: String!

    var reachability: Reachability!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
        textView.text = "Leave a reply!"
        textView.textColor = .lightGray
        
        postButton.isHidden = true
        anonymousSwitch.isHidden = true
        anonymousLabel.isHidden = true
        cancelButton.isHidden = true
        
        // resize the switch to make it smaller
        let switchResizeRatio: CGFloat = 0.75
        anonymousSwitch.transform = CGAffineTransform(scaleX: switchResizeRatio, y: switchResizeRatio)
    }
    
    func setupEditing(isAnonymous anon : Bool) {
        isEditingReply = true
        
        textView.text = replyText
        textView.textColor = .black
        
        postButton.isHidden = false
        cancelButton.isHidden = false
        postButton.setTitle("Save", for: .normal)
        anonymousSwitch.isHidden = false
        anonymousLabel.isHidden = false
        anonymousSwitch.isOn = anon
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        reachability = Reachability()!
        
        if reachability.connection == .none {
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        
        // get the date and time of posting in a readable format
        let currentDateTime = Date()
        
        let timePosted = String(currentDateTime.timeIntervalSince1970)

        
        let user = PFUser.current()! // there will always be a user if this cell is active
        
        let newReplyText = textView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // format the comment data as it is in the database
        let replyData = ["replyText": newReplyText,
                         "timePosted": timePosted,
                         "andrewID": user.username!,
                         "anonymous": anonymousSwitch.isOn] as [String : Any] //to append to replies
        
        if isEditingReply {
            if textView.text != replyText {
                self.delegate.askToSave(withData: replyData, toIndex: self.editingIndex)
            } else {
                // else just close the editing cell
                self.delegate.didCancelReply(atIndex: editingIndex)
            }
        } else {
            delegate.didPostReply(withData: replyData, wasEdited: false, toIndex: 0)
            
            // reset the text view to its default
            textView.resignFirstResponder()
            textView.text = "Leave a reply!"
            textView.textColor = .lightGray
            postButton.isHidden = true
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if replyText != textView.text {
            delegate.askToCancel(atIndex: self.editingIndex)
        } else {
            self.delegate.didCancelReply(atIndex: editingIndex)
        }
    }
    

    //MARK:- Text Field Delegates
    func textViewDidChange(_ textView: UITextView) {
        // toggle the switches when the text view is empty or not
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
        // remove the default text
        if textView.text == "Leave a reply!" && textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // put back the default text
        postButton.isHidden = true
        anonymousSwitch.isHidden = true
        anonymousLabel.isHidden = true
        if textView.text == "" {
            textView.text = "Leave a reply!"
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }

}
