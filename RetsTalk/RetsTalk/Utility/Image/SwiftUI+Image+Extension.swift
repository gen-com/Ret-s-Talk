//
//  SwiftUI+Image+Extension.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

import SwiftUI

extension Image {
    init(systemImage: SystemImage) {
        self.init(systemName: systemImage.name)
    }
    
    enum SystemImage {
        case calendar
        case totalRetrospect
        
        var name: String {
            switch self {
            case .calendar:
                "calendar"
            case .totalRetrospect:
                "tray.full.fill"
            }
        }
    }
}
