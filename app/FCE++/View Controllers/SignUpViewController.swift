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
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    // the button for guest login
    @IBOutlet weak var guestButton: UIButton!
    @IBOutlet weak var passwordInfoLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var buttonBar: UIView!
    @IBOutlet weak var buttonBarLeftConstraint: NSLayoutConstraint!
    
    var reachability: Reachability!
    
    var courses: [Course]! // array of courses to display upon signup
    var selectedCourses = [String]() // the array of courses numbers selected when signing up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        courses = appDelegate.courses
        
        self.hideKeyboardWhenTappedAround()
        
        // fixes weird error where black bars would appear under navigation bar
        // because navigation bar is not translucent
        extendedLayoutIncludesOpaqueBars = true
        
        setupTextFields()
        setupSegmentControl()
        
        loginButton.isHidden = true
        passwordInfoLabel.isHidden = true
        confirmPasswordField.isHidden = true

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
        setupField(andrewIDField, withString: "andrewID")
        setupField(passwordField, withString: "Password")
        setupField(confirmPasswordField, withString: "Confirm Password")
    }
    
    func generateLayer(forTextField field: UITextField) -> CALayer {
        // returns a layer for a text field to put a single white line underneath
        let layer = CALayer()
        layer.frame = CGRect.init(x: 0, y: field.frame.size.height-5, width: field.frame.size.width, height: 1.5)
        layer.backgroundColor = UIColor.white.cgColor
        return layer
    }
    
    func generateAttributed(withString string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 20)!])
    }
    
    func setupField(_ textField: UITextField, withString string: String) {
        // apply the effects to a text field so that it is just an underline
        textField.borderStyle = .none
        textField.layer.addSublayer(generateLayer(forTextField: textField))
        textField.delegate = self
        // turn off autocomplete in the text field
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = generateAttributed(withString: string)
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        print("pressed")
        performSegue(withIdentifier: "ResetPassword", sender: nil)
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
            passwordInfoLabel.isHidden = true
            confirmPasswordField.isHidden = true
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
            confirmPasswordField.isHidden = false
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCourseSelection" {
            let controller = segue.destination as! SelectCoursesViewController
            controller.courses = courses
        }
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        if segmentControl.selectedSegmentIndex == 0 {
            login()
        } else {
            signUp()
        }
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
            if let user = user {
                // login succeeds
                SVProgressHUD.dismiss()
                if user["firstLogin"] as! Bool {
                    self.welcomeUser()
                } else {
                    SVProgressHUD.showSuccess(withStatus: "Logged in!")
                    SVProgressHUD.dismiss(withDelay: 1)
                    self.performSegue(withIdentifier: "LoggedIn", sender: nil)
                }
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
    
    func welcomeUser() {
        
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        
        let titleString = "Welcome!"
        var attributedTitle = NSMutableAttributedString()
        attributedTitle = NSMutableAttributedString(string: titleString, attributes: [NSAttributedString.Key.font:UIFont(name: "IowanOldSt OSF BT", size: 21.0)!])
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1), range: NSRange(location:0,length: titleString.count))
        alert.setValue(attributedTitle, forKey: "attributedTitle")
        
        let messageString = "Use the course selection wheel to select courses that you have taken or are interested in taking. The most recent comments from these courses will be displayed on the home screen. These courses can be changed at any time by pressed the ℹ️ button on the home screen"
        var attributedMessage = NSMutableAttributedString()
        attributedMessage = NSMutableAttributedString(string: messageString, attributes: [NSAttributedString.Key.font:UIFont(name: "IowanOldStyleW01-Roman", size: 16.0)!])
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        let action = UIAlertAction(title: "OK", style: .cancel, handler: selectCoursesButtonPressed(_:))
        alert.addAction(action)
        alert.view.tintColor = UIColor(red: 166/255, green: 25/255, blue: 49/255, alpha: 1)
        
        
        present(alert, animated: true)
    }

    func selectCoursesButtonPressed(_ sender: Any) {
        let selectionMenu = RSSelectionMenu(selectionStyle: .multiple, dataSource: courses, cellType: .subTitle) { (cell, element: Course, indexPath) in
            
            // populate it with the course information
            cell.textLabel?.attributedText = NSAttributedString(string: element.number, attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1), NSAttributedString.Key.font: UIFont(name: "IowanOldSt OSF BT", size: 22)!])
            cell.detailTextLabel?.attributedText = NSAttributedString(string: element.name ?? "No name available", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(name: "IowanOldStyleW01-Roman", size: 12)!])
        }
        
        selectionMenu.cellSelectionStyle = .checkbox // checkbox or tickmark
        
        selectionMenu.onDismiss = { [weak self] selectedItems in
            // selected items is the array of courses that are selected in the menu
            var selectedCourses = [String]()
            for course in selectedItems {
                // selected courses is the array of course numbers to be stored in the cloud
                selectedCourses.append(course.number)
            }
            self?.setUserCourses(selectedCourses)
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
                return self.courses.filter {
                    $0.name?.lowercased().contains(searchTerm.lowercased()) ?? false
                }
            }
            
        }
        selectionMenu.show(style: .actionSheet(title: nil, action: "Done", height: nil), from: self)
    }

    func setUserCourses(_ courses: [String]) {
        let user = PFUser.current()! // there will always be a current user on this page
        user["highlightedCourses"] = courses
        //        user["firstLogin"] = false
        SVProgressHUD.show()
        user.saveInBackground(block: { (success: Bool, error: Error?) in
            SVProgressHUD.dismiss()
            if success {
                SVProgressHUD.showSuccess(withStatus: "Logged in!")
                self.performSegue(withIdentifier: "LoggedIn", sender: nil)
            } else if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.showError(withStatus: "Failed to update")
            }
            SVProgressHUD.dismiss(withDelay: 1)
        })
    }
    
    func signUp() {
        if passwordField.text != confirmPasswordField.text {
            SVProgressHUD.showError(withStatus: "Passwords must match")
            SVProgressHUD.dismiss(withDelay: 1)
            return
        }
        
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
        user["firstLogin"] = true
        
        user.signUpInBackground { (success: Bool, error: Error?) in
            if success {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "Signed up!", message: "You should get a verification email on \(andrewID).andrew.cmu.edu shortly. If you don't get an email, check your spam folder. Login when you have verified your email!", preferredStyle: .alert)
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
        if (textField == passwordField || textField == confirmPasswordField) && segmentControl.selectedSegmentIndex == 1 {
            passwordInfoLabel.isHidden = false
        }
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
        // press enter on second -> confirm/login if non-empty, else do nothing
        if textField == andrewIDField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            if segmentControl.selectedSegmentIndex == 1 {
                confirmPasswordField.becomeFirstResponder()
            } else {
                if textField.text == "" || andrewIDField.text == "" {
                    // if any are empty, do nothing
                    return true
                } else {
                    // log the user in
                    loginPressed(self)
                }
            }
        } else {
            if textField.text == "" || passwordField.text == "" || andrewIDField.text == "" {
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
