//
//  SignUpViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 6/13/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var andrewIDField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
        
    var reachability: Reachability!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Logging in...")
        
        reachability = Reachability()!
        if reachability.connection == .none {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }

        PFUser.logInWithUsername(inBackground: andrewIDField.text!, password: passwordField.text!) { (user: PFUser?, error: Error?) in
            if user != nil {
                // login succeeds
                SVProgressHUD.dismiss()
                SVProgressHUD.showSuccess(withStatus: "Logged in!")
                SVProgressHUD.dismiss(withDelay: 1)
                self.performSegue(withIdentifier: "LoggedIn", sender: nil)
            } else {
                SVProgressHUD.dismiss()
                // login failed
                if let error = error {
                    // if there was an error, show it
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: 1.5)
                } else {
                    // else just show a generic error message
                    SVProgressHUD.showError(withStatus: "Login failed")
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            }
        }
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Signing up...")
        reachability = Reachability()!
        if reachability.connection == .none {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }
        let user = PFUser()
        let andrewID = andrewIDField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        user.username = andrewID
        user.password = password
        user.email = andrewID + "@andrew.cmu.edu"
        
        user.signUpInBackground { (success: Bool, error: Error?) in
            if success {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "Signed up!", message: "You should get a verification email on \(andrewID).andrew.cmu.edu shortly. Login when you have verified your email!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                SVProgressHUD.dismiss()
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    SVProgressHUD.dismiss(withDelay: 1.5)
                } else {
                    SVProgressHUD.showError(withStatus: "Sign up failed")
                }
            }
        }
    }

}
