//
//  CourseInfoTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/24/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

class CourseInfoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var hoursDetailsLabel: UILabel!
    @IBOutlet weak var prereqsDetailsLabel: UILabel!
    
    
    // labels that need constraints to centerX
    @IBOutlet weak var courseRateLabel: UILabel!
    @IBOutlet weak var courseRateDetailsLabel: UILabel!
    
    @IBOutlet weak var coreqLabel: UILabel!
    @IBOutlet weak var coreqDetailsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // setup centerX constraints as couldn't see how to in storyboard
        courseRateLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        courseRateDetailsLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        coreqLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        coreqDetailsLabel.leftAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        
        prereqsDetailsLabel.rightAnchor.constraint(lessThanOrEqualTo: self.contentView.centerXAnchor, constant: -15).isActive = true
        
        
    }


}
