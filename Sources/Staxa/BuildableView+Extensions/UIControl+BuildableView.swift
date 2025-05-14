//
//  UIControl+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 04/03/25.
//

import UIKit

public extension BuildableView where Self: UIControl {
    /// BuildableView: A Boolean value indicating whether the control is in the enabled state.
    @discardableResult
    func isEnabled(_ enabled: Bool) -> Self {
        isEnabled = enabled
        return self
    }
    
    /// BuildableView: A Boolean value indicating whether the control is in the selected state.
    @discardableResult
    func isSelected(_ selected: Bool) -> Self {
        isSelected = selected
        return self
    }
    
    /// BuildableView: Associates a target object and action method with the control.
    @discardableResult
    func addTarget(_ target: Any, action: Selector) -> Self {
        self.addTarget(target, action: action, for: .touchUpInside)
        return self
    }
    
    /// BuildableView: Action on tap
    @discardableResult
    func onTap(_ action: @escaping () -> Void) -> Self {
        self.tapAction = action
        return self
    }
    
    /// BuildableView: Action with debounce on tap
    @discardableResult
    func onTapWithDebounce(_ action: @escaping () -> Void) -> Self {
        self.tapAction = { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.isEnabled = false
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isEnabled = true
            }
        }
        return self
    }
}

fileprivate final class UIControlStorage {
    var tapAction: (() -> Void)?
}

extension UIControl {
    private static let associatedObject = AssociatedObject<UIControlStorage>()
    
    private var storage: UIControlStorage {
        if let storage = Self.associatedObject.get(for: self) {
            return storage
        } else {
            let newStorage = UIControlStorage()
            Self.associatedObject.set(newStorage, for: self)
            return newStorage
        }
    }
    
    var tapAction: (() -> Void)? {
        get { storage.tapAction }
        set {
            storage.tapAction = newValue
            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }
    }
    
    @objc private func handleTap() {
        tapAction?()
    }
}
