//
//  InstructorTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 8/9/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit
import Cosmos

class InstructorTableViewCell: UITableViewCell {
    
    @IBOutlet weak var instructorLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var ratingStars: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var labelConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        ratingStars.settings.fillMode = .precise
    }
    
    func hasDisclosureIndicator(_ hasInd: Bool) {
        if hasInd {
            self.accessoryType = .disclosureIndicator
            self.labelConstraint.constant = 0
            self.selectionStyle = .default
        } else {
            self.accessoryType = .none
            self.labelConstraint.constant = 10
            self.selectionStyle = .none
        }
    }


}
