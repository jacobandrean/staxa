//
//  BaseCollectionView.swift
//  Staxa
//
//  Created by Jacob Andrean on 09/08/25.
//

import Combine
import UIKit

public class BaseCollectionView: UICollectionView, UICollectionViewDelegate {
    // MARK: - Non Sectioned Init
    public init<Item: Hashable>(
        _ data: AnyPublisher<[Item], Never>,
        layout: Layout,
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        itemContent: @escaping (Item) -> UIView
    ) {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        self.layout = layout
        
        let compositionalLayout = makeCompositionalLayout(
            layout: layout,
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets
        )
        
        self.collectionViewLayout(compositionalLayout)
            .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
            .bind(
                to: data,
                section: 0,
                animatingDifferences: animatingDifferences,
                cellProvider: cellProvider(identifier: identifier, itemContent: itemContent)
            )
            .delegate(self)
    }
    
    // MARK: - Sectioned Init
    public init<Section: Hashable, Item: Hashable>(
        _ data: (layouts: [Layout], sectionedItems: AnyPublisher<[ListSection<Section, Item>], Never>),
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        sectionIdentifier: String = "\(String(describing: UIViewHostingCollectionSupplementaryView.self))_\(String(describing: Section.self))",
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        sectionContent: ((Section) -> UIView)? = nil,
        itemContent: @escaping (Item) -> UIView
    ) {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        
        let compositionalLayout = makeSectionedCompositionalLayout(
            layouts: data.layouts,
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets,
            sectionContent: sectionContent
        )
        
        self.collectionViewLayout(compositionalLayout)
            .register(UIViewHostingCollectionSupplementaryView.self, ofKind: UICollectionView.elementKindSectionHeader, identifier: sectionIdentifier)
            .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
            .bind(
                to: data.sectionedItems,
                supplementaryViewProvider: supplementaryViewProvider(sectionIdentifier: sectionIdentifier, sectionContent: sectionContent),
                cellProvider: cellProvider(identifier: identifier, itemContent: itemContent)
            )
            .delegate(self)
    }
    
    // MARK: - XIB/Storyboard Handler
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - On Event Handler
    
    public enum Event {
        case willDisplayItem(IndexPath)
        case orthogonalContentOffset(CGPoint)
        case contentOffsetChanged(CGPoint)
    }
    
    private var onEvent: ((Event) -> Void)?
    private var layout: Layout?
    
    @discardableResult
    public func onEvent(_ handler: @escaping (Event) -> Void) -> Self {
        self.onEvent = handler
        return self
    }
    
    // MARK: - Bindable Orthogonal ContentOffset
    
    private var orthogonalContentOffset: PublishedBinding<CGPoint>?
    
    @discardableResult
    public func bindOrthogonalContentOffset(to publisher: PublishedBinding<CGPoint>) -> Self {
        self.orthogonalContentOffset = publisher
        return self
    }
    
    // MARK: - Auto Adjust Height to Content Size
    
    private var shouldAutoAdjustHeight = false
    
    public override var intrinsicContentSize: CGSize {
        guard shouldAutoAdjustHeight else {
            return super.intrinsicContentSize
        }
        
        // Force layout so we get the correct contentSize
        layoutIfNeeded()
        
        // prevent zero height at first
        let height = max(contentSize.height, 1)
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if shouldAutoAdjustHeight {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Warning: you should not use auto adjust when the items count is large
    @discardableResult
    public func shouldAutoAdjustHeight(_ shouldAutoAdjustHeight: Bool) -> Self {
        self.shouldAutoAdjustHeight = shouldAutoAdjustHeight
        invalidateIntrinsicContentSize()
        return self
    }
    
    // MARK: - Delegate
    
    private var onWillDisplayItemAt: ((IndexPath) -> Void)?
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        onWillDisplayItemAt?(indexPath)
        onEvent?(.willDisplayItem(indexPath))
    }
    
    @available(*, deprecated, message: "onWillDisplayItemAt will be removed in the future, please use onEvent", renamed: "onEvent")
    @discardableResult
    public func onWillDisplayItemAt(_ handler: @escaping (IndexPath) -> Void) -> Self {
        self.onWillDisplayItemAt = handler
        return self
    }
}

// MARK: - Layout Handling
extension BaseCollectionView {
    // MARK: - Compositional Layout Type
    public enum Layout {
        case adaptive
        case columns(CGFloat)
        case rows(numberOfRows: CGFloat, itemHeight: CGFloat, sectionInsets: NSDirectionalEdgeInsets = .zero)
        case carousel(groupFractionalWidth: CGFloat, isVerticalScroll: Bool)
        
        public static var table: Layout { .columns(1) }
        public static var carousel: Layout { .carousel(groupFractionalWidth: 1.0, isVerticalScroll: false) }
        public static var verticalCarousel: Layout { .carousel(groupFractionalWidth: 1.0, isVerticalScroll: true) }
    }
    
    // MARK: - Cell and Supplementary Provider
    
