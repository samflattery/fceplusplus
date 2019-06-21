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

class SignUpViewController: UIViewController {
    
    // the text fields for user data
    @IBOutlet weak var andrewIDField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
        
    var reachability: Reachability!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var courses: [Course]! // array of courses to display upon signup
    var selectedCourses = [String]() // the array of courses numbers selected when signing up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        courses = appDelegate.courses
    }
    
    @IBAction func loginPressed(_ sender: Any) {
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
    
    @IBAction func signUpPressed(_ sender: Any) {
        showCourseSelection()
    }

}
