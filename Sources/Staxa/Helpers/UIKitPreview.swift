//
//  UIKitPreview.swift
//  Staxa
//
//  Created by Jacob Andrean on 11/02/25.
//

import SwiftUI
import UIKit

public struct UIViewPreview<T: UIView>: UIViewRepresentable {
    let makeView: () -> T

    public init(_ makeView: @escaping () -> T) {
        self.makeView = makeView
    }

    public func makeUIView(context: Context) -> T {
        return makeView()
    }

    public func updateUIView(_ uiView: T, context: Context) {}
}

public struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    public init(_ builder: @escaping () -> ViewController) {
        self.viewController = builder()
    }
    
    public func makeUIViewController(context: Context) -> ViewController {
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}


#Preview {
    UIViewPreview {
        let label = UILabel()
        label.text = "hello world!"
        return label
    }
}

#Preview {
    UIViewControllerPreview {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        return viewController
    }
}