    private func cellProvider<Item>(
        identifier: String,
        itemContent: @escaping (Item) -> UIView
    ) -> (UICollectionView, IndexPath, Item) -> UICollectionViewCell {
        return { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? UIViewHostingCollectionViewCell else {
                return UICollectionViewCell()
            }
            cell.setContent(itemContent(item))
            return cell
        }
    }
    
    private func supplementaryViewProvider<Section>(
        sectionIdentifier: String,
        sectionContent: ((Section) -> UIView)? = nil
    ) -> (UICollectionView, String, Section, IndexPath) -> UICollectionReusableView {
        return { collectionView, kind, section, indexPath in
            guard let sectionContent,
                  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionIdentifier, for: indexPath) as? UIViewHostingCollectionSupplementaryView else { return UICollectionReusableView()
            }
            header.setContent(sectionContent(section))
            return header
        }
    }
    
    // MARK: - Sectioned Compositional Layout Builder
    private func makeSectionedCompositionalLayout<Section>(
        layouts: [Layout],
        itemSpacing: CGFloat,
        groupSpacing: CGFloat,
        sectionInsets: NSDirectionalEdgeInsets,
        sectionContent: ((Section) -> UIView)? = nil
    ) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self, sectionIndex < layouts.count else { return nil }
            let layout = layouts[sectionIndex]
            let section = makeLayoutSection(
                layout: layout,
                itemSpacing: itemSpacing,
                groupSpacing: groupSpacing,
                sectionInsets: sectionInsets,
                layoutEnvironment: layoutEnvironment,
                sectionContent: sectionContent
            )
            section.visibleItemsInvalidationHandler = { [weak self] item, contentOffset, env in
                self?.orthogonalContentOffset?.wrappedValue = contentOffset
                self?.onEvent?(.orthogonalContentOffset(contentOffset))
            }
            return section
        }
    }
    
    // MARK: - Compositional Layout Builder
    private func makeCompositionalLayout(
        layout: Layout,
        itemSpacing: CGFloat,
        groupSpacing: CGFloat,
        sectionInsets: NSDirectionalEdgeInsets,
        sectionContent: ((Int) -> UIView)? = nil
    ) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self else { return nil }
            let section = makeLayoutSection(
                layout: layout,
                itemSpacing: itemSpacing,
                groupSpacing: groupSpacing,
                sectionInsets: sectionInsets,
                layoutEnvironment: layoutEnvironment,
                sectionContent: sectionContent
            )
            section.visibleItemsInvalidationHandler = { [weak self] item, contentOffset, env in
                self?.orthogonalContentOffset?.wrappedValue = contentOffset
                self?.onEvent?(.orthogonalContentOffset(contentOffset))
            }
            return section
        }
    }
    
    // MARK: - Layout Section Builder
    private func makeLayoutSection<Section>(
        layout: Layout,
        itemSpacing: CGFloat,
        groupSpacing: CGFloat,
        sectionInsets: NSDirectionalEdgeInsets,
        layoutEnvironment: NSCollectionLayoutEnvironment,
        sectionContent: ((Section) -> UIView)? = nil
    ) -> NSCollectionLayoutSection {
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        
        switch layout {
        case .adaptive:
            // Dynamic item size
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(44),
                heightDimension: .estimated(44)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Group that contains 1 item — allows wrapping to new line
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.interItemSpacing = .fixed(itemSpacing)
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = groupSpacing
            section.contentInsets = sectionInsets
            section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
            
            return section
        case .columns(let numberOfColumns):
            // item size
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / numberOfColumns),
                heightDimension: .estimated(44)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Horizontal group that can hold up to numberOfItem items
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(44)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitem: item,
                count: Int(numberOfColumns)
            )
            group.interItemSpacing = .fixed(itemSpacing)
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = groupSpacing
            section.contentInsets = sectionInsets
            section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
            
            return section
        case .rows(let numberOfRows, let itemHeight, let sectionInsets):
            // item size
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(44),
                heightDimension: .estimated(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // Vertical group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .estimated(44),
                heightDimension: .absolute(numberOfRows * itemHeight)
            )
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: groupSize,
                subitem: item,
                count: Int(numberOfRows)
            )
            group.interItemSpacing = .fixed(itemSpacing)
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = groupSpacing
            section.contentInsets = sectionInsets
            section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
            
            return section
        case .carousel(let groupFractionalWidth, let isVerticalScroll):
            let containerHeight = layoutEnvironment.container.effectiveContentSize.height
            let heightDimension: NSCollectionLayoutDimension = isVerticalScroll ? .absolute(containerHeight) : .estimated(containerHeight)
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: heightDimension
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(groupFractionalWidth),
                heightDimension: heightDimension
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            
            let section = NSCollectionLayoutSection(group: group)
            if !isVerticalScroll {
                section.orthogonalScrollingBehavior = .groupPagingCentered
            }
            section.interGroupSpacing = groupSpacing
            section.contentInsets = sectionInsets
            section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
            
            return section
        }
    }
}

// MARK: - Convenience init
extension BaseCollectionView {
    // MARK: - Convenience for non sectioned item
    
