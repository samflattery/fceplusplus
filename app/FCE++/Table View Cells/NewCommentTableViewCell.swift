//
//  NewCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 8/3/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class NewCommentTableViewCell: UITableViewCell, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var titleField : UITextField!
    @IBOutlet weak var commentTextView : UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        commentTextView.text = "Leave your thoughts on this course or ask a question!"
        commentTextView.delegate = self
        commentTextView.textColor = .lightGray
        
        let titleBottomLine = CALayer()
//        titleBottomLine.frame = CGRect.init(x: 0, y: titleField.frame.size.height - 1, width: titleField.frame.size.width, height: 2)
        titleBottomLine.frame = CGRect.init(x: 0, y: titleField.frame.size.height - 1, width: titleField.frame.size.width - 25, height: 1.5)
        print(titleField.frame.size.width)
        print(titleBottomLine.frame.size.width)
        print(self.frame.size.width)
        titleBottomLine.backgroundColor = UIColor.lightGray.cgColor
//        titleBottomLine.backgroundColor = UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1).cgColor
        
        // just have the bottom border line
        titleField.borderStyle = .none
        titleField.layer.addSublayer(titleBottomLine)
        titleField.delegate = self
        titleField.autocapitalizationType = .sentences
        
        titleField.attributedPlaceholder = NSAttributedString(string: "Title", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 20)!])
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
//            textView.text = "Leave your thoughts on this course or ask a question!"
//            textView.textColor = .lightGray
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


}
