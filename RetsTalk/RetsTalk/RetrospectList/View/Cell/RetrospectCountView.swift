//
//  RetrospectCountView.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

import SwiftUI

struct RetrospectCountView: View {
    let count: RetrospectList.Count
    
    var body: some View {
        GeometryReader { proxy in
            HStack {
                monthlyCount
                    .frame(width: proxy.size.width / 2)
                totalCount
                    .frame(width: proxy.size.width / 2)
            }
        }
        .frame(height: Metrics.height)
        .padding()
    }
    
    // MARK: Subviews
    
    private var monthlyCount: some View {
        HStack {
            Image(systemImage: .calendar)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.blazingOrange)
            VStack(alignment: .leading) {
                Text(Texts.monthly)
                    .foregroundStyle(.secondary)
                Text(Texts.count(count.monthly))
                    .bold()
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }
    
    private var totalCount: some View {
        HStack {
            Image(systemImage: .totalRetrospect)
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack(alignment: .leading) {
                Text(Texts.total)
                Text(Texts.count(count.total))
                    .bold()
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Constants

fileprivate extension RetrospectCountView {
    enum Metrics {
        static let height = 30.0
    }
    
    enum Texts {
        static let monthly = "이달의 회고"
        static let total = "총 회고 수"
        
        static func count(_ value: Int) -> String {
            "\(value)개"
        }
    }
}
