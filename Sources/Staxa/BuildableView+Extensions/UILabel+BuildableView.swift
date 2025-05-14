//
//  UILabel+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import Combine
import SwiftUI
import UIKit

/// Enum for gradient directions
public enum GradientDirection {
    case topToBottom
    case leftToRight
    case topLeftToBottomRight
    case bottomLeftToTopRight
}

// MARK: - Declarative UILabel
public extension BuildableView where Self: UILabel {
    /// BuildableView: The styled text that the label displays.
    @discardableResult
    func attributedText(_ attributedText: NSAttributedString?) -> Self {
        self.attributedText = attributedText
        return self
    }
    
    /// BuildableView: The maximum number of lines for rendering text.
    @discardableResult
    func numberOfLines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }
    
    /// BuildableView: The text that the label displays.
    @discardableResult
    func text(_ text: String?) -> Self {
        self.text = text
        return self
    }
    
    @discardableResult
    func text<P: Publisher>(_ text: P) -> Self where P.Output == String?, P.Failure == Never {
        text.sink { [weak self] newText in
            guard let self else { return }
            
            var attributes: [NSAttributedString.Key: Any]?
            if newText?.isEmpty ?? true {
                attributes?[.font] = self.font ?? .systemFont(ofSize: UIFont.systemFontSize)
            } else {
                attributes = lastKnownAttributes
            }
            attributedText = NSAttributedString(
                string: newText ?? "",
                attributes: attributes
            )
        }
        .store(in: &viewCancellables)
        return self
    }
    
    /// BuildableView: The color of the text.
    @discardableResult
    func textColor(_ color: UIColor?) -> Self {
        self.textColor = color
        return self
    }
    
    /// BuildableView: The font of the text.
    @discardableResult
    func font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    /// BuildableView: The technique for aligning the text.
    @discardableResult
    func textAlignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
    
    /// BuildableView: Adjusts letter spacing while preserving other attributes.
    @discardableResult
    func kerning(_ kerning: CGFloat) -> Self {
        updateAttributedText { $0[.kern] = kerning }
        return self
    }
    
    /// BuildableView: Adjusts line height while preserving other attributes.
    @discardableResult
    func paragraphLineHeight(_ height: CGFloat) -> Self {
        updateAttributedText { attributes in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = height
            paragraphStyle.maximumLineHeight = height
            paragraphStyle.alignment = textAlignment
            paragraphStyle.lineBreakMode = .byWordWrapping
            attributes[.paragraphStyle] = paragraphStyle
        }
        self.numberOfLines = 0
        return self
    }
    
    /// BuildableView: Highlight partial text
    @discardableResult
    func highlight(_ pattern: String, color: UIColor?, font: UIFont? = nil) -> Self {
        guard let text = self.text else { return self }
        
        // Create a mutable attributed string from the existing attributed text or plain text
        let attributedString: NSMutableAttributedString
        if let existingAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: existingAttributedText)
        } else {
            // Use lastKnownAttributes to preserve existing attributes
            var attributes = lastKnownAttributes ?? [:]
            // Ensure the font is set if not already in lastKnownAttributes
            if attributes[.font] == nil, let labelFont = self.font {
                attributes[.font] = labelFont
            }
            // Ensure the text color is set if not already in lastKnownAttributes
            if attributes[.foregroundColor] == nil, let labelTextColor = self.textColor {
                attributes[.foregroundColor] = labelTextColor
            }
            attributedString = NSMutableAttributedString(string: text, attributes: attributes)
        }
        
        // Find the range of the pattern to highlight
        let range = (text as NSString).range(of: pattern)
        if range.location != NSNotFound {
            // Apply the highlight color
            if let color = color {
                attributedString.addAttribute(.foregroundColor, value: color, range: range)
            }
            // Apply the highlight font if provided
            if let font = font {
                attributedString.addAttribute(.font, value: font, range: range)
            }
        }
        
        // Set the updated attributed text
        self.attributedText = attributedString
        // Update lastKnownAttributes with the new attributes
        self.lastKnownAttributes = attributedString.attributes(at: 0, effectiveRange: nil)
        return self
    }
    
    /// BuildableView: Applies a gradient color to the text.
    @discardableResult
    func gradientTextColor(colors: [UIColor], direction: GradientDirection) -> Self {
        guard let text = self.text, !colors.isEmpty else { return self }
        
        let textSize = (text as NSString).size(withAttributes: [NSAttributedString.Key.font: self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)])
        UIGraphicsBeginImageContextWithOptions(textSize, false, 0)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .topLeftToBottomRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        case .bottomLeftToTopRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 1)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        }
        gradientLayer.frame = CGRect(origin: .zero, size: textSize)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
        }
        
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let gradientImage = gradientImage {
            let gradientColor = UIColor(patternImage: gradientImage)
            updateAttributedText { attributes in
                attributes[.foregroundColor] = gradientColor
            }
        }
        
        return self
    }
    
    /// Helper function to update attributed text while preserving existing attributes.
    private func updateAttributedText(_ modify: (inout [NSAttributedString.Key: Any]) -> Void) {
        guard let existingText = self.text else { return }
        
        var attributes: [NSAttributedString.Key: Any] = lastKnownAttributes ?? [:]
        
        if attributes[.font] == nil {
            attributes[.font] = self.font ?? .systemFont(ofSize: UIFont.systemFontSize)
        }
        
        modify(&attributes)
        self.attributedText = NSAttributedString(string: existingText, attributes: attributes)
        self.lastKnownAttributes = attributes
    }
    
    @discardableResult
    func strikethrough(_ isActive: Bool = true) -> Self {
        guard let currentText = self.text else { return self }

        let attributes: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: isActive ? NSUnderlineStyle.single.rawValue : 0,
            .foregroundColor: self.textColor ?? UIColor.black,
            .font: self.font ?? UIFont.systemFont(ofSize: 14)
        ]

        self.attributedText = NSAttributedString(string: currentText, attributes: attributes)
        return self
    }
}


