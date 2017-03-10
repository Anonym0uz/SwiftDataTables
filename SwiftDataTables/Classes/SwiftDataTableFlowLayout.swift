//
//  SwiftDataTableFlowLayout.swift
//  SwiftDataTables
//
//  Created by Pavan Kataria on 21/02/2017.
//  Copyright © 2017 Pavan Kataria. All rights reserved.
//

import UIKit

class SwiftDataTableFlowLayout: UICollectionViewFlowLayout {
    
    //MARK: - Properties
    fileprivate(set) open var dataTable: SwiftDataTable!
    
    private var cache = [UICollectionViewLayoutAttributes]()
    
    
    //MARK: - Lifecycle
    init(dataTable: SwiftDataTable){
        self.dataTable = dataTable
        super.init()
//        self.collectionView?.isPrefetchingEnabled = false;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func clearLayoutCache(){
        self.cache.removeAll()
    }
    
    public override func prepare(){
        super.prepare()
        
        guard self.cache.isEmpty else {
            return
        }
        
        let methodStart = Date()

        var xOffsets = [CGFloat]()
        var yOffsets = [CGFloat]()
        
        //Reduces the computation by working out one column
        for column in 0..<self.dataTable.numberOfColumns() {
            let currentColumnXOffset = Array(0..<column).reduce(self.dataTable.widthForRowHeader()) {
                $0 + self.dataTable.widthForColumn(index: $1)
            }
            xOffsets.append(currentColumnXOffset)
        }
        
        //Reduces the computation by calculating the height offset against one column
        let defaultUpperHeight = self.dataTable.heightForMenuLengthView() + self.dataTable.heightForSectionHeader()
        for row in Array(0..<self.dataTable.numberOfRows()){
            let currentRowYOffset = Array(0..<row).reduce(defaultUpperHeight) { $0 + self.dataTable.heightForRow(index: $1) + self.dataTable.heightOfInterRowSpacing() }
            yOffsets.append(currentRowYOffset)
        }
        
        
        //Item equals the current item in the row
        for item in Array(0..<self.dataTable.numberOfColumns()) {
            let width = self.dataTable.widthForColumn(index: item)
            for row in Array(0..<self.dataTable.numberOfRows()){
                let indexPath = IndexPath(item: item, section: row)
                //Should this method call be used or is keeping an array of row heights more efficcient?
                let height = self.dataTable.heightForRow(index: row)
                
                let frame = CGRect(x: xOffsets[item], y: yOffsets[row], width: width, height: height)
//                let insetFrame = CGRectInset(frame, cellPadding, cellPadding)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = frame//insetFrame
                cache.append(attributes)
            }
        }
        let methodFinish = Date()
        let executionTime = methodFinish.timeIntervalSince(methodStart)
        print("Prepare method: exec-time: \(executionTime)")
        
        self.collectionView?.scrollIndicatorInsets = UIEdgeInsets(
            top: self.dataTable.shouldSectionHeadersFloat() ? self.dataTable.heightForSectionHeader() + self.dataTable.heightForPaginationView(): 0,
            left: 0,
            bottom: self.dataTable.shouldSectionFootersFloat() ? self.dataTable.heightForSectionFooter() + self.dataTable.heightForMenuLengthView() : 0,
            right: 0
        )
        
        self.collectionView?.showsVerticalScrollIndicator = self.dataTable.showVerticalScrollBars()
        
        self.collectionView?.showsHorizontalScrollIndicator = self.dataTable.showHorizontalScrollBars()
    }
    
    override var collectionViewContentSize: CGSize {
        let width = Array(0..<self.dataTable.numberOfColumns()).reduce(self.dataTable.widthForRowHeader()) { $0 + self.dataTable.widthForColumn(index: $1)}
        let height = Array(0..<self.dataTable.numberOfRows()).reduce(self.dataTable.heightForSectionHeader() + self.dataTable.heightForSectionFooter() + self.dataTable.heightForPaginationView() + self.dataTable.heightForMenuLengthView()) {
                $0 + self.dataTable.heightForRow(index: $1) + self.dataTable.heightOfInterRowSpacing()
        }
        return CGSize(width: width, height: height)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        //Item Cells
        var attributes = self.cache.filter{ $0.frame.intersects(rect) }

        //MARK: Menu Length
        if self.dataTable.shouldShowSearchSection(){
            let menuLengthIndexPath = IndexPath(index: 0)
            if let menuLengthAttributes = self.layoutAttributesForSupplementaryView(ofKind:
                SwiftDataTable.SupplementaryViewType.menuLengthHeader.rawValue, at: menuLengthIndexPath){
                attributes.append(menuLengthAttributes)
            }
        }

        //MARK: Column Headers
        for i in 0..<self.dataTable.numberOfHeaderColumns() {
            let headerIndexPath = IndexPath(index: i)
            if let headerAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftDataTable.SupplementaryViewType.columnHeader.rawValue, at: headerIndexPath){
                attributes.append(headerAttributes)
            }
        }
        
        //MARK: Column Footers
        for i in 0..<self.dataTable.numberOfFooterColumns() {
            let footerIndexPath = IndexPath(index: i)
            if let footerAttributes = self.layoutAttributesForSupplementaryView(ofKind: SwiftDataTable.SupplementaryViewType.footerHeader.rawValue, at: footerIndexPath){
                attributes.append(footerAttributes)
            }
        }
        
