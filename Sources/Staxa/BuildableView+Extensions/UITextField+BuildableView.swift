//
//  UITextField+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import SwiftUI
import UIKit
import Combine

extension UITextField {
    public enum CursorPolicy {
        case system
        case preserve
    }
}

public extension BuildableView where Self: UITextField {
    /// DeclarativeView:
    @discardableResult
    func text(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    /// DeclarativeView: this is for set the text reactively
    @discardableResult
    func text(_ text: AnyPublisher<String?, Never>) -> Self {
        bind(text, to: \.text)
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func placeholder(_ placeholder: String?) -> Self {
        self.placeholder = placeholder
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func attributedText(_ attributedText: NSAttributedString?) -> Self {
        self.attributedText = attributedText
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func attributedPlaceholder(_ attributedPlaceholder: NSAttributedString?) -> Self {
        self.attributedPlaceholder = attributedPlaceholder
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func textColor(_ color: UIColor?) -> Self {
        self.textColor = color
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func font(_ font: UIFont?) -> Self {
        self.font = font
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func borderStyle(_ style: UITextField.BorderStyle) -> Self {
        self.borderStyle = style
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
        self.keyboardType = keyboardType
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func returnKeyType(_ returnKeyType: UIReturnKeyType) -> Self {
        self.returnKeyType = returnKeyType
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func clearButtonMode(_ mode: UITextField.ViewMode) -> Self {
        self.clearButtonMode = mode
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func textAlignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
        self.autocapitalizationType = type
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
        self.autocorrectionType = type
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func isSecureTextEntry(_ isSecure: Bool) -> Self {
        isSecureTextEntry = isSecure
        return self
    }
    
    /// DeclarativeView:
    @discardableResult
    func maxInput(_ length: Int) -> Self {
        self.maxInputLength = length
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
    
    @discardableResult
    func text(
        _ binding: PublishedBinding<String?>,
        cursorPolicy: CursorPolicy = .system
    ) -> Self {
        switch cursorPolicy {
        case .system:
            bind(binding.projectedValue, to: \.text)
        case .preserve:
            binding.projectedValue
                .receive(on: DispatchQueue.main)
                .removeDuplicates()
                .sink { [weak self] newText in
                    self?.setTextPreservingCursor(newText)
                }
                .store(in: &viewCancellables)
        }
        didChangeAction = {
            binding.wrappedValue = $0
        }
        return self
    }
    
    private func setTextPreservingCursor(_ newText: String?) {
        guard text != newText else { return }

        let oldRange = selectedTextRange
        text = newText

        guard
            let oldRange,
            let start = position(
                from: beginningOfDocument,
                offset: offset(from: beginningOfDocument, to: oldRange.start)
            )
        else { return }

        selectedTextRange = textRange(from: start, to: start)
    }
    
    @discardableResult
    func didBeginEditing(_ action: (() -> Void)?) -> Self {
        didBeginEditingAction = action
        return self
    }
    
    @discardableResult
    func didEndEditing(_ action: (() -> Void)?) -> Self {
        didEndEditingAction = action
        return self
    }
}

// MARK: - Helpers
fileprivate final class UITextFieldStorage {
    var didChangeAction: ((String?) -> Void)?
    var didBeginEditingAction: (() -> Void)?
    var didEndEditingAction: (() -> Void)?
    var maxInputLength: Int?
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
    
    var maxInputLength: Int? {
        get { storage.maxInputLength }
        set {
            storage.maxInputLength = newValue
            addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
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
        if let maxInputLength = storage.maxInputLength, let currentText = text, currentText.count > maxInputLength {
            text = String(currentText.prefix(maxInputLength))
            return
        }
        didChangeAction?(text)
    }
    
    var didBeginEditingAction: (() -> Void)? {
        get { storage.didBeginEditingAction }
        set {
            storage.didBeginEditingAction = newValue
            addTarget(self, action: #selector(didBeginEditing), for: .editingDidBegin)
        }
    }
    
    var didEndEditingAction: (() -> Void)? {
        get { storage.didEndEditingAction }
        set {
            storage.didEndEditingAction = newValue
            addTarget(self, action: #selector(didEndEditing), for: .editingDidEnd)
        }
    }
    
    @objc private func didBeginEditing() {
        storage.didBeginEditingAction?()
    }
    
    @objc private func didEndEditing() {
        storage.didEndEditingAction?()
    }
}
