//
//  File.swift
//  Staxa
//
//  Created by Avows Technologies on 18/05/25.
//

import Combine
import UIKit

public class ListView<P: Publisher, Item: Hashable>: StaxaView where P.Output == [Item], P.Failure == Never {
    private let spacing: CGFloat
    private let identifier: String
    private let data: P
    private let rowContent: (Item) -> UIView

    public init(
        _ data: P,
        spacing: CGFloat = 0,
        identifier: String = UUID().uuidString,
        rowContent: @escaping (Item) -> UIView
    ) {
        self.identifier = identifier
        self.spacing = spacing
        self.data = data
        self.rowContent = rowContent
        super.init(frame: .zero)
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
            .register(UIViewHostingCollectionViewCell.self, identifier: identifier)
            .bind(to: data, section: 0) { collectionView, indexPath, model in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifier, for: indexPath) as? UIViewHostingCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.setContent(self.rowContent(model))
                return cell
            }
    }
}
