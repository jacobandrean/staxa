//
//  UICollectionView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import Combine
import UIKit

public extension BuildableView where Self: UICollectionView {
    @discardableResult
    func compositionalLayout(_ builder: @escaping () -> UICollectionViewCompositionalLayout) -> Self {
        self.collectionViewLayout = builder()
        return self
    }
    
    @discardableResult
    func diffableDataSource<Section, Item>(
        _ dataSource: inout UICollectionViewDiffableDataSource<Section, Item>?,
        cellProvider: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell?
    ) -> Self {
        dataSource = .init(collectionView: self, cellProvider: cellProvider)
        return self
    }
    
    @discardableResult
    func applySnapshot<Section, Item>(
        _ dataSource: inout UICollectionViewDiffableDataSource<Section, Item>?,
        section: Section,
        items: [Item],
        animatingDifferences: Bool = true
    ) -> Self {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([section])
        snapshot.appendItems(items)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
        return self
    }
    
    /// BuildableView: Registers a reusable cell class with the table view.
    @discardableResult
    func register<Cell: UICollectionViewCell>(_ cellType: Cell.Type) -> Self {
        self.register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
        return self
    }
    
    @discardableResult
    func register<Cell: UICollectionViewCell>(_ cellType: Cell.Type, identifier: String) -> Self {
        self.register(cellType, forCellWithReuseIdentifier: identifier)
        return self
    }
    
    @discardableResult
    func register<SupplementaryView: UICollectionReusableView>(
        _ supplementaryViewType: SupplementaryView.Type,
        ofKind kind: String
    ) -> Self {
        let identifier = String(describing: supplementaryViewType)
        self.register(supplementaryViewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
        return self
    }
    
    @discardableResult
    func register<SupplementaryView: UICollectionReusableView>(
        _ supplementaryViewType: SupplementaryView.Type,
        ofKind kind: String,
        identifier: String
    ) -> Self {
        self.register(supplementaryViewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
        return self
    }
    
    /// BuildableView: The layout used to organize the collected view’s items.
    @discardableResult
    func collectionViewLayout(_ layout: UICollectionViewLayout) -> Self {
        self.collectionViewLayout = layout
        return self
    }
    
    /// BuildableView: The object that acts as the delegate of the collection view.
    @discardableResult
    func delegate(_ delegate: UICollectionViewDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    /// BuildableView: The object that provides the data for the collection view.
    @discardableResult
    func dataSource(_ dataSource: UICollectionViewDataSource?) -> Self {
        self.dataSource = dataSource
        return self
    }
    
    /// BuildableView: A Boolean value that indicates whether cell and data prefetching are enabled.
    @discardableResult
    func isPrefetchingEnabled(_ enabled: Bool) -> Self {
        self.isPrefetchingEnabled = enabled
        return self
    }
    
    /// BuildableView: A Boolean value that indicates whether users can select items in the collection view.
    @discardableResult
    func allowsSelection(_ allowsSelection: Bool) -> Self {
        self.allowsSelection = allowsSelection
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether users can select more than one item in the collection view.
    @discardableResult
    func allowsMultipleSelection(_ allowsMultipleSelection: Bool) -> Self {
        self.allowsMultipleSelection = allowsMultipleSelection
        return self
    }
    
    /// BuildableView: Binds a `@Published` or any `Publisher` to the `UICollectionView DataSource`
    @discardableResult
    func bind<T, P: Publisher>(
        to publisher: P,
        cellProvider: @escaping (UICollectionView, IndexPath, T) -> UICollectionViewCell,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self where P.Output == [T], P.Failure == Never {
        let dataSource = CombineCollectionViewDataSource<T>(cellProvider: cellProvider)
        self.dataSource = dataSource
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newData in
                dataSource.updateData(newData)
                self?.reloadData()
            }
            .store(in: &cancellables)
        
        return self
    }
    
    /// BuildableView: Binds a `CurrentValueSubject` to the `UICollectionView DataSource`
    @discardableResult
    func bind<T>(
        to subject: CurrentValueSubject<[T], Never>,
        cellProvider: @escaping (UICollectionView, IndexPath, T) -> UICollectionViewCell,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self {
        return bind(
            to: subject.eraseToAnyPublisher(),
            cellProvider: cellProvider,
            storeIn: &cancellables
        )
    }
    
    /// BuildableView: Binds a `PassthroughSubject` to the `UICollectionView DataSource`
    @discardableResult
    func bind<T>(
        to subject: PassthroughSubject<[T], Never>,
        cellProvider: @escaping (UICollectionView, IndexPath, T) -> UICollectionViewCell,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self {
        return bind(
            to: subject.eraseToAnyPublisher(),
            cellProvider: cellProvider,
            storeIn: &cancellables
        )
    }
    
    @discardableResult
    func bind<Section: Hashable, Item: Hashable, P: Publisher>(
        to publisher: P,
        section: Section,
        cellProvider: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell
//        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self where P.Output == [Item], P.Failure == Never {
        
        let dataSourceWrapper = CombineCollectionViewDiffableDataSourceWrapper<Section, Item>(
            collectionView: self,
            cellProvider: cellProvider
        )
        self.dataSource = dataSourceWrapper.dataSource
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { items in
                dataSourceWrapper.apply(items: items, to: section)
            }
            .store(in: &viewCancellables)
        
        return self
    }
    
    @discardableResult
    func bind<Section: Hashable, Item: Hashable, P: Publisher>(
        to publisher: P,
        supplementaryViewProvider: ((UICollectionView, String, Section, IndexPath) -> UICollectionReusableView)? = nil,
        cellProvider: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell
    ) -> Self where P.Output == [(Section, [Item])], P.Failure == Never {
        
        let dataSourceWrapper = CombineCollectionViewDiffableDataSourceWrapper<Section, Item>(
            collectionView: self,
            cellProvider: cellProvider
        )
        self.dataSource = dataSourceWrapper.dataSource
        
        // Assign supplementary view provider if provided
        if let supplementaryViewProvider = supplementaryViewProvider {
            dataSourceWrapper.dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
                let section = dataSourceWrapper.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                return supplementaryViewProvider(collectionView, kind, section, indexPath)
            }
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { sectionedItems in
                dataSourceWrapper.apply(sectionedItems: sectionedItems)
            }
            .store(in: &viewCancellables)
        
        return self
    }
}

/// Custom Combine-powered UICollectionViewDataSource
private class CombineCollectionViewDataSource<T>: NSObject, UICollectionViewDataSource {
    private var data: [T] = []
    private let cellProvider: (UICollectionView, IndexPath, T) -> UICollectionViewCell

    init(cellProvider: @escaping (UICollectionView, IndexPath, T) -> UICollectionViewCell) {
        self.cellProvider = cellProvider
    }

    func updateData(_ newData: [T]) {
        self.data = newData
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(collectionView, indexPath, data[indexPath.row])
    }
}

private class CombineCollectionViewDiffableDataSourceWrapper<Section: Hashable, Item: Hashable> {
    let dataSource: UICollectionViewDiffableDataSource<Section, Item>
    
    init(
        collectionView: UICollectionView,
        cellProvider: @escaping (UICollectionView, IndexPath, Item) -> UICollectionViewCell
    ) {
        self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView,
            cellProvider: cellProvider
        )
    }
    
    func apply(items: [Item], to section: Section) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([section])
        snapshot.appendItems(items, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func apply(sectionedItems: [(Section, [Item])]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        for (section, items) in sectionedItems {
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
