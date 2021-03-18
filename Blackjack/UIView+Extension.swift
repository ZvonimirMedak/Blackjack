//
//  UIView+Extension.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import Foundation
import UIKit

public extension UIView {
    
    func addSubviews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }
}
