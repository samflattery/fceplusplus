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
import RSSelectionMenu

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // the text fields for user data
    @IBOutlet weak var andrewIDField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    // the button for guest login
    @IBOutlet weak var guestButton: UIButton!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var buttonBar: UIView!
    @IBOutlet weak var buttonBarLeftConstraint: NSLayoutConstraint!
    
    // true if this view controller has been instantiated by a guest asking for login
    // if true, do not show them the option of signing in as a guest
    var hasComeFromGuest = false
    
    var reachability: Reachability!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var courses: [Course]! // array of courses to display upon signup
    var selectedCourses = [String]() // the array of courses numbers selected when signing up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        courses = appDelegate.courses
        
        self.hideKeyboardWhenTappedAround()
        
        // fixes weird error where black bars would appear under navigation bar
        // because navigation bar is not translucent
        extendedLayoutIncludesOpaqueBars = true
        
        setupTextFields()
        setupSegmentControl()
        
        loginButton.isHidden = true
        
        if hasComeFromGuest {
            guestButton.isHidden = true
        }
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        if segmentControl.selectedSegmentIndex == 0 {
            login()
        } else {
            signUp()
        }
    }
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        view.layoutIfNeeded() // ensure the previous animation is finished
        UIView.animate(withDuration: 0.3) {
            // the new origin for the bar is the bottom left corner of the selected segment
            let originX = (self.segmentControl.frame.width / CGFloat(self.segmentControl.numberOfSegments)) * CGFloat(self.segmentControl.selectedSegmentIndex) + self.segmentControl.frame.minX
            self.buttonBarLeftConstraint.constant = originX
            self.view.layoutIfNeeded()
        }
        
        if segmentControl.selectedSegmentIndex == 0 {
            loginButton.setTitle("Login", for: .normal)
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
        }
        
    }
    
    func setupSegmentControl() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        
        // This needs to be false since we are using auto layout constraints
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        
        // setup the constraints of the bar under the segment control
        buttonBar.backgroundColor = UIColor.white
        buttonBar.topAnchor.constraint(equalTo: segmentControl.bottomAnchor).isActive = true
        buttonBar.heightAnchor.constraint(equalToConstant: 3).isActive = true
        // Constrain the button bar to the left side of the segmented control
        buttonBarLeftConstraint.constant = segmentControl.frame.origin.x
        
        // Constrain the button bar to the width of the segmented control divided by the number of segments
        buttonBar.widthAnchor.constraint(equalTo: segmentControl.widthAnchor, multiplier: 1 / CGFloat(segmentControl.numberOfSegments)).isActive = true

        // the segment control should only be text
        segmentControl.backgroundColor = .clear
        segmentControl.tintColor = .clear
        segmentControl.setTitleTextAttributes([
            NSAttributedString.Key.font : UIFont(name: "IowanOldStyleW01-Roman", size: 20)!,
            NSAttributedString.Key.foregroundColor: UIColor.lightGray
            ], for: .normal)
        
        segmentControl.setTitleTextAttributes([
            NSAttributedString.Key.font : UIFont(name: "IowanOldStyleW01-Roman", size: 20)!,
            NSAttributedString.Key.foregroundColor: UIColor.white
            ], for: .selected)
    }
    
    func setupTextFields() {
        // changes the border of the text field to a single white line underneath
        let andrewBottomLine = CALayer()
        andrewBottomLine.frame = CGRect.init(x: 0, y: andrewIDField.frame.size.height - 1, width: andrewIDField.frame.size.width, height: 2)
        andrewBottomLine.backgroundColor = UIColor.white.cgColor
        
        let passwordBottomLine = CALayer()
        passwordBottomLine.frame = CGRect.init(x: 0, y: passwordField.frame.size.height - 1, width: passwordField.frame.size.width, height: 2)
        passwordBottomLine.backgroundColor = UIColor.white.cgColor
        
        // just have tthe bottom border line
        andrewIDField.borderStyle = .none
        andrewIDField.layer.addSublayer(andrewBottomLine)
        andrewIDField.delegate = self
        // turn off autocomplete in the text field
        andrewIDField.autocorrectionType = .no
        
        passwordField.borderStyle = .none
        passwordField.layer.addSublayer(passwordBottomLine)
        passwordField.delegate = self
        passwordField.autocorrectionType = .no
        
        andrewIDField.attributedPlaceholder = NSAttributedString(string: "andrewID", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 20)!])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 20)!])

    }
    
    func login() {
        SVProgressHUD.show(withStatus: "Logging in...")

        let andrewID = andrewIDField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text!.trimmingCharacters(in: .whitespacesAndNewlines)

        reachability = Reachability()!
        if reachability.connection == .none {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "No internet connection")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }

        PFUser.logInWithUsername(inBackground: andrewID, password: password) { (user: PFUser?, error: Error?) in
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
    
    func signUp() {
        // lets the user pick their courses, then signs them up
        // with a "verify email" prompt
        showCourseSelection()
    }
    
    func showCourseSelection() {
        // setup the selection menu
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: courses, cellType: .subTitle) { (cell, element: Course, indexPath) in
            
            // populate it with the course information
            cell.textLabel?.text = element.number
            cell.detailTextLabel?.text = element.name
        }
        
        selectionMenu.cellSelectionStyle = .checkbox // checkbox or tickmark
        
        selectionMenu.onDismiss = { [weak self] selectedItems in
            // selected items is the array of courses that are selected in the menu
            for course in selectedItems {
                // selected courses is the array of course numbers to be stored in the cloud
                self?.selectedCourses.append(course.number)
            }
            self?.signUserUpWithSelectedCourses()
        }
        
        selectionMenu.showSearchBar { (searchTerm) -> ([Course]) in
            if let _ = Int(searchTerm) { // if it's a number
                if searchTerm.count > 2 && searchTerm.firstIndex(of: "-") == nil {
                    // if it's in the form xxxxx then convert to xx-xxx
                    let firstTwoIndex = searchTerm.index(searchTerm.startIndex, offsetBy: 2)
                    let hyphenatedSearchTerm = searchTerm[..<firstTwoIndex] + "-" + searchTerm[firstTwoIndex...]
                    return self.courses.filter { $0.number.contains(hyphenatedSearchTerm) }
                } else { // just filter by course number
                    return self.courses.filter { $0.number.contains(searchTerm) }
                }
            } else { // if it's not a number, filter by course name
                return self.courses.filter { $0.name?.lowercased().contains(searchTerm.lowercased()) ?? false }
            }
            
        }
        //        selectionMenu.show(style: .alert(title: "Select", action: "Done", height: nil), from: self)
        selectionMenu.show(style: .actionSheet(title: nil, action: "Done", height: nil), from: self)
        //        selectionMenu.show(style: .popover(sourceView: self.view, size: nil), from: self)
    }
    
    func signUserUpWithSelectedCourses() {
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
        user["highlightedCourses"] = selectedCourses
        
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
    
    //MARK:- TextFieldDelegates
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.returnKeyType = .next
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // only want the login/signup button to be shown when both text fields are non-empty
        if textField == andrewIDField {
            if passwordField.text != "" && range != NSRange(location: 0, length: 1) {
                loginButton.isHidden = false
            } else {
                loginButton.isHidden = true
            }
        } else {
            if andrewIDField.text != "" && range != NSRange(location: 0, length: 1) {
                loginButton.isHidden = false
            } else {
                loginButton.isHidden = true
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if andrewIDField.text == "" || passwordField.text == "" {
            loginButton.isHidden = true
        } else {
            loginButton.isHidden = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // press enter on first text field -> jump to second
        // press enter on second -> login if non-empty, else do nothing
        if textField == andrewIDField {
            passwordField.becomeFirstResponder()
        } else {
            if textField.text == "" || andrewIDField.text == "" {
                return true
            } else {
                loginPressed(self)
            }
        }
        return true
    }

} // end of class

extension UIViewController {
    // tap anywhere on view controller to dismiss keyboard
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