extension UILabel {
    private static let associatedObject = AssociatedObject<[NSAttributedString.Key: Any]>()
    
    var lastKnownAttributes: [NSAttributedString.Key: Any]? {
        get { Self.associatedObject.get(for: self) }
        set { Self.associatedObject.set(newValue, for: self) }
    }
}

#Preview {
    VStack {
        UIViewPreview {
            return UILabel()
                .text("Hello Jacob! 123 \n aklsdmlawm")
                .font(.systemFont(ofSize: 20))
                .kerning(12)
                .gradientTextColor(colors: [.red, .blue], direction: .leftToRight)
                .textAlignment(.center)
                .paragraphLineHeight(21)
        }
        .frame(height: 100)
        
        Text("Hello Jacob! 123 \n askmdlasm")
            .kerning(12)
            .font(.system(size: 20, weight: .heavy))
            .lineSpacing(1)
    }
}

/*
 public extension UILabel {
     /// A computed property that updates only the text while preserving attributes
     var textPreservingAttributes: String? {
         get { attributedText?.string }
         set {
             guard let newText = newValue, let existingAttributes = attributedText?.attributes(at: 0, effectiveRange: nil) else {
                 attributedText = NSAttributedString(string: newValue ?? "")
                 return
             }
             attributedText = NSAttributedString(string: newText, attributes: existingAttributes)
         }
     }
 }
 
 //    @discardableResult
 //    func bindText<T: Publisher>(_ text: T) -> Self where T.Output == String?, T.Failure == Never {
 //        text
 //            .receive(on: DispatchQueue.main)
 //            .sink { [weak self] newText in
 //                guard let self else { return }
 //                let existingAttributes = attributedText?.attributes(at: 0, effectiveRange: nil)
 //                attributedText = NSAttributedString(
 //                    string: newText ?? "",
 //                    attributes: existingAttributes
 //                )
 //            }
 //            .store(in: &viewCancellables)
 //
 //        return self
 //    }
 */
