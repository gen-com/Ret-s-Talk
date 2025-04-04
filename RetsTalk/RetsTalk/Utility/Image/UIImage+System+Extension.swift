//
//  UIImage+Extension.swift
//  RetsTalk
//
//  Created on 11/19/24.
//

import UIKit

extension UIImage {
    convenience init?(systemImage: SystemImage) {
        self.init(systemName: systemImage.name)
    }
    
    static let arrowUp = UIImage(systemImage: .arrowUp)
    static let leftChevron = UIImage(systemImage: .leftChevron)
    static let pinned = UIImage(systemImage: .pinned)
    static let trash = UIImage(systemImage: .trash)
    static let unpinned = UIImage(systemImage: .unpinned)
    
    /// 시스템 아이콘 이름으로 tintColor를 적용한 후 주어진 비율로 크기 조정합니다.
    static func systemImage(named name: String, tintColor: UIColor, scaleFactor: CGFloat) -> UIImage? {
        guard let originalImage = UIImage(systemName: name) else { return nil }
        
        let tintedImage = originalImage.withTintColor(tintColor, renderingMode: .alwaysOriginal)
        
        let originalSize = tintedImage.size
        let targetSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            tintedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resizedImage
    }
    
    enum SystemImage {
        case arrowUp
        case leftChevron
        case pinned
        case trash
        case unpinned
        
        var name: String {
            switch self {
            case .arrowUp:
                "arrow.up.circle"
            case .leftChevron:
                "chevron.left"
            case .pinned:
                "pin.fill"
            case .trash:
                "trash.fill"
            case .unpinned:
                "pin.slash"
            }
        }
    }
}
