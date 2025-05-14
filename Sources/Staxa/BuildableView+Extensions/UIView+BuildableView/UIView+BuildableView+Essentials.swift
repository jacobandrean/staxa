//
//  UIView+BuildableView.swift
//  Staxa
//
//  Created by Jacob Andrean on 04/03/25.
//

import Combine
import UIKit

/*
 // MARK: - Hierarchy
 
 NSObject
 --- UIResponder
 ------UIView
 ---------UIImageView, UILabel, UIProgressView,
 ---------UIActivityIndicatorView, UIVisualEffectView, MKMapView
 ---------UIControl
 -------------UIButton, UISwitch, UISlider, UITextField,
 -------------UISegmentedControl, UIStepper, UIDatePicker,
 -------------UIPageControl
 ---------UIScrollView
 -------------UITableView, UICollectionView, UITextView, UIStackView
 */

extension UIView: BuildableView {}

public extension BuildableView where Self: UIView {
    /// BuildableView: set `keyPath` with `value`
    @discardableResult
    func set<T>(_ keyPath: ReferenceWritableKeyPath<Self, T>, with value: T) -> Self {
        self[keyPath: keyPath] = value
        return self
    }
    
    // MARK: - Bind with cancellables parameters
    /// Binds a `@Published`or `any Publisher` to the `UIView`
    @discardableResult
    func bind<T, P: Publisher>(
        to publisher: P,
        keyPath: ReferenceWritableKeyPath<Self, T>,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self where P.Output == T, P.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: keyPath, on: self)
            .store(in: &cancellables)
        return self
    }
    
    /// Binds a `CurrentValueSubject` to the `UIView`
    @discardableResult
    func bind<T>(
        to subject: CurrentValueSubject<T, Never>,
        keyPath: ReferenceWritableKeyPath<Self, T>,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self {
        return bind(
            to: subject.eraseToAnyPublisher(),
            keyPath: keyPath,
            storeIn: &cancellables
        )
    }
    
    /// Binds a `PassthroughSubject` to the `UIView`
    @discardableResult
    func bind<T>(
        to subject: PassthroughSubject<T, Never>,
        keyPath: ReferenceWritableKeyPath<Self, T>,
        storeIn cancellables: inout Set<AnyCancellable>
    ) -> Self {
        return bind(
            to: subject.eraseToAnyPublisher(),
            keyPath: keyPath,
            storeIn: &cancellables
        )
    }
    
    // MARK: - Bind and store to viewCancellables
    /// BuildableView: Binds a `@Published`or `any Publisher` to the `NSObject`
    @discardableResult
    func bind<T, P: Publisher>(
        _ publisher: P,
        to keyPath: ReferenceWritableKeyPath<Self, T>
    ) -> Self where P.Output == T, P.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: keyPath, on: self)
            .store(in: &viewCancellables)
        return self
    }
    
    /// BuildableView: Binds a `PassthroughSubject` to the `NSObject`
    @discardableResult
    func bind<T>(
        _ subject: PassthroughSubject<T, Never>,
        to keyPath: ReferenceWritableKeyPath<Self, T>
    ) -> Self {
        return bind(subject.eraseToAnyPublisher(), to: keyPath)
    }

    /// BuildableView: Binds a `CurrentValueSubject` to the `NSObject`
    @discardableResult
    func bind<T>(
        _ subject: CurrentValueSubject<T, Never>,
        to keyPath: ReferenceWritableKeyPath<Self, T>
    ) -> Self {
        return bind(subject.eraseToAnyPublisher(), to: keyPath)
    }
    
    // MARK: Sink
    @discardableResult
    func sink<T, P: Publisher>(
        _ publisher: P,
        receiveValue: @escaping (Self, T) -> Void
    ) -> Self where P.Output == T, P.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { receiveValue(self, $0) }
            .store(in: &viewCancellables)
        return self
    }
    
    /// Binds a `CurrentValueSubject` using `sink` to execute custom logic
    @discardableResult
    func sink<T>(
        _ subject: CurrentValueSubject<T, Never>,
        receiveValue: @escaping (Self, T) -> Void
    ) -> Self {
        return sink(
            subject.eraseToAnyPublisher(),
            receiveValue: receiveValue
        )
    }
    
    /// Binds a `PassthroughSubject` using `sink` to execute custom logic
    @discardableResult
    func sink<T>(
        _ subject: PassthroughSubject<T, Never>,
        receiveValue: @escaping (Self, T) -> Void
    ) -> Self {
        return sink(
            subject.eraseToAnyPublisher(),
            receiveValue: receiveValue
        )
    }
    
    @discardableResult
    func sink<T1, T2, P1: Publisher, P2: Publisher>(
        _ publisher1: P1,
        _ publisher2: P2,
        receiveValue: @escaping (Self, T1, T2) -> Void
    ) -> Self where P1.Output == T1, P2.Output == T2, P1.Failure == Never, P2.Failure == Never {
        Publishers.CombineLatest(publisher1, publisher2)
            .receive(on: DispatchQueue.main)
            .sink { receiveValue(self, $0, $1) }
            .store(in: &viewCancellables)
        return self
    }
    
    @discardableResult
    func sink<T1, T2, T3, P1: Publisher, P2: Publisher, P3: Publisher>(
        _ publisher1: P1,
        _ publisher2: P2,
        _ publisher3: P3,
        receiveValue: @escaping (Self, T1, T2, T3) -> Void
    ) -> Self where P1.Output == T1, P2.Output == T2, P3.Output == T3,
                    P1.Failure == Never, P2.Failure == Never, P3.Failure == Never {
        Publishers.CombineLatest3(publisher1, publisher2, publisher3)
            .receive(on: DispatchQueue.main)
            .sink { receiveValue(self, $0, $1, $2) }
            .store(in: &viewCancellables)
        return self
    }
    
    // MARK: -
    @discardableResult
    func transferviewCancellables(to cancellables: inout Set<AnyCancellable>) -> Self {
        cancellables.formUnion(viewCancellables)
        viewCancellables.removeAll()
        return self
    }
}

// MARK: - Helpers
final class UIViewStorage {
    var cancellables = Set<AnyCancellable>()
    var tapGestureAction: (() -> Void)?
    var ignoreSafeArea: UIRectEdge = []
}

extension UIView {
    private static let associatedObject = AssociatedObject<UIViewStorage>()
    
    private var storage: UIViewStorage {
        if let storage = Self.associatedObject.get(for: self) {
            return storage
        } else {
            let newStorage = UIViewStorage()
            Self.associatedObject.set(newStorage, for: self)
            return newStorage
        }
    }
    
    public var viewCancellables: Set<AnyCancellable> {
        get { storage.cancellables }
        set { storage.cancellables = newValue }
    }
    
    // MARK: - ignoreSafeArea
    var ignoreSafeArea: UIRectEdge {
        get { storage.ignoreSafeArea }
        set { storage.ignoreSafeArea = newValue }
    }
    
    // MARK: - tapGestureAction
    var tapGestureAction: (() -> Void)? {
        get { storage.tapGestureAction }
        set {
            storage.tapGestureAction = newValue
            isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
            gestureRecognizers?
                .filter { $0 is UITapGestureRecognizer }
                .forEach(removeGestureRecognizer)
            addGestureRecognizer(tapGesture)
        }
    }
    
    @objc private func handleTapGesture() {
        tapGestureAction?()
    }
}
