//
//  RetryViewDelegate.swift
//  RetsTalk
//
//  Created on 2/20/25.
//

import UIKit

@MainActor
protocol RetryViewDelegate: AnyObject {
    func retryView(_ retryView: RetryView, didTapRetryButton sender: UIButton)
}
