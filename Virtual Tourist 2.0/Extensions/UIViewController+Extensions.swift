//
//  UIViewController+Extensions.swift
//  Virtual Tourist 2.0
//
//  Created by Abdullah AlBargi on 03/11/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    enum NotificationType {
        case add
        case delete
    }
    
    func getNotificationView(text: String, type: NotificationType) -> UILabel {
        let notifView  = UIView()
        notifView.center = view.center
        notifView.layer.cornerRadius = 5
        notifView.backgroundColor = type == .add ? .green : .red
        let label = UILabel()
        label.backgroundColor = type == .add ? UIColor.systemGreen : UIColor.systemRed
        label.textColor = type == .add ? UIColor.black : UIColor.white
        label.textAlignment = .center
        label.text = text
        
        return label
    }
}
