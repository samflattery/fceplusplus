//
//  InstructorInfoViewController.swift
//  FCE++
//
//  Created by Sam Flattery on 8/10/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Cosmos

class InstructorInfoTableViewController: UITableViewController {
    
    var instructor : Instructor!
    var instructorInfo : [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        extendedLayoutIncludesOpaqueBars = true

        instructorInfo = getInstructorData(instructor)
        
        let cellNib = UINib(nibName: "InstructorCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "InstructorCell")
        self.navigationItem.title = instructor.name
    }
    
    //Mark:- TableViewDelegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return 7
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let j = indexPath.section
        
        if j == 0 {
            let instructorCell = tableView.dequeueReusableCell(withIdentifier: "InstructorCell", for: indexPath) as! InstructorTableViewCell
            instructorCell.hasDisclosureIndicator(false)
            instructorCell.instructorLabel.text = instructor.name
            instructorCell.ratingStars.rating = instructor.teachingRate
            instructorCell.ratingLabel.text = "(\(String(format: "%.1f", instructor.teachingRate)))"
            instructorCell.hoursLabel.text = String(format: "%.1f", instructor.hours)
            return instructorCell
        } else {
            let infoCell = tableView.dequeueReusableCell(withIdentifier: "InstructorInfoCell", for: indexPath) as! InstructorCell
            infoCell.headingLabel.text = instructorTitles[i+2]
            infoCell.starRating.settings.fillMode = .precise
            let rating = Double(instructorInfo[i+2])!
            infoCell.starRating.rating = rating
            infoCell.starRating.text = "(\(String(format: "%.1f", rating)))"
            return infoCell
        }
    }
    
}


class InstructorCell: UITableViewCell {
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var starRating: CosmosView!
    
}
