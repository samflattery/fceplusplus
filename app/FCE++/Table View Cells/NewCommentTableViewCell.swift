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
    func didPostComment(withData data: [String: Any])
}

class NewCommentTableViewCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var titleField : UITextField!
    @IBOutlet weak var commentTextView : UITextView!
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    @IBOutlet weak var anonymousLabel: UILabel!
    
    var delegate : NewCommentCellDelegate!
    var courseNumber: String!
    var reachability: Reachability!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        postButton.isHidden = true
        anonymousSwitch.isHidden = true
        anonymousLabel.isHidden = true
        anonymousSwitch.isOn = false

        // make the switch smaller
        let switchResizeRatio: CGFloat = 0.75
        anonymousSwitch.transform = CGAffineTransform(scaleX: switchResizeRatio, y: switchResizeRatio)
        
        commentTextView.text = "Leave your thoughts on this course or ask a question!"
        commentTextView.delegate = self
        commentTextView.textColor = .lightGray
        
        let titleBottomLine = CALayer()
        titleBottomLine.frame = CGRect.init(x: 0, y: titleField.frame.size.height - 1, width: titleField.frame.size.width - 25, height: 1.5)
        print(titleField.frame.size.width)
        print(titleBottomLine.frame.size.width)
        print(self.frame.size.width)
        titleBottomLine.backgroundColor = UIColor.lightGray.cgColor

        // just have the bottom border line
        titleField.borderStyle = .none
//        titleField.layer.addSublayer(titleBottomLine)
        titleField.delegate = self
        titleField.autocapitalizationType = .sentences
        
        titleField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 24)!])
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        if titleField.text == "" {
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
                           "header": titleField.text!,
                           "courseNumber": courseNumber!,
                           "replies": []] as [String : Any]
        
        titleField.text = ""
        commentTextView.text = "Leave your thoughts on this course or ask a question!"
        commentTextView.textColor = .lightGray
        
        delegate.didPostComment(withData: commentData)
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
