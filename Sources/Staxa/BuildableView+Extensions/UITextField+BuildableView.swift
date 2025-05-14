//
//  UITextField+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import SwiftUI
import UIKit
import Combine

public extension BuildableView where Self: UITextField {
    /// BuildableView:
    @discardableResult
    func text(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func placeholder(_ placeholder: String?) -> Self {
        self.placeholder = placeholder
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func attributedText(_ attributedText: NSAttributedString?) -> Self {
        self.attributedText = attributedText
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func attributedPlaceholder(_ attributedPlaceholder: NSAttributedString?) -> Self {
        self.attributedPlaceholder = attributedPlaceholder
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func textColor(_ color: UIColor?) -> Self {
        self.textColor = color
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func font(_ font: UIFont?) -> Self {
        self.font = font
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func borderStyle(_ style: UITextField.BorderStyle) -> Self {
        self.borderStyle = style
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
        self.keyboardType = keyboardType
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func returnKeyType(_ returnKeyType: UIReturnKeyType) -> Self {
        self.returnKeyType = returnKeyType
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func clearButtonMode(_ mode: UITextField.ViewMode) -> Self {
        self.clearButtonMode = mode
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func textAlignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
        self.autocapitalizationType = type
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
        self.autocorrectionType = type
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func isSecureTextEntry(_ isSecure: Bool) -> Self {
        isSecureTextEntry = isSecure
        return self
    }
    
    @discardableResult
    func bindText(to subject: CurrentValueSubject<String?, Never>) -> Self {
        subject.eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newText in
                guard let self else { return }
                self.text = newText
            }
            .store(in: &viewCancellables)
        
        didChangeAction = { newText in
            subject.send(newText)
        }
        
        return self
    }
    
    @discardableResult
    func text(_ binding: Binding<String?>) -> Self {
        text = binding.wrappedValue
        didChangeAction = { newText in
            binding.wrappedValue = newText
        }
        
        return self
    }
}

// MARK: - Helpers
fileprivate final class UITextFieldStorage {
    var didChangeAction: ((String?) -> Void)?
}

extension UITextField {
    private static let associatedObject = AssociatedObject<UITextFieldStorage>()
    
    private var storage: UITextFieldStorage {
        if let storage = Self.associatedObject.get(for: self) {
            return storage
        } else {
            let newStorage = UITextFieldStorage()
            Self.associatedObject.set(newStorage, for: self)
            return newStorage
        }
    }
    
    var didChangeAction: ((String?) -> Void)? {
        get { storage.didChangeAction }
        set {
            storage.didChangeAction = newValue
            addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }
    
    @objc private func textFieldDidChange() {
        didChangeAction?(text)
    }
}
