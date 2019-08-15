//
//  FormatAlert.swift
//  FCE++
//
//  Created by Sam Flattery on 8/15/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation
import UIKit

func formattedAlert(titleString title: String, messageString message: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    var attributedTitle = NSMutableAttributedString()
    attributedTitle = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font:UIFont(name: "IowanOldSt OSF BT", size: 20.0)!])
    attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1), range: NSRange(location:0,length: title.count))
    alert.setValue(attributedTitle, forKey: "attributedTitle")
    
    var attributedMessage = NSMutableAttributedString()
    attributedMessage = NSMutableAttributedString(string: message, attributes: [NSAttributedString.Key.font:UIFont(name: "IowanOldStyleW01-Roman", size: 16.0)!])
    alert.setValue(attributedMessage, forKey: "attributedMessage")

    alert.view.tintColor = UIColor(red: 166/255, green: 25/255, blue: 49/255, alpha: 1)
    return alert
}
