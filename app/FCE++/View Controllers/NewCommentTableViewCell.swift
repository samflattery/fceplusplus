//
//  NewCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/11/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class NewCommentTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    var comments: [Comment]!
    var courseTitle: String!
    
    @IBAction func postButtonPressed(_ sender: Any) {
        Comments.addNewComment(&comments, toCourse: courseTitle, withText: textView.text)
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