    public convenience init<P: Publisher, Item: Hashable>(
        _ data: P,
        layout: Layout,
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        itemContent: @escaping (Item) -> UIView
    ) where P.Output == [Item], P.Failure == Never {
        self.init(
            data.eraseToAnyPublisher(),
            layout: layout,
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets,
            animatingDifferences: animatingDifferences,
            identifier: identifier,
            itemContent: itemContent
        )
    }
    
    public convenience init<Item: Hashable>(
        _ data: [Item],
        layout: Layout,
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        itemContent: @escaping (Item) -> UIView
    ) {
        self.init(
            CurrentValueSubject(data).eraseToAnyPublisher(),
            layout: layout,
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets,
            animatingDifferences: animatingDifferences,
            identifier: identifier,
            itemContent: itemContent
        )
    }
    
    // MARK: - Convenience for sectioned item
    
    public convenience init<P: Publisher, Section: Hashable, Item: Hashable>(
        _ data: (layouts: [Layout], sectionedItems: P),
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        sectionIdentifier: String = "\(String(describing: UIViewHostingCollectionSupplementaryView.self))_\(String(describing: Section.self))",
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        sectionContent: ((Section) -> UIView)? = nil,
        itemContent: @escaping (Item) -> UIView
    ) where P.Output == [ListSection<Section, Item>], P.Failure == Never {
        self.init(
            (data.layouts, data.sectionedItems.eraseToAnyPublisher()),
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets,
            animatingDifferences: animatingDifferences,
            sectionIdentifier: sectionIdentifier,
            identifier: identifier,
            sectionContent: sectionContent,
            itemContent: itemContent
        )
    }
    
    public convenience init<Section: Hashable, Item: Hashable>(
        _ data: (layouts: [Layout], sectionedItems: [ListSection<Section, Item>]),
        itemSpacing: CGFloat = 0,
        groupSpacing: CGFloat = 0,
        sectionInsets: NSDirectionalEdgeInsets = .zero,
        animatingDifferences: Bool = true,
        sectionIdentifier: String = "\(String(describing: UIViewHostingCollectionSupplementaryView.self))_\(String(describing: Section.self))",
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        sectionContent: ((Section) -> UIView)? = nil,
        itemContent: @escaping (Item) -> UIView
    ) {
        self.init(
            (data.layouts, CurrentValueSubject(data.sectionedItems).eraseToAnyPublisher()),
            itemSpacing: itemSpacing,
            groupSpacing: groupSpacing,
            sectionInsets: sectionInsets,
            animatingDifferences: animatingDifferences,
            sectionIdentifier: sectionIdentifier,
            identifier: identifier,
            sectionContent: sectionContent,
            itemContent: itemContent
        )
    }
}


extension BaseCollectionView: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        switch self.layout {
        case .carousel(_, let isVerticalScroll):
            let pageHeight = scrollView.bounds.height
            guard isVerticalScroll, pageHeight > 0 else { break }

            let adjustedOffset = targetContentOffset.pointee.y
            let snappedPage = round(targetContentOffset.pointee.y / pageHeight)
            let snappedY = snappedPage * pageHeight
            let maxOffset = scrollView.contentSize.height - scrollView.frame.height
            let finalSnappedY = min(snappedY, maxOffset)
            targetContentOffset.pointee.y = finalSnappedY
            break
        default:
            break
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.onEvent?(.contentOffsetChanged(scrollView.contentOffset))
    }
}

// MARK: - Demo
fileprivate class DemoVC: StaxaViewController {
    @Published var items: [String] = ["a"]
    
    @Published var items2: [String] = ["abc", "def", "ghi", "jkl", "mno", "pqr", "stu", "vwx", "yz", "ABC", "DEF", "GHI", "JKL", "MNO", "PQR", "STU", "VWX", "YZ", "123", "456", "789", "000", "111", "222", "333", "444", "555", "666", "777", "888", "999","asdfdfk","ksmdflsmd","kmflsd","skdmflkdsmflksef", "gmkmklemglker", "390j0f"]
    
    @Published var typedText: String?
    
    override var body: UIView {
        VStackView {
            BaseCollectionView($items, layout: .adaptive) { item in
                UILabel().text(item).padding().padding().border(width: 1, color: .red)
            }
            .shouldAutoAdjustHeight(true)
            
            SpacerView()
            
            UIButton("add positive value") {
                print("tapped")
                self.items.append("\(Int.random(in: 0...10000000))")
            }
            .frame(height: 40)
            .titleColor(.white)
            .backgroundColor(.blue)
            
            UIButton()
                .frame(height: 40)
                .titleColor(.black)
                .attributedTitle(
                    "add negative value"
                        .attributedText(
                            font: .boldSystemFont(ofSize: 40),
                            textColor: .white,
                            letterSpacing: 0.01,
                            textAlignment: .center
                        )
                )
                .onTap {
                    print("tapped")
                    self.items.append("\(Int.random(in: -10000000...0))")
                }
                .backgroundColor(.red)
        }
    }
}

import SwiftUI
#Preview {
    return UIViewControllerPreview {
        DemoVC()
    }
}
