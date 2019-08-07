//
//  GuestCommentTableViewCell.swift
//  FCE++
//
//  Created by Sam Flattery on 6/21/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import UIKit

protocol GuestCommentCellDelegate {
    func showLoginScreen()
}

class GuestCommentCell: UITableViewCell {
    
    var delegate: GuestCommentCellDelegate!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func loginPressed(_ sender: Any) {
        delegate.showLoginScreen()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let bottomLine = CALayer()
        bottomLine.frame = CGRect.init(x: 0, y: loginButton.frame.size.height, width: loginButton.frame.size.width, height: 1)
        bottomLine.backgroundColor = UIColor(red: 166/255, green: 25/255, blue: 46/255, alpha: 1).cgColor
        loginButton.layer.addSublayer(bottomLine)

    }

}
