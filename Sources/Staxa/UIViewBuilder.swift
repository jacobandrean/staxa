//
//  UIViewBuilder.swift
//  Staxa
//
//  Created by Jacob Andrean on 14/05/25.
//

import Combine
import SwiftUI
import UIKit

// MARK: - UIViewBuilder
@resultBuilder
public struct UIViewBuilder {
    public typealias Component = [Expression]
    public typealias Expression = UIView

    public static func buildExpression(_ element: Expression) -> Component {
        return [element]
    }

    public static func buildExpression(_ component: Component) -> Component {
        return component
    }

    public static func buildOptional(_ component: Component?) -> Component {
        guard let component = component else { return [] }
        return component
    }

    public static func buildEither(first component: Component) -> Component {
        return component
    }

    public static func buildEither(second component: Component) -> Component {
        return component
    }

    public static func buildArray(_ components: [Component]) -> Component {
        return Array(components.joined())
    }

    public static func buildBlock(_ components: Component...) -> Component {
        return Array(components.joined())
    }
    
    public static func buildBlock() -> Component {
        return []
    }
}

// MARK: - VStackView
public class VStackView: UIStackView {
    public init(spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, @UIViewBuilder _ content: () -> [UIView]) {
        super.init(frame: .zero)
        self.axis = .vertical
        self.spacing = spacing
        self.alignment = alignment
        self.translatesAutoresizingMaskIntoConstraints = false
        var views = content()
        // Check if there is at least one SpacerView
        let hasSpacer = views.contains(where: { $0 is SpacerView })
        // If no SpacerView exists, add one at the top and bottom
        if !hasSpacer {
            views.insert(SpacerView(), at: 0)
            views.append(SpacerView())
        }
        views.forEach(addArrangedSubview)
        setEqualHeightForSpacers()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setEqualHeightForSpacers() {
        // Filter out all SpacerView instances without explicit height constraints
        let spacers = arrangedSubviews.compactMap { $0 as? SpacerView }
            .filter { $0.constraints.first(where: { $0.firstAttribute == .height }) == nil }
        
        // Ensure there are at least two spacers to apply constraints
        guard spacers.count >= 2 else { return }
        
        // Apply equal height constraints between all spacers
        for i in 1..<spacers.count {
            spacers[i].heightAnchor.constraint(equalTo: spacers[0].heightAnchor).isActive = true
        }
    }
}

// MARK: - HStackView
public class HStackView: UIStackView {
    public init(spacing: CGFloat = 0, alignment: UIStackView.Alignment = .center, @UIViewBuilder _ content: () -> [UIView]) {
        super.init(frame: .zero)
        self.axis = .horizontal
        self.spacing = spacing
        self.alignment = alignment
        self.translatesAutoresizingMaskIntoConstraints = false
        var views = content()
        // Check if there is at least one SpacerView
        let hasSpacer = views.contains(where: { $0 is SpacerView })
        // If no SpacerView exists, add one at the top and bottom
        if !hasSpacer {
            views.insert(SpacerView(), at: 0)
            views.append(SpacerView())
        }
        views.forEach(addArrangedSubview)
        setEqualWidthForSpacers()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setEqualWidthForSpacers() {
        // Filter out all SpacerView instances without explicit height constraints
        let spacers = arrangedSubviews.compactMap { $0 as? SpacerView }
            .filter { $0.constraints.first(where: { $0.firstAttribute == .width }) == nil }
        
        // Ensure there are at least two spacers to apply constraints
        guard spacers.count >= 2 else { return }
        
        // Apply equal height constraints between all spacers
        for i in 1..<spacers.count {
            spacers[i].widthAnchor.constraint(equalTo: spacers[0].widthAnchor).isActive = true
        }
    }
}

// MARK: - ZStackView
public class ZStackView: UIView {
    public enum Alignment {
        case topLeading, top, topTrailing
        case leading, center, trailing
        case bottomLeading, bottom, bottomTrailing
        case fill
    }
    
    private var isFirstSubview: Bool = true
    
