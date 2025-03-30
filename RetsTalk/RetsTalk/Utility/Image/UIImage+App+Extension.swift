//
//  UIImage+App+Extension.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

import UIKit

extension UIImage {
    convenience init?(named name: AssetName) {
        self.init(named: name.name)
    }
    
    static let appIcon = UIImage(named: .appIcon)
    
    enum AssetName {
        case appIcon
        
        var name: String {
            switch self {
            case .appIcon:
                "icon"
            }
        }
    }
}
