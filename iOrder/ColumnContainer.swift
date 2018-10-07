//
//  ColumnContainer.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

class ColumnContainer {
    fileprivate var columns = [Column]()
    fileprivate let configuration: AdaptiveItemSizeLayout.Configuration
    
    init(configuration: AdaptiveItemSizeLayout.Configuration){
        self.configuration = configuration
        columns = [Column]()
        (0..<configuration.columnCount).forEach{
            let column = Column(configuration: configuration, columnNumber: $0)
            self.columns.append(column)
        }
    }
    
    var bottom: CGFloat {
        let bottomItem = columns.sorted{ $0.0.maxY < $0.1.maxY }.last
        if let maxY = bottomItem?.maxY {
            return maxY + configuration.sectionInsets.bottom
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    var all: [Column] {
        return columns

    }
    
    var next: Column? {
        let sortedColumns = columns.sorted{ $0.0.maxY < $0.1.maxY }
        return sortedColumns.first
    }
    
    func reset() {
        let count = columns.count
        columns = [Column]()
        (0..<count).forEach{
            let column = Column(configuration: configuration, columnNumber: $0)
            self.columns.append(column)
        }
    }
    
    func addAttributes(_ indexPath: IndexPath, itemSize: CGSize) {
        next?.addAttributes(indexPath, itemSize: itemSize)
    }
}