    public init(alignment: Alignment = .center, @UIViewBuilder _ content: () -> [UIView]) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        content().forEach { view in
            self.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            guard !isFirstSubview else {
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: topAnchor),
                    view.bottomAnchor.constraint(equalTo: bottomAnchor),
                    view.leadingAnchor.constraint(equalTo: leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: trailingAnchor)
                ])
                isFirstSubview = false
                return
            }
            NSLayoutConstraint.activate(constraints(for: view, in: self, alignment: alignment))
        }
    }
    
    private func constraints(for view: UIView, in superview: UIView, alignment: Alignment) -> [NSLayoutConstraint] {
        switch alignment {
        case .topLeading:
            return [view.topAnchor.constraint(equalTo: superview.topAnchor),
                    view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)]
        case .top:
            return [view.topAnchor.constraint(equalTo: superview.topAnchor),
                    view.centerXAnchor.constraint(equalTo: superview.centerXAnchor)]
        case .topTrailing:
            return [view.topAnchor.constraint(equalTo: superview.topAnchor),
                    view.trailingAnchor.constraint(equalTo: superview.trailingAnchor)]
        case .leading:
            return [view.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
                    view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)]
        case .center:
            return [view.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
                    view.centerYAnchor.constraint(equalTo: superview.centerYAnchor)]
        case .trailing:
            return [view.centerYAnchor.constraint(equalTo: superview.centerYAnchor),
                    view.trailingAnchor.constraint(equalTo: superview.trailingAnchor)]
        case .bottomLeading:
            return [view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                    view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)]
        case .bottom:
            return [view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                    view.centerXAnchor.constraint(equalTo: superview.centerXAnchor)]
        case .bottomTrailing:
            return [view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                    view.trailingAnchor.constraint(equalTo: superview.trailingAnchor)]
        case .fill:
            return [
                view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                view.topAnchor.constraint(equalTo: superview.topAnchor),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ScrollStackView
public class ScrollStackView: UIScrollView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 0
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    public init(axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 0, alignment: UIStackView.Alignment = .fill, showsScrollIndicator: Bool = true, @UIViewBuilder _ content: () -> [UIView]) {
        super.init(frame: .zero)
        self.showsVerticalScrollIndicator = showsScrollIndicator
        self.showsHorizontalScrollIndicator = showsScrollIndicator
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        stackView.axis = axis
        stackView.spacing = spacing
        stackView.alignment = alignment
        content().forEach(stackView.addArrangedSubview)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        if axis == .vertical {
            stackView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        } else {
            stackView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - LazyVStackView
public class LazyVStackView: UIView, UITableViewDataSource, UITableViewDelegate {
    public enum Alignment {
        case fill, leading, center, trailing
    }

    private let tableView = UITableView()
    private var views: [UIView] = []
    private var spacing: CGFloat = 0
    private var alignment: Alignment = .fill
    private var contentSizeObserver: NSKeyValueObservation?

    public init(
        spacing: CGFloat = 0,
        alignment: Alignment = .fill,
        @UIViewBuilder _ content: () -> [UIView]
    ) {
        super.init(frame: .zero)
        self.spacing = spacing
        self.alignment = alignment
        self.views = content()
        setupTableView()
        observeContentSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(Cell.self, forCellReuseIdentifier: "LazyVStackCell")

        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func observeContentSize() {
        contentSizeObserver = tableView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            self?.invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: tableView.contentSize.height)
    }

    // MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        views.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let view = views[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "LazyVStackCell", for: indexPath) as! Cell
        cell.setContent(view, spacing: spacing, isLast: indexPath.row == views.count - 1, alignment: alignment)
        return cell
    }

    // MARK: - Private Cell
    private class Cell: UITableViewCell {
        private var hostedView: UIView?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            selectionStyle = .none
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setContent(_ view: UIView, spacing: CGFloat, isLast: Bool, alignment: Alignment) {
            hostedView?.removeFromSuperview()
            hostedView = view
            contentView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false

            var constraints: [NSLayoutConstraint] = [
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: isLast ? 0 : -spacing)
            ]

            switch alignment {
            case .fill:
                constraints += [
                    view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
                ]
            case .leading:
                constraints += [
                    view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    view.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
                ]
            case .trailing:
                constraints += [
                    view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
                ]
            case .center:
                constraints += [
                    view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                    view.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
                ]
            }

            NSLayoutConstraint.activate(constraints)
        }
    }
}

// MARK: LazyHStackView
public class LazyHStackView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let collectionView: UICollectionView
    private let views: [UIView]
    private let spacing: CGFloat
    private let alignment: UIStackView.Alignment
    private var contentSizeObserver: NSKeyValueObservation?
    private var maxItemHeight: CGFloat = 0

    public init(
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        @UIViewBuilder _ content: () -> [UIView]
    ) {
        self.views = content()
        self.spacing = spacing
        self.alignment = alignment

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)

        setupCollectionView()
        observeContentSize()
        calculateMaxHeight()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "LazyHStackCell")

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func observeContentSize() {
        contentSizeObserver = collectionView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            self?.invalidateIntrinsicContentSize()
        }
    }

    private func calculateMaxHeight() {
        for view in views {
            let size = view.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize,
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .defaultHigh
            )
            maxItemHeight = max(maxItemHeight, size.height)
        }
    }

    public override var intrinsicContentSize: CGSize {
        let width = collectionView.collectionViewLayout.collectionViewContentSize.width
        return CGSize(width: width, height: maxItemHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        views.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let view = views[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LazyHStackCell", for: indexPath) as! Cell
        cell.setContent(view, alignment: alignment)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let view = views[indexPath.item]
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let size = view.systemLayoutSizeFitting(
            CGSize(width: UIView.layoutFittingCompressedSize.width,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .defaultHigh
        )

        return size
    }

    private class Cell: UICollectionViewCell {
        private var hostedView: UIView?

        func setContent(_ view: UIView, alignment: UIStackView.Alignment) {
            hostedView?.removeFromSuperview()
            hostedView = view
            contentView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false

            var constraints: [NSLayoutConstraint] = [
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ]

            switch alignment {
            case .fill:
                constraints += [
                    view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ]
            case .center:
                constraints += [
                    view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
                ]
            case .top:
                constraints += [
                    view.topAnchor.constraint(equalTo: contentView.topAnchor)
                ]
            case .bottom:
                constraints += [
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ]
            default:
                constraints += [
                    view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ]
            }

            NSLayoutConstraint.activate(constraints)
        }
    }
}

// MARK: - ForEachView
public class ForEachView<T>: UIStackView {
    private var items: [T] = []
    private var content: (T) -> [UIView]
    
    public init(_ items: [T], @UIViewBuilder _ content: @escaping (T) -> [UIView]) {
        self.items = items
        self.content = content
        super.init(frame: .zero)
        buildViews()
    }
    
    public init<P: Publisher>(
        _ publisher: P,
        @UIViewBuilder _ content: @escaping (T) -> [UIView]
    ) where P.Output == [T], P.Failure == Never {
        self.content = content
        super.init(frame: .zero)
        
        publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] newItems in
                guard let self = self else { return }
                self.update(with: newItems)
            }
            .store(in: &viewCancellables)
    }
    
    private func update(with newItems: [T]) {
        items = newItems
        buildViews()
    }
    
    private func buildViews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in items {
            let views = content(item)
            views.forEach { addArrangedSubview($0) }
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let parentStackView = superview as? UIStackView {
            axis = parentStackView.axis
        }
    }
}

