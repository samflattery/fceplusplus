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
    
//    let network: NetworkManager = NetworkManager.sharedInstance
    
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
                SVProgressHUD.dismiss()
                SVProgressHUD.showSuccess(withStatus: "Logged in!")
                SVProgressHUD.dismiss(withDelay: 1)
                self.performSegue(withIdentifier: "LoggedIn", sender: nil)
            } else {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "Login Failed", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
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
                if let error = error {
                    SVProgressHUD.dismiss()
                    let alert = UIAlertController(title: "Sign up Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Sign up Failed", message: "Please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
