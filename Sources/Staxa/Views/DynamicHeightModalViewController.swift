//
//  DynamicHeightModalViewController.swift
//  Staxa
//
//  Created by Avows Technologies on 14/05/25.
//

import UIKit
import SwiftUI

// MARK: - DynamicHeightModalViewController
protocol DynamicHeightModalConfigurable {
    var isDismissable: Bool { get set }
    var ignoresBottomSafeArea: Bool { get set }
}

open class DynamicHeightModalViewController: UIViewController, DynamicHeightModalConfigurable {
    public var isDismissable: Bool = true
    public var ignoresBottomSafeArea: Bool = false
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    open var modalView: UIView {
        UIView()
    }
    
    lazy var contentView: UIView = {
        let view = modalView
        return view
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor(.white)
            .addSubviews(contentView)
        
        contentView
            .topConstraint(equalTo: view)
            .leadingConstraint(equalTo: view)
            .trailingConstraint(equalTo: view)
    }
}

public extension DynamicHeightModalViewController {
    @discardableResult
    func isDismissable(_ isDismissable: Bool) -> Self {
        self.isDismissable = isDismissable
        return self
    }
    
    @discardableResult
    func ignoresBottomSafeArea(_ ignores: Bool) -> Self {
        self.ignoresBottomSafeArea = ignores
        return self
    }
}

public class DynamicHeightModalPresentationController: UIPresentationController {
    private let dimmingView = UIView()
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var initialY: CGFloat = 0
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
        setupPanGesture()
    }
    
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView,
              let presentedVC = presentedViewController as? DynamicHeightModalViewController else { return .zero }
        
        presentedVC.contentView.setNeedsLayout()
        presentedVC.contentView.layoutIfNeeded()
        
        // Calculate the stackView height
        let bottomPadding = presentedVC.ignoresBottomSafeArea ? 0 : containerView.safeAreaInsets.bottom
        let targetHeight = presentedVC.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + bottomPadding
        let maxHeight = containerView.bounds.height * 0.9  // Limit height to 90% of the screen
        
        // Use the calculated height or limit to 90% of the screen height
        let height = min(targetHeight, maxHeight)
        
        return CGRect(
            x: 0,
            y: containerView.bounds.height - height,
            width: containerView.bounds.width,
            height: height
        )
    }
    
    public override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)

        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 1
            })
        } else {
            dimmingView.alpha = 1
        }
    }
    
    public override func dismissalTransitionWillBegin() {
        if let transitionCoordinator = presentingViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            })
        } else {
            dimmingView.alpha = 0
        }
    }
    
    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }
}

extension DynamicHeightModalPresentationController {
    private func setupDimmingView() {
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
    }
    
    @objc
    private func dimmingViewTapped() {
        guard let modalConfigurable = presentedViewController as? DynamicHeightModalConfigurable,
              modalConfigurable.isDismissable else { return }
        presentedViewController.dismiss(animated: true)
    }
    
    private func setupPanGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        presentedView?.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let presentedView,
              let modalConfigurable = presentedViewController as? DynamicHeightModalConfigurable,
              modalConfigurable.isDismissable else { return }
        
        let translation = gesture.translation(in: presentedView)
        let velocity = gesture.velocity(in: presentedView)
        
        switch gesture.state {
        case .began:
            initialY = presentedView.frame.origin.y
        case .changed:
            if translation.y > 0 {  // Only drag downwards
                presentedView.frame.origin.y = initialY + translation.y
            }
        case .ended:
            let dismissThreshold: CGFloat = 200  // Distance to dismiss
            let shouldDismiss = translation.y > dismissThreshold || velocity.y > 1000
            
            if shouldDismiss {
                UIView.animate(withDuration: 0.3, animations: {
                    presentedView.frame.origin.y = self.containerView?.bounds.height ?? UIScreen.main.bounds.height
                    self.dimmingView.alpha = 0
                }) { _ in
                    self.presentedViewController.dismiss(animated: false)
                }
            } else {
                // Revert to original position if not dismissed
                UIView.animate(withDuration: 0.3) {
                    presentedView.frame.origin.y = self.initialY
                }
            }
        default:
            break
        }
    }
}

extension DynamicHeightModalViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        switch presented {
        case is DynamicHeightModalViewController:
            return DynamicHeightModalPresentationController(
                presentedViewController: presented,
                presenting: presenting
            )
        default:
            return UIPresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
}


// MARK: - Demo
#Preview {
    UIViewControllerPreview {
        MyViewController()
    }
}

fileprivate class MyViewController: StaxaViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let button = UIButton(type: .system)
        button.setTitle("Open Modal", for: .normal)
        button.addTarget(self, action: #selector(openModal), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func openModal() {
        let baseModal = MyModal()
            .isDismissable(false)
            .ignoresBottomSafeArea(true)
        present(baseModal, animated: true, completion: nil)
    }
}

fileprivate class MyModal: DynamicHeightModalViewController {
    override var modalView: UIView {
        return VStackView(spacing: 0) {
            Array(0...3).compactMap {
                UILabel()
                    .text("item \($0)")
                    .textAlignment(.center)
            }
        }
        .backgroundColor(.red)
        .onTapGesture {
            self.dismiss(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.cornerRadius([.topLeft, .topRight], 30)
    }
}