// MARK: - SpacerView
public class SpacerView: UIView {
    public init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - BuilderLayoutVC
open class StaxaViewController: UIViewController {
    open var body: UIView { UIView() }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let body = body
        let ignoreSafeArea = body.ignoreSafeArea
        view.addSubview(body)
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(
                equalTo: ignoreSafeArea.contains(.top) ? view.topAnchor : view.safeAreaLayoutGuide.topAnchor
            ),
            body.bottomAnchor.constraint(
                equalTo: ignoreSafeArea.contains(.bottom) ? view.bottomAnchor : view.safeAreaLayoutGuide.bottomAnchor
            ),
            body.leadingAnchor.constraint(
                equalTo: ignoreSafeArea.contains(.left) ? view.leadingAnchor : view.safeAreaLayoutGuide.leadingAnchor
            ),
            body.trailingAnchor.constraint(
                equalTo: ignoreSafeArea.contains(.right) ? view.trailingAnchor : view.safeAreaLayoutGuide.trailingAnchor
            ),
        ])
    }
}

// MARK: - BuilderLayoutView
open class StaxaView: UIView {
    private var hasSetupBody = false
    
    open var body: UIView { UIView() }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !hasSetupBody {
            setupBuilderLayout()
            hasSetupBody = true
        }
    }
    
    private func setupBuilderLayout() {
        let body = body
        addSubview(body)
        body.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: topAnchor),
            body.bottomAnchor.constraint(equalTo: bottomAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor),
            body.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
