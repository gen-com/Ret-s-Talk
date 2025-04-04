//
//  MessageView.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

import SwiftUI

struct MessageView: View {
    let message: Message
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        Text(message.content)
            .font(.appFont(.body))
            .padding(Metrics.textPadding)
            .cornerRadius(Metrics.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                    .stroke(isUser ? .blazingOrange : .secondary, lineWidth: Metrics.RectangleStrokeWidth)
            )
            .padding(isUser ? .leading : .trailing, Metrics.sidePadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Constants

fileprivate extension MessageView {
    enum Metrics {
        static let textPadding = 8.0
        static let cornerRadius = 10.0
        static let RectangleStrokeWidth = 1.0
        static let sidePadding = 80.0
    }
}
