//
//  UIStackView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import SwiftUI
import UIKit

public extension BuildableView where Self: UIStackView {
    /// BuildableView: Adds a views to the end of the arranged subviews array.
    @discardableResult
    func addArrangedSubviews(_ views: UIView...) -> Self {
        for view in views {
            self.addArrangedSubview(view)
        }
        return self
    }
    
    /// BuildableView: Set arranged subviews array.
    @discardableResult
    func arrangedSubviews(_ views: UIView...) -> Self {
        self.arrangedSubviews.forEach { $0.removeFromSuperview() }
        views.forEach { self.addArrangedSubview($0) }
        return self
    }
    
    /// BuildableView: The axis along which the arranged views lay out.
    @discardableResult
    func axis(_ axis: NSLayoutConstraint.Axis) -> Self {
        self.axis = axis
        return self
    }
    
    /// BuildableView: The distance in points between the adjacent edges of the stack view’s arranged views.
    @discardableResult
    func spacing(_ spacing: CGFloat) -> Self {
        self.spacing = spacing
        return self
    }
    
    /// BuildableView: Applies custom spacing after the specified view.
    @discardableResult
    func customSpacing(_ spacing: CGFloat, after view: UIView?) -> Self {
        if let view {
            self.setCustomSpacing(spacing, after: view)
        }
        return self
    }
    
    /// BuildableView: The distribution of the arranged views along the stack view’s axis.
    @discardableResult
    func distribution(_ distribution: UIStackView.Distribution) -> Self {
        self.distribution = distribution
        return self
    }
    
    /// BuildableView: The alignment of the arranged subviews perpendicular to the stack view’s axis.
    @discardableResult
    func alignment(_ alignment: UIStackView.Alignment) -> Self {
        self.alignment = alignment
        return self
    }
}

#Preview {
    UIViewPreview {
        let labelOne = UILabel()
            .text("text 1")
            .textColor(.red)
        let labelTwo = UILabel()
            .text("text 2")
            .textColor(.black)
        
        let stackView = UIStackView()
            .arrangedSubviews(labelOne, labelTwo)
            .axis(.vertical)
        
        return stackView
    }
}