        //MARK: Pagination
        if self.dataTable.shouldShowPaginationSection() {
            let paginationIndexPath = IndexPath(index: 0)
            if let paginationAttributes = self.layoutAttributesForSupplementaryView(ofKind:
                SwiftDataTable.SupplementaryViewType.paginationHeader.rawValue, at: paginationIndexPath){
                attributes.append(paginationAttributes)
            }
        }
        return attributes
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

//MARK: - Layout Attributes For Elements And Supplmentary Views
extension SwiftDataTableFlowLayout {
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let initialRowYPosition = self.dataTable.heightForMenuLengthView() + self.dataTable.heightForSectionHeader()
        
        let x: CGFloat = Array(0..<indexPath.row).reduce(self.dataTable.widthForRowHeader()) { $0 + self.dataTable.widthForColumn(index: $1)}
        let y = initialRowYPosition + CGFloat(Int(self.dataTable.heightForRow(index: 0)) * indexPath.section)
        let width = self.dataTable.widthForColumn(index: indexPath.row)
        let height = self.dataTable.heightForRow(index: indexPath.section)
        
        attributes.frame = CGRect(
            x: max(0, x),
            y: max(0, y),
            width: width,
            height: height
        )
        return attributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let kind = SwiftDataTable.SupplementaryViewType(kind: elementKind)
        switch kind {
        case .menuLengthHeader: return self.layoutAttributesForMenuLengthView(at: indexPath)
        case .columnHeader: return self.layoutAttributesForColumnHeaderView(at: indexPath)
        case .footerHeader: return self.layoutAttributesForColumnFooterView(at: indexPath)
        case .paginationHeader:  return self.layoutAttributesForPaginationView(at: indexPath)
        }
    }
    
    
    func layoutAttributesForMenuLengthView(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftDataTable.SupplementaryViewType.menuLengthHeader.rawValue, with: indexPath)
        let x: CGFloat = self.dataTable.collectionView.contentOffset.x
        let y: CGFloat = 0
        let width = self.dataTable.collectionView.bounds.width
        let height = self.dataTable.heightForMenuLengthView()
        
        attribute.frame = CGRect(
            x: max(0, x),
            y: max(0, y),
            width: width,
            height: height
        )
        attribute.zIndex = 5
        
        if self.dataTable.shouldSectionHeadersFloat(){
            let yOffsetTopView: CGFloat = self.dataTable.collectionView.contentOffset.y
            attribute.frame.origin.y = yOffsetTopView
            attribute.zIndex += 1
        }
        
        return attribute
    }
    
    func layoutAttributesForColumnHeaderView(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftDataTable.SupplementaryViewType.columnHeader.rawValue, with: indexPath)
        //Because the widths can change between columns we need to get a running total for the x position so far up
        //until the currnt column header.
        let x = Array(0..<indexPath.index).reduce(self.dataTable.widthForRowHeader()){$0 + self.dataTable.widthForColumn(index: $1)}
        let y: CGFloat = self.dataTable.heightForMenuLengthView() /*self.dataTable.heightForPaginationView()*/
        let width = self.dataTable.widthForColumn(index: indexPath.index)
        let height = self.dataTable.heightForSectionHeader()
        attribute.frame = CGRect(
            x: max(0.0, x),
            y: max(0, y),
            width: width,
            height: height
        )
        attribute.zIndex = 2
        //This should call the delegate method whether or not the headers should float.
        if self.dataTable.shouldSectionHeadersFloat(){
            let yScrollOffsetPosition = self.dataTable.heightForMenuLengthView() + self.collectionView!.contentOffset.y
            attribute.frame.origin.y = yScrollOffsetPosition//max(yScrollOffsetPosition, attribute.frame.origin.y)
            attribute.zIndex += 1
        }
        return attribute
    }
    
    func layoutAttributesForColumnFooterView(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftDataTable.SupplementaryViewType.footerHeader.rawValue, with: indexPath)

        let width = self.dataTable.widthForColumn(index: indexPath.index)
        let height = self.dataTable.heightForSectionFooter()

        let x = Array(0..<indexPath.index).reduce(self.dataTable.widthForRowHeader()){$0 + self.dataTable.widthForColumn(index: $1)}
        let y: CGFloat = self.collectionView!.contentSize.height - height

        attribute.frame = CGRect(
            x: max(0, x),
            y: y,
            width: width,
            height: height
        )
        attribute.zIndex = 2
        //This should call the delegate method whether or not the headers should float.
        if self.dataTable.shouldSectionFootersFloat(){
            let yOffsetBottomView: CGFloat = self.collectionView!.contentOffset.y + self.collectionView!.bounds.height - height - self.dataTable.heightForPaginationView() // - height
            attribute.frame.origin.y = yOffsetBottomView
            attribute.zIndex += 1
        }
        return attribute
    }
    
    func layoutAttributesForPaginationView(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: SwiftDataTable.SupplementaryViewType.paginationHeader.rawValue, with: indexPath)
        
        let x: CGFloat = self.dataTable.collectionView.contentOffset.x
        let y: CGFloat = 0
        
        let width = self.dataTable.collectionView.bounds.width
        let height = self.dataTable.heightForPaginationView()
        
        attribute.frame = CGRect(
            x: max(0, x),
            y: max(0, y),
            width: width,
            height: height
        )
        attribute.zIndex = 5
        
        if self.dataTable.shouldSectionHeadersFloat(){
            let yOffsetBottomView: CGFloat = self.dataTable.collectionView.contentOffset.y + self.dataTable.collectionView.bounds.height - height // - height
            attribute.frame.origin.y = yOffsetBottomView
            attribute.zIndex += 1
        }
        
        return attribute
    }
}
