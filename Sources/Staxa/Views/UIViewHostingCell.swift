//
//  UIViewHostingCell.swift
//  Staxa
//
//  Created by Jacob Andrean on 15/04/25.
//

import UIKit

public class UIViewHostingTableViewCell: UITableViewCell {
    public private(set) var hostedView: UIView?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setContent(_ view: UIView) {
        hostedView?.removeFromSuperview()
        hostedView = view
        contentView.addSubview(view)
        view.pin(to: contentView)
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}

public class UIViewHostingCollectionViewCell: UICollectionViewCell {
    public private(set) var hostedView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setContent(_ view: UIView) {
        hostedView?.removeFromSuperview()
        hostedView = view
        contentView.addSubview(view)
        view.pin(to: contentView)
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}

public class UIViewHostingCollectionSupplementaryView: UICollectionReusableView {
    public private(set) var hostedView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setContent(_ view: UIView) {
        hostedView?.removeFromSuperview()
        hostedView = view
        addSubview(view)
        view.pin(to: self)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        hostedView?.removeFromSuperview()
        hostedView = nil
    }
}
