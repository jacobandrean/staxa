//
//  UIView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import Combine
import SwiftUI
import UIKit

public enum OverlayAlignment {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
    case fill
}

public extension BuildableView where Self: UIView {
    @discardableResult
    func overlay(
        alignment: OverlayAlignment = .fill,
        _ content: () -> UIView,
        didLayoutOverlayView: ((UIView) -> Void)? = nil
    ) -> Self {
        let overlayView = content()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let overlaySize = overlayView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            switch alignment {
            case .topLeading:
                break
            case .top:
                let xOffset = (bounds.width - overlaySize.width) / 2
                overlayView.offset(x: xOffset)
            case .topTrailing:
                let xOffset = bounds.width - overlaySize.width
                overlayView.offset(x: xOffset)
            case .leading:
                let yOffset = bounds.height / 2
                overlayView.offset(y: abs(yOffset))
            case .center:
                let xOffset = (bounds.width - overlaySize.width) / 2
                let yOffset = bounds.height / 2
                overlayView.offset(x: xOffset, y: abs(yOffset))
            case .trailing:
                let xOffset = bounds.width - overlaySize.width
                let yOffset = bounds.height / 2
                overlayView.offset(x: xOffset, y: abs(yOffset))
            case .bottomLeading:
                overlayView.offset(y: bounds.height)
            case .bottom:
                let xOffset = (bounds.width - overlaySize.width) / 2
                overlayView.offset(x: xOffset, y: bounds.height)
            case .bottomTrailing:
                let xOffset = bounds.width - overlaySize.width
                overlayView.offset(x: xOffset, y: bounds.height)
            case .fill:
                overlayView.frame(width: bounds.width)
            }
            self.addSubview(overlayView)
        }
        // FIXME: Temporary workaround for execute code after didLayoutOverlayView
        if let didLayoutOverlayView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                didLayoutOverlayView(overlayView)
            }
        }
        return self
    }
    
    // Helper to find parent view controller
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let responder = parentResponder {
            if let vc = responder as? UIViewController {
                return vc
            }
            parentResponder = responder.next
        }
        return nil
    }
    
    /// BuildableView: A Boolean value that indicates whether the element is an accessibility element that an assistive app can access.
    @discardableResult
    func isAccessibilityElement(_ isAccessibilityElement: Bool) -> Self {
        self.isAccessibilityElement = isAccessibilityElement
        return self
    }
    
    @discardableResult
    func store<T: UIView>(in target: inout T?) -> Self {
        if let typedSelf = self as? T {
            target = typedSelf
        }
        return self
    }
    
    @discardableResult
    func offset(x: CGFloat = 0, y: CGFloat = 0) -> Self {
        self.transform = self.transform.translatedBy(x: x, y: y)
        return self
    }
    
    @discardableResult
    func zPosition(_ zPosition: CGFloat) -> Self {
        self.layer.zPosition = zPosition
        return self
    }
    
    @discardableResult
    func isUserInteractionEnabled(_ enabled: Bool) -> Self {
        self.isUserInteractionEnabled = enabled
        return self
    }
    
    @discardableResult
    func isUserInteractionEnabled<P: Publisher>(_ enabled: P) -> Self where P.Output == Bool, P.Failure == Never {
        bind(enabled, to: \.isUserInteractionEnabled)
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func dropShadow(
        color: UIColor? = .black.withAlphaComponent(0.2),
        offset: CGSize = .init(width: 0, height: 8),
        blur: CGFloat = 18,
        opacity: Float = 1,
        spread: CGFloat = 0,
        masksToBounds: Bool = false
    ) -> Self {
        self.layer.shadowColor = color?.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = blur / 2
        self.layer.shadowOpacity = opacity
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let rect = self.bounds.insetBy(dx: -spread, dy: -spread)
            self.layer.shadowPath = UIBezierPath(rect: rect).cgPath
        }
        self.layer.masksToBounds = masksToBounds
        return self
    }
    
    /// BuildableView: Inner Shadow
    @discardableResult
    func innerShadow(
        color: UIColor? = .black,
        blur: CGFloat = 20,
        opacity: Float = 0.3,
        edges: UIRectEdge = .all,
        cornerRadius: CGFloat = 0
    ) -> Self {
        let radius = blur / 2
        DispatchQueue.main.async { [weak self] in
            guard let self, let color else { return }

            self.layer.sublayers?
                .filter { $0.name?.hasPrefix("innerShadow_") == true }
                .forEach { $0.removeFromSuperlayer() }

            if edges.contains(.top) {
                self.addInnerShadow(edge: .top, color: color, radius: radius, opacity: opacity, cornerRadius: cornerRadius)
            }
            if edges.contains(.bottom) {
                self.addInnerShadow(edge: .bottom, color: color, radius: radius, opacity: opacity, cornerRadius: cornerRadius)
            }
            if edges.contains(.left) {
                self.addInnerShadow(edge: .left, color: color, radius: radius, opacity: opacity, cornerRadius: cornerRadius)
            }
            if edges.contains(.right) {
                self.addInnerShadow(edge: .right, color: color, radius: radius, opacity: opacity, cornerRadius: cornerRadius)
            }
        }
        return self
    }

    private func addInnerShadow(
        edge: UIRectEdge,
        color: UIColor,
        radius: CGFloat,
        opacity: Float,
        cornerRadius: CGFloat
    ) {
        let shadowLayer = CAGradientLayer()
        shadowLayer.name = "innerShadow_\(edge)"

        switch edge {
        case .top:
            shadowLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: radius)
            shadowLayer.startPoint = CGPoint(x: 0.5, y: 0)
            shadowLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .bottom:
            shadowLayer.frame = CGRect(x: 0, y: bounds.height - radius, width: bounds.width, height: radius)
            shadowLayer.startPoint = CGPoint(x: 0.5, y: 1)
            shadowLayer.endPoint = CGPoint(x: 0.5, y: 0)
        case .left:
            shadowLayer.frame = CGRect(x: 0, y: 0, width: radius, height: bounds.height)
            shadowLayer.startPoint = CGPoint(x: 0, y: 0.5)
            shadowLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .right:
            shadowLayer.frame = CGRect(x: bounds.width - radius, y: 0, width: radius, height: bounds.height)
            shadowLayer.startPoint = CGPoint(x: 1, y: 0.5)
            shadowLayer.endPoint = CGPoint(x: 0, y: 0.5)
        default:
            return
        }

        shadowLayer.colors = [
            color.withAlphaComponent(CGFloat(opacity)).cgColor,
            UIColor.clear.cgColor
        ]

        if cornerRadius > 0, edge == .top || edge == .bottom {
            let corners: UIRectCorner = (edge == .top) ? [.topLeft, .topRight] : [.bottomLeft, .bottomRight]
            let path = UIBezierPath(roundedRect: shadowLayer.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            shadowLayer.mask = maskLayer
        }

        layer.addSublayer(shadowLayer)
    }
    
    /// BuildableView:
    @discardableResult
    func frame(_ frame: CGRect) -> Self {
        self.frame = frame
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func tintColor(_ color: UIColor?) -> Self {
        self.tintColor = color
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func isHidden(_ hidden: Bool) -> Self {
        self.isHidden = hidden
        return self
    }
    
    /// BuildableView : for hiding reactively
    @discardableResult
    func isHidden<P: Publisher>(_ hidden: P) -> Self where P.Output == Bool, P.Failure == Never {
        bind(hidden, to: \.isHidden)
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func alpha(_ alpha: CGFloat) -> Self {
        self.alpha = alpha
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func backgroundColor(_ color: UIColor?) -> Self {
        self.backgroundColor = color
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func cornerRadius(_ radius: CGFloat) -> Self {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    func cornerRadius(_ corners: UIRectCorner, _ radius: CGFloat) -> Self {
        let maskedCorners: CACornerMask
        switch corners {
        case .allCorners:
            maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                             .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        default:
            var mask: CACornerMask = []
            if corners.contains(.topLeft)     { mask.insert(.layerMinXMinYCorner) }
            if corners.contains(.bottomLeft)  { mask.insert(.layerMinXMaxYCorner) }
            if corners.contains(.topRight)    { mask.insert(.layerMaxXMinYCorner) }
            if corners.contains(.bottomRight) { mask.insert(.layerMaxXMaxYCorner) }
            maskedCorners = mask
        }
        
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = maskedCorners
        self.layer.masksToBounds = true
        
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func border(width: CGFloat, color: UIColor?) -> Self {
        self.layer.borderWidth = width
        self.layer.borderColor = color?.cgColor
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func clipsToBounds(_ clipsToBounds: Bool) -> Self {
        self.clipsToBounds = clipsToBounds
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func contentMode(_ mode: UIView.ContentMode) -> Self {
        self.contentMode = mode
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func translatesAutoresizingMaskIntoConstraints(_ translates: Bool) -> Self {
        self.translatesAutoresizingMaskIntoConstraints = translates
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func addSubviews(_ views: UIView...) -> Self {
        views.forEach { self.addSubview($0) }
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func ignoreSafeArea(_ edges: UIRectEdge = .all) -> Self {
        self.ignoreSafeArea = edges
        return self
    }
    
    /// BuildableView:
    @discardableResult
    func onTapGesture(_ action: @escaping () -> Void) -> Self {
        self.tapGestureAction = action
        return self
    }
    
//    /// BuildableView:
//    @discardableResult
//    func isShowingLoaderView<P: Publisher>(_ isShowing: P) -> Self where P.Output == Bool, P.Failure == Never {
//        isShowing
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] in
//                guard let self,
//                      let vc = parentViewController as? CustomBaseVC
//                else { return }
//                $0 ? vc.showLoaderView() : vc.hideLoaderView()
//            }
//            .store(in: &viewCancellables)
//        return self
//    }
}

#Preview {
    UIViewPreview {
        let view = UIView()
            .backgroundColor(.red)
            .alpha(0.5)
            .cornerRadius(100)
            .onTapGesture {
                print("view tapped")
            }
        view.backgroundColor(.blue)
        return view
    }
    .frame(height: 100)
}
