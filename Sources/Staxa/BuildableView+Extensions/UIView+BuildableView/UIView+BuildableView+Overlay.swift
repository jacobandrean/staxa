//
//  File.swift
//  Staxa
//
//  Created by Avows Technologies on 17/06/25.
//

import UIKit

public extension UIView {
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
}

public extension UIView {
    enum OverlayAlignment {
        case topLeading, top, topTrailing
        case leading, center, trailing
        case bottomLeading, bottom, bottomTrailing
        case aboveFill, aboveLeading, above, aboveTrailing
        case belowFill, belowLeading, below, belowTrailing
    }
}

public extension BuildableView where Self: UIView {
    /// Finds the best container to attach an overlay view:
    /// - Prefers the outermost UIScrollView if present.
    /// - Falls back to the top-level subview of the view controller's view that contains this view.
    private var preferredOverlayContainer: UIView? {
        guard let rootView = parentViewController?.view else { return nil }

        var view: UIView? = self
        var lastScrollView: UIScrollView?

        while let current = view {
            if let scrollView = current as? UIScrollView {
                lastScrollView = scrollView
            }
            if current.superview === rootView {
                return lastScrollView ?? current
            }
            view = current.superview
        }
        return nil
    }
    
    @discardableResult
    func overlay(alignment: OverlayAlignment = .center, _ content: () -> UIView) -> Self {
        let overlayView = content()
        onAttachToWindowAndLayout { [weak self] in
            guard let self, let parentView = preferredOverlayContainer else { return }
            
            let overlaySize = overlayView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let rect = convert(bounds, to: parentView)
            
            let leadingOffset = rect.minX
            let centerXOffset = rect.midX - overlaySize.width / 2
            let trailingOffset = rect.maxX - overlaySize.width
            let topOffset = rect.minY
            let centerYOffset = rect.midY - overlaySize.height / 2
            let bottomOffset = rect.maxY - overlaySize.height
            let aboveOffset = rect.minY - overlaySize.height
            let belowOffset = rect.maxY
            
            switch alignment {
            case .topLeading:
                overlayView.offset(x: leadingOffset, y: topOffset)
            case .top:
                overlayView.offset(x: centerXOffset, y: topOffset)
            case .topTrailing:
                overlayView.offset(x: trailingOffset, y: topOffset)
            case .leading:
                overlayView.offset(x: leadingOffset, y: centerYOffset)
            case .center:
                overlayView.offset(x: centerXOffset, y: centerYOffset)
            case .trailing:
                overlayView.offset(x: trailingOffset, y: centerYOffset)
            case .bottomLeading:
                overlayView.offset(x: leadingOffset, y: bottomOffset)
            case .bottom:
                overlayView.offset(x: centerXOffset, y: bottomOffset)
            case .bottomTrailing:
                overlayView.offset(x: trailingOffset, y: bottomOffset)
            case .aboveLeading:
                overlayView.offset(x: leadingOffset, y: aboveOffset)
            case .above:
                overlayView.offset(x: centerXOffset, y: aboveOffset)
            case .aboveTrailing:
                overlayView.offset(x: trailingOffset, y: aboveOffset)
            case .aboveFill:
                overlayView.frame(width: rect.width)
                overlayView.offset(x: rect.minX, y: aboveOffset)
            case .belowLeading:
                overlayView.offset(x: leadingOffset, y: belowOffset)
            case .below:
                overlayView.offset(x: centerXOffset, y: belowOffset)
            case .belowTrailing:
                overlayView.offset(x: trailingOffset, y: belowOffset)
            case .belowFill:
                overlayView.frame(width: rect.width)
                overlayView.offset(x: rect.minX, y: belowOffset)
            }
            parentView.addSubview(overlayView)
        }
        return self
    }
    
    @discardableResult
    func overlayOnSuperview(
        alignment: OverlayAlignment = .center,
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
            default:
                break
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
}

extension UIView {
    func onAttachToWindowAndLayout(_ action: @escaping () -> Void) {
        class HandlerView: UIView {
            let action: () -> Void
            var didRun = false
            
            init(action: @escaping () -> Void) {
                self.action = action
                super.init(frame: .zero)
                isHidden = true
                isUserInteractionEnabled = false
            }
            
            required init?(coder: NSCoder) { fatalError() }
            
            override func didMoveToWindow() {
                super.didMoveToWindow()
                guard window != nil else { return }
                
                // Wait until layout happens
                DispatchQueue.main.async { [weak self] in
                    guard let self, !didRun else { return }
                    
                    // Ensure layout has been performed
                    if superview?.bounds.size != .zero {
                        didRun = true
                        action()
                        removeFromSuperview()
                    } else {
                        // Retry one frame later if bounds are still zero
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            if !didRun {
                                didRun = true
                                action()
                                removeFromSuperview()
                            }
                        }
                    }
                }
            }
        }
        
        let handler = HandlerView(action: action)
        addSubview(handler)
    }
}
