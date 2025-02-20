//
//  PlaceholderTextViewDelegate.swift
//  RetsTalk
//
//  Created by Byeongjo Koo on 2/19/25.
//

@MainActor
protocol PlaceholderTextViewDelegate: AnyObject {
    func textViewDidChange(_ placeholderTextView: PlaceholderTextView)
}

extension PlaceholderTextViewDelegate {
    func textViewDidChange(_ placeholderTextView: PlaceholderTextView) {}
}
