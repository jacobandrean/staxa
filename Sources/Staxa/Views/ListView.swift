//
//  File.swift
//  Staxa
//
//  Created by Avows Technologies on 18/05/25.
//

import Combine
import UIKit

// MARK: - Model for ListView
public struct ListSection<Section: Hashable, Item: Hashable>: Hashable {
    public var section: Section
    public var items: [Item]
    
    public init(title: Section, items: [Item]) {
        self.section = title
        self.items = items
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(section)
    }

    public static func == (lhs: ListSection, rhs: ListSection) -> Bool {
        lhs.section == rhs.section
    }
}

public typealias FlatListView<Item: Hashable> = ListView<Never, Item>

// MARK: - ListView
public class ListView<Section: Hashable, Item: Hashable>: StaxaView, UICollectionViewDelegate {
    public enum Layout {
        case adaptive
        case columns(CGFloat)
        case rows(numberOfRows: CGFloat, itemHeight: CGFloat)
        case carousel
    }
    
    @Published private var data: [Item] = []
    @Published private var sectionedData: [ListSection<Section, Item>] = []
    @Published private var isScrollEnabled: Bool = true
    private var adjustsHeightToContent: Bool = false
    
    private let layout: Layout
    private let spacing: CGFloat
    private let identifier: String
    private let sectionIdentifier: String?
    private let sectionContent: ((Section) -> UIView)?
    private let itemContent: (Item) -> UIView
    private var onWillDisplayItem: ((Item) -> Void)?
    
    // MARK: Init for non-Sectioned Data
    public init<P: Publisher>(
        _ data: P,
        layout: Layout = .adaptive,
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        itemContent: @escaping (Item) -> UIView
    ) where P.Output == [Item], P.Failure == Never {
        self.layout = layout
        self.spacing = spacing
        self.identifier = identifier
        self.sectionIdentifier = nil
        self.sectionContent = nil
        self.itemContent = itemContent
        super.init(frame: .zero)
        data.weakAssign(to: \.data, on: self).store(in: &viewCancellables)
    }
    
    // MARK: Init for static non-Sectioned Data
    public convenience init(
        _ data: [Item],
        layout: Layout = .adaptive,
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        itemContent: @escaping (Item) -> UIView
    ) {
        self.init(
            Just(data).eraseToAnyPublisher(),
            layout: layout,
            spacing: spacing,
            identifier: identifier,
            itemContent: itemContent
        )
    }
    
    // MARK: Init for Sectioned Data
    public init<P: Publisher>(
        _ sectionedData: P,
        layout: Layout = .adaptive,
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        sectionIdentifier: String = "\(String(describing: UIViewHostingCollectionSupplementaryView.self))_\(String(describing: Section.self))",
        sectionContent: @escaping (Section) -> UIView,
        itemContent: @escaping (Item) -> UIView
    ) where P.Output == [ListSection<Section, Item>], P.Failure == Never {
        self.layout = layout
        self.spacing = spacing
        self.identifier = identifier
        self.sectionIdentifier = sectionIdentifier
        self.sectionContent = sectionContent
        self.itemContent = itemContent
        super.init(frame: .zero)
        sectionedData.weakAssign(to: \.sectionedData, on: self).store(in: &viewCancellables)
    }
    
    // MARK: Init for static Data
    public convenience init(
        _ sectionedData: [ListSection<Section, Item>],
        layout: Layout = .adaptive,
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        sectionIdentifier: String = "\(String(describing: UIViewHostingCollectionSupplementaryView.self))_\(String(describing: Section.self))",
        sectionContent: @escaping (Section) -> UIView,
        itemContent: @escaping (Item) -> UIView
    ) {
        self.init(
            Just(sectionedData).eraseToAnyPublisher(),
            layout: layout,
            spacing: spacing,
            identifier: identifier,
            sectionIdentifier: sectionIdentifier,
            sectionContent: sectionContent,
            itemContent: itemContent
        )
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var body: UIView {
        if let sectionContent {
            return UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
                .backgroundColor(.clear)
                .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
                .register(UIViewHostingCollectionSupplementaryView.self, ofKind: UICollectionView.elementKindSectionHeader, identifier: sectionIdentifier ?? "Header")
                .bind(
                    to: $sectionedData,
                    supplementaryViewProvider: { [weak self] collectionView, kind, section, indexPath in
                        guard let self,
                              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionIdentifier ?? "Header", for: indexPath) as? UIViewHostingCollectionSupplementaryView else { return UICollectionReusableView() }
                        header.setContent(sectionContent(section))
                        return header
                    },
                    cellProvider: { [weak self] collectionView, indexPath, model in
                        guard let self,
                              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifier, for: indexPath) as? UIViewHostingCollectionViewCell else {
                            return UICollectionViewCell()
                        }
                        cell.setContent(self.itemContent(model))
                        return cell
                    }
                )
                .delegate(self)
                .isScrollEnabled($isScrollEnabled)
        } else {
            return UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
                .backgroundColor(.clear)
                .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
                .bind(to: $data, section: 0) { [weak self] collectionView, indexPath, model in
                    guard let self,
                          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifier, for: indexPath) as? UIViewHostingCollectionViewCell else {
                        return UICollectionViewCell()
                    }
                    cell.setContent(self.itemContent(model))
                    return cell
                }
                .delegate(self)
                .isScrollEnabled($isScrollEnabled)
        }
    }
    
    // MARK: Compositional Layout
    private var compositionalLayout: UICollectionViewCompositionalLayout {
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self else {
                return NSCollectionLayoutSection(group: .init(layoutSize: .init(widthDimension: .estimated(1), heightDimension: .estimated(1))))
            }
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
                group.interItemSpacing = .fixed(spacing)
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = spacing
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
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
                group.interItemSpacing = .fixed(spacing)
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = spacing
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
                
                return section
            case .rows(let numberOfRows, let itemHeight):
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
                group.interItemSpacing = .fixed(spacing)
                
                // Section
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = spacing
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
                
                return section
            case .carousel:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.8),
                    heightDimension: .estimated(44)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.interGroupSpacing = spacing
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = sectionContent == nil ? [] : [sectionHeader]
                
                return section
            }
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        if adjustsHeightToContent {
            guard let collectionView = subviews.first(where: { $0 is UICollectionView }) as? UICollectionView else { return }
            collectionView.layoutIfNeeded()
            DispatchQueue.main.async { [weak self, weak collectionView] in
                guard let self, let collectionView else { return }
                let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
                frame(height: contentSize.height)
            }
        }
    }
    
    // MARK: - Delegate
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < data.count else { return }
        let item = data[indexPath.item]
        onWillDisplayItem?(item)
    }
    
    // MARK: - builder pattern helper
    @discardableResult
    public func onWillDisplayItem(_ action: @escaping (Item) -> Void) -> Self {
        self.onWillDisplayItem = action
        return self
    }
    
    @discardableResult
    public func isScrollEnabled(_ isEnabled: Bool) -> Self {
        self.isScrollEnabled = isEnabled
        return self
    }
    
    @discardableResult
    public func adjustsHeightToContent(_ adjustsHeightToContent: Bool) -> Self {
        /// Set an initial height constraint to 1.
        /// This is necessary in case the list view is used inside an overlay,
        /// where `layoutSubviews()` may be called while the size is still zero,
        /// preventing accurate content size calculation.
        /// This ensures the layout system keeps the view alive and allows for
        /// proper height adjustment once content is available.
        self.frame(height: 1)
        self.adjustsHeightToContent = adjustsHeightToContent
        return self
    }
}
