//
//  NewCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 8/3/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import SVProgressHUD
import Parse

protocol NewCommentCellDelegate {
    func didPostComment(withData data: [String: Any], wasEdited edited: Bool, atIndex index: Int)
    func askToSave(withData data: [String: Any], toIndex index: Int)
    func askToCancel(atIndex index: Int)
    func didCancelComment(atIndex index: Int)
}

class NewCommentCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var titleField : UITextField!
    @IBOutlet weak var commentTextView : UITextView!
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var anonymousLabel: UILabel!
    
    var delegate : NewCommentCellDelegate!
    var courseNumber: String!
    var reachability: Reachability!
    
    // if the user is editing an existing comment and not writing a new one,
    // these values will be initialized
    var isEditingComment : Bool!
    var editingCommentIndex : Int!
    var commentText : String!
    var commentTitle: String!
    var wasAnonymous: Bool!
    var replies: CommentReplies!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isEditingComment = false

        // make the switch smaller
        let switchResizeRatio: CGFloat = 0.75
        anonymousSwitch.transform = CGAffineTransform(scaleX: switchResizeRatio, y: switchResizeRatio)
        
        // just have the bottom border line
        titleField.borderStyle = .none
        titleField.delegate = self
        titleField.autocapitalizationType = .sentences
        commentTextView.delegate = self
        
        titleField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 24)!])
    }
    
    func setupText() {
        if isEditingComment {
            postButton.setTitle("Save", for: .normal)
            commentTextView.text = commentText
            titleField.text = commentTitle
            commentTextView.textColor = .black
            
            postButton.isHidden = false
            anonymousSwitch.isHidden = false
            anonymousLabel.isHidden = false
            anonymousSwitch.isOn = wasAnonymous
            cancelButton.isHidden = false
        } else {
            postButton.setTitle("Post", for: .normal)
            commentTextView.text = "Leave your thoughts on this course or ask a question!"
            commentTextView.textColor = .lightGray
            titleField.text = ""
            
            postButton.isHidden = true
            anonymousSwitch.isHidden = true
            anonymousLabel.isHidden = true
            anonymousSwitch.isOn = false
            cancelButton.isHidden = true
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if titleField.text != commentTitle || commentTextView.text != commentText {
            delegate.askToCancel(atIndex: self.editingCommentIndex)
        } else {
            delegate.didCancelComment(atIndex: editingCommentIndex)
        }
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        if titleField.text == "" || commentTextView.text == "" {
            return
        }
        
        reachability = Reachability()!
        
        // if there's no internet connection, inform the user with an alert
        if reachability.connection == .none {
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1.5)
            return
        }
        
        // get the date and time of posting in a readable format
        let currentDateTime = Date()
        
        let timePosted = String(currentDateTime.timeIntervalSince1970)
        
        let user = PFUser.current()! // the user will never be nil if this cell is visible
        
        // format the comment data as it is in the database
        let newCommentText = commentTextView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let newCommentTitle = titleField.text!.trimmingCharacters(in: .whitespacesAndNewlines)

        var commentData = ["commentText": newCommentText,
                           "timePosted": timePosted,
                           "andrewID": user.username!,
                           "anonymous": anonymousSwitch.isOn,
                           "header": newCommentTitle,
                           "courseNumber": courseNumber!] as [String : Any]
        
        if isEditingComment {
            commentData["replies"] = replies
        } else {
            commentData["replies"] = []
        }
        
        if isEditingComment {
            // if the comment is being edited and is not a new comment,
            // it has to update an existing cell and not just add a new comment to the array
            if titleField.text != commentTitle || commentTextView.text != commentText {
                // if the user changed something, ask if they want to save
                delegate.askToSave(withData: commentData, toIndex: editingCommentIndex)
            } else {
                // else just close the editing cell
                delegate.didCancelComment(atIndex: editingCommentIndex)
            }
            
        } else {
            // post the comment and reset the first cell which is the new comment cell
            delegate.didPostComment(withData: commentData, wasEdited: false, atIndex: 0)
            titleField.text = ""
            commentTextView.text = "Leave your thoughts on this course or ask a question!"
            commentTextView.textColor = .lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" || textView.text == "Leave your thoughts on this course or ask a question!" {
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
        if textView.text == "Leave your thoughts on this course or ask a question!" && textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // put back the default text
        if textView.text == "" {
            textView.text = "Leave your thoughts on this course or ask a question!"
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        postButton.isHidden = false
        anonymousSwitch.isHidden = false
        anonymousLabel.isHidden = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == "" {
            postButton.isHidden = true
            anonymousSwitch.isHidden = true
            anonymousLabel.isHidden = true
        }
    }

}
