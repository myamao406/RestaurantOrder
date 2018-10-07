//
//  AdaptiveItemSizeLayout.swift
//  iOrder
//
//  Created by 山尾守 on 2016/07/08.
//  Copyright © 2016年 山尾守. All rights reserved.
//

import UIKit

protocol AdaptiveItemSizeLayoutable: class {
    var layout: AdaptiveItemSizeLayout {get set}
    var collectionView: UICollectionView! {get}
    func sizeForItemAtIndexPath(_ indexPath: IndexPath) -> CGSize
}

extension AdaptiveItemSizeLayoutable where Self: UIViewController {
    func reloadLayout(){
        let layout = AdaptiveItemSizeLayout(configuration: self.layout.configuration)
        layout.delegate = self
        
        collectionView.setCollectionViewLayout(layout, animated: true){[weak self] (result) in
            self?.collectionView.reloadData()
            self?.layout = layout
        }
    }
    
    func incrementColumn() -> Bool {
        guard !layout.configuration.atMaxColumn else {return false}
        layout.configuration.columnCount += 1
        reloadLayout()
        return true
    }
    
    func decrementColumn() -> Bool {
        guard !layout.configuration.atMaxColumn else {return false}
        layout.configuration.columnCount -= 1
        reloadLayout()
        return true
    }
    
}

class AdaptiveItemSizeLayout: UICollectionViewLayout{
    struct Configuration {
        var columnCount: Int
        var minColumnCount: Int
        var maxColumnCount: Int
        var minimumInterItemSpacing: CGFloat
        var minimumLineSpacing: CGFloat
        var sectionInsets: UIEdgeInsets
        
        init(
//            columnCount: Int = 2,
//            minColumnCount: Int = 1,
//            maxColumnCount: Int = Int.max,
//            minimumInterItemSpacing: CGFloat = 5.0,
//            minimumLineSpacing: CGFloat = 10.0,
//            sectionInsets: UIEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
            columnCount: Int = 2,
            minColumnCount: Int = 1,
            maxColumnCount: Int = Int.max,
            minimumInterItemSpacing: CGFloat = 5.0,
            minimumLineSpacing: CGFloat = 5.0,
            sectionInsets: UIEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
//            sectionInsets: UIEdgeInsets = UIEdgeInsetsZero
            ) {
                self.columnCount = columnCount
                self.minColumnCount = minColumnCount
                self.maxColumnCount = maxColumnCount
                self.minimumInterItemSpacing = minimumInterItemSpacing
                self.minimumLineSpacing = minimumLineSpacing
                self.sectionInsets = sectionInsets
                
        }
        
        var atMaxColumn: Bool {
            return (columnCount == maxColumnCount)
        }
        
        var atMinColumn: Bool {
            return (columnCount == minColumnCount)
        }
        
        var totalSpace: Int {
            return columnCount - 1
        }
        
        var itemWidth: CGFloat {
            let totalHorizontalInsets = sectionInsets.left + sectionInsets.right
            let totalInterItemSpace = minimumInterItemSpacing * CGFloat(totalSpace)
            let itemWidth = (UIScreen.main.bounds.width - totalHorizontalInsets - totalInterItemSpace) / CGFloat(columnCount)
            return itemWidth
        }

        func itemHeight(rawItemSize: CGSize) -> CGFloat {
            let itemHeight = rawItemSize.height * itemWidth / rawItemSize.width
            return itemHeight
        }
    }
    
    weak var delegate: AdaptiveItemSizeLayoutable?
    
    fileprivate var configuration = Configuration()
    fileprivate var columnContainer: ColumnContainer
    
    init (configuration: Configuration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        self.columnContainer = ColumnContainer(configuration: self.configuration)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder){
        self.columnContainer = ColumnContainer(configuration: self.configuration)
        super.init(coder: aDecoder)
        
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else {return}
        reset()
        
        for section in (0..<collectionView.numberOfSections){
            for item in (0..<collectionView.numberOfItems(inSection: section)){
                let indexPath = IndexPath(item: item, section: section)
                let itemSize = delegate?.sizeForItemAtIndexPath(indexPath) ?? CGSize.zero
                columnContainer.addAttributes(indexPath,itemSize: itemSize)
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return columnContainer.all.flatMap{ $0.getAttributes(rect) }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return columnContainer.all.flatMap{ $0.getAttributes(indexPath) }.first
    }
    
    override var collectionViewContentSize : CGSize {
        let width = collectionView?.bounds.width ?? CGFloat.leastNormalMagnitude
        let height = columnContainer.bottom
        return CGSize(width: width, height: height)
    }
    
    fileprivate func reset(){
        columnContainer.reset()
    }
}
