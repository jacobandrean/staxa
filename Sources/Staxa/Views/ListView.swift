//
//  File.swift
//  Staxa
//
//  Created by Avows Technologies on 18/05/25.
//

import Combine
import UIKit

public class ListView<Item: Hashable>: StaxaView {
    private let spacing: CGFloat
    private let identifier: String
    private let rowContent: (Item) -> UIView
    @Published private var data: [Item] = []
    
    public init<P: Publisher>(
        _ data: P,
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        rowContent: @escaping (Item) -> UIView
    ) where P.Output == [Item], P.Failure == Never {
        self.spacing = spacing
        self.identifier = identifier
        self.rowContent = rowContent
        super.init(frame: .zero)
        data.weakAssign(to: \.data, on: self).store(in: &viewCancellables)
    }
    
    public convenience init(
        _ data: [Item],
        spacing: CGFloat = 0,
        identifier: String = "\(String(describing: UIViewHostingCollectionViewCell.self))_\(String(describing: Item.self))",
        rowContent: @escaping (Item) -> UIView
    ) {
        self.init(
            Just(data).eraseToAnyPublisher(),
            spacing: spacing,
            identifier: identifier,
            rowContent: rowContent
        )
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var body: UIView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = self.spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        }

        return UICollectionView(frame: .zero, collectionViewLayout: layout)
            .backgroundColor(.clear)
            .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
            .bind(to: $data, section: 0) { collectionView, indexPath, model in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifier, for: indexPath) as? UIViewHostingCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.setContent(self.rowContent(model))
                return cell
            }
    }
}
