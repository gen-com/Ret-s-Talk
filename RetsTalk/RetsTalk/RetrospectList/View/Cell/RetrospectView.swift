//
//  RetrospectView.swift
//  RetsTalk
//
//  Created on 11/21/24.
//

import SwiftUI

struct RetrospectView: View {
    let summary: String
    let createdAt: Date
    let isPinned: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            SummaryText(summary)
            Spacer()
                .frame(height: Metrics.padding)
            CreatedDateText(createdAt)
        }
        .padding(Metrics.padding)
        .background(Color.backgroundRetrospect)
        .cornerRadius(Metrics.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(
                    isPinned ? Color.blazingOrange : Color.strokeRetrospect,
                    lineWidth: Metrics.RectangleStrokeWidth
                )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subviews

private extension RetrospectView {
    struct SummaryText: View {
        let content: String
        
        init(_ content: String) {
            self.content = content
        }
        
        var body: some View {
            HStack(alignment: .top) {
                Text(content.charWrapping)
                    .font(Font(UIFont.appFont(.semiTitle)))
                    .lineLimit(Numerics.summaryTextLineLimit)
                    .truncationMode(.tail)
                Spacer()
            }
            .frame(height: Metrics.summaryTextHeight, alignment: .topLeading)
        }
    }
    
    struct CreatedDateText: View {
        let date: Date
        
        init(_ date: Date) {
            self.date = date
        }
        
        var body: some View {
            Text(date.formattedToKoreanStyle)
                .font(Font(UIFont.appFont(.caption)))
                .foregroundStyle(.blueBerry)
        }
    }
}

// MARK: - Constants

fileprivate extension RetrospectView {
    enum Metrics {
        static let margin = 16.0
        static let padding = 10.0
        static let cornerRadius = 12.0
        static let RectangleStrokeWidth = 1.0
        static let summaryTextHeight = 40.0
    }
    
    enum Numerics {
        static let summaryTextLineLimit = 2
    }
}
