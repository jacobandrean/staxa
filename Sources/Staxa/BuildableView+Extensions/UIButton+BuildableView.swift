//
//  UIButton+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import SwiftUI
import UIKit

public extension BuildableView where Self: UIButton {
    /// BuildableView: Sets the styled title to use for the specified state.
    @discardableResult
    func attributedTitle(_ title: NSAttributedString?, for state: UIControl.State = .normal) -> Self {
        self.setAttributedTitle(title, for: state)
        return self
    }
    
    /// BuildableView: Sets the title to use for the specified state.
    @discardableResult
    func title(_ title: String?, for state: UIControl.State = .normal) -> Self {
        self.setTitle(title, for: state)
        return self
    }
    
    /// BuildableView: Sets the color of the title to use for the specified state.
    @discardableResult
    func titleColor(_ color: UIColor?, for state: UIControl.State = .normal) -> Self {
        self.setTitleColor(color, for: state)
        return self
    }
    
    /// BuildableView: Sets the image to use for the specified state.
    @discardableResult
    func image(_ image: UIImage?, for state: UIControl.State = .normal) -> Self {
        self.setImage(image, for: state)
        return self
    }
    
    /// BuildableView: Sets the background image to use for the specified button state.
    @discardableResult
    func backgroundImage(_ image: UIImage?, for state: UIControl.State = .normal) -> Self {
        self.setBackgroundImage(image, for: state)
        return self
    }
}

#Preview {
    UIViewPreview {
        let button = UIButton()
            .title("tap me")
            .titleColor(.blue)
        return button
    }
}
