//
//  UIImageView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 17/02/25.
//

import Combine
import UIKit

public extension BuildableView where Self: UIImageView {
    /// BuildableView: The image displayed in the image view.
    @discardableResult
    func image(_ image: UIImage?) -> Self {
        self.image = image
        return self
    }
    
    /// BuildableView reactive image store
    @discardableResult
    func image<P: Publisher>(_ image: P) -> Self where P.Output == UIImage?, P.Failure == Never {
        bind(image, to: \.image)
        return self
    }
    
    /// BuildableView: The highlighted image displayed in the image view.
    @discardableResult
    func highlightedImage(_ highlightedImage: UIImage?) -> Self {
        self.highlightedImage = highlightedImage
        return self
    }

}
