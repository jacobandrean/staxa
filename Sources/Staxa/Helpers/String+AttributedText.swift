//
//  String+AttributedText.swift
//  Staxa
//
//  Created by Jacob Andrean on 21/02/25.
//

import Foundation
import UIKit

// MARK: - Extension for creating attributedText with font, textColor, letterSpacing, and lineHeight
public extension String {
    enum GradientDirection {
        case topToBottom
        case topLeftToBottomRight
        case bottomLeftToTopRight
    }
    
    func attributedText(
        font: UIFont = .systemFont(ofSize: 17),
        textColor: UIColor? = .black,
        letterSpacing: CGFloat? = nil,
        textAlignment: NSTextAlignment = .left,
        lineHeight: CGFloat? = nil,
        gradient: ([UIColor], GradientDirection)? = nil
    ) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        
        if let textColor {
            attributes[.foregroundColor] = textColor
        }

        if let letterSpacing {
            let kern = font.pointSize * letterSpacing
            attributes[.kern] = kern
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        if let lineHeight {
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
        }
        attributes[.paragraphStyle] = paragraphStyle
        
        if let gradientColors = gradient?.0,
           gradientColors.count > 1,
           let gradientDirection = gradient?.1,
           !isEmpty {
            let textSize = (self as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
            UIGraphicsBeginImageContextWithOptions(textSize, false, 0)
            
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = gradientColors.map { $0.cgColor }
            switch gradientDirection {
            case .topToBottom:
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            case .topLeftToBottomRight:
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            case .bottomLeftToTopRight:
                gradientLayer.startPoint = CGPoint(x: 0, y: 1)
                gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            }
            gradientLayer.frame = CGRect(origin: .zero, size: textSize)
            gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
            
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let gradientImage = gradientImage {
                let gradientColor = UIColor(patternImage: gradientImage)
                attributes[.foregroundColor] = gradientColor
            }
        }
        
        return NSAttributedString(string: self, attributes: attributes)
    }
}

