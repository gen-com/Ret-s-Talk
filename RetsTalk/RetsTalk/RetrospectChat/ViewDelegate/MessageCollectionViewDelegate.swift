//
//  MessageCollectionViewDelegate.swift
//  RetsTalk
//
//  Created on 2/6/25.
//

@MainActor
protocol MessageCollectionViewDelegate: AnyObject {
    func messageCollectionViewDidReachPrependablePoint(_ messageCollectionView: MessageCollectionView)
}
