//
//  MessageCollectionViewCell.swift
//  RetsTalk
//
//  Created on 2/6/25.
//

import SwiftUI
import UIKit

final class MessageCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "\(MessageCollectionViewCell.self)"
    
    func configure(with message: Message, width: CGFloat) {
        contentConfiguration = UIHostingConfiguration {
            MessageView(message: message)
                .padding()
                .frame(width: width)
        }
        .margins(.all, .zero)
    }
}
