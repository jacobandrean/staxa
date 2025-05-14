//
//  UITableView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import Combine
import UIKit

public extension BuildableView where Self: UITableView {
    /// BuildableView: Registers a reusable cell class with the table view.
    @discardableResult
    func register<Cell: UITableViewCell>(_ cellType: Cell.Type) -> Self {
        self.register(cellType, forCellReuseIdentifier: String(describing: cellType))
        return self
    }
    
    @discardableResult
    func register<Cell: UITableViewCell>(_ cellType: Cell.Type, identifier: String) -> Self {
        self.register(cellType, forCellReuseIdentifier: identifier)
        return self
    }
    
    /// BuildableView: The style for table cells to use as separators.
    @discardableResult
    func separatorStyle(_ style: UITableViewCell.SeparatorStyle) -> Self {
        self.separatorStyle = style
        return self
    }
    
    /// BuildableView: The color of separator rows in the table view.
    @discardableResult
    func separatorColor(_ color: UIColor?) -> Self {
        self.separatorColor = color
        return self
    }
    
    /// BuildableView: The default height in points of each row in the table view.
    @discardableResult
    func rowHeight(_ height: CGFloat) -> Self {
        self.rowHeight = height
        return self
    }
    
    /// BuildableView: The estimated height of rows in the table view.
    @discardableResult
    func estimatedRowHeight(_ height: CGFloat) -> Self {
        self.estimatedRowHeight = height
        return self
    }
    
    /// BuildableView: The height of section footers in the table view.
    @discardableResult
    func sectionFooterHeight(_ height: CGFloat) -> Self {
        self.sectionFooterHeight = height
        return self
    }
    
    /// BuildableView: The height of section headers in the table view.
    @discardableResult
    func sectionHeaderHeight(_ height: CGFloat) -> Self {
        self.sectionHeaderHeight = height
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether users can select a row.
    @discardableResult
    func allowsSelection(_ allowsSelection: Bool) -> Self {
        self.allowsSelection = allowsSelection
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether users can select more than one row outside of editing mode.
    @discardableResult
    func allowsMultipleSelection(_ allowsMultipleSelection: Bool) -> Self {
        self.allowsMultipleSelection = allowsMultipleSelection
        return self
    }
    
    /// BuildableView: The view that displays below the table’s content.
    @discardableResult
    func tableFooterView(_ footerView: UIView?) -> Self {
        self.tableFooterView = footerView
        return self
    }
    
    /// BuildableView: The view that displays above the table’s content.
    @discardableResult
    func tableHeaderView(_ headerView: UIView?) -> Self {
        self.tableHeaderView = headerView
        return self
    }
    
    /// BuildableView: The object that acts as the delegate of the table view.
    @discardableResult
    func delegate(_ delegate: UITableViewDelegate?) -> Self {
        self.delegate = delegate
        return self
    }
    
    /// BuildableView: The object that acts as the data source of the table view.
    @discardableResult
    func dataSource(_ dataSource: UITableViewDataSource?) -> Self {
        self.dataSource = dataSource
        return self
    }
    
    /// BuildableView: The color to use for the table view’s index text.
    @discardableResult
    func sectionIndexColor(_ color: UIColor?) -> Self {
        self.sectionIndexColor = color
        return self
    }
    
    /// BuildableView: The color to use for the background of the table view’s section index.
    @discardableResult
    func sectionIndexBackgroundColor(_ color: UIColor?) -> Self {
        self.sectionIndexBackgroundColor = color
        return self
    }
    
    /// BuildableView: Binds a `@Published`or `any Publisher` to the `UITableView DataSource`
    @discardableResult
    func bind<T, P: Publisher>(
        _ publisher: P,
        cellProvider: @escaping (UITableView, IndexPath, T) -> UITableViewCell
        //storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self where P.Output == [T], P.Failure == Never {
        let dataSource = CombineTableViewDataSource<T>(cellProvider: cellProvider)
        self.dataSource = dataSource
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newData in
                dataSource.updateData(newData)
                self?.reloadData()
            }
            .store(in: &viewCancellables)
        
        return self
    }
    
    /// BuildableView: Binds a `CurrentValueSubject` to the `UITableView DataSource`
    @discardableResult
    func bind<T>(
        _ subject: CurrentValueSubject<[T], Never>,
        cellProvider: @escaping (UITableView, IndexPath, T) -> UITableViewCell
    ) -> Self {
        return bind(
            subject.eraseToAnyPublisher(),
            cellProvider: cellProvider
        )
    }
    
    /// BuildableView: Binds a `PassthroughSubject` to the `UITableView DataSource`
    @discardableResult
    func bind<T>(
        _ subject: PassthroughSubject<[T], Never>,
        cellProvider: @escaping (UITableView, IndexPath, T) -> UITableViewCell
    ) -> Self {
        return bind(
            subject.eraseToAnyPublisher(),
            cellProvider: cellProvider
        )
    }
}

/// Custom Combine-powered UITableViewDataSource
private class CombineTableViewDataSource<T>: NSObject, UITableViewDataSource {
    private var data: [T] = []
    private let cellProvider: (UITableView, IndexPath, T) -> UITableViewCell

    init(cellProvider: @escaping (UITableView, IndexPath, T) -> UITableViewCell) {
        self.cellProvider = cellProvider
    }

    func updateData(_ newData: [T]) {
        self.data = newData
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellProvider(tableView, indexPath, data[indexPath.row])
    }
}
