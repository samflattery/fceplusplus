//
//  RoundedEdges.swift
//  FCE++
//
//  Created by Sam Flattery on 8/9/19.
//  Copyright © 2019 Sam Flattery. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class BetterUIView: UIView {
    // prevents the UIViews in the table view cells from becoming
    // transparent when the cell is selected
    // allows the UIViews to have rounded corners
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != nil && backgroundColor!.cgColor.alpha == 0 {
                backgroundColor = oldValue
            }
        }
    }
    
}
