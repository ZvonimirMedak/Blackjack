//
//  UIViewController+Extension.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlertController(message: String, handler: ((UIAlertAction) -> Void)?) {
        let controller = UIAlertController(title: "Round over", message: message, preferredStyle: .actionSheet)
        
        controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
        self.present(controller, animated: true, completion: nil)
    }
}
