//
//  MessageCollectionViewLayout.swift
//  RetsTalk
//
//  Created on 2/4/25.
//

import UIKit

final class MessageCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: Properties
    
    private var contentSize = CGSize.zero
    private var adjustedOffsetY = CGFloat.zero
    private var layoutAttributesList = [UICollectionViewLayoutAttributes]()
    
    override var collectionViewContentSize: CGSize {
        contentSize
    }
    
    // MARK: DataSource & Delegate
    
    weak var dataSource: MessageCollectionViewLayoutDataSource?
    
    // MARK: Overrided methods
    
    override func prepare() {
        guard let collectionView else { return }
        
        let height = max(collectionView.bounds.height + 1, layoutAttributesList.reduce(0, { $0 + $1.size.height }))
        contentSize = CGSize(width: collectionView.bounds.width, height: height)
        if .zero < adjustedOffsetY {
            collectionView.contentOffset.y = adjustedOffsetY
            adjustedOffsetY = .zero
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < layoutAttributesList.count else { return nil }
        
        return layoutAttributesList[indexPath.item]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        layoutAttributesList.filter({ $0.frame.intersects(rect) })
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        false
    }
    
    // MARK: Custom layout update
    
    func updateLayout(for updatedIndexPaths: [IndexPath]) {
        guard let collectionView else { return }
        
        if let firstUpdatedIndexPath = updatedIndexPaths.first,
           let lastPreviousLayoutAttributes = layoutAttributesList.last,
           firstUpdatedIndexPath.item < lastPreviousLayoutAttributes.indexPath.item {
            prependItem(updatedIndexPaths, in: collectionView)
        } else {
            appendItem(updatedIndexPaths, in: collectionView)
        }
        invalidateLayout()
    }
    
    func recalculateLayouts() {
        var offsetY = CGFloat.zero
        let updatedCellSizeList = fittingSizeList(for: layoutAttributesList.map({ $0.indexPath }))
        for index in layoutAttributesList.indices {
            let layoutAttributes = layoutAttributesList[index]
            let updatedCellSize = updatedCellSizeList[index]
            layoutAttributes.frame = CGRect(origin: CGPoint(x: .zero, y: offsetY), size: updatedCellSize)
            offsetY += updatedCellSize.height
        }
        invalidateLayout()
    }
    
    private func prependItem(_ updatedIndexPaths: [IndexPath], in collectionView: UICollectionView) {
        let fittingSizeList = fittingSizeList(for: updatedIndexPaths)
        let previousLayoutAttributesList = layoutAttributesList
        layoutAttributesList = []
        var offsetY = CGFloat.zero
        for index in updatedIndexPaths.indices {
            let indexPath = updatedIndexPaths[index], fittingSize = fittingSizeList[index]
            let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            layoutAttributes.frame = CGRect(origin: CGPoint(x: .zero, y: offsetY), size: fittingSize)
            layoutAttributesList.append(layoutAttributes)
            offsetY += fittingSize.height
        }
        adjustedOffsetY = collectionView.contentOffset.y + offsetY
        for previousLayoutAttributes in previousLayoutAttributesList {
            previousLayoutAttributes.indexPath.item = layoutAttributesList.count
            previousLayoutAttributes.frame.origin.y = offsetY
            offsetY += previousLayoutAttributes.frame.height
            layoutAttributesList.append(previousLayoutAttributes)
        }
    }
    
    private func appendItem(_ updatedIndexPaths: [IndexPath], in collectionView: UICollectionView) {
        let fittingSizeList = fittingSizeList(for: updatedIndexPaths)
        var offsetY = layoutAttributesList.reduce(0, { $0 + $1.frame.height })
        for index in updatedIndexPaths.indices {
            let indexPath = updatedIndexPaths[index], fittingSize = fittingSizeList[index]
            let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            layoutAttributes.frame = CGRect(origin: CGPoint(x: .zero, y: offsetY), size: fittingSize)
            layoutAttributesList.append(layoutAttributes)
            offsetY += fittingSize.height
        }
        adjustedOffsetY = offsetY - collectionView.bounds.height
    }
    
    private func fittingSizeList(for updatedIndexPaths: [IndexPath]) -> [CGSize] {
        guard let collectionView else { return [] }
        
        let messageCell = MessageCollectionViewCell()
        let baseSize = CGSize(width: collectionView.bounds.width, height: .infinity)
        var fittingSizeList = [CGSize]()
        for indexPath in updatedIndexPaths {
            if let message = dataSource?.messageCollectionViewLayout(self, messageForItemAt: indexPath) {
                messageCell.configure(with: message, width: collectionView.bounds.width)
                fittingSizeList.append(messageCell.sizeThatFits(baseSize))
            }
        }
        return fittingSizeList
    }
}
