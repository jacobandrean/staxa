//
//  UIKitPreview.swift
//  Staxa
//
//  Created by Jacob Andrean on 11/02/25.
//

import SwiftUI
import UIKit

public struct UIViewPreview<Content: UIView>: UIViewRepresentable {
    let content: () -> Content

    public init(_ content: @escaping () -> Content) {
        self.content = content
    }

    public func makeUIView(context: Context) -> UIView {
        let view = content()
        let container = UIView().addSubviews(view)
        view.centerConstraint(equalTo: container)
        return container
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
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
        ZStackView {
            UIView()
                .sizeConstraint(width: 50, height: 50)
                .backgroundColor(.red).cornerRadius(25).padding(20)
                .backgroundColor(.green).cornerRadius(45).padding(20)
                .backgroundColor(.blue).cornerRadius(65)
            UIImageView()
                .image(.init(systemName: "xmark"))
                .tintColor(.black)
        }
    }
}

#Preview {
    UIViewControllerPreview {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        return viewController
    }
}
