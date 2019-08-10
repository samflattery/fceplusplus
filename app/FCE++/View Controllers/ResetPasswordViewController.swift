//
//  ResetPasswordViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 8/10/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var andrewIDField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        let andrewBottomLine = CALayer()
        andrewBottomLine.frame = CGRect.init(x: 0, y: andrewIDField.frame.size.height, width: andrewIDField.frame.size.width, height: 2)
        andrewBottomLine.backgroundColor = UIColor.white.cgColor
        
        // just have tthe bottom border line
        andrewIDField.borderStyle = .none
        andrewIDField.layer.addSublayer(andrewBottomLine)
        andrewIDField.delegate = self
        // turn off autocomplete in the text field
        andrewIDField.autocorrectionType = .no
        andrewIDField.autocapitalizationType = .none
        
        andrewIDField.attributedPlaceholder = NSAttributedString(string: "andrewID", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 20)!])
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        performSegue(withIdentifier: "CancelReset", sender: nil)
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        if andrewIDField.text == "" {
            return
        }
        PFUser.requestPasswordResetForEmail(inBackground: andrewIDField.text! + "@andrew.cmu.edu")
        SVProgressHUD.showSuccess(withStatus: "Password reset email sent to \(andrewIDField.text!)@andrew.cmu.edu.")
        SVProgressHUD.dismiss(withDelay: 1) {
            self.performSegue(withIdentifier: "CancelReset", sender: nil)
        }
    }

    
}
