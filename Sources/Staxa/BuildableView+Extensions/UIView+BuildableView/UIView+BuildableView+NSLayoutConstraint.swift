//
//  UIView+BuildableView+NSLayoutConstraint.swift
//  Staxa
//
//  Created by Jacob Andrean on 08/03/25.
//

import Combine
import SwiftUI
import UIKit

public extension BuildableView where Self: UIView {
    @discardableResult
    func pin(to view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant).isActive = true
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -constant).isActive = true
        return self
    }
    
    @discardableResult
    func pin(to view: UIView, top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: top).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottom).isActive = true
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailing).isActive = true
        return self
    }
    
    // MARK: - Top Anchor
    @discardableResult
    func topConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func topConstraint(lessThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(lessThanOrEqualTo: view.topAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func topConstraint(greaterThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: constant).isActive = true
        return self
    }

    // MARK: - Leading Anchor
    @discardableResult
    func leadingConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func leadingConstraint(lessThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(lessThanOrEqualTo: view.leadingAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func leadingConstraint(greaterThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: constant).isActive = true
        return self
    }

    // MARK: - Trailing Anchor
    @discardableResult
    func trailingConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func trailingConstraint(lessThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func trailingConstraint(greaterThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: constant).isActive = true
        return self
    }

    // MARK: - Bottom Anchor
    @discardableResult
    func bottomConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func bottomConstraint(lessThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func bottomConstraint(greaterThanOrEqualTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: constant).isActive = true
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func frame(minWidth: CGFloat? = nil, width: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, height: CGFloat? = nil, maxHeight: CGFloat? = nil) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        if let minWidth = minWidth {
            removeConstraint(for: .width, relation: .greaterThanOrEqual)
            self.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        }
        if let width = width {
            removeConstraint(for: .width, relation: .equal)
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let maxWidth = maxWidth {
            removeConstraint(for: .width, relation: .lessThanOrEqual)
            self.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
        }
        if let minHeight = minHeight {
            removeConstraint(for: .height, relation: .greaterThanOrEqual)
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
        }
        if let height = height {
            removeConstraint(for: .height, relation: .equal)
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if let maxHeight = maxHeight {
            removeConstraint(for: .height, relation: .lessThanOrEqual)
            self.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
        }
        return self
    }

    // MARK: - Center X and Center Y
    @discardableResult
    func centerConstraint(equalTo view: UIView) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        return self
    }
    
    @discardableResult
    func centerXConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant).isActive = true
        return self
    }

    @discardableResult
    func centerYConstraint(equalTo view: UIView, constant: CGFloat = 0) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
        return self
    }

    // MARK: - Aspect Ratio
    @discardableResult
    func aspectRatioConstraint(_ ratio: CGFloat) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: ratio).isActive = true
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func constraints(_ constraints: (Self) -> [NSLayoutConstraint]) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints(self))
        return self
    }
    
    @discardableResult
    func padding(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        self.pin(
            to: containerView,
            top: top,
            leading: left,
            bottom: bottom,
            trailing: right
        )
        return containerView
    }
    
    @discardableResult
    func padding(_ allEdges: CGFloat = 16) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        self.pin(
            to: containerView,
            top: allEdges,
            leading: allEdges,
            bottom: allEdges,
            trailing: allEdges
        )
        return containerView
    }
    
    @discardableResult
    func margins(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> UIView {
        let containerView = UIView()
        containerView.layoutMargins = .init(top: top, left: left, bottom: bottom, right: right)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            self.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            self.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor)
        ])
        
        return containerView
    }
    
    @discardableResult
    func margins(_ allEdges: CGFloat = 16) -> UIView {
        let containerView = UIView()
        containerView.layoutMargins = .init(top: allEdges, left: allEdges, bottom: allEdges, right: allEdges)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)
        
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            self.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            self.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor)
        ])
        
        return containerView
    }
    
    // Helper: Remove existing constraints for this attribute and relation
    private func removeConstraint(for attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation) {
        self.constraints
            .filter { $0.firstAttribute == attribute && $0.relation == relation && $0.firstItem as? UIView === self }
            .forEach { self.removeConstraint($0) }
    }
}
