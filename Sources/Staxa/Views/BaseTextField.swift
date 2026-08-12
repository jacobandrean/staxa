//
//  BaseTextField.swift
//  Staxa
//
//  Created by Jacob Andrean on 01/08/25.
//

import UIKit

open class BaseTextField: UITextField {
    
    // MARK: - Init
    
    public convenience init(
        _ binding: PublishedBinding<String?>,
        cursorPolicy: UITextField.CursorPolicy = .system
    ) {
        self.init(frame: .zero)
        self.text(binding, cursorPolicy: cursorPolicy)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: -  LeadingView & TrailingView
    
    var leadingView: UIView? {
        didSet {
            leftView = leadingView
            leftViewMode = .always
            invalidateIntrinsicContentSize()
        }
    }
    
    var trailingView: UIView? {
        didSet {
            rightView = trailingView
            rightViewMode = .always
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Text Insets
    
    var textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return adjustedRect(forBounds: bounds)
    }

    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return adjustedRect(forBounds: bounds)
    }

    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return adjustedRect(forBounds: bounds)
    }

    private func adjustedRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds.inset(by: textInsets)

        if let leftView = leftView {
            rect.origin.x += leftView.frame.width
            rect.size.width -= leftView.frame.width
        }

        if let rightView = rightView {
            rect.size.width -= rightView.frame.width
        }

        return rect
    }

    // MARK: - Dynamic Height
    public override var intrinsicContentSize: CGSize {
        // Ensure subviews are laid out
        leadingView?.layoutIfNeeded()
        trailingView?.layoutIfNeeded()
        
        let fontHeight = font?.lineHeight ?? 0
        let leadingHeight = leadingView?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0
        let trailingHeight = trailingView?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0
        
        let maxHeight = max(fontHeight, leadingHeight, trailingHeight)
        return CGSize(width: UIView.noIntrinsicMetric, height: maxHeight)
    }
}

// MARK: - DeclarativeView + BaseTextField
public extension BuildableView where Self: BaseTextField {
    @discardableResult
    func leadingView(_ view: () -> UIView) -> Self {
        self.leadingView = view()
        return self
    }
    
    @discardableResult
    func trailingView(_ view: () -> UIView) -> Self {
        self.trailingView = view()
        return self
    }
    
    @discardableResult
    func textInsets(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> Self {
        self.textInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        return self
    }
}
