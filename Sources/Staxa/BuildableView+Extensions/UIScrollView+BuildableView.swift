//
//  UIScrollView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import UIKit

public extension BuildableView where Self: UIScrollView {
    /// BuildableView: The size of the content view.
    @discardableResult
    func contentSize(_ size: CGSize) -> Self {
        self.contentSize = size
        return self
    }
    
    /// BuildableView: The custom distance that the content view is inset from the safe area or scroll view edges.
    @discardableResult
    func contentInset(_ inset: UIEdgeInsets) -> Self {
        self.contentInset = inset
        return self
    }
    
    /// BuildableView: The point at which the origin of the content view is offset from the origin of the scroll view.
    @discardableResult
    func contentOffset(_ offset: CGPoint) -> Self {
        self.contentOffset = offset
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether bouncing always occurs when vertical scrolling reaches the end of the content.
    @discardableResult
    func alwaysBounceVertical(_ bounce: Bool) -> Self {
        self.alwaysBounceVertical = bounce
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view.
    @discardableResult
    func alwaysBounceHorizontal(_ bounce: Bool) -> Self {
        self.alwaysBounceHorizontal = bounce
        return self
    }
    
    /// BuildableView: A Boolean value that controls whether the scroll view bounces past the edge of content and back again.
    @discardableResult
    func bounces(_ bounces: Bool) -> Self {
        self.bounces = bounces
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether paging is enabled for the scroll view.
    @discardableResult
    func isPagingEnabled(_ enabled: Bool) -> Self {
        self.isPagingEnabled = enabled
        return self
    }
    
    /// BuildableView: A Boolean value that controls whether the vertical scroll indicator is visible.
    @discardableResult
    func showsVerticalScrollIndicator(_ shows: Bool) -> Self {
        self.showsVerticalScrollIndicator = shows
        return self
    }
    
    /// BuildableView: A Boolean value that controls whether the horizontal scroll indicator is visible.
    @discardableResult
    func showsHorizontalScrollIndicator(_ shows: Bool) -> Self {
        self.showsHorizontalScrollIndicator = shows
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether scrolling is enabled.
    @discardableResult
    func isScrollEnabled(_ enabled: Bool) -> Self {
        self.isScrollEnabled = enabled
        return self
    }
    
    /// BuildableView: A Boolean value that determines whether scrolling is disabled in a particular direction.
    @discardableResult
    func isDirectionalLockEnabled(_ enabled: Bool) -> Self {
        self.isDirectionalLockEnabled = enabled
        return self
    }
    
    /// BuildableView: A floating-point value that determines the rate of deceleration after the user lifts their finger.
    @discardableResult
    func decelerationRate(_ rate: UIScrollView.DecelerationRate) -> Self {
        self.decelerationRate = rate
        return self
    }
    
    /// BuildableView: The style of the scroll indicators.
    @discardableResult
    func indicatorStyle(_ style: UIScrollView.IndicatorStyle) -> Self {
        self.indicatorStyle = style
        return self
    }
    
    /// BuildableView: A Boolean value that controls whether the scroll-to-top gesture is enabled.
    @discardableResult
    func scrollsToTop(_ scrollsToTop: Bool) -> Self {
        self.scrollsToTop = scrollsToTop
        return self
    }
}
