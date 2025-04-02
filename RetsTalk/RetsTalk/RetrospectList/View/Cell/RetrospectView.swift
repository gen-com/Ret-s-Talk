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
            SummaryText(content: summary)
            Spacer()
                .frame(height: Metrics.padding)
            CreatedDateText(date: createdAt)
        }
        .padding(Metrics.padding)
        .cornerRadius(Metrics.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(
                    isPinned ? .blazingOrange : .secondary,
                    lineWidth: Metrics.rectangleStrokeWidth
                )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subviews

private extension RetrospectView {
    struct SummaryText: View {
        let content: String
        
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
        
        var body: some View {
            Text(date.formattedToKoreanStyle)
                .font(Font(UIFont.appFont(.caption)))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Constants

fileprivate extension RetrospectView {
    enum Metrics {
        static let margin = 16.0
        static let padding = 10.0
        static let cornerRadius = 12.0
        static let rectangleStrokeWidth = 1.0
        static let summaryTextHeight = 40.0
    }
    
    enum Numerics {
        static let summaryTextLineLimit = 2
    }
}
