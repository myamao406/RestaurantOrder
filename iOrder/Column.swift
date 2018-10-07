//
//  Column.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class Column{
    fileprivate let configuration: AdaptiveItemSizeLayout.Configuration
    fileprivate let columnNumber: Int
    fileprivate var attributesSet = [UICollectionViewLayoutAttributes]()
    fileprivate(set) var maxY: CGFloat = 0.0
    
    init(configuration: AdaptiveItemSizeLayout.Configuration, columnNumber: Int){
        self.configuration = configuration
        self.columnNumber = columnNumber
    }
    
    fileprivate var originX: CGFloat {
        var x = configuration.sectionInsets.left
        if columnNumber != 0 {
            x += (configuration.itemWidth + configuration.minimumInterItemSpacing) * CGFloat(columnNumber)
        }
        return x
    }
    
    fileprivate var originY: CGFloat {
        return (attributesSet.count == 0) ? configuration.sectionInsets.top : maxY + configuration.minimumInterItemSpacing
    }
    
    func addAttributes(_ indexPath: IndexPath, itemSize: CGSize) {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = CGRect(x: originX, y: originY, width: configuration.itemWidth, height: configuration.itemHeight(rawItemSize: itemSize))
        maxY = attributes.frame.maxY
        attributesSet.append(attributes)
    }
    
    func getAttributes(_ indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesSet.filter{
            $0.indexPath.section == indexPath.section && $0.indexPath.item == indexPath.item
            }.first
    }
    
    func getAttributes(_ rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return attributesSet.filter{ $0.frame.intersects(rect) }
    }
    
}
